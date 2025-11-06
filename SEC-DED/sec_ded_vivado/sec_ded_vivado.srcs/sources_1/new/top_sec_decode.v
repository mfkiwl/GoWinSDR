`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/06 15:00:15
// Design Name: 
// Module Name: top_sec_decode
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


module top_sec_decode(
    input clk,
    input rst_n,

    // serial 8-bit input (from channel)
    input i_valid_serial,
    input [7:0] i_data_serial,

    // 8-bit parallel output (one byte per valid)
    output reg o_valid_byte,
    output reg [7:0] o_data_byte,

    // error flag: 1 if decoded codeword had uncorrectable error
    output reg o_uncorrectable
    );

    // Assemble 72-bit from serial bytes, decode to 64-bit, then present bytes sequentially

    wire [71:0] rec_codeword;
    wire rec_valid_parral;

    // instantiate serial->parallel (72->8) to collect incoming bytes
    ser_parral_trans #(.SERIAL_WIDTH(8), .PARRAL_WIDTH(72)) s2p (
        .clk(clk),
        .o_data_parral(rec_codeword),
        .o_valid_parral_data(rec_valid_parral),
        .i_valid_serial_data(i_valid_serial),
        .i_data_serial(i_data_serial)
    );

    // connect to sec_decoder
    wire dec_valid_out;
    wire [63:0] dec_data;
    wire dec_uncorrectable;

    sec_decoder dec (
        .clk(clk),
        .rst_n(rst_n),
        .o_data_decrypt(dec_data),
        .o_valid_datain(dec_valid_out),
        .o_uncorrectable(dec_uncorrectable),
        .i_valid_dataout(rec_valid_parral),
        .i_data_crypt(rec_codeword)
    );

    // output bytes from decoder when dec_valid_out (or dec_uncorrectable) pulses.
    // To avoid races, latch decoder outputs when they are registered, then start
    // streaming from the next clock cycle.
    reg [2:0] out_idx;
    reg [63:0] out_buffer;
    reg start_stream;
    reg frame_uncorr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_valid_byte <= 1'b0;
            o_data_byte <= 8'b0;
            o_uncorrectable <= 1'b0;
            out_idx <= 3'd0;
            out_buffer <= 64'b0;
            start_stream <= 1'b0;
            frame_uncorr <= 1'b0;
        end else begin
            // default
            o_valid_byte <= 1'b0;

            // when decoder registers a frame (either valid or uncorrectable), latch and
            // prepare to stream starting next cycle
            if (dec_valid_out || dec_uncorrectable) begin
                out_buffer <= dec_data;
                out_idx <= 3'd0;
                start_stream <= 1'b1; // begin streaming next cycle
                frame_uncorr <= dec_uncorrectable;
            end else if (start_stream) begin
                // begin/continue streaming bytes
                o_data_byte <= out_buffer[out_idx*8 +: 8];
                o_valid_byte <= 1'b1;
                o_uncorrectable <= frame_uncorr;
                if (out_idx == 3'd7) begin
                    start_stream <= 1'b0;
                    out_idx <= 3'd0;
                    frame_uncorr <= 1'b0;
                end else begin
                    out_idx <= out_idx + 1'b1;
                end
            end else begin
                // idle
                o_uncorrectable <= 1'b0;
            end
        end
    end

    // debug prints
    always @(posedge clk) begin
        if (rec_valid_parral) $display("[top_sec_decode] rec_codeword ready at %0t code=0x%0h", $time, rec_codeword);
        if (dec_valid_out) $display("[top_sec_decode] decoder valid at %0t data=0x%0h", $time, dec_data);
        if (o_valid_byte) $display("[top_sec_decode] out byte 0x%0h at %0t uncorr=%b", o_data_byte, $time, o_uncorrectable);
    end

endmodule
