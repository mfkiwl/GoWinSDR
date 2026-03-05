module ad9363_dev_cmos(
    input                               rst_n,

    output                              data_clk,
    
    // RX Port
    input              [11:0]           rx_data_in,
    input                               rx_clk_in_p,
    input                               rx_frame_in_p,

    output reg         [11:0]           adc_data_out_i1,
    output reg         [11:0]           adc_data_out_q1,
    output reg                          adc_out_valid,
    output                              adc_status,
 
    // TX Port
    input              [11:0]           dac_data_in_i1,
    input              [11:0]           dac_data_in_q1,
    input                               dac_in_valid,

    output             [11:0]           tx_data_out,
    output                              tx_clk_out_p,
    output                              tx_frame_out_p              
);

// 时钟分配
assign data_clk = rx_clk_in_p;
assign tx_clk_out_p = data_clk;
assign adc_status = 1'b0;

// ==================== RX路径 ====================
wire [11:0] rx_i_iddr, rx_q_iddr;
wire rx_frame_iddr_q0, rx_frame_iddr_q1;

// RX FRAME IDDR
IDDR IDDR_rx_frame_inst (
    .Q0  (rx_frame_iddr_q0),  // 第一个边沿
    .Q1  (rx_frame_iddr_q1),  // 第二个边沿
    .CLK (data_clk),
    .D   (rx_frame_in_p)
);

// RX DATA IDDR (12位)
IDDR IDDR_rx_data_inst_0  (.Q0(rx_i_iddr[0]),  .Q1(rx_q_iddr[0]),  .CLK(data_clk), .D(rx_data_in[0]));
IDDR IDDR_rx_data_inst_1  (.Q0(rx_i_iddr[1]),  .Q1(rx_q_iddr[1]),  .CLK(data_clk), .D(rx_data_in[1]));
IDDR IDDR_rx_data_inst_2  (.Q0(rx_i_iddr[2]),  .Q1(rx_q_iddr[2]),  .CLK(data_clk), .D(rx_data_in[2]));
IDDR IDDR_rx_data_inst_3  (.Q0(rx_i_iddr[3]),  .Q1(rx_q_iddr[3]),  .CLK(data_clk), .D(rx_data_in[3]));
IDDR IDDR_rx_data_inst_4  (.Q0(rx_i_iddr[4]),  .Q1(rx_q_iddr[4]),  .CLK(data_clk), .D(rx_data_in[4]));
IDDR IDDR_rx_data_inst_5  (.Q0(rx_i_iddr[5]),  .Q1(rx_q_iddr[5]),  .CLK(data_clk), .D(rx_data_in[5]));
IDDR IDDR_rx_data_inst_6  (.Q0(rx_i_iddr[6]),  .Q1(rx_q_iddr[6]),  .CLK(data_clk), .D(rx_data_in[6]));
IDDR IDDR_rx_data_inst_7  (.Q0(rx_i_iddr[7]),  .Q1(rx_q_iddr[7]),  .CLK(data_clk), .D(rx_data_in[7]));
IDDR IDDR_rx_data_inst_8  (.Q0(rx_i_iddr[8]),  .Q1(rx_q_iddr[8]),  .CLK(data_clk), .D(rx_data_in[8]));
IDDR IDDR_rx_data_inst_9  (.Q0(rx_i_iddr[9]),  .Q1(rx_q_iddr[9]),  .CLK(data_clk), .D(rx_data_in[9]));
IDDR IDDR_rx_data_inst_10 (.Q0(rx_i_iddr[10]), .Q1(rx_q_iddr[10]), .CLK(data_clk), .D(rx_data_in[10]));
IDDR IDDR_rx_data_inst_11 (.Q0(rx_i_iddr[11]), .Q1(rx_q_iddr[11]), .CLK(data_clk), .D(rx_data_in[11]));

