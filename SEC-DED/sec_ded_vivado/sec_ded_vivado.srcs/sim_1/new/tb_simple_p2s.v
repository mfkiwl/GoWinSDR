`timescale 1ns / 1ps

module tb_simple;
    parameter CLK_PERIOD = 10;
    
    reg clk, rst_n;
    reg i_valid_parral;
    reg [71:0] i_data_parral;
    wire o_valid_serial;
    wire [7:0] o_data_serial;
    
    // DUT
    parral_ser_trans #(.PARRAL_WIDTH(72), .SERIAL_WIDTH(8)) dut_p2s (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid_parral(i_valid_parral),
        .i_data_parral(i_data_parral),
        .o_valid_serial(o_valid_serial),
        .o_data_serial(o_data_serial)
    );
    
    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test
    initial begin
        rst_n = 0;
        i_valid_parral = 0;
        i_data_parral = 0;
        
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);
        
        $display("\n=== TEST: Send 72-bit parallel data ===\n");
        
        // Send first 72-bit word (9 bytes: 0x0-0x8)
        @(negedge clk);
        i_data_parral = {8'h08, 8'h07, 8'h06, 8'h05, 8'h04, 8'h03, 8'h02, 8'h01, 8'h00};
        i_valid_parral = 1;
        @(posedge clk);
        i_valid_parral = 0;
        
        // Watch 12 cycles of output
        repeat(12) @(posedge clk);
        
        $display("\n=== TEST: Send 2nd 72-bit parallel data (back-to-back) ===\n");
        
        // Send second 72-bit word (9 bytes: 0x10-0x18)
        @(negedge clk);
        i_data_parral = {8'h18, 8'h17, 8'h16, 8'h15, 8'h14, 8'h13, 8'h12, 8'h11, 8'h10};
        i_valid_parral = 1;
        @(posedge clk);
        i_valid_parral = 0;
        
        // Watch 12 cycles of output
        repeat(12) @(posedge clk);
        
        $display("\n=== TEST COMPLETE ===\n");
        $finish;
    end
    
    // Monitor
    always @(posedge clk) begin
        if (o_valid_serial) begin
            $display("[%0d] P2S OUT: 0x%02h", $time/CLK_PERIOD, o_data_serial);
        end
    end

endmodule
