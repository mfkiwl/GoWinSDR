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

    // serial 9-bit input (from channel)
    input i_valid_serial,
    input [8:0] i_data_serial,

    // 8-bit parallel output (one byte per valid)
    output reg o_valid_byte,
    output reg [7:0] o_data_byte,

    // error flag: 1 if decoded codeword had uncorrectable error
    output reg o_uncorrectable
    );

    // Assemble 72-bit from serial bytes, decode to 64-bit, then present bytes sequentially

    wire [71:0] rec_codeword;
    wire rec_valid_parral;

    // instantiate serial->parallel (72->9) to collect incoming words
    ser_parral_trans #(.SERIAL_WIDTH(9), .PARRAL_WIDTH(72)) s2p (
        .clk(clk),
        .rst_n(rst_n),
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
    // Use P2S module to convert 64-bit decoded data to 8-bit serial stream
    reg [63:0] out_buffer_reg;
    reg out_buffer_valid;
    reg out_buffer_uncorr;

    // Latch decoder output and prepare for P2S
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_buffer_reg <= 64'b0;
            out_buffer_valid <= 1'b0;
            out_buffer_uncorr <= 1'b0;
        end else begin
            // When decoder produces output, latch it for P2S
            if (dec_valid_out || dec_uncorrectable) begin
                out_buffer_reg <= dec_data;
                out_buffer_valid <= 1'b1;
                out_buffer_uncorr <= dec_uncorrectable;
            end else begin
                out_buffer_valid <= 1'b0;
            end
        end
    end

    // Use P2S to convert 64-bit to 8-bit serial
    wire p2s_valid_serial;
    wire [7:0] p2s_data_serial;
    
    parral_ser_trans #(.PARRAL_WIDTH(64), .SERIAL_WIDTH(8)) output_p2s (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid_parral(out_buffer_valid),
        .i_data_parral(out_buffer_reg),
        .o_valid_serial(p2s_valid_serial),
        .o_data_serial(p2s_data_serial),
        .error()
    );

    // Capture P2S output and add uncorrectable flag
    reg uncorr_sr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uncorr_sr <= 1'b0;
        end else begin
            // Latch uncorrectable flag when P2S starts outputting
            if (out_buffer_valid && !p2s_valid_serial) begin
                uncorr_sr <= out_buffer_uncorr;
            end else if (!p2s_valid_serial) begin
                uncorr_sr <= 1'b0;
            end
        end
    end

    // Connect P2S output to module output
    always @(posedge clk) begin
        o_valid_byte <= p2s_valid_serial;
        o_data_byte <= p2s_data_serial;
        o_uncorrectable <= (p2s_valid_serial) ? uncorr_sr : 1'b0;
    end

    // // debug prints
    // always @(posedge clk) begin
    //     if (rec_valid_parral) $display("[top_sec_decode] rec_codeword ready at %0t code=0x%0h", $time, rec_codeword);
    //     if (dec_valid_out) $display("[top_sec_decode] decoder valid at %0t data=0x%0h", $time, dec_data);
    //     if (o_valid_byte) $display("[top_sec_decode] out byte 0x%0h at %0t uncorr=%b", o_data_byte, $time, o_uncorrectable);
    // end

endmodule
