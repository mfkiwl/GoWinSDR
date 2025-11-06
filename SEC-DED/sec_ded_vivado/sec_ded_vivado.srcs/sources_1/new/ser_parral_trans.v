`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/06 11:13:51
// Design Name: 
// Module Name: ser_parral_trans
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


module ser_parral_trans
#(
    parameter SERIAL_WIDTH = 8,
    parameter PARRAL_WIDTH = 64
)
(
    input clk

,   output reg [PARRAL_WIDTH-1:0] o_data_parral
,   output reg o_valid_parral_data

,   input i_valid_serial_data
,   input [SERIAL_WIDTH-1:0] i_data_serial
);
        // Simple parameterized serial->parallel converter.
        // Assumes PARRAL_WIDTH is integer multiple of SERIAL_WIDTH.

        localparam integer WORDS = PARRAL_WIDTH / SERIAL_WIDTH;

        // function for clog2
        function integer clog2; input integer value; integer i; begin clog2 = 0; for (i = value - 1; i > 0; i = i >> 1) clog2 = clog2 + 1; end endfunction

        reg [PARRAL_WIDTH-1:0] buffer;
        reg [clog2(WORDS)-1:0] idx;

        initial begin
            buffer = {PARRAL_WIDTH{1'b0}};
            idx = 0;
            o_data_parral = {PARRAL_WIDTH{1'b0}};
            o_valid_parral_data = 1'b0;
        end

        always @(posedge clk) begin
            // default
            o_valid_parral_data <= 1'b0;

                    if (i_valid_serial_data) begin
                        // capture incoming serial word into buffer at current index (blocking so buffer updated immediately)
                        buffer[idx*SERIAL_WIDTH +: SERIAL_WIDTH] = i_data_serial;
                        $display("[ser_parral_trans] capture at %0t idx=%0d data=0x%0h", $time, idx, i_data_serial);
                        if (idx == WORDS - 1) begin
                            // completed the whole parallel word -> present buffer
                            o_data_parral <= buffer;
                            o_valid_parral_data <= 1'b1;
                            idx <= 0;
                        end else begin
                            idx <= idx + 1;
                        end
            end
        end

    endmodule
