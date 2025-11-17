module eth_ddr3_loopback_top #(
    parameter BOARD_MAC     = 48'h11_45_14_19_19_81,
    parameter BOARD_IP      = {8'd192,8'd168,8'd3,8'd2},
    parameter BOARD_PORT    = 16'h8000,
    parameter DES_MAC       = 48'hff_ff_ff_ff_ff_ff,
    parameter DES_IP        = {8'd192,8'd168,8'd3,8'd3},
    parameter DES_PORT      = 16'h8000
)(
    // 系统时钟和复位
    input               sys_clk,        // 50MHz系统时钟
    input               rst_n,
    
    // 以太网PHY接口 - RGMII
    input               RGMII_RXCLK,
    input [3:0]         RGMII_RXD,
    input               RGMII_RXDV,
    output              RGMII_GTXCLK,
    output [3:0]        RGMII_TXD,
    output              RGMII_TXEN,
    output              RGMII_RST_N,
    
    // DDR3物理接口
    output [13:0]       ddr_addr,
    output [2:0]        ddr_bank,
    output              ddr_cs,
    output              ddr_ras,
    output              ddr_cas,
    output              ddr_we,
    output              ddr_ck,
    output              ddr_ck_n,
    output              ddr_cke,
    output              ddr_odt,
    output              ddr_reset_n,
    output [1:0]        ddr_dm,
    inout  [15:0]       ddr_dq,
    inout  [1:0]        ddr_dqs,
    inout  [1:0]        ddr_dqs_n
);

// 状态指示LED
wire              led_rx_active;
wire              led_tx_active;
wire              led_ddr_init;
wire              led_fifo_full;
wire             led_fifo_empty;

/////////////////////////////////////////////////////////////////////////////////////////
// 内部信号定义
/////////////////////////////////////////////////////////////////////////////////////////
// 以太网接收信号
wire [7:0]  eth_rx_data;
wire        eth_rx_data_valid;
wire        eth_rx_frame_start;
wire        eth_rx_frame_end;
wire        eth_rx_active;

// 以太网发送信号
wire [7:0]  eth_tx_data;
wire        eth_tx_data_valid;
wire        eth_tx_frame_start;
wire        eth_tx_ready;
wire        eth_tx_active;

// DDR3 FIFO信号
wire        fifo_wr_en;
wire [7:0]  fifo_wr_data;
wire        fifo_wr_full;
wire        fifo_wr_almost_full;

wire        fifo_rd_en;
wire [7:0]  fifo_rd_data;
wire        fifo_rd_empty;
wire        fifo_rd_almost_empty;
wire        fifo_rd_data_valid;

wire [31:0] fifo_count;
wire [2:0]  fifo_state;
wire        ddr_init_done;

// 时钟信号
wire        clk_eth;        // 以太网时钟(从PLL获取)

/////////////////////////////////////////////////////////////////////////////////////////
// 以太网收发器例化
/////////////////////////////////////////////////////////////////////////////////////////
eth_transceiver #(
    .BOARD_MAC  (BOARD_MAC  ),
    .BOARD_IP   (BOARD_IP   ),
    .BOARD_PORT (BOARD_PORT ),
    .DES_MAC    (DES_MAC    ),
    .DES_IP     (DES_IP     ),
    .DES_PORT   (DES_PORT   )
) u_eth_transceiver (
    .sys_clk            (sys_clk            ),
    .rst_n              (rst_n              ),
    
    // PHY接口
    .PHY_CLK            (                   ),
    .RGMII_RXCLK        (RGMII_RXCLK        ),
    .RGMII_RXD          (RGMII_RXD          ),
    .RGMII_RXDV         (RGMII_RXDV         ),
    .RGMII_GTXCLK       (RGMII_GTXCLK       ),
    .RGMII_TXD          (RGMII_TXD          ),
    .RGMII_TXEN         (RGMII_TXEN         ),
    .RGMII_RST_N        (RGMII_RST_N        ),
    
    // 用户发送接口
    .tx_data            (eth_tx_data        ),
    .tx_data_valid      (eth_tx_data_valid  ),
    .tx_frame_start     (eth_tx_frame_start ),
    .tx_ready           (eth_tx_ready       ),
    
    // 用户接收接口
    .rx_data            (eth_rx_data        ),
    .rx_data_valid      (eth_rx_data_valid  ),
    .rx_frame_start     (eth_rx_frame_start ),
    .rx_frame_end       (eth_rx_frame_end   ),
    
    // 状态指示
    .rx_active          (eth_rx_active      ),
    .tx_active          (eth_tx_active      )
);

// 获取以太网时钟(125MHz)
assign clk_eth = RGMII_GTXCLK;

