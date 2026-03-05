module eth_loopback_demo(
    input               sys_clk,
    input               rst_n,
    
    // RGMII接口
    output              PHY_CLK,
    input               RGMII_RXCLK,
    input [3:0]         RGMII_RXD,
    input               RGMII_RXDV,
    output              RGMII_GTXCLK,
    output [3:0]        RGMII_TXD,
    output              RGMII_TXEN,
    output              RGMII_RST_N,
    
    // LED指示
    output              led_rx,
    output              led_tx
);

wire [7:0]  rx_data;
wire        rx_data_valid;
wire        rx_frame_start;
wire        rx_frame_end;
wire        tx_ready;
wire        rx_active;
wire        tx_active;

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
    
    .tx_data            (rx_data        ),  // 回环：接收数据直接发送
    .tx_data_valid      (rx_data_valid  ),
    .tx_frame_start     (rx_frame_start ),
    .tx_ready           (tx_ready       ),
    
    .rx_data            (rx_data        ),
    .rx_data_valid      (rx_data_valid  ),
    .rx_frame_start     (rx_frame_start ),
    .rx_frame_end       (rx_frame_end   ),
    
    .rx_active          (rx_active      ),
    .tx_active          (tx_active      )
);

// LED指示
assign led_rx = rx_active;
assign led_tx = tx_active;

endmodule