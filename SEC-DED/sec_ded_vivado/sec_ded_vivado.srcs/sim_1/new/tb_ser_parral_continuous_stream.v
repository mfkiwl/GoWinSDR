`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_ser_parral_continuous_stream
// Purpose: Demonstrate pipelined serial-to-parallel and parallel-to-serial
//          with continuous streaming: 32 cycles of valid data (256 bits)
//          feeding through S2P -> P2S roundtrip
//
// Observation points:
// 1. Serial input (32 bytes continuously)
// 2. S2P output (should be 4 x 64-bit parallel words)
// 3. P2S output (should be 32 continuous 8-bit serial words)
//
//////////////////////////////////////////////////////////////////////////////////

module tb_ser_parral_continuous_stream;

    // Test parameters
    parameter S2P_SERIAL_WIDTH = 8;
    parameter S2P_PARRAL_WIDTH = 64;
    parameter P2S_PARRAL_WIDTH = 64;
    parameter P2S_SERIAL_WIDTH = 8;
    parameter P2S_DEPTH = 4;
    
    parameter CLK_PERIOD = 10;
    
    // Testbench signals
    reg clk;
    reg rst_n;
    
    // S2P: Serial-to-Parallel converter
    reg s2p_i_valid_serial;
    reg [S2P_SERIAL_WIDTH-1:0] s2p_i_data_serial;
    wire s2p_o_valid_parral;
    wire [S2P_PARRAL_WIDTH-1:0] s2p_o_data_parral;
    
    // P2S: Parallel-to-Serial converter
    reg p2s_i_valid_parral;
    reg [P2S_PARRAL_WIDTH-1:0] p2s_i_data_parral;
    wire p2s_o_valid_serial;
    wire [P2S_SERIAL_WIDTH-1:0] p2s_o_data_serial;
    
    // ========================================================================
    // DUT Instances
    // ========================================================================
    
    // S2P: takes serial stream and outputs parallel
    ser_parral_trans #(
        .SERIAL_WIDTH(S2P_SERIAL_WIDTH),
        .PARRAL_WIDTH(S2P_PARRAL_WIDTH)
    ) dut_s2p (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid_serial_data(s2p_i_valid_serial),
        .i_data_serial(s2p_i_data_serial),
        .o_valid_parral_data(s2p_o_valid_parral),
        .o_data_parral(s2p_o_data_parral)
    );
    
    // P2S: takes parallel stream and outputs serial
    parral_ser_trans #(
        .PARRAL_WIDTH(P2S_PARRAL_WIDTH),
        .SERIAL_WIDTH(P2S_SERIAL_WIDTH),
        .DEPTH(P2S_DEPTH)
    ) dut_p2s (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid_parral(p2s_i_valid_parral),
        .i_data_parral(p2s_i_data_parral),
        .o_valid_serial(p2s_o_valid_serial),
        .o_data_serial(p2s_o_data_serial)
    );
    
    // Connect S2P output to P2S input
    always @(*) begin
        p2s_i_valid_parral = s2p_o_valid_parral;
        p2s_i_data_parral = s2p_o_data_parral;
    end
    
    // ========================================================================
    // Clock Generation
    // ========================================================================
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // ========================================================================
    // Monitoring and Output Display
    // ========================================================================
    
    integer s2p_output_count;
    integer p2s_output_count;
    integer cycle_count;
    integer i;
    
    always @(posedge clk) begin
        if (s2p_o_valid_parral) begin
            s2p_output_count = s2p_output_count + 1;
            $display("[%0d] [S2P OUTPUT #%0d] 0x%016h", cycle_count, s2p_output_count, s2p_o_data_parral);
        end
    end
    
    always @(posedge clk) begin
        if (p2s_o_valid_serial) begin
            p2s_output_count = p2s_output_count + 1;
            $display("[%0d] [P2S OUTPUT #%0d] 0x%02h", cycle_count, p2s_output_count, p2s_o_data_serial);
        end
    end
    
    // ========================================================================
    // Main Test Stimulus
    // ========================================================================
    
    initial begin
        // Initialize
        rst_n = 1'b0;
        s2p_i_valid_serial = 1'b0;
        s2p_i_data_serial = 8'h00;
        p2s_i_valid_parral = 1'b0;
        p2s_i_data_parral = 64'h0;
        s2p_output_count = 0;
        p2s_output_count = 0;
        cycle_count = 0;
        
        // Reset phase
        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);
        
        $display("\n");
        $display("================================================================================");
        $display("TEST: Continuous Stream of 32 Bytes (256 bits) via Serial Interface");
        $display("================================================================================");
        $display("Setup:");
        $display("  - S2P: SERIAL_WIDTH=%0d, PARRAL_WIDTH=%0d", S2P_SERIAL_WIDTH, S2P_PARRAL_WIDTH);
        $display("  - P2S: PARRAL_WIDTH=%0d, SERIAL_WIDTH=%0d, DEPTH=%0d", 
                 P2S_PARRAL_WIDTH, P2S_SERIAL_WIDTH, P2S_DEPTH);
        $display("");
        $display("Test data: 32 continuous cycles with valid=1");
        $display("  Byte 0:  0x00");
        $display("  Byte 1:  0x01");
        $display("  ...");
        $display("  Byte 31: 0x1F");
        $display("");
        $display("Expected results:");
        $display("  - S2P outputs: 4 parallel words (256 / 64 = 4)");
        $display("  - P2S outputs: 32 serial words (4 words * 64 / 8 = 32)");
        $display("================================================================================\n");
        
        // ====================================================================
        // MAIN TEST: Send 32 bytes continuously with valid HIGH
        // ====================================================================
        
        $display("[SENDING] Cycles 0-31: Sending 32 bytes with valid=1 throughout\n");
        $display("Cycle | S2P_Valid | S2P_Data         | P2S_Valid | P2S_Data | Comments");
        $display("------|-----------|------------------|-----------|----------|----------");
        
        for (i = 0; i < 32; i = i + 1) begin
            s2p_i_valid_serial = 1'b1;
            s2p_i_data_serial = i[7:0];  // 0x00, 0x01, ..., 0x1F
            
            @(posedge clk);
            cycle_count = cycle_count + 1;
            
            // Display cycle information
            if (s2p_o_valid_parral) begin
                $display("%5d | %9b | 0x%016h | %9b | 0x%02h | S2P OUTPUT", 
                         cycle_count, s2p_o_valid_parral, s2p_o_data_parral, 
                         p2s_o_valid_serial, p2s_o_data_serial);
            end
            else if (p2s_o_valid_serial) begin
                $display("%5d | %9b | %-16s | %9b | 0x%02h |", 
                         cycle_count, s2p_o_valid_parral, "-", 
                         p2s_o_valid_serial, p2s_o_data_serial);
            end
            else begin
                $display("%5d | %9b | %-16s | %9b | %-8s |", 
                         cycle_count, s2p_o_valid_parral, "-", 
                         p2s_o_valid_serial, "-");
            end
        end
        
        s2p_i_valid_serial = 1'b0;
        
        $display("\n[WAITING] Waiting for final outputs (32 cycles)...\n");
        
        // Wait for all outputs to complete
        for (i = 0; i < 40; i = i + 1) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            
            if (s2p_o_valid_parral || p2s_o_valid_serial) begin
                if (s2p_o_valid_parral) begin
                    $display("%5d | %9b | 0x%016h | %9b | 0x%02h | S2P OUTPUT", 
                             cycle_count, s2p_o_valid_parral, s2p_o_data_parral, 
                             p2s_o_valid_serial, p2s_o_data_serial);
                end
                else begin
                    $display("%5d | %9b | %-16s | %9b | 0x%02h |", 
                             cycle_count, s2p_o_valid_parral, "-", 
                             p2s_o_valid_serial, p2s_o_data_serial);
                end
            end
        end
        
        $display("\n");
        $display("================================================================================");
        $display("TEST SUMMARY");
        $display("================================================================================");
        $display("Total cycles executed: %0d", cycle_count);
        $display("S2P parallel outputs: %0d (expected: 4)", s2p_output_count);
        $display("P2S serial outputs: %0d (expected: 32)", p2s_output_count);
        
        if (s2p_output_count == 4 && p2s_output_count == 32) begin
            $display("RESULT: PASS ✓");
        end
        else begin
            $display("RESULT: FAIL ✗");
        end
        
        $display("================================================================================\n");
        $finish;
    end

endmodule
