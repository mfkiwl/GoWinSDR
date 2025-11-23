module calibration(
    input wire sample_clk,
    input wire rst_n,

    input wire [11:0] data_in,

    // 连接到物理接口
    output wire [7:0] cal_data_out,
    output wire cal_data_clk,
    output wire cal_valid,

    input wire cal_request
);

wire [23:0] square;
    Gowin_MULT_1212 square_u0(
        .dout(square), //output [23:0] dout
        .a(data_in), //input [11:0] a
        .b(data_in), //input [11:0] b
        .clk(sample_clk), //input clk
        .ce(1'b1), //input ce
        .reset(~rst_n) //input reset
    );

wire [11:0] envelop;

	FIR_Calib lowpass_filter_u0(
		.clk(sample_clk), //input clk
		.rstn(rst_n), //input rstn
		.fir_rfi_o(), //output fir_rfi_o
		.fir_valid_i(1'b1), //input fir_valid_i
		.fir_sync_i(1'b1), //input fir_sync_i
		.fir_data_i(square[23:12]), //input [11:0] fir_data_i
		.fir_valid_o(), //output fir_valid_o
		.fir_sync_o(), //output fir_sync_o
		.fir_data_o(envelop) //output [11:0] fir_data_o
	);
     

wire [23:0] freq_out;
wire freq_valid;
    sine_frequency_meter dut (
    .clk(sample_clk),
    .rst_n(rst_n),
    .sine_in(envelop),
    .freq_out(freq_out),
    .freq_valid(freq_valid)
    );

    data_sender_24bit u_sender (
        .sample_clk(sample_clk),
        .rst_n(rst_n),
        .data_in(freq_out), 
        .request(cal_request),
        .data_out(cal_data_out),
        .valid(cal_valid),
        .data_clk(cal_data_clk)
    );

endmodule

module sine_frequency_meter (
    input clk,                    // 30.72 MHz采样时钟
    input rst_n,
    input [11:0] sine_in,         // 12位正弦信号输入（平方后全正） 
    output reg [23:0] freq_out,   // 输出频率(Hz)
    output reg freq_valid         // 频率有效标志
);

// 测量输入信号的平均值
parameter ACCUM_BITS = 32;
parameter SAMPLE_COUNT = 65536; // 2^16个样本

reg [ACCUM_BITS-1:0] accum;
reg [15:0] sample_cnt;
reg [11:0] average;
reg accum_done;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        accum <= 0;
        sample_cnt <= 0;
        average <= 0;
        accum_done <= 0;
    end else begin
        if (sample_cnt < SAMPLE_COUNT - 1) begin
            accum <= accum + sine_in;
            sample_cnt <= sample_cnt + 1;
            accum_done <= 0;
        end else begin
            average <= accum[ACCUM_BITS-1:16]; // 除以65536
            accum <= sine_in;
            sample_cnt <= 1;
            accum_done <= 1;
        end
    end
end

localparam ZERO_AREA = 2'd0;
localparam CNT_AREA  = 2'd1;
localparam FREQ_CALC  = 2'd2;
localparam WAIT = 2'd3;

reg [3:0] wait_count;

reg [31:0] period_count;
reg [1:0] state;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= CNT_AREA;
        period_count <= 0;
        freq_out <= 0;
        freq_valid <= 1'b0;
        wait_count <= 0;
    end else begin
        case (state)
            CNT_AREA: begin
                period_count <= period_count + 1;
                if (sine_in < (average >> 5)) begin
                    state <= FREQ_CALC;
                end
                else if (period_count == 32'hffffffff - 2) begin
                    state <= FREQ_CALC;
                end
            end
            FREQ_CALC: begin
                period_count <= 0;
                state <= WAIT;
            end
            WAIT: begin
                wait_count <= wait_count + 1;
                period_count <= period_count + 1;
                if (wait_count == 4'd1) begin
                    wait_count <= 0;
                    freq_out <= division_result >> 1;
                    freq_valid <= 1'b1;
                    state <= ZERO_AREA;
                end
            end
            ZERO_AREA: begin
                period_count <= period_count + 1;
                if (sine_in > (average >> 1)) begin
                    state <= CNT_AREA;
                end
                else if (period_count == 32'hffffffff - 2) begin
                    state <= FREQ_CALC;
                end
            end
            default: state <= ZERO_AREA;
        endcase
    end
end

wire [31:0] division_result;
	Integer_Division your_instance_name(
		.clk(clk), //input clk
		.rstn(rst_n), //input rstn
		.dividend(32'd30720000), //input [31:0] dividend
		.divisor(period_count), //input [31:0] divisor
		.quotient(division_result) //output [31:0] quotient
	);

endmodule