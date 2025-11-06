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


module tb_sec_dec(

    );
endmodule

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
            // drive encoder
            @(negedge clk);
            i_data = data;
            i_valid_datain = 1;
            @(posedge clk); // encoder samples
            i_valid_datain = 0;
            #1;
            cw = enc_cw;
            $display("TEST: data=0x%016h -> codeword=0x%018h (enc_valid=%b)", data, cw, enc_valid);

            // 1) no error
            @(negedge clk);
            dec_cw_in = cw;
            dec_valid_in = 1;
            @(posedge clk);
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
            @(negedge clk);
            dec_cw_in = cw_single_err;
            dec_valid_in = 1;
            @(posedge clk);
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
            @(negedge clk);
            dec_cw_in = cw_double_err;
            dec_valid_in = 1;
            @(posedge clk);
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

endmodule
