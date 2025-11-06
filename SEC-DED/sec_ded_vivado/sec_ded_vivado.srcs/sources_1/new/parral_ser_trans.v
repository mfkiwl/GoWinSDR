`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: parral_ser_trans
// Simple parallel-to-serial without FIFO
// Input: 72-bit parallel, Output: 8-bit serial (one byte per cycle)
//////////////////////////////////////////////////////////////////////////////////

module parral_ser_trans #(
    parameter PARRAL_WIDTH = 72,
    parameter SERIAL_WIDTH = 8
) (
    input                   clk,
    input                   rst_n,
    input                   i_valid_parral,
    input [PARRAL_WIDTH-1:0] i_data_parral,
    output                  o_valid_serial,
    output [SERIAL_WIDTH-1:0] o_data_serial,
    output reg              error
);

localparam NUM_CHUNKS = PARRAL_WIDTH / SERIAL_WIDTH;
localparam CNT_WIDTH = $clog2(NUM_CHUNKS);

reg [PARRAL_WIDTH-1:0] shift_reg;
reg [CNT_WIDTH-1:0]    cnt;
reg                    busy;

// Output assignment
assign o_valid_serial = busy;
assign o_data_serial = shift_reg[SERIAL_WIDTH-1:0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= {PARRAL_WIDTH{1'b0}};
        cnt       <= {CNT_WIDTH{1'b0}};
        busy      <= 1'b0;
        error     <= 1'b0;
    end 
    else begin
        error <= 1'b0;

        // Check if we've finished sending all 9 bytes
        if (cnt == NUM_CHUNKS - 1) begin
            // Last byte is being sent this cycle
            if (i_valid_parral) begin
                // New input arrives at the same time! Switch immediately
                shift_reg <= i_data_parral;
                cnt <= 0;
                busy <= 1'b1;
                $display("[P2S] SWITCH: new input=0x%h", i_data_parral);
            end else begin
                // No new input, go idle
                busy <= 1'b0;
                $display("[P2S] DONE at cnt=%0d\n", cnt);
            end
        end else if (busy) begin
            // Continue sending
            cnt <= cnt + 1;
            shift_reg <= shift_reg >> SERIAL_WIDTH;
        end else if (i_valid_parral) begin
            // Start new transmission (not busy)
            shift_reg <= i_data_parral;
            busy <= 1'b1;
            cnt <= 0;
            $display("[P2S] START: input=0x%h", i_data_parral);
        end
    end
end

endmodule
