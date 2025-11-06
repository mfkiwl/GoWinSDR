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
    // Simple parameterized parallel->serial converter.
    // Assumption: PARRAL_WIDTH is an integer multiple of SERIAL_WIDTH.
    // Behavior:
    // - When i_valid_parral is asserted for one cycle, the module latches i_data_parral and
    //   starts outputting SERIAL_WIDTH-bit words on o_data_serial, one word per clock cycle.
    // - The ordering is low-index first: i_data_parral[0 +: SERIAL_WIDTH] is sent first,
    //   then i_data_parral[SERIAL_WIDTH +: SERIAL_WIDTH], etc.
    // - o_valid_serial is asserted for each output word. After all words have been sent,
    //   the module returns to idle and waits for the next i_valid_parral pulse.

    localparam integer WORDS = PARRAL_WIDTH / SERIAL_WIDTH;
    // function to compute ceil(log2(x))
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    localparam integer IDX_WIDTH = (WORDS > 1) ? clog2(WORDS) : 1;
    // counters and storage
    reg [IDX_WIDTH-1:0] word_cnt;
    reg [IDX_WIDTH:0] words_remaining; // small helper width (one extra bit)
    reg sending;
    reg [PARRAL_WIDTH-1:0] buffer;

    // outputs (registered)
    reg [SERIAL_WIDTH-1:0] data_out_r;
    reg valid_out_r;

    assign o_data_serial = data_out_r;
    assign o_valid_serial = valid_out_r;

    // function to compute ceil(log2(x))
    // Drive state machine
    initial begin
        // initialize registers to known values for simulation
        sending = 1'b0;
        word_cnt = {IDX_WIDTH{1'b0}};
        words_remaining = { (IDX_WIDTH+1) {1'b0} };
        buffer = {PARRAL_WIDTH{1'b0}};
        data_out_r = {SERIAL_WIDTH{1'b0}};
        valid_out_r = 1'b0;
    end

    always @(posedge clk) begin
        // Default outputs
        valid_out_r <= 1'b0;
        data_out_r <= {SERIAL_WIDTH{1'b0}};

        if (!sending) begin
            if (i_valid_parral) begin
                // latch and start sending
                buffer <= i_data_parral;
                $display("[parral_ser_trans] latch at %0t data=0x%0h", $time, i_data_parral);
                sending <= 1'b1;
                word_cnt <= 0;
                // start sending on the next clock: latch buffer now, present first word
                // on the following posedge so receiver can sample it reliably.
                // words_remaining counts how many words still need to be sent.
                words_remaining <= WORDS;
            end
        end else begin
            // currently sending (sending==1)
            if (words_remaining > 0) begin
                // present current indexed word (word_cnt starts at 0 after latch)
                data_out_r <= buffer[word_cnt*SERIAL_WIDTH +: SERIAL_WIDTH];
                word_cnt <= word_cnt + 1;
                valid_out_r <= 1'b1;
                words_remaining <= words_remaining - 1;
            end else begin
                // finished sending last word this cycle; deassert next
                $display("[parral_ser_trans] finished sending at %0t", $time);
                sending <= 1'b0;
                valid_out_r <= 1'b0;
            end
        end
    end

endmodule
