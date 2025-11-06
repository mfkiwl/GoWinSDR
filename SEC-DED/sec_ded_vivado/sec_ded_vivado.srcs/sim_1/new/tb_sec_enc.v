
`timescale 1ns / 1ps

module tb_sec_enc;

    reg clk;
    reg rst_n;
    reg [63:0] i_data;
    reg i_valid_datain;

    wire i_valid_dataout;
    wire [71:0] o_data_crypt;

    // instantiate encoder
    sec_encoder uut (
        .clk(clk),
        .rst_n(rst_n),
        .i_data(i_data),
        .i_valid_datain(i_valid_datain),
        .i_valid_dataout(i_valid_dataout),
        .o_data_crypt(o_data_crypt)
    );

    // clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz (10ns period)
    end

    // test stimulus
    initial begin
        $dumpfile("tb_sec_enc.vcd");
        $dumpvars(0, tb_sec_enc);

        // reset
        rst_n = 0;
        i_data = 64'h0;
        i_valid_datain = 0;
        #20;
        rst_n = 1;

        // test vectors
        send_and_capture(64'h0123_4567_89AB_CDEF);
        send_and_capture(64'hFFFF_FFFF_FFFF_FFFF);
        send_and_capture(64'h0000_0000_0000_0000);

        #50;
        $display("tb_sec_enc finished");
        $finish;
    end

    task send_and_capture(input [63:0] data);
        reg [71:0] cw;
        begin
            @(negedge clk);
            i_data = data;
            i_valid_datain = 1;
            @(posedge clk); // encoder samples and will produce outputs at this posedge
            i_valid_datain = 0;
            #1;
            cw = o_data_crypt;
            $display("ENCODE: data=0x%016h -> codeword=0x%018h (valid=%b)", data, cw, i_valid_dataout);
        end
    endtask

endmodule
