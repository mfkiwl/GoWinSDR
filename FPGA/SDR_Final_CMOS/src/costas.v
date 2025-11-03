module costas (
    input rst_n,
    // Data Processing Block
    input sample_clk,
    input [11:0] sample_i1,
    input [11:0] sample_q1,
    output reg [11:0] data_out_i,
    output reg [11:0] data_out_q
);

// 科斯塔斯环参数
parameter NCO_WIDTH = 32;
parameter PHASE_WIDTH = 16;

// NCO和相位相关信号
reg [NCO_WIDTH-1:0] nco_freq;
reg [NCO_WIDTH-1:0] nco_phase;
wire [PHASE_WIDTH-1:0] phase_out;

// 鉴相器输出
reg signed [23:0] phase_error;

// 环路滤波器
reg signed [31:0] loop_integrator;
reg signed [31:0] loop_proportional;

// 本地载波生成 (sin/cos)
reg signed [11:0] local_i;
reg signed [11:0] local_q;

// 混频后的信号
reg signed [23:0] mixed_i;
reg signed [23:0] mixed_q;

// 环路滤波器参数
parameter signed [15:0] KP = 16'd100;  // 比例系数
parameter signed [15:0] KI = 16'd10;   // 积分系数

assign phase_out = nco_phase[NCO_WIDTH-1:NCO_WIDTH-PHASE_WIDTH];

// NCO - 数控振荡器
always @(posedge sample_clk or negedge rst_n) begin
    if (!rst_n) begin
        nco_phase <= 0;
    end else begin
        nco_phase <= nco_phase + nco_freq;
    end
end

// 生成本地载波 (简化的sin/cos查找表或CORDIC)
always @(posedge sample_clk or negedge rst_n) begin
    if (!rst_n) begin
        local_i <= 0;
        local_q <= 0;
    end else begin
        // 简化实现: 使用相位的高位近似sin/cos
        case (phase_out[PHASE_WIDTH-1:PHASE_WIDTH-2])
            2'b00: begin local_i <= 12'd2047; local_q <= 12'd0; end
            2'b01: begin local_i <= 12'd0; local_q <= 12'd2047; end
            2'b10: begin local_i <= -12'd2047; local_q <= 12'd0; end
            2'b11: begin local_i <= 12'd0; local_q <= -12'd2047; end
        endcase
    end
end

// 混频器 - 下变频
always @(posedge sample_clk or negedge rst_n) begin
    if (!rst_n) begin
        mixed_i <= 0;
        mixed_q <= 0;
    end else begin
        mixed_i <= ($signed(sample_i1) * $signed(local_i)) - ($signed(sample_q1) * $signed(local_q));
        mixed_q <= ($signed(sample_i1) * $signed(local_q)) + ($signed(sample_q1) * $signed(local_i));
    end
end

// 鉴相器 - Costas相位检测
always @(posedge sample_clk or negedge rst_n) begin
    if (!rst_n) begin
        phase_error <= 0;
    end else begin
        // Costas鉴相器: error = sign(I) * Q
        phase_error <= (mixed_i[23] ? -mixed_q : mixed_q);
    end
end

// 环路滤波器 - PI控制器
always @(posedge sample_clk or negedge rst_n) begin
    if (!rst_n) begin
        loop_integrator <= 0;
        loop_proportional <= 0;
    end else begin
        loop_integrator <= loop_integrator + ($signed(phase_error) * $signed(KI));
        loop_proportional <= $signed(phase_error) * $signed(KP);
    end
end

// 更新NCO频率
always @(posedge sample_clk or negedge rst_n) begin
    if (!rst_n) begin
        nco_freq <= 32'h10000000;
    end else begin
        nco_freq <= 32'h10000000 + loop_proportional + loop_integrator[31:16];
    end
end

// 输出锁定后的数据
always @(posedge sample_clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out_i <= 0;
        data_out_q <= 0;
    end else begin
        data_out_i <= mixed_i[23:12];
        data_out_q <= mixed_q[23:12];
    end
end

endmodule