module eth_transceiver#(
    parameter BOARD_MAC     = 48'h11_45_14_19_19_81,
    parameter BOARD_IP      = {8'd192,8'd168,8'd3,8'd2},
    parameter BOARD_PORT    = 16'h8000,
    parameter DES_MAC       = 48'hff_ff_ff_ff_ff_ff,
    parameter DES_IP        = {8'd192,8'd168,8'd3,8'd3},
    parameter DES_PORT      = 16'h8000
)(
    input               sys_clk,
    input               rst_n,
    
    // PHY接口 - RGMII
    output              PHY_CLK,            // PHY时钟输出
    input               RGMII_RXCLK,        // 接收时钟
    input [3:0]         RGMII_RXD,          // 接收数据
    input               RGMII_RXDV,         // 接收数据有效
    
    output              RGMII_GTXCLK,       // 发送时钟
    output [3:0]        RGMII_TXD,          // 发送数据
    output              RGMII_TXEN,         // 发送使能
    output              RGMII_RST_N,        // PHY复位
    
    // 用户发送接口
    input [7:0]         tx_data,            // 待发送数据
    input               tx_data_valid,      // 发送数据有效
    input               tx_frame_start,     // 开始发送帧
    output              tx_ready,           // 准备发送
    
    // 用户接收接口
    output [7:0]        rx_data,            // 接收到的数据
    output              rx_data_valid,      // 接收数据有效
    output              rx_frame_start,     // 帧开始
    output              rx_frame_end,       // 帧结束
    
    // 状态指示
    output              rx_active,          // 正在接收
    output              tx_active           // 正在发送
);

/////////////////////////////////////////////////////////////////////////////////////////
// 时钟生成
/////////////////////////////////////////////////////////////////////////////////////////
wire clk_125m;

GMII_PLL pll_inst(
    .clkin      (sys_clk        ),
    .clkout0    (clk_125m       ),  // 125MHz for RGMII
    .clkout1    (PHY_CLK        )   // 25MHz for PHY
);

assign RGMII_GTXCLK = clk_125m;
assign RGMII_RST_N = rst_n;

/////////////////////////////////////////////////////////////////////////////////////////
// RGMII转GMII - 接收路径
/////////////////////////////////////////////////////////////////////////////////////////
wire [7:0]  gmii_rxd;
wire        gmii_rxdv;

// DDR采样实现RGMII转GMII
reg [3:0] rxd_rising, rxd_falling;
reg rxdv_rising, rxdv_falling;

always @(posedge RGMII_RXCLK) begin
    rxd_rising  <= RGMII_RXD;
    rxdv_rising <= RGMII_RXDV;
end

always @(negedge RGMII_RXCLK) begin
    rxd_falling  <= RGMII_RXD;
    rxdv_falling <= RGMII_RXDV;
end

reg [7:0] gmii_rxd_reg;
reg gmii_rxdv_reg;

// ETH_DDR ETH_DDR_u0(
//     .din(RGMII_RXD), //input [3:0] din
//     .clk(RGMII_RXCLK), //input clk
//     .q(gmii_rxd_reg) //output [7:0] q
// );

always @(posedge RGMII_RXCLK) begin
    gmii_rxd_reg  <= {rxd_falling, rxd_rising};
    gmii_rxdv_reg <= rxdv_rising;
end

assign gmii_rxd  = gmii_rxd_reg;
assign gmii_rxdv = gmii_rxdv_reg;

/////////////////////////////////////////////////////////////////////////////////////////
// 以太网接收解析
/////////////////////////////////////////////////////////////////////////////////////////
localparam RX_IDLE      = 4'd0;
localparam RX_PREAMBLE  = 4'd1;
localparam RX_DEST_MAC  = 4'd2;
localparam RX_SRC_MAC   = 4'd3;
localparam RX_ETH_TYPE  = 4'd4;
localparam RX_IP_HEAD   = 4'd5;
localparam RX_UDP_HEAD  = 4'd6;
localparam RX_PAYLOAD   = 4'd7;
localparam RX_END       = 4'd8;

