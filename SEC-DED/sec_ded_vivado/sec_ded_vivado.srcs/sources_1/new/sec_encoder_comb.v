`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/06 11:22:23
// Design Name: 
// Module Name: sec_encoder_comb
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

// Combinational SEC-DED encoder (64 -> 72)
// - Codeword positions 1..72 map to vector bits [0]=pos1 .. [71]=pos72
// - Parity bits at positions 1,2,4,8,16,32,64 (powers of two)
// - Overall parity (even) at position 72
module sec_encoder_comb(
    input  [63:0] i_data,
    output reg [71:0] o_codeword
);
    integer pos, p, d_idx;
    reg [71:0] tmp;
    reg parity_bit;

    always @(*) begin
        tmp = 72'b0;
        // place data bits into non-parity positions
        d_idx = 0;
        for (pos = 1; pos <= 72; pos = pos + 1) begin
            if (pos == 72 || (pos & (pos - 1)) == 0) begin
                // parity / overall parity: leave for later
            end else begin
                if (d_idx < 64) tmp[pos-1] = i_data[d_idx];
                else tmp[pos-1] = 1'b0;
                d_idx = d_idx + 1;
            end
        end

        // compute Hamming parity bits using only data positions
        for (p = 0; p < 7; p = p + 1) begin
            integer pow2;
            pow2 = 1 << p;
            parity_bit = 1'b0;
            for (pos = 1; pos <= 71; pos = pos + 1) begin
                if (pos == 72 || (pos & (pos - 1)) == 0) begin
                    // skip parity positions and overall parity
                end else begin
                    if ((pos & pow2) != 0) parity_bit = parity_bit ^ tmp[pos-1];
                end
            end
            tmp[pow2-1] = parity_bit;
        end

        // overall parity (even) over positions 1..71
        tmp[71] = ^tmp[70:0];

        o_codeword = tmp;
    end

endmodule
