

`timescale 1ns / 1ps

module tb_serpara_trans;
    // Parameters to match modules
    localparam PARRAL_WIDTH = 72;
    localparam SERIAL_WIDTH = 8;
    localparam WORDS = PARRAL_WIDTH / SERIAL_WIDTH;

    reg clk;
    reg i_valid_parral;
    reg [PARRAL_WIDTH-1:0] i_data_parral;

    wire o_valid_serial;
    wire [SERIAL_WIDTH-1:0] o_data_serial;

    wire [PARRAL_WIDTH-1:0] o_data_parral;
    wire o_valid_parral_data;

    // instantiate modules with matching parameters
    parral_ser_trans #(.PARRAL_WIDTH(PARRAL_WIDTH), .SERIAL_WIDTH(SERIAL_WIDTH)) p2s (
        .clk(clk),
        .i_valid_parral(i_valid_parral),
        .i_data_parral(i_data_parral),
        .o_valid_serial(o_valid_serial),
        .o_data_serial(o_data_serial)
    );

    ser_parral_trans #(.SERIAL_WIDTH(SERIAL_WIDTH), .PARRAL_WIDTH(PARRAL_WIDTH)) s2p (
        .clk(clk),
        .o_data_parral(o_data_parral),
        .o_valid_parral_data(o_valid_parral_data),
        .i_valid_serial_data(o_valid_serial),
        .i_data_serial(o_data_serial)
    );

    // clock
    initial begin
        clk = 0; forever #5 clk = ~clk; // 100MHz
    end

    initial begin
        $dumpfile("tb_serpara_trans.vcd");
        $dumpvars(0, tb_serpara_trans);

        // test vectors
        test_one(72'h0123_4567_89AB_CDEF_012);
        test_one({8'hAA,8'h55,8'hFF,8'h00,8'h11,8'h22,8'h33,8'h44,8'h66}); // 72 bits assembled
        test_one({72{1'b1}});
        test_one(72'h0);

        $display("tb_serpara_trans finished");
        $finish;
    end

    task test_one(input [PARRAL_WIDTH-1:0] vec);
        integer i;
    reg [PARRAL_WIDTH-1:0] collected;
    integer widx;
    reg [PARRAL_WIDTH-1:0] recovered;
    reg recovered_valid;
        begin
            // drive parallel valid for one clock to latch and start sending
            @(negedge clk);
            i_data_parral = vec;
            i_valid_parral = 1'b1;
            // hold valid for two posedges to ensure p2s latches
            @(posedge clk);
            @(posedge clk);
            i_valid_parral = 1'b0;


            // wait enough cycles for all words to be transmitted and received
            $display("  CYCLES: showing serial outputs (valid:data)");
            collected = {PARRAL_WIDTH{1'b0}};
            widx = 0;
            recovered = {PARRAL_WIDTH{1'b0}};
            recovered_valid = 1'b0;
            for (i = 0; i < WORDS + 2; i = i + 1) begin
                @(posedge clk);
                $display("    cycle %0d: o_valid_serial=%b o_data_serial=0x%0h", i, o_valid_serial, o_data_serial);
                if (o_valid_serial) begin
                    collected[widx*SERIAL_WIDTH +: SERIAL_WIDTH] = o_data_serial;
                    widx = widx + 1;
                end
                if (o_valid_parral_data) begin
                    recovered = o_data_parral;
                    recovered_valid = 1'b1;
                end
            end

            $display("    collected=0x%0h o_data_parral=0x%0h o_valid_parral_data=%b", collected, o_data_parral, o_valid_parral_data);
            if (collected == vec && recovered_valid && recovered == vec) begin
                $display("PASS: vec=0x%0h recovered OK", vec);
            end else begin
                $display("FAIL: vec=0x%0h collected=0x%0h recovered=0x%0h valid=%b", vec, collected, recovered, recovered_valid);
            end

            // small gap
            repeat (2) @(posedge clk);
        end
    endtask

    // initialize signals
    initial begin
        i_valid_parral = 1'b0;
        i_data_parral = {PARRAL_WIDTH{1'b0}};
    end

endmodule
