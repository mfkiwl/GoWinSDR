module rf_data_depacketizer #(
    parameter FRAME_HEAD = 32'hEB90CAD3,  // 帧头标识
    parameter FRAME_TAIL = 16'h55AA,  // 帧尾标识
    parameter TIMEOUT_CNT = 32'd32768  // 超时计数器
)(
    // 射频解调时钟域
    input  wire        rf_rx_clk,
    input  wire        rf_rx_rst_n,
    input  wire        rf_rx_data,      
    input  wire        rf_rx_valid,    
    
    // 以太网发送时钟域
    input  wire        eth_tx_clk,
    input  wire        eth_tx_rst_n,
    output reg  [7:0]  tx_data,
    output reg         tx_data_valid,
    output reg         tx_frame_start,
    input  wire        tx_ready,
    

    output reg         frame_error,      // 帧错误指示
    output reg [15:0]  frame_length     
);


    localparam FIND_HEAD = 3'd0;
    localparam PAYLOAD   = 3'd1;
    localparam WAIT_SEND = 3'd2;

    reg [2:0]  pack_state;
    reg [47:0] bit_shift_reg;   
    reg [7:0]  byte_count;
    reg [31:0] timeout_counter;
    reg [15:0] payload_byte_cnt;  
    reg        frame_done;        
    reg find_head_flag;

    wire  [31:0] head_window;
    assign head_window = bit_shift_reg[47:16];
    
    always @(posedge rf_rx_clk or negedge rf_rx_rst_n) begin
        if (!rf_rx_rst_n) begin
            bit_shift_reg <= 48'd0;
            pack_state <= FIND_HEAD;
            fifo_wen <= 1'b0;
            fifo_wr_data <= 8'd0;
            timeout_counter <= 32'd0;
            byte_count <= 8'd0;
            payload_byte_cnt <= 16'd0;
            frame_done <= 1'b0;
            frame_error <= 1'b0;
            frame_length <= 16'd0;
            find_head_flag <= 1'b0;
        end else begin
            frame_done <= 1'b0;  // 默认清除
            
            case (pack_state)
                FIND_HEAD: begin
                    fifo_wen <= 1'b0;
                    fifo_wr_data <= 8'd0;
                    payload_byte_cnt <= 16'd0;
                    frame_error <= 1'b0;    
                    timeout_counter <= 32'd0;
                    byte_count <= 8'd0;
                    frame_length <= 16'd0;
                    find_head_flag <= 1'b1;
                    if (rf_rx_valid) begin
                        bit_shift_reg <= {bit_shift_reg[46:0], rf_rx_data};
                        if (head_window == FRAME_HEAD) begin
                            pack_state <= PAYLOAD;
                        end
                    end
                end

                PAYLOAD: begin
                    timeout_counter <= timeout_counter + 1'b1;
                    find_head_flag <= 1'b0;
                    if (rf_rx_valid) begin
                        bit_shift_reg <= {bit_shift_reg[46:0], rf_rx_data};
                        
                        if (byte_count != 8'd7) begin
                            byte_count <= byte_count + 1'b1;
                            fifo_wen <= 1'b0;
                        end else begin
                            
                            if (bit_shift_reg[23:8] == FRAME_TAIL) begin
                                pack_state <= FIND_HEAD;
                                frame_length <= payload_byte_cnt;
                                frame_done <= 1'b1;
                                fifo_wen <= 1'b0;
                            end
                            else begin
                                byte_count <= 8'd0;
                                fifo_wen <= 1'b1;
                                fifo_wr_data <= bit_shift_reg[23:16];
                                payload_byte_cnt <= payload_byte_cnt + 1'b1;
                            end
                        end
                    end else begin
                        fifo_wen <= 1'b0;
                    end

                    // 超时处理
                    if (timeout_counter >= TIMEOUT_CNT) begin
                        pack_state <= FIND_HEAD;
                        frame_error <= 1'b1;
                        timeout_counter <= 32'd0;
                        byte_count <= 8'd0;
                        fifo_wen <= 1'b0;
                    end
                end

                WAIT_SEND: begin
                    if (eth_state == ETH_FRAME_END) begin
                        pack_state <= FIND_HEAD;
                    end
                end
                
                default: begin
                    pack_state <= FIND_HEAD;
                end
            endcase
        end
    end

    // ========================================
    // FIFO实例化
    // ========================================
    reg [7:0]  fifo_wr_data;
    wire [7:0] fifo_rd_data;
    wire       fifo_empty;
    wire       fifo_full;
    reg        fifo_wen;
    reg        fifo_ren;

    fifo_eth_tx fifo_eth_tx_u0 (
        .Data(fifo_wr_data),        
        .WrClk(rf_rx_clk),          
        .RdClk(eth_tx_clk),         
        .WrEn(fifo_wen),
        .RdEn(fifo_ren),          
        .Q(fifo_rd_data),           
        .Empty(fifo_empty),         
        .Full(fifo_full)            
    );

    // ========================================
    // 以太网发送侧 - 跨时钟域同步
    // ========================================
    reg frame_done_d1, frame_done_d2, frame_done_d3;
    
    // frame_done信号同步到以太网时钟域（三级触发器）
    always @(posedge eth_tx_clk or negedge eth_tx_rst_n) begin
        if (!eth_tx_rst_n) begin
            frame_done_d1 <= 1'b0;
            frame_done_d2 <= 1'b0;
            frame_done_d3 <= 1'b0;
        end else begin
            frame_done_d1 <= frame_done;
            frame_done_d2 <= frame_done_d1;
            frame_done_d3 <= frame_done_d2;
        end
    end
    
    // 检测frame_done上升沿（脉冲）
    wire frame_ready_pulse = frame_done_d2 & ~frame_done_d3;
    
    // ========================================
    // 以太网发送状态机
    // ========================================
localparam ETH_IDLE       = 3'd0;
localparam ETH_START      = 3'd1;
localparam ETH_WAIT_READY = 3'd2;
localparam ETH_SEND_DATA  = 3'd3;
localparam ETH_FRAME_END  = 3'd4;

reg [2:0]  eth_state;
reg        has_frame;  // 标记有完整帧待发送

always @(posedge eth_tx_clk or negedge eth_tx_rst_n) begin
    if (!eth_tx_rst_n) begin
        eth_state <= ETH_IDLE;
        tx_data <= 8'd0;
        tx_data_valid <= 1'b0;
        tx_frame_start <= 1'b0;
        fifo_ren <= 1'b0;
        has_frame <= 1'b0;
    end else begin
        // 检测到新帧完成
        if (frame_ready_pulse) begin
            has_frame <= 1'b1;
        end
        
        case (eth_state)
            ETH_IDLE: begin
                tx_data_valid <= 1'b0;
                tx_frame_start <= 1'b0;
                
                // 有完整帧且FIFO非空时开始发送
                if (has_frame && !fifo_empty) begin
                    has_frame <= 1'b0;  // 清除标志
                    eth_state <= ETH_START;
                end

                if (find_head_flag) begin
                    fifo_ren <= 1'b1;
                end
                else begin
                    fifo_ren <= 1'b0;
                end
            end
            
            ETH_START: begin
                // 发送帧起始信号
                tx_frame_start <= 1'b1;
                fifo_ren <= 1'b1;
                eth_state <= ETH_WAIT_READY;
            end
            
            ETH_WAIT_READY: begin
                tx_frame_start <= 1'b0;
                
                // 等待以太网MAC准备好
                if (tx_ready) begin
                    if (!fifo_empty) begin
                        fifo_ren <= 1'b1;  // 开始读FIFO
                        eth_state <= ETH_SEND_DATA;
                    end else begin
                        // FIFO已空，结束发送
                        eth_state <= ETH_FRAME_END;
                    end
                end
            end
            
            ETH_SEND_DATA: begin
                // FIFO有一拍延迟，此时fifo_rd_data已经是有效数据
                tx_data <= fifo_rd_data;
                tx_data_valid <= 1'b1;
                
                // 继续判断是否还有数据
                if (!fifo_empty) begin
                    fifo_ren <= 1'b1;  // 继续读取下一个字节
                    // 保持在SEND_DATA状态
                end else begin
                    fifo_ren <= 1'b0;  // 停止读取
                    eth_state <= ETH_FRAME_END;
                end
            end
            
            ETH_FRAME_END: begin
                tx_data_valid <= 1'b0;
                tx_data <= 8'd0;
                fifo_ren <= 1'b0;
                eth_state <= ETH_IDLE;
            end
            
            default: begin
                eth_state <= ETH_IDLE;
            end
        endcase
    end
end

endmodule
