`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/06 15:00:15
// Design Name: 
// Module Name: top_sec_encode
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


module top_sec_encode(
    input clk,
    input rst_n,

    // 8-bit parallel input (one byte per valid pulse)
    input i_valid_byte,
    input [7:0] i_data_byte,

    // 9-bit serial output (valid indicates output word on each cycle)
    output wire o_valid_serial,
    output wire [8:0] o_data_serial
    );

    // Assemble 8 bytes into 64-bit word using S2P, then feed sec_encoder -> 72-bit codeword -> P2S converts to 9-bit stream

    wire [63:0] data64;
    wire data64_valid;

    // Use S2P to assemble 8 input bytes (8-bit) into 64-bit word
    ser_parral_trans #(.SERIAL_WIDTH(8), .PARRAL_WIDTH(64)) input_s2p (
        .clk(clk),
        .rst_n(rst_n),
        .o_data_parral(data64),
        .o_valid_parral_data(data64_valid),
        .i_valid_serial_data(i_valid_byte),
        .i_data_serial(i_data_byte)
    );

    // encoder wires
    wire enc_valid_out;
    wire [71:0] enc_codeword;

    // instantiate SEC encoder
    sec_encoder enc (
        .clk(clk),
        .rst_n(rst_n),
        .i_data(data64),
        .i_valid_datain(data64_valid),
        .i_valid_dataout(enc_valid_out),
        .o_data_crypt(enc_codeword)
    );

    // Register encoder outputs for stable timing to P2S
    reg [71:0] enc_codeword_r;
    reg enc_valid_r;

    // Use P2S to convert 72-bit codeword into 9-bit serial stream
    wire p2s_valid_serial;
    wire [8:0] p2s_data_serial;
    
    parral_ser_trans #(.PARRAL_WIDTH(72), .SERIAL_WIDTH(9)) output_p2s (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid_parral(enc_valid_r),
        .i_data_parral(enc_codeword_r),
        .o_valid_serial(p2s_valid_serial),
        .o_data_serial(p2s_data_serial),
        .error()
    );

    // Connect P2S output to module output
    assign o_valid_serial = p2s_valid_serial;
    assign o_data_serial = p2s_data_serial;

    // Capture encoder output and forward to P2S for serialization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enc_codeword_r <= 72'b0;
            enc_valid_r <= 1'b0;
        end else begin
            if (enc_valid_out) begin
                enc_codeword_r <= enc_codeword;
                enc_valid_r <= 1'b1;
            end else begin
                enc_valid_r <= 1'b0;
            end
        end
    end

    // debug display
    always @(posedge clk) begin
        if (data64_valid) $display("[top_sec_encode] assembled 64-bit at %0t data=0x%0h", $time, data64);
        if (i_valid_byte) $display("[top_sec_encode] recv byte 0x%0h at %0t", i_data_byte, $time);
    end

endmodule