// RX数据锁存和对齐
always @(posedge data_clk or negedge rst_n) begin
    if (!rst_n) begin
        adc_data_out_i1 <= 12'd0;
        adc_data_out_q1 <= 12'd0;
        adc_out_valid <= 1'b0;
    end else begin
        // 使用rx_frame来对齐I/Q数据
        if (rx_frame_iddr_q0) begin  // FRAME高时是I数据
            adc_data_out_i1 <= rx_i_iddr;
            adc_out_valid <= 1'b0;
        end else begin               // FRAME低时是Q数据
            adc_data_out_q1 <= rx_q_iddr;
            adc_out_valid <= 1'b1;   // Q数据有效时拉高
        end
    end
end

// ==================== TX路径 ====================
reg tx_frame_toggle;
reg [11:0] tx_i_reg, tx_q_reg;

// TX帧切换逻辑
always @(posedge data_clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_frame_toggle <= 1'b0;
        tx_i_reg <= 12'd0;
        tx_q_reg <= 12'd0;
    end else begin
        tx_frame_toggle <= ~tx_frame_toggle;  // 每周期翻转
        
        if (dac_in_valid) begin
            tx_i_reg <= dac_data_in_i1;
            tx_q_reg <= dac_data_in_q1;
        end
    end
end

// TX FRAME ODDR
ODDR ODDR_tx_frame_inst (
    .Q0  (tx_frame_out_p),
    .CLK (data_clk),
    .D0  (tx_frame_toggle),   // 上升沿输出
    .D1  (~tx_frame_toggle),  // 下降沿输出
    .TX  (1'b1)
);

// TX DATA ODDR (12位)
// 注意：需要根据AD9363时序确定I/Q顺序
// 如果FRAME=1时发送I，则D0=I, D1=Q
// 如果FRAME=1时发送Q，则D0=Q, D1=I
ODDR ODDR_tx_data_inst_0  (.Q0(tx_data_out[0]),  .CLK(data_clk), .D0(tx_i_reg[0]),  .D1(tx_q_reg[0]),  .TX(1'b1));
ODDR ODDR_tx_data_inst_1  (.Q0(tx_data_out[1]),  .CLK(data_clk), .D0(tx_i_reg[1]),  .D1(tx_q_reg[1]),  .TX(1'b1));
ODDR ODDR_tx_data_inst_2  (.Q0(tx_data_out[2]),  .CLK(data_clk), .D0(tx_i_reg[2]),  .D1(tx_q_reg[2]),  .TX(1'b1));
ODDR ODDR_tx_data_inst_3  (.Q0(tx_data_out[3]),  .CLK(data_clk), .D0(tx_i_reg[3]),  .D1(tx_q_reg[3]),  .TX(1'b1));
ODDR ODDR_tx_data_inst_4  (.Q0(tx_data_out[4]),  .CLK(data_clk), .D0(tx_i_reg[4]),  .D1(tx_q_reg[4]),  .TX(1'b1));
ODDR ODDR_tx_data_inst_5  (.Q0(tx_data_out[5]),  .CLK(data_clk), .D0(tx_i_reg[5]),  .D1(tx_q_reg[5]),  .TX(1'b1));
ODDR ODDR_tx_data_inst_6  (.Q0(tx_data_out[6]),  .CLK(data_clk), .D0(tx_i_reg[6]),  .D1(tx_q_reg[6]),  .TX(1'b1));
ODDR ODDR_tx_data_inst_7  (.Q0(tx_data_out[7]),  .CLK(data_clk), .D0(tx_i_reg[7]),  .D1(tx_q_reg[7]),  .TX(1'b1));
ODDR ODDR_tx_data_inst_8  (.Q0(tx_data_out[8]),  .CLK(data_clk), .D0(tx_i_reg[8]),  .D1(tx_q_reg[8]),  .TX(1'b1));
ODDR ODDR_tx_data_inst_9  (.Q0(tx_data_out[9]),  .CLK(data_clk), .D0(tx_i_reg[9]),  .D1(tx_q_reg[9]),  .TX(1'b1));
ODDR ODDR_tx_data_inst_10 (.Q0(tx_data_out[10]), .CLK(data_clk), .D0(tx_i_reg[10]), .D1(tx_q_reg[10]), .TX(1'b1));
ODDR ODDR_tx_data_inst_11 (.Q0(tx_data_out[11]), .CLK(data_clk), .D0(tx_i_reg[11]), .D1(tx_q_reg[11]), .TX(1'b1));

endmodule