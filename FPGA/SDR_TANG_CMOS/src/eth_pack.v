module rf_data_depacketizer #(
    parameter FRAME_HEAD = 16'hEB90,  // 帧头标识（需与封包模块一致）
    parameter FRAME_TAIL = 16'h55AA,  // 帧尾标识
    parameter TIMEOUT_CNT = 32'd125000  // 超时计数器，假设125MHz时钟，1ms超时
)(
    // 射频解调时钟域
    input  wire        rf_rx_clk,
    input  wire        rf_rx_rst_n,
    input  wire [7:0]  rf_rx_data,
    input  wire        rf_rx_valid,
    
    // 以太网发送时钟域
    input  wire        eth_tx_clk,
    input  wire        eth_tx_rst_n,
    output reg  [7:0]  tx_data,
    output reg         tx_data_valid,
    output reg         tx_frame_start,
    input  wire        tx_ready,
    
    // 状态指示
    output reg         frame_error,      // 帧错误指示
    output reg [15:0]  frame_length      // 当前帧长度
);

    // ========================================
    // 1. 射频接收侧：帧识别和数据提取
    // ========================================
    localparam SEARCH_HEAD  = 3'd0;
    localparam CHECK_HEAD   = 3'd1;
    localparam RECEIVE_DATA = 3'd2;
    localparam CHECK_TAIL1  = 3'd3;
    localparam CHECK_TAIL2  = 3'd4;
    localparam FRAME_ERROR  = 3'd5;
    
    reg [2:0]  rx_state;
    reg [7:0]  head_byte1;
    reg [15:0] data_cnt;
    reg [31:0] timeout_cnt;
    
    reg [7:0]  fifo_wr_data;
    reg        fifo_wr_en;
    reg        frame_valid;
    reg        frame_complete;
    
    // 帧识别状态机
    always @(posedge rf_rx_clk or negedge rf_rx_rst_n) begin
        if (!rf_rx_rst_n) begin
            rx_state <= SEARCH_HEAD;
            head_byte1 <= 8'd0;
            data_cnt <= 16'd0;
            timeout_cnt <= 32'd0;
            fifo_wr_data <= 8'd0;
            fifo_wr_en <= 1'b0;
            frame_valid <= 1'b0;
            frame_complete <= 1'b0;
            frame_error <= 1'b0;
            frame_length <= 16'd0;
        end else begin
            // 默认值
            fifo_wr_en <= 1'b0;
            frame_complete <= 1'b0;
            
            case (rx_state)
                SEARCH_HEAD: begin
                    frame_valid <= 1'b0;
                    frame_error <= 1'b0;
                    data_cnt <= 16'd0;
                    timeout_cnt <= 32'd0;
                    
                    if (rf_rx_valid && rf_rx_data == FRAME_HEAD[15:8]) begin
                        head_byte1 <= rf_rx_data;
                        rx_state <= CHECK_HEAD;
                    end
                end
                
                CHECK_HEAD: begin
                    if (rf_rx_valid) begin
                        if (rf_rx_data == FRAME_HEAD[7:0]) begin
                            // 帧头匹配成功
                            frame_valid <= 1'b1;
                            rx_state <= RECEIVE_DATA;
                            timeout_cnt <= 32'd0;
                        end else begin
                            // 帧头匹配失败，继续搜索
                            rx_state <= SEARCH_HEAD;
                        end
                    end else begin
                        timeout_cnt <= timeout_cnt + 1'b1;
                        if (timeout_cnt >= TIMEOUT_CNT) begin
                            rx_state <= SEARCH_HEAD;
                        end
                    end
                end
                
                RECEIVE_DATA: begin
                    timeout_cnt <= timeout_cnt + 1'b1;
                    
                    if (rf_rx_valid) begin
                        timeout_cnt <= 32'd0;
                        
                        // 检查是否为帧尾第一字节
                        if (rf_rx_data == FRAME_TAIL[15:8]) begin
                            rx_state <= CHECK_TAIL1;
                        end else begin
                            // 写入数据到FIFO
                            fifo_wr_data <= rf_rx_data;
                            fifo_wr_en <= 1'b1;
                            data_cnt <= data_cnt + 1'b1;
                        end
                    end else if (timeout_cnt >= TIMEOUT_CNT) begin
                        // 超时，帧错误
                        frame_error <= 1'b1;
                        rx_state <= FRAME_ERROR;
                    end
                end
                
                CHECK_TAIL1: begin
                    if (rf_rx_valid) begin
                        if (rf_rx_data == FRAME_TAIL[7:0]) begin
                            // 帧尾匹配成功，帧完整
                            rx_state <= CHECK_TAIL2;
                            frame_length <= data_cnt;
                            frame_complete <= 1'b1;
                        end else begin
                            // 不是帧尾，可能是数据
                            fifo_wr_data <= FRAME_TAIL[15:8];
                            fifo_wr_en <= 1'b1;
                            data_cnt <= data_cnt + 1'b1;
                            
                            // 检查当前字节是否又是帧尾开始
                            if (rf_rx_data == FRAME_TAIL[15:8]) begin
                                rx_state <= CHECK_TAIL1;
                            end else begin
                                fifo_wr_data <= rf_rx_data;
                                fifo_wr_en <= 1'b1;
                                data_cnt <= data_cnt + 2'd2;
                                rx_state <= RECEIVE_DATA;
                            end
                        end
                    end else begin
                        timeout_cnt <= timeout_cnt + 1'b1;
                        if (timeout_cnt >= TIMEOUT_CNT) begin
                            frame_error <= 1'b1;
                            rx_state <= FRAME_ERROR;
                        end
                    end
                end
                
                CHECK_TAIL2: begin
                    // 帧完成，回到搜索状态
                    rx_state <= SEARCH_HEAD;
                end
                
                FRAME_ERROR: begin
                    // 帧错误，丢弃当前帧，重新搜索
                    frame_error <= 1'b1;
                    rx_state <= SEARCH_HEAD;
                end
                
                default: begin
                    rx_state <= SEARCH_HEAD;
                end
            endcase
        end
    end

    // ========================================
    // 2. 异步FIFO例化（跨时钟域）
    // ========================================
    wire [7:0] fifo_rd_data;
    wire       fifo_empty;
    wire       fifo_full;
    reg        fifo_rd_en;
    wire       fifo_prog_full;  // 可编程满信号
    
    // 注意：需要确保FIFO深度足够大，避免溢出
    fifo_eth_tx fifo_eth_tx_u0 (
        .Data(fifo_wr_data),        // input [7:0]
        .WrClk(rf_rx_clk),          // input
        .RdClk(eth_tx_clk),         // input
        .WrEn(fifo_wr_en & frame_valid),  // input，只有在有效帧时才写入
        .RdEn(fifo_rd_en),          // input
        .Q(fifo_rd_data),           // output [7:0]
        .Empty(fifo_empty),         // output
        .Full(fifo_full)            // output
    );

    // ========================================
    // 3. 以太网发送侧：FIFO读取和数据发送
    // ========================================
    localparam TX_IDLE        = 3'd0;
    localparam TX_FRAME_START = 3'd1;
    localparam TX_SEND_DATA   = 3'd2;
    localparam TX_WAIT_READY  = 3'd3;
    localparam TX_FRAME_END   = 3'd4;
    
    reg [2:0]  tx_state;
    reg [15:0] tx_byte_cnt;
    reg        frame_complete_d1, frame_complete_d2;  // 跨时钟域同步
    reg [15:0] frame_length_sync;
    
    // frame_complete信号跨时钟域同步（简化处理，实际应使用握手）
    always @(posedge eth_tx_clk or negedge eth_tx_rst_n) begin
        if (!eth_tx_rst_n) begin
            frame_complete_d1 <= 1'b0;
            frame_complete_d2 <= 1'b0;
        end else begin
            frame_complete_d1 <= frame_complete;
            frame_complete_d2 <= frame_complete_d1;
        end
    end
    
    wire frame_ready = frame_complete_d2;
    
    // 以太网发送状态机
    always @(posedge eth_tx_clk or negedge eth_tx_rst_n) begin
        if (!eth_tx_rst_n) begin
            tx_state <= TX_IDLE;
            tx_data <= 8'd0;
            tx_data_valid <= 1'b0;
            tx_frame_start <= 1'b0;
            fifo_rd_en <= 1'b0;
            tx_byte_cnt <= 16'd0;
            frame_length_sync <= 16'd0;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    tx_data_valid <= 1'b0;
                    tx_frame_start <= 1'b0;
                    fifo_rd_en <= 1'b0;
                    tx_byte_cnt <= 16'd0;
                    
                    // 等待完整帧到达且FIFO非空
                    if (frame_ready && !fifo_empty) begin
                        frame_length_sync <= frame_length;
                        tx_state <= TX_FRAME_START;
                    end
                end
                
                TX_FRAME_START: begin
                    tx_frame_start <= 1'b1;
                    tx_state <= TX_WAIT_READY;
                end
                
                TX_WAIT_READY: begin
                    tx_frame_start <= 1'b0;
                    if (tx_ready && !fifo_empty) begin
                        fifo_rd_en <= 1'b1;
                        tx_state <= TX_SEND_DATA;
                    end
                end
                
                TX_SEND_DATA: begin
                    if (fifo_rd_en) begin
                        // 上一周期发出读使能，本周期数据有效
                        fifo_rd_en <= 1'b0;
                        tx_data <= fifo_rd_data;
                        tx_data_valid <= 1'b1;
                        tx_byte_cnt <= tx_byte_cnt + 1'b1;
                        
                        // 判断是否发送完成
                        if (tx_byte_cnt >= frame_length_sync - 1'b1) begin
                            tx_state <= TX_FRAME_END;
                        end else if (!fifo_empty && tx_ready) begin
                            fifo_rd_en <= 1'b1;  // 继续读取
                        end
                    end else begin
                        tx_data_valid <= 1'b0;
                        if (!fifo_empty && tx_ready) begin
                            fifo_rd_en <= 1'b1;
                        end
                    end
                end
                
                TX_FRAME_END: begin
                    tx_data_valid <= 1'b0;
                    tx_state <= TX_IDLE;
                end
                
                default: begin
                    tx_state <= TX_IDLE;
                end
            endcase
        end
    end

endmodule