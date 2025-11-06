

`timescale 1ns / 1ps

module tb_serpara_trans;
    // Parameters to match modules
    localparam PARRAL_WIDTH = 72;
    localparam SERIAL_WIDTH = 8;
    localparam WORDS = PARRAL_WIDTH / SERIAL_WIDTH;

    reg clk;
    reg rst_n;
    reg i_valid_parral;
    reg [PARRAL_WIDTH-1:0] i_data_parral;

    wire o_valid_serial;
    wire [SERIAL_WIDTH-1:0] o_data_serial;

    wire [PARRAL_WIDTH-1:0] o_data_parral;
    wire o_valid_parral_data;

    // instantiate modules with matching parameters
    parral_ser_trans #(.PARRAL_WIDTH(PARRAL_WIDTH), .SERIAL_WIDTH(SERIAL_WIDTH)) p2s (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid_parral(i_valid_parral),
        .i_data_parral(i_data_parral),
        .o_valid_serial(o_valid_serial),
        .o_data_serial(o_data_serial)
    );

    ser_parral_trans #(.SERIAL_WIDTH(SERIAL_WIDTH), .PARRAL_WIDTH(PARRAL_WIDTH)) s2p (
        .clk(clk),
        .rst_n(rst_n),
        .o_data_parral(o_data_parral),
        .o_valid_parral_data(o_valid_parral_data),
        .i_valid_serial_data(o_valid_serial),
        .i_data_serial(o_data_serial)
    );

    // clock
    initial begin
        clk = 1; forever #5 clk = ~clk; // 100MHz
    end

    initial begin
        $dumpfile("tb_serpara_trans.vcd");
        $dumpvars(0, tb_serpara_trans);

        // Initialize
        rst_n = 1'b0;
        i_valid_parral = 1'b0;
        i_data_parral = {PARRAL_WIDTH{1'b0}};
        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);

        $display("\n\n");
        $display("================================================================================");
        $display("TEST 1: Single vector roundtrip tests (P2S -> S2P loopback)");
        $display("================================================================================");
        // test vectors
        test_one(72'h0123_4567_89AB_CDEF_012);
        test_one({8'hAA,8'h55,8'hFF,8'h00,8'h11,8'h22,8'h33,8'h44,8'h66});
        test_one({72{1'b1}});
        test_one(72'h0);

        // Wait between test groups
        repeat(5) @(posedge clk);

        $display("\n\n================================================================================");
        $display("tb_serpara_trans finished");
        $display("================================================================================\n");
        $finish;
    end

    task test_one(input [PARRAL_WIDTH-1:0] vec);
        integer i, j;
        reg [PARRAL_WIDTH-1:0] collected;
        integer widx;
        reg [PARRAL_WIDTH-1:0] recovered;
        reg recovered_valid;
        begin
            $display("\n[TEST] Input vector: 0x%018h (repeating every %0d cycles)", vec, WORDS);
            
            // Collect serial outputs for multiple cycles
            // Repeat input every WORDS cycles to test continuous stream
            collected = {PARRAL_WIDTH{1'b0}};
            widx = 0;
            recovered = {PARRAL_WIDTH{1'b0}};
            recovered_valid = 1'b0;
            
            $display("  Cycle | P2S Valid | P2S Data | S2P Valid | S2P Data");
            $display("  ------|-----------|----------|-----------|----------");
            
            for (j = 0; j < 3; j = j + 1) begin
                // Drive input valid pulse (single cycle pulse)
                @(posedge clk);
                i_data_parral = vec;
                i_valid_parral = 1'b1;
                @(posedge clk);
                i_valid_parral = 1'b0;
                
                // Now we've consumed 2 cycles from the 9-cycle window
                // Wait for remaining 7 cycles (total 9 cycles including the 2 drive cycles)
                for (i = 0; i < WORDS - 2; i = i + 1) begin
                    @(posedge clk);
                    
                    // Log this cycle
                    if (o_valid_serial && o_valid_parral_data) begin
                        $display("  %5d |    1      | 0x%02h    |    1      | 0x%018h", 
                                 j*WORDS+i, o_data_serial, o_data_parral);
                    end
                    else if (o_valid_serial) begin
                        $display("  %5d |    1      | 0x%02h    |    0      | -", 
                                 j*WORDS+i, o_data_serial);
                    end
                    else if (o_valid_parral_data) begin
                        $display("  %5d |    0      | -        |    1      | 0x%018h", 
                                 j*WORDS+i, o_data_parral);
                    end
                    else begin
                        $display("  %5d |    0      | -        |    0      | -", j*WORDS+i);
                    end
                    
                    // Collect serial data
                    if (o_valid_serial) begin
                        collected[widx*SERIAL_WIDTH +: SERIAL_WIDTH] = o_data_serial;
                        widx = widx + 1;
                    end
                    
                    // Capture parallel data when valid
                    if (o_valid_parral_data) begin
                        recovered = o_data_parral;
                        recovered_valid = 1'b1;
                    end
                end
            end

            // Verify results
            $display("\n  Results:");
            $display("    Input vector:    0x%018h", vec);
            $display("    Collected serial: 0x%018h (from %0d bytes)", collected, widx);
            $display("    S2P output:       0x%018h (valid=%b)", recovered, recovered_valid);
            
            if (recovered_valid && recovered == vec) begin
                $display("     PASS: At least one cycle completed successfully!\n");
            end
            else begin
                $display("     FAIL: Issues detected!\n");
                if (!recovered_valid)
                    $display("      - S2P never produced valid output");
                if (recovered != vec && recovered_valid)
                    $display("      - S2P output mismatch");
            end

            // Wait before next test
            //repeat(1) @(posedge clk);
        end
    endtask

endmodule
