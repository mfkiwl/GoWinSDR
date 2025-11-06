`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/06 11:13:51
// Design Name: 
// Module Name: sec_encoder
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


module sec_encoder
(
    input clk
,   input rst_n

,   input [63:0] i_data
,   input i_valid_datain

,   output reg i_valid_dataout
,   output reg [71:0] o_data_crypt
    );
// Implementation notes:
// - Codeword positions are 1..72 (1-based). We map them into vector indexes [0]=pos1 ... [71]=pos72.
// - Parity bits (Hamming) are placed at positions 1,2,4,8,16,32,64 (powers of two).
// - Overall parity (for DED) is placed at position 72 (the last bit).
// - Data bits (64 bits) are filled into positions that are NOT the parity positions nor position 72,
//   in ascending order: i_data[0] -> lowest data position, etc. The decoder uses the same mapping.

    integer pos, p, d_idx;
    reg [71:0] tmp;
    reg parity_bit;

    always @(*) begin
        // clear
        tmp = 72'b0;
        // place data bits into non-parity positions (positions 1..72, skip powers of two and pos 72)
        d_idx = 0;
        for (pos = 1; pos <= 72; pos = pos + 1) begin
            // skip parity positions 1,2,4,8,16,32,64 and overall parity pos 72
            if (pos == 72 || (pos & (pos - 1)) == 0) begin
                // parity / overall parity: leave for later
            end else begin
                if (d_idx < 64) begin
                    tmp[pos-1] = i_data[d_idx];
                end else begin
                    tmp[pos-1] = 1'b0; // safety
                end
                d_idx = d_idx + 1;
            end
        end

        // compute Hamming parity bits for positions 1,2,4,8,16,32,64
        // Each parity bit covers all positions where its bit is set in binary representation
        // We XOR all covered positions (including data and other parity bits, but not overall parity at pos 72)
        for (p = 0; p < 7; p = p + 1) begin:Hamming_parity_compute
            integer pow2;
            pow2 = 1 << p; // parity position (1-based)
            parity_bit = 1'b0;
            for (pos = 1; pos <= 71; pos = pos + 1) begin
                // XOR positions where bit p is set, excluding position 72 (overall parity)
                if ((pos & pow2) != 0) begin
                    parity_bit = parity_bit ^ tmp[pos-1];
                end
            end
            tmp[pow2-1] = parity_bit; // write parity
        end

        // compute overall parity (even) placed at position 72
        // overall parity is XOR of bits at positions 1..71 (first 71 bits)
        tmp[71] = ^tmp[70:0];
    end

    // register outputs on valid input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_data_crypt <= 72'b0;
            i_valid_dataout <= 1'b0;
        end else begin
            if (i_valid_datain) begin
                o_data_crypt <= tmp;
                i_valid_dataout <= 1'b1;
                $display("[sec_encoder] time=%0t data=0x%0h code=0x%0h", $time, i_data, tmp);
            end else begin
                i_valid_dataout <= 1'b0;
            end
        end
    end

endmodule
