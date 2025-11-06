`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/06 11:22:23
// Design Name: 
// Module Name: sec_decoder_comb
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

// Combinational SEC-DED decoder for codeword 72 -> data 64
// - Inputs: full 72-bit codeword (positions 1..72 -> bits [0..71])
// - Outputs: corrected 64-bit data, o_valid = 1 when correctable/no-error, o_uncorrectable = 1 when detected double-bit error
module sec_decoder_comb(
    input  [71:0] i_codeword,
    output reg [63:0] o_data,
    output reg o_valid,
    output reg o_uncorrectable
);
    integer pos, p, d_idx;
    reg [71:0] rec;
    reg [6:0] syndrome_bits;
    reg [6:0] syndrome_value;
    reg overall_parity;
    reg [71:0] corrected;
    reg [63:0] extracted;

    always @(*) begin
        rec = i_codeword;
        syndrome_bits = 7'b0;

        // compute syndrome bits: compare expected parity from data positions with received parity bits
        for (p = 0; p < 7; p = p + 1) begin
            integer pow2;
            reg parity_expected;
            reg parity_mismatch;
            pow2 = 1 << p;
            parity_expected = 1'b0;
            for (pos = 1; pos <= 71; pos = pos + 1) begin
                if (pos == 72 || (pos & (pos - 1)) == 0) begin
                    // skip parity and overall parity
                end else begin
                    if ((pos & pow2) != 0) parity_expected = parity_expected ^ rec[pos-1];
                end
            end
            parity_mismatch = parity_expected ^ rec[pow2-1];
            syndrome_bits[p] = parity_mismatch;
        end

        // syndrome value
        syndrome_value = 7'b0;
        for (p = 0; p < 7; p = p + 1) if (syndrome_bits[p]) syndrome_value = syndrome_value + (1<<p);

        // overall parity across all 72 bits
        overall_parity = ^rec;

        corrected = rec;
        o_uncorrectable = 1'b0;

        if (syndrome_value == 0) begin
            if (overall_parity == 1'b1) begin
                // overall parity bit wrong
                corrected[71] = ~rec[71];
            end
            // else no error
        end else begin
            if (overall_parity == 1'b1) begin
                // single-bit error at syndrome_value
                if (syndrome_value >= 1 && syndrome_value <= 72) corrected[syndrome_value-1] = ~rec[syndrome_value-1];
            end else begin
                // double-bit detected
                o_uncorrectable = 1'b1;
            end
        end

        // extract 64-bit data from corrected codeword
        d_idx = 0;
        extracted = 64'b0;
        for (pos = 1; pos <= 72; pos = pos + 1) begin
            if (pos == 72 || (pos & (pos - 1)) == 0) begin
                // skip parity / overall parity
            end else begin
                if (d_idx < 64) begin
                    extracted[d_idx] = corrected[pos-1];
                end
                d_idx = d_idx + 1;
            end
        end

        // valid if not uncorrectable
        if (o_uncorrectable) begin
            o_valid = 1'b0;
        end else begin
            o_valid = 1'b1;
        end

        o_data = extracted;
    end

endmodule
