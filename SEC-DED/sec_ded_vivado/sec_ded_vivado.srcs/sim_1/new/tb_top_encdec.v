`timescale 1ns / 1ps

module tb_top_encdec;
    // simple end-to-end test for top_sec_encode -> (serial channel) -> top_sec_decode
    reg clk;
    reg rst_n;

    // encoder side inputs
    reg i_valid_byte;
    reg [7:0] i_data_byte;

    // serial channel wires (9-bit chunks)
    wire o_valid_serial;
    wire [8:0] o_data_serial;

    // decoder side outputs
    wire o_valid_byte_dec;
    wire [7:0] o_data_byte_dec;
    wire o_uncorrectable;

    top_sec_encode tx (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid_byte(i_valid_byte),
        .i_data_byte(i_data_byte),
        .o_valid_serial(o_valid_serial),
        .o_data_serial(o_data_serial)
    );

    top_sec_decode rx (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid_serial(o_valid_serial),
        .i_data_serial(o_data_serial),
        .o_valid_byte(o_valid_byte_dec),
        .o_data_byte(o_data_byte_dec),
        .o_uncorrectable(o_uncorrectable)
    );

    // clock
    initial begin
        clk = 0; forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_top_encdec.vcd");
        $dumpvars(0, tb_top_encdec);

        rst_n = 0; i_valid_byte = 0; i_data_byte = 8'b0;
        repeat (2) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);

        // send 8 bytes
        send_byte(8'h01);
        send_byte(8'h23);
        send_byte(8'h45);
        send_byte(8'h67);
        send_byte(8'h89);
        send_byte(8'hAB);
        send_byte(8'hCD);
        send_byte(8'hEF);

        // wait long enough for round trip
        repeat (200) @(posedge clk);

        $display("tb_top_encdec finished");
        $finish;
    end

    task send_byte(input [7:0] b);
        begin
            @(negedge clk);
            i_data_byte = b;
            i_valid_byte = 1'b1;
            // let the DUT sample on the following posedge; deassert at next negedge to avoid
            // racing with posedge evaluation in DUT.
            @(posedge clk);
            @(negedge clk);
            i_valid_byte = 1'b0;
            @(posedge clk);
        end
    endtask

    // observe recovered bytes
    // collect recovered bytes and compare to sent payload once 8 bytes are received
    reg [7:0] rec_buf [0:7];
    integer rec_cnt;
    reg [7:0] tx_payload [0:7];
    integer tx_idx;
    reg frame_sent;

    initial begin
        rec_cnt = 0;
        tx_idx = 0;
        frame_sent = 1'b0;
    end

    always @(posedge clk) begin
        if (i_valid_byte) begin
            // record bytes we send to compare later
            tx_payload[tx_idx] = i_data_byte;
            tx_idx = tx_idx + 1;
            if (tx_idx == 8) begin
                frame_sent = 1'b1;
            end
        end

        if (o_valid_byte_dec) begin
            rec_buf[rec_cnt] = o_data_byte_dec;
            $display("RECOVERED byte: 0x%0h uncorr=%b at time %0t", o_data_byte_dec, o_uncorrectable, $time);
            rec_cnt = rec_cnt + 1;
            if (rec_cnt == 8) begin:gener
                // compare
                integer k; reg mismatch; mismatch = 0;
                for (k = 0; k < 8; k = k + 1) begin
                    if (rec_buf[k] !== tx_payload[k]) begin
                        mismatch = 1;
                    end
                end
                if (!mismatch && !o_uncorrectable) $display("FRAME CHECK: PASS");
                else if (!mismatch && o_uncorrectable) $display("FRAME CHECK: PASS (but flagged uncorrectable)");
                else $display("FRAME CHECK: FAIL - mismatch or uncorrectable");
                // reset counters for next frame
                rec_cnt = 0;
                tx_idx = 0;
                frame_sent = 0;
            end
        end
    end

    // debug: show when testbench drives bytes
    always @(posedge clk) begin
        $display("TB@%0t i_valid_byte=%b i_data_byte=0x%0h o_valid_serial=%b o_data_serial=0x%0h", $time, i_valid_byte, i_data_byte, o_valid_serial, o_data_serial);
    end

endmodule
