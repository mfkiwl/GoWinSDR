`timescale 1ns / 1ps

module parral_ser_trans
#(
    parameter PARRAL_WIDTH = 72,
    parameter SERIAL_WIDTH = 8,
    parameter DEPTH = 4
)
(
    input clk,
    input rst_n,
    input i_valid_parral,
    input [PARRAL_WIDTH-1:0] i_data_parral,
    output reg o_valid_serial,
    output reg [SERIAL_WIDTH-1:0] o_data_serial
);

    localparam integer WORDS = PARRAL_WIDTH / SERIAL_WIDTH;
    
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
    localparam integer PTR_W = (DEPTH > 1) ? clog2(DEPTH) : 1;
    
    // FIFO storage
    reg [PARRAL_WIDTH-1:0] fifo [0:DEPTH-1];
    reg [PTR_W-1:0] wptr, rptr;
    reg [PTR_W:0] fifo_count;
    
    // Serialization state
    reg [PARRAL_WIDTH-1:0] ser_buffer;
    reg [CNT_WIDTH-1:0] ser_idx;
    reg ser_active;
    
    integer fi;
    
    // Combinational output logic
    always @(*) begin
        if (ser_active) begin
            o_valid_serial = 1'b1;
            o_data_serial = ser_buffer[ser_idx * SERIAL_WIDTH +: SERIAL_WIDTH];
        end
        else begin
            o_valid_serial = 1'b0;
            o_data_serial = {SERIAL_WIDTH{1'b0}};
        end
    end
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= 0;
            rptr <= 0;
            fifo_count <= 0;
            ser_buffer <= 0;
            ser_idx <= 0;
            ser_active <= 1'b0;
            for (fi = 0; fi < DEPTH; fi = fi + 1) 
                fifo[fi] <= 0;
        end
        else begin
            // Push to FIFO if input is valid and FIFO not full
            if (i_valid_parral && fifo_count < DEPTH) begin
                fifo[wptr] <= i_data_parral;
                wptr <= (wptr == DEPTH - 1) ? 0 : wptr + 1;
                $display("[P2S] PUSH: data=0x%h, count=%0d->%0d", i_data_parral, fifo_count, fifo_count + 1);
            end
            
            // Serialize current buffer if active
            if (ser_active) begin
                if (ser_idx == WORDS - 1) begin
                    // Last word of current buffer - transition to next
                    ser_idx <= 0;
                    if (fifo_count > 0) begin
                        // Pop next from FIFO and continue
                        ser_buffer <= fifo[rptr];
                        rptr <= (rptr == DEPTH - 1) ? 0 : rptr + 1;
                        $display("[P2S] POP & CONTINUE: data=0x%h", fifo[rptr]);
                    end
                    else begin
                        // FIFO empty - stop
                        ser_active <= 1'b0;
                        $display("[P2S] STOP (FIFO empty)");
                    end
                end
                else begin
                    // Not at end - just increment index
                    ser_idx <= ser_idx + 1;
                end
            end
            else begin
                // Not active - check if FIFO has data
                if (fifo_count > 0) begin
                    // Start serialization
                    ser_buffer <= fifo[rptr];
                    rptr <= (rptr == DEPTH - 1) ? 0 : rptr + 1;
                    ser_idx <= 0;
                    ser_active <= 1'b1;
                    $display("[P2S] START: data=0x%h, count=%0d->%0d", fifo[rptr], fifo_count, fifo_count - 1);
                end
            end
            
            // Update FIFO count
            if (i_valid_parral && fifo_count < DEPTH) begin
                if (ser_active && ser_idx == WORDS - 1 && fifo_count > 0) begin
                    // Simultaneous push and pop at transition: count unchanged
                    // fifo_count stays same
                end
                else if (ser_active && ser_idx == WORDS - 1) begin
                    // Pop only: count decreases
                    fifo_count <= fifo_count;  // Net effect after pop
                end
                else begin
                    // Push only or no pop
                    fifo_count <= fifo_count + 1;
                end
            end
            else if (ser_active && ser_idx == WORDS - 1 && fifo_count > 0) begin
                // Pop only
                fifo_count <= fifo_count - 1;
            end
        end
    end

endmodule
