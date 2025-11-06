`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/06 11:26:26
// Design Name: 
// Module Name: tb_sec_dec
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// Testbench for encoder + decoder with error injection
`timescale 1ns / 1ps

module tb_sec_dec;

    reg clk;
    reg rst_n;
    reg [63:0] i_data;
    reg i_valid_datain;

    wire enc_valid;
    wire [71:0] enc_cw;

    // decoder inputs
    reg dec_valid_in;
    reg [71:0] dec_cw_in;

    wire [63:0] dec_data_out;
    wire dec_valid_out;

    // instantiate encoder
    sec_encoder enc (
        .clk(clk),
        .rst_n(rst_n),
        .i_data(i_data),
        .i_valid_datain(i_valid_datain),
        .i_valid_dataout(enc_valid),
        .o_data_crypt(enc_cw)
    );

    // instantiate decoder
    ser_parral_trans dec (
        .clk(clk),
        .rst_n(rst_n),
        .o_data_decrypt(dec_data_out),
        .o_valid_datain(dec_valid_out),
        .i_valid_dataout(dec_valid_in),
        .i_data_crypt(dec_cw_in)
    );

    // clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_sec_dec.vcd");
        $dumpvars(0, tb_sec_dec);

        // reset
        rst_n = 0;
        i_data = 64'h0;
        i_valid_datain = 0;
        dec_valid_in = 0;
        dec_cw_in = 72'h0;
        #20;
        rst_n = 1;

        // testcases
        test_case(64'h0123_4567_89AB_CDEF);
        test_case(64'h8000_0000_0000_0001);

        #100;
        $display("tb_sec_dec finished");
        $finish;
    end

    task test_case(input [63:0] data);
        reg [71:0] cw;
        reg [71:0] cw_single_err;
        reg [71:0] cw_double_err;
        integer b1, b2;
        begin
            // drive encoder (stable data before posedge, assert valid at negedge so posedge samples it)
            @(posedge clk);
            i_data = data;
            @(negedge clk);
            i_valid_datain = 1;
            @(posedge clk); // encoder samples and registers outputs
            #1;
            i_valid_datain = 0;
            #1;
            cw = enc_cw;
            $display("TEST: data=0x%016h -> codeword=0x%018h (enc_valid=%b)", data, cw, enc_valid);
            // compute and display syndrome/overall parity in TB for debugging
            compute_syndrome_and_parity(cw);
            check_encoder_parity(cw);

            // 1) no error
            // present codeword to decoder and assert valid around next posedge
            @(posedge clk);
            dec_cw_in = cw;
            @(negedge clk);
            dec_valid_in = 1;
            @(posedge clk);
            #1;
            dec_valid_in = 0;
            #1;
            if (dec_valid_out && dec_data_out == data) begin
                $display("  [NO ERR] PASS: decoded=0x%016h", dec_data_out);
            end else begin
                $display("  [NO ERR] FAIL: decoded=0x%016h valid=%b expected=0x%016h", dec_data_out, dec_valid_out, data);
            end

            // 2) single-bit error -> should be corrected
            cw_single_err = cw;
            b1 = 10; // flip bit 10
            cw_single_err[b1] = ~cw_single_err[b1];
            // single-bit error injection: present at negedge before posedge sampling
            @(posedge clk);
            dec_cw_in = cw_single_err;
            @(negedge clk);
            dec_valid_in = 1;
            @(posedge clk);
            #1;
            dec_valid_in = 0;
            #1;
            if (dec_valid_out && dec_data_out == data) begin
                $display("  [1-BIT] PASS: single-bit at %0d corrected -> decoded=0x%016h", b1, dec_data_out);
            end else begin
                $display("  [1-BIT] FAIL: decoded=0x%016h valid=%b expected=0x%016h", dec_data_out, dec_valid_out, data);
            end

            // 3) double-bit error -> should be detected as uncorrectable (decoder sets valid=0 in our implementation)
            cw_double_err = cw;
            b1 = 12; b2 = 25;
            cw_double_err[b1] = ~cw_double_err[b1];
            cw_double_err[b2] = ~cw_double_err[b2];
            // double-bit error injection
            @(posedge clk);
            dec_cw_in = cw_double_err;
            @(negedge clk);
            dec_valid_in = 1;
            @(posedge clk);
            #1;
            dec_valid_in = 0;
            #1;
            if (!dec_valid_out) begin
                $display("  [2-BIT] PASS: double-bit at %0d,%0d detected as uncorrectable (valid=0)", b1, b2);
            end else begin
                $display("  [2-BIT] FAIL: decoder reported valid=1 decoded=0x%016h (expected invalid)", dec_data_out);
            end

            #20;
        end
    endtask

    // helper: compute syndrome and overall parity for given codeword and display
    task compute_syndrome_and_parity(input [71:0] cw_in);
        integer p, pos;
        reg [6:0] synb;
        integer sval;
        reg overall;
        begin
            synb = 7'b0;
            for (p = 0; p < 7; p = p + 1) begin
                integer pow2;
                integer pos2;
                reg pc;
                pow2 = 1 << p;
                pc = 1'b0;
                for (pos2 = 1; pos2 <= 72; pos2 = pos2 + 1) begin
                    if ((pos2 & pow2) != 0) pc = pc ^ cw_in[pos2-1];
                end
                synb[p] = pc;
            end
            sval = 0;
            for (p = 0; p < 7; p = p + 1) if (synb[p]) sval = sval + (1<<p);
            overall = ^cw_in;
            $display("    TB SYNDROME: bits=%b value=%0d overall_parity=%b", synb, sval, overall);
        end
    endtask

    // Compute expected parity bits from data positions and compare to parity bits embedded in codeword
    task check_encoder_parity(input [71:0] cw_in);
        integer p, pos;
        integer pow2;
        reg expected;
        begin
            $display("    TB PARITY CHECK: parity positions (pos:value) and expected from data");
            for (p = 0; p < 7; p = p + 1) begin
                pow2 = 1 << p;
                expected = 1'b0;
                for (pos = 1; pos <= 72; pos = pos + 1) begin
                    // only data positions (skip parity positions and pos72)
                    if (pos == 72 || (pos & (pos - 1)) == 0) begin
                        // skip
                    end else begin
                        if ((pos & pow2) != 0) expected = expected ^ cw_in[pos-1];
                    end
                end
                $display("      pos%0d: enc=%b expected=%b", pow2, cw_in[pow2-1], expected);
            end
        end
    endtask

endmodule