/////////////////////////////////////////////////////////////////////////////////////////
// DDR3 FIFO例化
/////////////////////////////////////////////////////////////////////////////////////////
DDR3_LARGE_FIFO #(
    .WR_DATA_WIDTH  (8      ),  // 8位写数据宽度
    .RD_DATA_WIDTH  (8      ),  // 8位读数据宽度
    .DDR_DATA_WIDTH (128    ),  // DDR3 128位数据宽度
    .DDR_ADDR_WIDTH (28     ),  // DDR3 28位地址
    .FIFO_DEPTH     (2**24  )   // 16M深度
) u_ddr3_fifo (
    // 系统时钟
    .sys_clk            (sys_clk            ),
    .wr_clk             (RGMII_RXCLK        ),  // 使用接收时钟作为写时钟
    .rd_clk             (clk_eth            ),  // 使用以太网发送时钟作为读时钟
    .rst_n              (rst_n              ),
    
    // 写接口
    .wr_en              (fifo_wr_en         ),
    .wr_data            (fifo_wr_data       ),
    .wr_full            (fifo_wr_full       ),
    .wr_almost_full     (fifo_wr_almost_full),
    
    // 读接口
    .rd_en              (fifo_rd_en         ),
    .rd_data            (fifo_rd_data       ),
    .rd_empty           (fifo_rd_empty      ),
    .rd_almost_empty    (fifo_rd_almost_empty),
    .rd_data_valid      (fifo_rd_data_valid ),
    
    // DDR3物理接口
    .ddr_addr           (ddr_addr           ),
    .ddr_bank           (ddr_bank           ),
    .ddr_cs             (ddr_cs             ),
    .ddr_ras            (ddr_ras            ),
    .ddr_cas            (ddr_cas            ),
    .ddr_we             (ddr_we             ),
    .ddr_ck             (ddr_ck             ),
    .ddr_ck_n           (ddr_ck_n           ),
    .ddr_cke            (ddr_cke            ),
    .ddr_odt            (ddr_odt            ),
    .ddr_reset_n        (ddr_reset_n        ),
    .ddr_dm             (ddr_dm             ),
    .ddr_dq             (ddr_dq             ),
    .ddr_dqs            (ddr_dqs            ),
    .ddr_dqs_n          (ddr_dqs_n          ),
    
    // 状态输出
    .fifo_count         (fifo_count         ),
    .fifo_state         (fifo_state         ),
    .ddr_init_done      (ddr_init_done      )
);

/////////////////////////////////////////////////////////////////////////////////////////
// 接收数据写入DDR3 FIFO逻辑
/////////////////////////////////////////////////////////////////////////////////////////
assign fifo_wr_en = eth_rx_data_valid && !fifo_wr_full && ddr_init_done;
assign fifo_wr_data = eth_rx_data;

/////////////////////////////////////////////////////////////////////////////////////////
// 从DDR3 FIFO读取数据并发送逻辑
/////////////////////////////////////////////////////////////////////////////////////////
localparam TX_IDLE          = 3'd0;
localparam TX_WAIT_INIT     = 3'd1;
localparam TX_START_FRAME   = 3'd2;
localparam TX_SEND_DATA     = 3'd3;
localparam TX_WAIT_READY    = 3'd4;

reg [2:0]   tx_state;
reg [15:0]  tx_byte_cnt;
reg [7:0]   tx_data_reg;
reg         tx_data_valid_reg;
reg         tx_frame_start_reg;

assign eth_tx_data = tx_data_reg;
assign eth_tx_data_valid = tx_data_valid_reg;
assign eth_tx_frame_start = tx_frame_start_reg;

// 发送状态机
always @(posedge clk_eth or negedge rst_n) begin
    if (!rst_n) begin
        tx_state            <= TX_IDLE;
        tx_byte_cnt         <= 16'd0;
        tx_data_reg         <= 8'd0;
        tx_data_valid_reg   <= 1'b0;
        tx_frame_start_reg  <= 1'b0;
    end
    else begin
        tx_frame_start_reg <= 1'b0;
        
        case (tx_state)
            TX_IDLE: begin
                tx_data_valid_reg <= 1'b0;
                tx_byte_cnt <= 16'd0;
                
                if (ddr_init_done) begin
                    tx_state <= TX_WAIT_INIT;
                end
            end
            
            TX_WAIT_INIT: begin
                // 等待FIFO有足够数据再开始发送(避免频繁发送小包)
                if (fifo_count >= 32 && eth_tx_ready) begin
                    tx_state <= TX_START_FRAME;
                end
            end
            
            TX_START_FRAME: begin
                // 发送帧开始标志
                tx_frame_start_reg <= 1'b1;
                tx_byte_cnt <= 16'd0;
                tx_state <= TX_SEND_DATA;
            end
            
            TX_SEND_DATA: begin
                if (!fifo_rd_empty) begin
                    // 从FIFO读取数据
                    if (fifo_rd_data_valid) begin
                        tx_data_reg <= fifo_rd_data;
                        tx_data_valid_reg <= 1'b1;
                        tx_byte_cnt <= tx_byte_cnt + 1'b1;
                        
                        // 发送一定数量后结束当前帧
                        // 或者FIFO即将空时结束
                        if (tx_byte_cnt >= 16'd1024 || fifo_count <= 4) begin
                            tx_state <= TX_WAIT_READY;
                        end
                    end
                    else begin
                        tx_data_valid_reg <= 1'b0;
                    end
                end
                else begin
                    // FIFO空了,结束发送
                    tx_data_valid_reg <= 1'b0;
                    tx_state <= TX_WAIT_READY;
                end
            end
            
            TX_WAIT_READY: begin
                tx_data_valid_reg <= 1'b0;
                
                // 等待以太网模块准备好后,检查是否还有数据要发送
                if (eth_tx_ready) begin
                    if (fifo_count >= 32) begin
                        tx_state <= TX_START_FRAME;
                    end
                    else begin
                        tx_state <= TX_WAIT_INIT;
                    end
                end
            end
            
            default: tx_state <= TX_IDLE;
        endcase
    end
end

// FIFO读使能
assign fifo_rd_en = (tx_state == TX_SEND_DATA) && !fifo_rd_empty;

/////////////////////////////////////////////////////////////////////////////////////////
// 状态LED指示
/////////////////////////////////////////////////////////////////////////////////////////
assign led_rx_active    = eth_rx_active;
assign led_tx_active    = eth_tx_active;
assign led_ddr_init     = ddr_init_done;
assign led_fifo_full    = fifo_wr_almost_full;
assign led_fifo_empty   = fifo_rd_empty;

endmodule