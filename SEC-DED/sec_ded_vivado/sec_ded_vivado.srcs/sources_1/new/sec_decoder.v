`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/06 11:13:51
// Design Name: 
// Module Name: sec_decoder
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


module sec_decoder
(
    input clk
,   input rst_n

,   output reg [63:0] o_data_decrypt
,   output reg o_valid_datain

,   input i_valid_dataout
,   input [71:0] i_data_crypt
    );
    // The decoder implements SEC-DED for the codeword layout produced by sec_encoder.v
    // - Codeword positions 1..72 (vector index 0..71)
    // - Parity bits at positions 1,2,4,8,16,32,64
    // - Overall parity at position 72
    // Behavior:
    // - On i_valid_dataout asserted, compute syndrome and overall parity.
    // - If single-bit error, correct it and extract 64-bit data.
    // - If double-bit error detected (uncorrectable), output data as-is and deassert valid (or still raise valid but user may check error flag if added).

    integer pos, p, d_idx;
    reg [71:0] rec;
    reg [6:0] syndrome_bits;
    reg [6:0] syndrome_value_bin;
    reg overall_parity;
    reg [71:0] corrected;
    reg uncorrectable;

    always @(*) begin
        rec = i_data_crypt;
        syndrome_bits = 7'b0;
        // compute syndrome bits (p=0..6 -> parity positions 1,2,4...)
        for (p = 0; p < 7; p = p + 1) begin
            integer pow2;
            reg parity_check;
            pow2 = 1 << p;
            parity_check = 1'b0;
            for (pos = 1; pos <= 72; pos = pos + 1) begin
                if ((pos & pow2) != 0) begin
                    parity_check = parity_check ^ rec[pos-1];
                end
            end
            syndrome_bits[p] = parity_check; // 1 if mismatch
        end

        // convert syndrome bits into numeric position (1-based)
        syndrome_value_bin = 7'b0;
        for (p = 0; p < 7; p = p + 1) begin
            if (syndrome_bits[p]) begin
                syndrome_value_bin = syndrome_value_bin + (1 << p);
            end
        end

        // overall parity computed across full received word; for even parity should be 0 when correct
        overall_parity = ^rec; // XOR of all 72 bits

        corrected = rec;
        uncorrectable = 1'b0;

        if (syndrome_value_bin == 0) begin
            if (overall_parity == 1'b1) begin
                // error only in overall parity bit (position 72) -> flip it
                corrected[71] = ~rec[71];
            end else begin
                // no error
            end
        end else begin
            if (overall_parity == 1'b1) begin
                // single-bit error at syndrome_value_bin -> correct
                if (syndrome_value_bin >= 1 && syndrome_value_bin <= 72) begin
                    corrected[syndrome_value_bin - 1] = ~rec[syndrome_value_bin - 1];
                end
            end else begin
                // syndrome != 0 but overall parity == 0 -> detected double-bit error (uncorrectable)
                uncorrectable = 1'b1;
            end
        end
    end

    // extract data bits from corrected word in same mapping as encoder
    reg [63:0] extracted;
    always @(*) begin
        d_idx = 0;
        extracted = 64'b0;
        for (pos = 1; pos <= 72; pos = pos + 1) begin
            if (pos == 72 || (pos & (pos - 1)) == 0) begin
                // parity / overall parity -> skip
            end else begin
                if (d_idx < 64) begin
                    extracted[d_idx] = corrected[pos-1];
                end
                d_idx = d_idx + 1;
            end
        end
    end

    // register outputs synchronously
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_data_decrypt <= 64'b0;
            o_valid_datain <= 1'b0;
        end else begin
            if (i_valid_dataout) begin
                if (uncorrectable) begin
                    // for an uncorrectable error we still present the extracted data but clear the valid flag
                    // Alternatively, user can add an explicit error output to signal uncorrectable condition.
                    o_data_decrypt <= extracted;
                    o_valid_datain <= 1'b0;
                end else begin
                    o_data_decrypt <= extracted;
                    o_valid_datain <= 1'b1;
                end
            end else begin
                o_valid_datain <= 1'b0;
            end
        end
    end

endmodule
