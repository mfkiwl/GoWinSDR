module rf_data_depacketizer #(
    parameter FRAME_HEAD = 16'hEB90,  // 帧头标识（需与封包模块一致）
    parameter FRAME_TAIL = 16'h55AA,  // 帧尾标识
    parameter TIMEOUT_CNT = 32'd125000  // 超时计数器，假设125MHz时钟，1ms超时
)(
    // 射频解调时钟域
    input  wire        rf_rx_clk,
    input  wire        rf_rx_rst_n,
    input  wire        rf_rx_data,      // 串行比特流输入
    input  wire        rf_rx_valid,     // 比特流有效信号
    
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

localparam FIND_HEAD = 3'd0;
localparam PAYLOAD   = 3'd1;

    reg [2:0] pack_state;
    reg [31:0] bit_shift_reg;   
    reg [7:0]  byte_count;
    reg [31:0] timeout_counter;
    
    always @(posedge rf_rx_clk or negedge rf_rx_rst_n) begin
        if (!rf_rx_rst_n) begin
            bit_shift_reg <= 32'd0;
            pack_state <= FIND_HEAD;
            fifo_ren <= 1'b0;
            fifo_wen <= 1'b0;
            timeout_counter <= 32'd0;
            byte_count <= 8'd0;
        end else begin
            case (pack_state)
                FIND_HEAD: begin
                    fifo_wen <= 1'b0;
                    fifo_wr_data <= 8'd0;
                    if (rf_rx_valid) begin
                        bit_shift_reg <= {bit_shift_reg[30:0], rf_rx_data};
                        if (bit_shift_reg[31:16] == FRAME_HEAD) begin
                            pack_state <= PAYLOAD;
                        end
                    end
                end

                PAYLOAD: begin
                    timeout_counter <= timeout_counter + 1'b1;
                    if (rf_rx_valid) begin
                        bit_shift_reg <= {bit_shift_reg[30:0], rf_rx_data};
                        if (byte_count != 8'd7) begin
                            byte_count <= byte_count + 1'b1;
                            fifo_wen <= 1'b0;
                            fifo_wr_data <= fifo_wr_data;
                        end
                        else begin
                            byte_count <= 8'd0;
                            if (bit_shift_reg[15:0] == FRAME_TAIL) begin
                            pack_state <= FIND_HEAD;
                            end
                            else begin
                                fifo_wen <= 1'b1;
                                fifo_wr_data <= bit_shift_reg[23:16];
                            end
                        end
                       
                    end

                    if (timeout_counter == TIMEOUT_CNT) begin
                        pack_state <= FIND_HEAD;
                        frame_error <= 1'b1;
                        timeout_counter <= 32'd0;
                        byte_count <= 8'd0;
                    end
                end
            endcase
            
        end
    end

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

   

endmodule