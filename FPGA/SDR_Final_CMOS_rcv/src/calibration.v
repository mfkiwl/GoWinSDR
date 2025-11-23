module calibration(
    input wire sample_clk,
    input wire rst_n,

    input wire [11:0] data_in,

    // 连接到物理接口
    output reg [7:0] cal_value
);

wire [11:0] envelop;

	FIR_Calib lowpass_filter_u0(
		.clk(sample_clk), //input clk
		.rstn(rst_n), //input rstn
		.fir_rfi_o(), //output fir_rfi_o
		.fir_valid_i(1'b1), //input fir_valid_i
		.fir_sync_i(1'b1), //input fir_sync_i
		.fir_data_i(data_in), //input [11:0] fir_data_i
		.fir_valid_o(), //output fir_valid_o
		.fir_sync_o(), //output fir_sync_o
		.fir_data_o(envelop) //output [11:0] fir_data_o
	);
     

wire [16:0] freq_out;
wire freq_valid;
    sine_frequency_meter dut (
    .clk(sample_clk),
    .rst_n(rst_n),
    .sine_in(envelop),
    .freq_out(freq_out),
    .freq_valid(freq_valid)
    );

endmodule


module sine_frequency_meter (
    input clk,                    // 30.72 MHz采样时钟
    input rst_n,
    input [11:0] sine_in,         // 12位正弦信号输入
    output reg [16:0] freq_out,   // 输出频率(Hz)，最大131kHz可表示
    output reg freq_valid         // 频率有效标志
);

// 参数定义
parameter CLK_FREQ = 30720000;    // 采样频率30.72MHz
parameter MID_VALUE = 12'd2048;   // 12位有符号数中点(假设2048为0点)

// 内部信号
reg [11:0] sine_delay1, sine_delay2;
reg [11:0] sine_diff;
reg cross_flag;
wire zero_cross;
reg zero_cross_r;
reg [31:0] cycle_counter;
reg [31:0] prev_cycle;
reg [31:0] period_counter;
reg count_en;
reg freq_calc_en;
reg [16:0] calc_freq;

// ============================================================
// 第一阶段：过零检测（检测上升过零点）
// ============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sine_delay1 <= 0;
        sine_delay2 <= 0;
    end else begin
        sine_delay1 <= sine_in;
        sine_delay2 <= sine_delay1;
    end
end

// 过零检测：上升过零
// 条件：前一个样本 < MID_VALUE 且当前样本 >= MID_VALUE
assign zero_cross = (sine_delay2 < MID_VALUE) && (sine_delay1 >= MID_VALUE);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        zero_cross_r <= 0;
    else
        zero_cross_r <= zero_cross;
end

// ============================================================
// 第二阶段：周期计数
// 每次检测到上升过零，计算距离上次过零的时间
// ============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cycle_counter <= 0;
        prev_cycle <= 0;
        period_counter <= 0;
        count_en <= 0;
        freq_calc_en <= 0;
    end else begin
        if (zero_cross && zero_cross_r == 0) begin  // 过零沿检测
            if (count_en == 0) begin
                // 第一次过零，使能计数
                count_en <= 1;
                cycle_counter <= 1;
                prev_cycle <= 0;
            end else begin
                // 后续过零，保存周期
                period_counter <= cycle_counter;
                prev_cycle <= cycle_counter;
                cycle_counter <= 1;
                freq_calc_en <= 1;  // 触发频率计算
            end
        end else if (count_en) begin
            if (cycle_counter < 32'h7FFFFFFF)
                cycle_counter <= cycle_counter + 1;
        end
    end
end

// ============================================================
// 第三阶段：频率计算
// freq = CLK_FREQ / (period_counter * 2)
// 乘以2是因为一个完整周期有两次过零（上升和下降）
// ============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        calc_freq <= 0;
        freq_valid <= 0;
    end else if (freq_calc_en) begin
        if (period_counter > 0) begin
            // 简化计算：freq = 30720000 / (period_counter * 2)
            // 为了避免除法，使用查表或移位
            calc_freq <= CLK_FREQ / (period_counter << 1);
            freq_valid <= 1;
        end else begin
            freq_valid <= 0;
        end
    end
end

// ============================================================
// 输出频率结果
// ============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        freq_out <= 0;
    end else if (freq_calc_en && freq_valid) begin
        freq_out <= calc_freq;
    end
end

endmodule