reg [3:0]   rx_state;
reg [15:0]  rx_cnt;
reg [47:0]  rx_dest_mac;
reg [47:0]  rx_src_mac;
reg [15:0]  rx_eth_type;
reg [31:0]  rx_src_ip;
reg [15:0]  rx_src_port;
reg [15:0]  rx_dest_port;
reg [15:0]  rx_payload_len;

reg [7:0]   rx_data_reg;
reg         rx_data_valid_reg;
reg         rx_frame_start_reg;
reg         rx_frame_end_reg;
reg         rx_active_reg;

assign rx_data        = rx_data_reg;
assign rx_data_valid  = rx_data_valid_reg;
assign rx_frame_start = rx_frame_start_reg;
assign rx_frame_end   = rx_frame_end_reg;
assign rx_active      = rx_active_reg;

// 接收状态机
always @(posedge RGMII_RXCLK or negedge rst_n) begin
    if (!rst_n) begin
        rx_state            <= RX_IDLE;
        rx_cnt              <= 16'd0;
        rx_data_reg         <= 8'd0;
        rx_data_valid_reg   <= 1'b0;
        rx_frame_start_reg  <= 1'b0;
        rx_frame_end_reg    <= 1'b0;
        rx_active_reg       <= 1'b0;
    end
    else begin
        rx_frame_start_reg <= 1'b0;
        rx_frame_end_reg   <= 1'b0;
        
        case (rx_state)
            RX_IDLE: begin
                rx_cnt              <= 16'd0;
                rx_data_valid_reg   <= 1'b0;
                rx_active_reg       <= 1'b0;
                
                if (gmii_rxdv && gmii_rxd == 8'h55) begin
                    rx_state <= RX_PREAMBLE;
                end
            end
            
            RX_PREAMBLE: begin
                if (gmii_rxdv) begin
                    if (gmii_rxd == 8'hD5) begin
                        rx_state            <= RX_DEST_MAC;
                        rx_cnt              <= 16'd0;
                        rx_frame_start_reg  <= 1'b1;
                        rx_active_reg       <= 1'b1;
                    end
                    else if (gmii_rxd != 8'h55) begin
                        rx_state <= RX_IDLE;
                    end
                end
                else begin
                    rx_state <= RX_IDLE;
                end
            end
            
            RX_DEST_MAC: begin
                if (gmii_rxdv) begin
                    rx_dest_mac <= {rx_dest_mac[39:0], gmii_rxd};
                    rx_cnt      <= rx_cnt + 1'b1;
                    if (rx_cnt == 16'd5) begin
                        rx_state <= RX_SRC_MAC;
                        rx_cnt   <= 16'd0;
                    end
                end
                else begin
                    rx_state <= RX_IDLE;
                end
            end
            
            RX_SRC_MAC: begin
                if (gmii_rxdv) begin
                    rx_src_mac <= {rx_src_mac[39:0], gmii_rxd};
                    rx_cnt     <= rx_cnt + 1'b1;
                    if (rx_cnt == 16'd5) begin
                        rx_state <= RX_ETH_TYPE;
                        rx_cnt   <= 16'd0;
                    end
                end
                else begin
                    rx_state <= RX_IDLE;
                end
            end
            
            RX_ETH_TYPE: begin
                if (gmii_rxdv) begin
                    rx_eth_type <= {rx_eth_type[7:0], gmii_rxd};
                    rx_cnt      <= rx_cnt + 1'b1;
                    if (rx_cnt == 16'd1) begin
                        // 检查MAC和类型
                        if (({rx_eth_type[7:0], gmii_rxd} == 16'h0800) && 
                            ((rx_dest_mac == BOARD_MAC) || (rx_dest_mac == 48'hFF_FF_FF_FF_FF_FF))) begin
                            rx_state <= RX_IP_HEAD;
                            rx_cnt   <= 16'd0;
                        end
                        else begin
                            rx_state <= RX_END;
                        end
                    end
                end
                else begin
                    rx_state <= RX_IDLE;
                end
            end
            
            RX_IP_HEAD: begin
                if (gmii_rxdv) begin
                    rx_cnt <= rx_cnt + 1'b1;
                    
                    case (rx_cnt)
                        16'd2:  rx_payload_len[15:8] <= gmii_rxd;
                        16'd3:  rx_payload_len[7:0]  <= gmii_rxd;
                        16'd12: rx_src_ip[31:24]     <= gmii_rxd;
                        16'd13: rx_src_ip[23:16]     <= gmii_rxd;
                        16'd14: rx_src_ip[15:8]      <= gmii_rxd;
                        16'd15: rx_src_ip[7:0]       <= gmii_rxd;
                    endcase
                    
                    if (rx_cnt == 16'd19) begin
                        rx_state <= RX_UDP_HEAD;
                        rx_cnt   <= 16'd0;
                    end
                end
                else begin
                    rx_state <= RX_IDLE;
                end
            end
            
            RX_UDP_HEAD: begin
                if (gmii_rxdv) begin
                    rx_cnt <= rx_cnt + 1'b1;
                    
                    case (rx_cnt)
                        16'd0: rx_src_port[15:8]  <= gmii_rxd;
                        16'd1: rx_src_port[7:0]   <= gmii_rxd;
                        16'd2: rx_dest_port[15:8] <= gmii_rxd;
                        16'd3: rx_dest_port[7:0]  <= gmii_rxd;
                    endcase
                    
                    if (rx_cnt == 16'd7) begin
                        if (rx_dest_port == BOARD_PORT) begin
                            rx_state <= RX_PAYLOAD;
                            rx_cnt   <= 16'd0;
                            // rx_data_valid_reg <= 1'b1;
                            // rx_data_reg       <= gmii_rxd;
                        end
                        else begin
                            rx_state <= RX_END;
                        end
                    end
                end
                else begin
                    rx_state <= RX_IDLE;
                end
            end
            
            RX_PAYLOAD: begin
                if (gmii_rxdv) begin
                    rx_data_reg       <= gmii_rxd;
                    rx_data_valid_reg <= 1'b1;
                    rx_cnt            <= rx_cnt + 1'b1;
                    
                    // UDP数据长度 = IP总长 - IP头(20) - UDP头(8)
                    if (rx_cnt >= (rx_payload_len - 16'd29)) begin
                        rx_state          <= RX_END;
                        rx_data_valid_reg <= 1'b0;
                    end
                end
                else begin
                    rx_state          <= RX_END;
                    rx_data_valid_reg <= 1'b0;
                end
            end
            
            RX_END: begin
                rx_data_valid_reg  <= 1'b0;
                rx_frame_end_reg   <= 1'b1;
                rx_active_reg      <= 1'b0;
                
                if (!gmii_rxdv) begin
                    rx_state <= RX_IDLE;
                end
            end
            
            default: rx_state <= RX_IDLE;
        endcase
    end
end

/////////////////////////////////////////////////////////////////////////////////////////
// 以太网发送
/////////////////////////////////////////////////////////////////////////////////////////
localparam TX_IDLE      = 4'd0;
localparam TX_CHECK_SUM = 4'd1;
localparam TX_PREAMBLE  = 4'd2;
localparam TX_MAC       = 4'd3;
localparam TX_IP_HEAD   = 4'd4;
localparam TX_UDP_HEAD  = 4'd5;
localparam TX_PAYLOAD   = 4'd6;
localparam TX_CRC       = 4'd7;
localparam TX_DELAY     = 4'd8;

reg [3:0]   tx_state;
reg [15:0]  tx_cnt;
reg [7:0]   tx_buffer [0:1471];
reg [15:0]  tx_buf_len;
reg [10:0]  tx_wr_ptr;
reg         tx_buf_ready;

reg [31:0]  ip_header [6:0];
reg [31:0]  ip_checksum_buf;

wire [31:0] crc_data;
reg         crc_en;
reg [7:0]   gmii_txd;
reg         gmii_txen;

// CRC校验模块
crc crc_inst(
    .Clk        (~clk_125m      ),
    .Reset      (1'b0           ),
    .Data_in    (gmii_txd       ),
    .Enable     (crc_en         ),
    .Crc        (crc_data       ),
    .CrcNext    (               )
);

// 发送数据缓冲
always @(posedge clk_125m or negedge rst_n) begin
    if (!rst_n) begin
        tx_wr_ptr    <= 11'd0;
        tx_buf_len   <= 16'd0;
        tx_buf_ready <= 1'b0;
    end
    else begin
        if (tx_frame_start) begin
            tx_wr_ptr    <= 11'd0;
            tx_buf_len   <= 16'd0;
            tx_buf_ready <= 1'b0;
        end
        else if (tx_data_valid && !tx_buf_ready) begin
            tx_buffer[tx_wr_ptr] <= tx_data;
            tx_wr_ptr            <= tx_wr_ptr + 1'b1;
            tx_buf_len           <= tx_wr_ptr + 1'b1;
        end
        else if (tx_state == TX_DELAY && tx_cnt[3]) begin
            tx_buf_ready <= 1'b0;
            tx_wr_ptr    <= 11'd0;
        end
        
        // 判断缓冲区是否准备好发送
        if (!tx_data_valid && tx_wr_ptr > 0 && !tx_buf_ready) begin
            tx_buf_ready <= 1'b1;
        end
    end
end

assign tx_ready = (tx_state == TX_IDLE) && !tx_buf_ready;
assign tx_active = (tx_state != TX_IDLE);

// 发送状态机
always @(posedge clk_125m or negedge rst_n) begin
    if (!rst_n) begin
        tx_state    <= TX_IDLE;
        tx_cnt      <= 16'd0;
        gmii_txd    <= 8'd0;
        gmii_txen   <= 1'b0;
        crc_en      <= 1'b0;
    end
    else begin
        case (tx_state)
            TX_IDLE: begin
                tx_cnt    <= 16'd0;
                gmii_txen <= 1'b0;
                gmii_txd  <= 8'd0;
                crc_en    <= 1'b0;
                
                if (tx_buf_ready && tx_buf_len > 0) begin
                    // 准备IP头
                    ip_header[0] <= {16'h4500, tx_buf_len + 16'd28};
                    ip_header[1] <= {5'b00000, 11'd0, 16'h4000};
                    ip_header[2] <= {8'h80, 8'h11, 16'h0000};
                    ip_header[3] <= BOARD_IP;
                    ip_header[4] <= (rx_state == RX_IDLE) ? DES_IP : rx_src_ip;  // 自动回复
                    ip_header[5] <= {BOARD_PORT, ((rx_state == RX_IDLE) ? DES_PORT : rx_src_port)};
                    ip_header[6] <= {tx_buf_len + 16'd8, 16'h0000};
                    
                    tx_state <= TX_CHECK_SUM;
                end
            end
            
            TX_CHECK_SUM: begin
                tx_cnt <= tx_cnt + 1'b1;
                
                case (tx_cnt)
                    16'd0: ip_checksum_buf <= ((ip_header[0][15:0] + ip_header[0][31:16]) +
                                               (ip_header[1][15:0] + ip_header[1][31:16])) +
                                              (((ip_header[2][15:0] + ip_header[2][31:16]) +
                                               (ip_header[3][15:0] + ip_header[3][31:16])) +
                                               (ip_header[4][15:0] + ip_header[4][31:16]));
                    16'd1: ip_checksum_buf[15:0] <= ip_checksum_buf[31:16] + ip_checksum_buf[15:0];
                    16'd2: begin
                        ip_header[2][15:0] <= ~ip_checksum_buf[15:0];
                        tx_state <= TX_PREAMBLE;
                        tx_cnt   <= 16'd0;
                    end
                endcase
            end
            
            TX_PREAMBLE: begin
                tx_cnt    <= tx_cnt + 1'b1;
                gmii_txen <= 1'b1;
                
                if (tx_cnt < 16'd7)
                    gmii_txd <= 8'h55;
                else
                    gmii_txd <= 8'hD5;
                
                if (tx_cnt == 16'd7) begin
                    tx_state <= TX_MAC;
                    tx_cnt   <= 16'd0;
                end
            end
            
            TX_MAC: begin
                tx_cnt <= tx_cnt + 1'b1;
                crc_en <= 1'b1;
                
                // 目的MAC + 源MAC + 类型
                if (tx_cnt < 16'd6) begin
                    // 自动回复模式或广播模式
                    if (rx_state == RX_IDLE)
                        gmii_txd <= DES_MAC[(5 - tx_cnt) * 8 +: 8];
                    else
                        gmii_txd <= rx_src_mac[(5 - tx_cnt) * 8 +: 8];
                end
                else if (tx_cnt < 16'd12)
                    gmii_txd <= BOARD_MAC[(11 - tx_cnt) * 8 +: 8];
                else if (tx_cnt == 16'd12)
                    gmii_txd <= 8'h08;
                else
                    gmii_txd <= 8'h00;
                
                if (tx_cnt == 16'd13) begin
                    tx_state <= TX_IP_HEAD;
                    tx_cnt   <= 16'd0;
                end
            end
            
            TX_IP_HEAD: begin
                tx_cnt   <= tx_cnt + 1'b1;
                gmii_txd <= ip_header[tx_cnt[4:2]][(3 - tx_cnt[1:0]) * 8 +: 8];
                
                if (tx_cnt == 16'd19) begin
                    tx_state <= TX_UDP_HEAD;
                    tx_cnt   <= 16'd0;
                end
            end
            
            TX_UDP_HEAD: begin
                tx_cnt   <= tx_cnt + 1'b1;
                // gmii_txd <= ip_header[5 + tx_cnt[3]][(3 - tx_cnt[1:0]) * 8 +: 8];
                gmii_txd <= ip_header[5 + tx_cnt[2]][(3 - tx_cnt[1:0]) * 8 +: 8];
                
                if (tx_cnt == 16'd7) begin
                    tx_state <= TX_PAYLOAD;
                    tx_cnt   <= 16'd0;
                end
            end
            
            TX_PAYLOAD: begin
                tx_cnt   <= tx_cnt + 1'b1;
                gmii_txd <= tx_buffer[tx_cnt];
                if (tx_cnt == tx_buf_len - 1) begin
                    tx_state <= TX_CRC;
                    tx_cnt   <= 16'd0;
                    crc_en   <= 1'b0;
                end
            end
            
            TX_CRC: begin
                tx_cnt <= tx_cnt + 1'b1;
                
                case (tx_cnt[1:0])
                    2'd0: gmii_txd <= {~crc_data[24], ~crc_data[25], ~crc_data[26], ~crc_data[27],
                                      ~crc_data[28], ~crc_data[29], ~crc_data[30], ~crc_data[31]};
                    2'd1: gmii_txd <= {~crc_data[16], ~crc_data[17], ~crc_data[18], ~crc_data[19],
                                      ~crc_data[20], ~crc_data[21], ~crc_data[22], ~crc_data[23]};
                    2'd2: gmii_txd <= {~crc_data[8], ~crc_data[9], ~crc_data[10], ~crc_data[11],
                                      ~crc_data[12], ~crc_data[13], ~crc_data[14], ~crc_data[15]};
                    2'd3: gmii_txd <= {~crc_data[0], ~crc_data[1], ~crc_data[2], ~crc_data[3],
                                      ~crc_data[4], ~crc_data[5], ~crc_data[6], ~crc_data[7]};
                endcase
                
                if (tx_cnt == 16'd3) begin
                    tx_state <= TX_DELAY;
                    tx_cnt   <= 16'd0;
                end
            end
            
            TX_DELAY: begin
                tx_cnt    <= tx_cnt + 1'b1;
                gmii_txen <= 1'b0;
                gmii_txd  <= 8'd0;
                
                if (tx_cnt[3]) begin
                    tx_state <= TX_IDLE;
                end
            end
            
            default: tx_state <= TX_IDLE;
        endcase
    end
end

/////////////////////////////////////////////////////////////////////////////////////////
// GMII转RGMII - 发送路径
/////////////////////////////////////////////////////////////////////////////////////////
reg [7:0] gmii_txd_r;
reg gmii_txen_r;

always @(posedge clk_125m) begin
    gmii_txd_r  <= gmii_txd;
    gmii_txen_r <= gmii_txen;
end

// DDR输出
reg [3:0] txd_h, txd_l;
always @(posedge clk_125m) begin
    txd_h <= gmii_txd_r[7:4];
    txd_l <= gmii_txd_r[3:0];
end

GMII2RGMII gmii2rgmii_inst(
    .clk    (clk_125m   ),
    .din    (gmii_txd_r ),
    .q      (RGMII_TXD  )
);

reg [2:0] txen_pipe;
always @(posedge clk_125m) begin
    txen_pipe <= {txen_pipe[1:0], gmii_txen_r};
end

assign RGMII_TXEN = txen_pipe[2];

endmodule