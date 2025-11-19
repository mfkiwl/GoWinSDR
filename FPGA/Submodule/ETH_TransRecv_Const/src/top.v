module eth_loopback_demo(
    input               sys_clk,
    input               rst_n,
    
    // RGMII接口
    input               RGMII_RXCLK,
    input [3:0]         RGMII_RXD,
    input               RGMII_RXDV,
    output              RGMII_GTXCLK,
    output [3:0]        RGMII_TXD,
    output              RGMII_TXEN,
    output              RGMII_RST_N,
    
    // LED指示
    output              ACT_LED
);

wire [7:0]  rx_data;
wire        rx_data_valid;
wire        rx_frame_start;
wire        rx_frame_end;
wire        tx_ready;
wire        rx_active;
wire        tx_active;
wire        PHY_CLK;
wire        ACT_LED;

assign ACT_LED = rx_active | tx_active;

// 实例化以太网收发模块
eth_transceiver #(
    .BOARD_MAC  (48'h11_45_14_19_19_81),
    .BOARD_IP   ({8'd192, 8'd168, 8'd3, 8'd2}),
    .BOARD_PORT (16'h8000)
) eth_inst (
    .sys_clk            (sys_clk        ),
    .rst_n              (rst_n          ),
    
    .PHY_CLK            (PHY_CLK        ),
    .RGMII_RXCLK        (RGMII_RXCLK    ),
    .RGMII_RXD          (RGMII_RXD      ),
    .RGMII_RXDV         (RGMII_RXDV     ),
    .RGMII_GTXCLK       (RGMII_GTXCLK   ),
    .RGMII_TXD          (RGMII_TXD      ),
    .RGMII_TXEN         (RGMII_TXEN     ),
    .RGMII_RST_N        (RGMII_RST_N    ),
    
    .tx_data            (tx_data        ),  // 回环：接收数据直接发送
    .tx_data_valid      (tx_data_valid  ),
    .tx_frame_start     (rx_frame_start ),
    .tx_ready           (tx_ready       ),
    
    .rx_data            (rx_data        ),
    .rx_data_valid      (rx_data_valid  ),
    .rx_frame_start     (rx_frame_start ),
    .rx_frame_end       (rx_frame_end   ),
    
    .rx_active          (rx_active      ),
    .tx_active          (tx_active      )
);

reg tx_data_valid_r;
reg tx_data_valid_temp;  
wire tx_data_valid;  
reg [7:0] tx_data;
wire fifo_empty;
wire fifo_full;
wire [7:0] fifo_out;
reg  rx_data_valid_d;
wire rx_data_valid_extended;

	always @(posedge RGMII_RXCLK or negedge rst_n) begin
		if (!rst_n) begin
			rx_data_valid_d <= 1'b0;
		end
		else begin
			rx_data_valid_d <= rx_data_valid;
		end
	end

	assign rx_data_valid_extended = rx_data_valid | rx_data_valid_d;

	fifo_top fifo_u0(
		.Data(rx_data), //input [7:0] Data
		.WrClk(RGMII_RXCLK), //input WrClk
		.RdClk(RGMII_GTXCLK), //input RdClk
		.WrEn(rx_data_valid_extended), //input WrEn
		.RdEn(tx_data_valid_r), //input RdEn
		.Q(fifo_out), //output [7:0] Q
		.Empty(fifo_empty), //output Empty
		.Full(fifo_full) //output Full
	);
reg tx_data_valid_t2;
reg fifo_empty_reg;
assign tx_data_valid = tx_data_valid_t2 && !fifo_empty_reg;
always @(posedge RGMII_GTXCLK or negedge rst_n) begin
    if (!rst_n) begin
        tx_data_valid_r <= 1'b0;
        tx_data_valid_t2 <= 1'b0;
    end
    else begin
        if (!fifo_empty) begin
            tx_data_valid_r <= 1'b1;
            tx_data <= fifo_out;
        end
        else begin
            tx_data_valid_r <= 1'b0;
        end
        tx_data_valid_temp <= tx_data_valid_r;
        tx_data_valid_t2 <= tx_data_valid_temp;
        fifo_empty_reg <= fifo_empty;
    end
end

// LED指示
assign led_rx = rx_active;
assign led_tx = tx_active;

endmodule