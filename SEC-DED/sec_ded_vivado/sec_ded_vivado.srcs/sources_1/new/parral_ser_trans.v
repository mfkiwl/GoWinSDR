`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/06 11:13:51
// Design Name: 
// Module Name: parral_ser_trans
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


module parral_ser_trans
#(
    parameter PARRAL_WIDTH = 72,
    parameter SERIAL_WIDTH = 8
)
(
    input clk
,   input i_valid_parral
,   input [PARRAL_WIDTH-1:0] i_data_parral

,   output o_valid_serial
,   output [SERIAL_WIDTH-1:0] o_data_serial
);

endmodule
