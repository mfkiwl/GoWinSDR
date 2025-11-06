`timescale 1ns / 1ps

module tb_pressure_9bit;
    reg clk;
    reg rst_n;

    // 8-bit input stream (flow/pressure data)
    reg [7:0] i_data_byte;
    reg i_valid_byte;

    // serial channel (9-bit)
    wire enc_valid_serial;
    wire [8:0] enc_data_serial;

    // decoder outputs (8-bit)
    wire dec_valid_byte;
    wire [7:0] dec_data_byte;
    wire dec_uncorrectable;

    // DUT chain: top_sec_encode -> top_sec_decode
    // top_sec_encode: 8b stream -> 64-bit assembly -> SEC encode (72-bit) -> parallel-to-serial (9-bit stream)
    top_sec_encode enc_top (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid_byte(i_valid_byte),
        .i_data_byte(i_data_byte),
        .o_valid_serial(enc_valid_serial),
        .o_data_serial(enc_data_serial)
    );

    // Optional: inject 1-bit errors into serial stream for testing ECC
    wire [8:0] tb_data_serial;
    wire tb_valid_serial = enc_valid_serial;
    assign tb_data_serial = enc_data_serial; // pass-through for now (no errors)

    // top_sec_decode: 9-bit serial stream -> serial-to-parallel (72-bit) -> SEC decode (64-bit) -> 8b stream
    top_sec_decode dec_top (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid_serial(tb_valid_serial),
        .i_data_serial(tb_data_serial),
        .o_valid_byte(dec_valid_byte),
        .o_data_byte(dec_data_byte),
        .o_uncorrectable(dec_uncorrectable)
    );

    // clock
    initial begin
        clk = 0; forever #5 clk = ~clk; // 100MHz, 10ns period
    end

    integer i, byte_idx;
    reg [7:0] tx_bytes [0:31]; // 32 test bytes (4 frames * 8 bytes/frame)
    reg [7:0] rx_bytes [0:31];
    integer rx_cnt;

    initial begin
        $dumpfile("tb_pressure_9bit.vcd");
        $dumpvars(0, tb_pressure_9bit);

        // Initialize test data: 32 bytes of test pattern
        for (i = 0; i < 32; i = i + 1) begin
            tx_bytes[i] = 8'h00 + i; // 0x00, 0x01, 0x02, ..., 0x1F
        end

        // Reset
        rst_n = 1'b0;
        i_valid_byte = 1'b0;
        i_data_byte = 8'b0;
        rx_cnt = 0;
        
        repeat(4) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);

        $display("\n================================================================================");
        $display("PRESSURE TEST: Continuous 8-bit stream through SEC-ECC with S/P conversion");
        $display("================================================================================\n");

        // Drive 32 bytes continuously with valid held high
        // This tests: 8b->64b assembly, SEC encoding, 72->9b serialization,
        // 9b serial stream, 72b deserialization, SEC decoding, 64b->8b disassembly
        @(posedge clk);
        for (byte_idx = 0; byte_idx < 32; byte_idx = byte_idx + 1) begin
            i_data_byte <= tx_bytes[byte_idx];
            i_valid_byte <= 1'b1;
            @(posedge clk);
        end
        i_valid_byte <= 1'b0;
        i_data_byte <= 8'b0;

        $display("\nWaiting for pipeline to drain...");
        // Wait for all data to propagate through: 
        // 8 cycles to fill first 64-bit, ~10 cycles for encode+serialize,
        // ~10 cycles for deserialize, ~10 cycles for decode+disassemble = ~40 cycles
        repeat(150) @(posedge clk);

        // Check results
        $display("\n================================================================================");
        $display("Results:");
        $display("  Transmitted %0d bytes", byte_idx);
        $display("  Received %0d bytes", rx_cnt);
        
        if (rx_cnt >= 32) begin:Fuck_vivado
            reg mismatch;
            mismatch = 1'b0;
            for (i = 0; i < 32; i = i + 1) begin
                if (rx_bytes[i] !== tx_bytes[i]) begin
                    $display("  MISMATCH at byte %0d: sent 0x%02h, got 0x%02h", 
                             i, tx_bytes[i], rx_bytes[i]);
                    mismatch = 1'b1;
                end
            end
            if (!mismatch) begin
                $display("\n✓ PRESSURE TEST PASS: All 32 bytes recovered correctly with SEC-ECC");
            end else begin
                $display("\n✗ PRESSURE TEST FAIL: Byte mismatches detected");
            end
        end else begin
            $display("\n✗ PRESSURE TEST FAIL: Expected 32 bytes, got only %0d", rx_cnt);
        end

        $display("================================================================================\n");
        $finish;
    end

    // Capture decoded output bytes
    always @(posedge clk) begin
        if (dec_valid_byte) begin
            if (rx_cnt < 32) begin
                rx_bytes[rx_cnt] <= dec_data_byte;
                $display("TB@%0t: RX byte[%0d] = 0x%02h (uncorr=%b)", 
                         $time, rx_cnt, dec_data_byte, dec_uncorrectable);
                rx_cnt <= rx_cnt + 1;
            end
        end
    end

    // Optional debug trace
    initial begin
        repeat(50) @(posedge clk);
        forever begin
            @(posedge clk);
            $display("TB@%0t: [enc_valid=%b enc_ser=0x%03h] [dec_valid=%b dec_byte=0x%02h]",
                     $time, enc_valid_serial, enc_data_serial, dec_valid_byte, dec_data_byte);
            repeat(40) @(posedge clk);
        end
    end

endmodule
