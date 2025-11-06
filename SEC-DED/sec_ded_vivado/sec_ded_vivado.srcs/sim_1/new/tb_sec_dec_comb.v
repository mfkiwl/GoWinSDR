`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/06 14:41:32
// Design Name: 
// Module Name: tb_sec_dec_comb
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


`timescale 1ns / 1ps

module tb_sec_dec_comb;
    reg [63:0] data_in;
    wire [71:0] cw;

    // combinational encoder and decoder
    sec_encoder_comb enc (.i_data(data_in), .o_codeword(cw));
    reg [71:0] cw_in;
    wire [63:0] dec_data;
    wire dec_valid;
    wire dec_uncorr;
    sec_decoder_comb dec (.i_codeword(cw_in), .o_data(dec_data), .o_valid(dec_valid), .o_uncorrectable(dec_uncorr));

    integer pass_count, fail_count;

    initial begin
        $dumpfile("tb_sec_dec_comb.vcd");
        $dumpvars(0, tb_sec_dec_comb);

        pass_count = 0; fail_count = 0;

        // test vectors
        run_case(64'h0123_4567_89AB_CDEF);
        run_case(64'h8000_0000_0000_0001);
        run_case(64'hFFFF_FFFF_FFFF_FFFF);
        run_case(64'h0000_0000_0000_0000);

        $display("COMBINATIONAL TB RESULT: pass=%0d fail=%0d", pass_count, fail_count);
        $finish;
    end

    task run_case(input [63:0] d);
        reg [71:0] cw_nom;
        reg [71:0] cw1;
        reg [71:0] cw2;
        integer b1, b2;
        begin
            data_in = d;
            #1; // wait for enc combinational output
            cw_nom = cw;
            $display("CASE: data=0x%016h codeword=0x%018h", d, cw_nom);

            // 1) no error
            cw_in = cw_nom;
            #1;
            if (dec_valid && dec_data == d && !dec_uncorr) begin
                $display("  [NO ERR] PASS"); pass_count = pass_count + 1;
            end else begin
                $display("  [NO ERR] FAIL: dec_data=0x%016h valid=%b uncorr=%b", dec_data, dec_valid, dec_uncorr); fail_count = fail_count + 1;
            end

            // 2) single-bit error
            cw1 = cw_nom;
            b1 = 10; // flip a data bit (index in codeword)
            cw1[b1] = ~cw1[b1];
            cw_in = cw1; #1;
            if (dec_valid && dec_data == d && !dec_uncorr) begin
                $display("  [1-BIT] PASS: corrected bit %0d", b1); pass_count = pass_count + 1;
            end else begin
                $display("  [1-BIT] FAIL: dec_data=0x%016h valid=%b uncorr=%b", dec_data, dec_valid, dec_uncorr); fail_count = fail_count + 1;
            end

            // 3) double-bit error
            cw2 = cw_nom;
            b1 = 12; b2 = 25;
            cw2[b1] = ~cw2[b1];
            cw2[b2] = ~cw2[b2];
            cw_in = cw2; #1;
            if (!dec_valid && dec_uncorr) begin
                $display("  [2-BIT] PASS: detected uncorrectable bits %0d,%0d", b1, b2); pass_count = pass_count + 1;
            end else begin
                $display("  [2-BIT] FAIL: dec_data=0x%016h valid=%b uncorr=%b", dec_data, dec_valid, dec_uncorr); fail_count = fail_count + 1;
            end

            #1;
        end
    endtask

endmodule
