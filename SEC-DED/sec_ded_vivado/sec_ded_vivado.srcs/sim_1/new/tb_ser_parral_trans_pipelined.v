`timescale 1ns / 1ps

module tb_ser_parral_trans_pipelined;

    // Test parameters
    parameter SERIAL_WIDTH = 8;
    parameter PARRAL_WIDTH = 64;
    parameter CLK_PERIOD = 10;
    
    // Testbench signals
    reg clk;
    reg rst_n;
    reg i_valid_serial;
    reg [SERIAL_WIDTH-1:0] i_data_serial;
    wire o_valid_parral;
    wire [PARRAL_WIDTH-1:0] o_data_parral;
    
    // Instance of DUT
    ser_parral_trans_pipelined #(
        .SERIAL_WIDTH(SERIAL_WIDTH),
        .PARRAL_WIDTH(PARRAL_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid_serial(i_valid_serial),
        .i_data_serial(i_data_serial),
        .o_valid_parral(o_valid_parral),
        .o_data_parral(o_data_parral)
    );
    
    // Clock generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Main test
    initial begin
        // Initialize
        rst_n = 1'b0;
        i_valid_serial = 1'b0;
        i_data_serial = 8'h00;
        
        // Reset
        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);
        
        $display("=== Test 1: Continuous stream of 256 bits (32 bytes * 8 bits) ===");
        $display("Expecting 4 outputs of 64-bit words");
        
        // Send continuous stream: 256 bits = 32 bytes
        // This will produce 4 words of 64-bit output (256/64 = 4)
        for (int i = 0; i < 32; i = i + 1) begin
            i_valid_serial = 1'b1;
            i_data_serial = i[7:0];  // 0x00, 0x01, 0x02, ..., 0x1F
            @(posedge clk);
        end
        i_valid_serial = 1'b0;
        
        // Wait for last outputs
        repeat(10) @(posedge clk);
        
        $display("\n=== Test 2: Non-continuous input (gaps) ===");
        repeat(5) @(posedge clk);
        
        // Send 8 bytes continuously (one 64-bit word)
        for (int i = 0; i < 8; i = i + 1) begin
            i_valid_serial = 1'b1;
            i_data_serial = 8'h10 + i;  // 0x10, 0x11, ..., 0x17
            @(posedge clk);
        end
        i_valid_serial = 1'b0;
        
        // Gap of 3 cycles
        repeat(3) @(posedge clk);
        
        // Send 8 more bytes
        for (int i = 0; i < 8; i = i + 1) begin
            i_valid_serial = 1'b1;
            i_data_serial = 8'h20 + i;  // 0x20, 0x21, ..., 0x27
            @(posedge clk);
        end
        i_valid_serial = 1'b0;
        
        // Wait for outputs
        repeat(10) @(posedge clk);
        
        $display("\n=== Test 3: Burst then gap pattern ===");
        repeat(5) @(posedge clk);
        
        // One continuous burst of 16 bytes (2 words)
        for (int i = 0; i < 16; i = i + 1) begin
            i_valid_serial = 1'b1;
            i_data_serial = 8'h30 + i;
            @(posedge clk);
        end
        i_valid_serial = 1'b0;
        
        repeat(20) @(posedge clk);
        $display("\n=== Test Complete ===");
        $finish;
    end
    
    // Monitor outputs
    always @(posedge clk) begin
        if (o_valid_parral) begin
            $display("[OUTPUT] at time %0t: 0x%016h", $time, o_data_parral);
        end
    end

endmodule
