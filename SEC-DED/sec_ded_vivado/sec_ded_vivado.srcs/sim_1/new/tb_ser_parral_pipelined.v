`timescale 1ns / 1ps

module tb_ser_parral_trans_pipelined;

    // Test parameters
    parameter SERIAL_WIDTH = 8;
    parameter PARRAL_WIDTH = 64;
    parameter CLK_PERIOD = 10;
    
    // Testbench signals
    reg clk;
    reg rst_n;
    
    // DUT1: Serial-to-Parallel converter
    reg i_valid_serial;
    reg [SERIAL_WIDTH-1:0] i_data_serial;
    wire o_valid_parral;
    wire [PARRAL_WIDTH-1:0] o_data_parral;
    
    // DUT2: Parallel-to-Serial converter
    reg p2s_i_valid_parral;
    reg [PARRAL_WIDTH-1:0] p2s_i_data_parral;
    wire p2s_o_valid_serial;
    wire [SERIAL_WIDTH-1:0] p2s_o_data_serial;
    
    // Instance of DUT1: Serial-to-Parallel
    ser_parral_trans #(
        .SERIAL_WIDTH(SERIAL_WIDTH),
        .PARRAL_WIDTH(PARRAL_WIDTH)
    ) dut_s2p (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid_serial_data(i_valid_serial),
        .i_data_serial(i_data_serial),
        .o_valid_parral_data(o_valid_parral),
        .o_data_parral(o_data_parral)
    );
    
    // Instance of DUT2: Parallel-to-Serial
    parral_ser_trans #(
        .PARRAL_WIDTH(PARRAL_WIDTH),
        .SERIAL_WIDTH(SERIAL_WIDTH),
        .DEPTH(4)
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
        p2s_i_valid_parral = o_valid_parral;
        p2s_i_data_parral = o_data_parral;
    end
    
    // Clock generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Monitor for S2P output
    integer s2p_output_count;
    always @(posedge clk) begin
        if (o_valid_parral) begin
            s2p_output_count = s2p_output_count + 1;
            $display("[S2P OUTPUT #%0d] at time %0t: 0x%016h", s2p_output_count, $time, o_data_parral);
        end
    end
    
    // Monitor for P2S output
    integer p2s_output_count;
    always @(posedge clk) begin
        if (p2s_o_valid_serial) begin
            p2s_output_count = p2s_output_count + 1;
            $display("[P2S OUTPUT #%0d] at time %0t: 0x%02h", p2s_output_count, $time, p2s_o_data_serial);
        end
    end
    
    // Main test
    initial begin
        // Initialize
        rst_n = 1'b0;
        i_valid_serial = 1'b0;
        i_data_serial = 8'h00;
        p2s_i_valid_parral = 1'b0;
        p2s_i_data_parral = 64'h0;
        s2p_output_count = 0;
        p2s_output_count = 0;
        
        // Reset
        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);
        
        $display("\n");
        $display("================================================================================");
        $display("TEST: Continuous 32 cycles of valid, sending 256 bits (32 bytes) total");
        $display("================================================================================");
        $display("Expected behavior:");
        $display("  - S2P: Every 8 serial words (8 bytes) -> 1 parallel word (64 bits)");
        $display("    Total: 32 serial inputs should produce 4 parallel outputs");
        $display("  - P2S: Each parallel word -> 8 serial words");
        $display("    Total: 4 parallel inputs should produce 32 serial outputs");
        $display("================================================================================\n");
        
        // Send 32 bytes continuously with valid signal high for all 32 cycles
        // Byte values: 0x00, 0x01, 0x02, ..., 0x1F
        $display("[SENDING] Starting transmission of 32 bytes (256 bits)...\n");
        
        for (int i = 0; i < 32; i = i + 1) begin
            i_valid_serial = 1'b1;
            i_data_serial = i[7:0];  // 0x00, 0x01, 0x02, ..., 0x1F
            @(posedge clk);
        end
        
        i_valid_serial = 1'b0;
        
        $display("\n[SENDING] Transmission complete. Waiting for outputs...\n");
        
        // Wait for all outputs to complete
        repeat(50) @(posedge clk);
        
        $display("\n");
        $display("================================================================================");
        $display("SUMMARY");
        $display("================================================================================");
        $display("S2P Total Outputs: %0d (expected: 4)", s2p_output_count);
        $display("P2S Total Outputs: %0d (expected: 32)", p2s_output_count);
        $display("================================================================================\n");
        
        $finish;
    end

endmodule
