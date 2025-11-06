`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/06 14:41:32
// Design Name: 
// Module Name: tb_sec_enc_comb
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

module tb_sec_enc_comb;
    reg [63:0] data_in;
    wire [71:0] cw;

    sec_encoder_comb enc (.i_data(data_in), .o_codeword(cw));

    initial begin
        $dumpfile("tb_sec_enc_comb.vcd");
        $dumpvars(0, tb_sec_enc_comb);

        // test vectors
        test_vector(64'h0123_4567_89AB_CDEF);
        test_vector(64'h8000_0000_0000_0001);
        test_vector(64'hFFFF_FFFF_FFFF_FFFF);
        test_vector(64'h0000_0000_0000_0000);

        $display("tb_sec_enc_comb finished");
        $finish;
    end

    task test_vector(input [63:0] d);
        integer p, pos;
        reg expected;
        begin
            data_in = d;
            #1; // allow combinational outputs to settle
            $display("ENC_COMB: data=0x%016h -> codeword=0x%018h", d, cw);
            // verify parity bits are consistent with data positions
            for (p = 0; p < 7; p = p + 1) begin
                integer pow2;
                pow2 = 1 << p;
                expected = 1'b0;
                for (pos = 1; pos <= 71; pos = pos + 1) begin
                    if (pos == 72 || (pos & (pos - 1)) == 0) begin
                        // skip parity
                    end else begin
                        if ((pos & pow2) != 0) expected = expected ^ cw[pos-1];
                    end
                end
                if (cw[pow2-1] !== expected) $display("  PARITY MISMATCH at pos %0d: enc=%b expected=%b", pow2, cw[pow2-1], expected);
            end
            // overall parity check
            if (cw[71] !== (^cw[70:0])) $display("  OVERALL PARITY MISMATCH: enc=%b expected=%b", cw[71], ^cw[70:0]);
        end
    endtask

endmodule
