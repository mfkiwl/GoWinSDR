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

    // 8-bit serial output (valid indicates output byte on each cycle)
    output wire o_valid_serial,
    output wire [7:0] o_data_serial
    );

    // Assemble 8 bytes -> 64-bit word, then feed sec_encoder -> 72-bit codeword -> parral_ser_trans

    reg [2:0] byte_cnt;
    reg [63:0] data64;
    reg assembled; // one-cycle pulse to encoder
    reg assembled_req; // request set when last byte arrives, presented as assembled next cycle

    // encoder wires
    wire enc_valid_out;
    wire [71:0] enc_codeword;

    // instantiate SEC encoder
    sec_encoder enc (
        .clk(clk),
        .rst_n(rst_n),
        .i_data(data64),
        .i_valid_datain(assembled),
        .i_valid_dataout(enc_valid_out),
        .o_data_crypt(enc_codeword)
    );

    // instantiate parallel->serial to split 72-bit into 8-bit words
    // We will present the parral->serial with a registered version of encoder outputs
    // to avoid any combinational race between encoder's registered outputs and the
    // p2s module which expects a stable data input when i_valid_parral is asserted.
    reg [71:0] enc_codeword_r;
    reg enc_valid_r;

    parral_ser_trans #(.PARRAL_WIDTH(72), .SERIAL_WIDTH(8)) p2s (
        .clk(clk),
        .i_valid_parral(enc_valid_r),
        .i_data_parral(enc_codeword_r),
        .o_valid_serial(o_valid_serial),
        .o_data_serial(o_data_serial)
    );

    // capture bytes and set assembled flag for one cycle when full
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_cnt <= 3'd0;
            data64 <= 64'b0;
            assembled <= 1'b0;
            assembled_req <= 1'b0;
            enc_codeword_r <= 72'b0;
            enc_valid_r <= 1'b0;
        end else begin
            // default: assembled follows assembled_req (one-cycle delayed pulse)
            assembled <= assembled_req;
            // clear assembled_req after it has been presented
            if (assembled) assembled_req <= 1'b0;

            // register encoder outputs when they become valid so p2s sees stable inputs
            if (enc_valid_out) begin
                enc_codeword_r <= enc_codeword;
                // present a one-cycle valid to p2s next cycle by setting enc_valid_r
                enc_valid_r <= 1'b1;
            end else begin
                // clear register-valid after one cycle
                enc_valid_r <= 1'b0;
            end

            if (i_valid_byte) begin
                data64[byte_cnt*8 +: 8] <= i_data_byte;
                if (byte_cnt == 3'd7) begin
                    // collected 8 bytes, request encoder on next cycle by setting assembled_req
                    assembled_req <= 1'b1;
                    byte_cnt <= 3'd0;
                end else begin
                    byte_cnt <= byte_cnt + 1'b1;
                end
            end
        end
    end

    // debug display
    always @(posedge clk) begin
        if (assembled) $display("[top_sec_encode] assembled at %0t data64=0x%0h", $time, data64);
        if (i_valid_byte) $display("[top_sec_encode] recv byte 0x%0h cnt=%0d at %0t", i_data_byte, byte_cnt, $time);
    end

endmodule
