`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: ser_parral_trans_pipelined
// Description: 
//   Pipelined serial-to-parallel converter with continuous throughput.
//   Accepts SERIAL_WIDTH bits per cycle and outputs PARRAL_WIDTH bits 
//   every (PARRAL_WIDTH/SERIAL_WIDTH) cycles.
//   
//   Key features:
//   - Continuous data flow (no backpressure needed)
//   - No stall cycles between outputs
//   - Assumes PARRAL_WIDTH is an integer multiple of SERIAL_WIDTH
//   - Assumes downstream processing rate is sufficient (no overflow)
//
// Parameters:
//   SERIAL_WIDTH  : Width of input serial data (default: 8 bits)
//   PARRAL_WIDTH  : Width of output parallel data (default: 64 bits)
//
// Ports:
//   clk              : Clock input
//   rst_n            : Active-low asynchronous reset
//   i_valid_serial   : Input valid signal (high indicates valid serial data)
//   i_data_serial    : Input serial data (SERIAL_WIDTH bits)
//   o_valid_parral   : Output valid signal (high indicates valid parallel data)
//   o_data_parral    : Output parallel data (PARRAL_WIDTH bits)
//
//////////////////////////////////////////////////////////////////////////////////

module ser_parral_trans_pipelined
#(
    parameter SERIAL_WIDTH = 8,
    parameter PARRAL_WIDTH = 64
)
(
    input clk,
    input rst_n,
    
    // Serial input interface
    input i_valid_serial,
    input [SERIAL_WIDTH-1:0] i_data_serial,
    
    // Parallel output interface
    output reg o_valid_parral,
    output reg [PARRAL_WIDTH-1:0] o_data_parral
);

    // Number of serial words needed to form one parallel word
    localparam integer WORDS = PARRAL_WIDTH / SERIAL_WIDTH;
    
    // Counter width to track position within parallel word
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction
    
    localparam integer CNT_WIDTH = clog2(WORDS);
    
    // ============================================================================
    // Storage: shift register or collection buffer for incoming serial data
    // ============================================================================
    reg [PARRAL_WIDTH-1:0] buffer;
    reg [CNT_WIDTH-1:0] word_count;  // Tracks how many SERIAL_WIDTH chunks we've collected
    
    // ============================================================================
    // Main logic: collect serial words and emit parallel words
    // ============================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer <= {PARRAL_WIDTH{1'b0}};
            word_count <= {CNT_WIDTH{1'b0}};
            o_valid_parral <= 1'b0;
            o_data_parral <= {PARRAL_WIDTH{1'b0}};
        end
        else begin
            // Default: no output this cycle
            o_valid_parral <= 1'b0;
            
            if (i_valid_serial) begin
                // Shift incoming serial data into buffer at current position
                buffer[word_count * SERIAL_WIDTH +: SERIAL_WIDTH] <= i_data_serial;
                
                if (word_count == WORDS - 1) begin
                    // We just completed collecting a full parallel word
                    // Output the buffer (with the newly shifted-in data)
                    o_data_parral <= {buffer[PARRAL_WIDTH - SERIAL_WIDTH - 1:0], i_data_serial};
                    o_valid_parral <= 1'b1;
                    word_count <= {CNT_WIDTH{1'b0}};
                    
                    $display("[ser_parral_trans_pipelined] OUTPUT at %0t: 0x%0h", 
                             $time, {buffer[PARRAL_WIDTH - SERIAL_WIDTH - 1:0], i_data_serial});
                end
                else begin
                    // Still collecting; move to next position
                    word_count <= word_count + 1;
                    $display("[ser_parral_trans_pipelined] CAPTURE at %0t: idx=%0d data=0x%0h", 
                             $time, word_count, i_data_serial);
                end
            end
            // If no valid input, maintain current state and wait for next data
        end
    end

endmodule
