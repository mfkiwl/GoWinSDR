module data_sender_24bit (
    input sample_clk,                    // 时钟信号
    input rst_n,                  // 复位信号（低电平有效）
    input [23:0] data_in,         // 输入的24位数据
    input request,                // STM32请求信号（高电平有效）
    
    output reg [7:0] data_out,    // 输出数据（PA0-PA7）
    output wire data_clk,          // 数据时钟信号（STM32采样时钟）
    output reg valid              // 数据有效信号（不需要ready）
);

// 128分频时钟生成
reg [6:0] clk_div_cnt;
reg clk_div128;
wire clk;

assign clk = clk_div128;
assign data_clk = clk_div128;

always @(posedge sample_clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_div_cnt <= 0;
        clk_div128 <= 0;
    end else begin
        if (clk_div_cnt == 7'd63) begin
            clk_div_cnt <= 0;
            clk_div128 <= ~clk_div128;
        end else begin
            clk_div_cnt <= clk_div_cnt + 1;
        end
    end
end
localparam IDLE = 2'b00;
    localparam SEND = 2'b01;
    localparam WAIT_RELEASE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [1:0] byte_cnt;           // 字节计数器 0-2
    reg [23:0] data_buffer;
    reg request_last;
    
    // 状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            byte_cnt <= 0;
            data_buffer <= 0;
            data_out <= 0;
            valid <= 0;
            request_last <= 0;
        end else begin
            state <= next_state;
            request_last <= request;
            
            case(state)
                IDLE: begin
                    valid <= 0;
                    byte_cnt <= 0;
                    data_out <= 0;
                    if (request && !request_last) begin
                        // 检测到请求上升沿，锁存数据
                        data_buffer <= data_in;
                    end
                end
                
                SEND: begin
                    // 根据字节计数选择输出的字节
                    case(byte_cnt)
                        2'b00: data_out <= data_buffer[7:0];    // 低8位（Byte0）
                        2'b01: data_out <= data_buffer[15:8];   // 中8位（Byte1）
                        2'b10: data_out <= data_buffer[23:16];  // 高8位（Byte2）
                        default: data_out <= 8'h00;
                    endcase
                    
                    // 每个时钟周期发送一个字节
                    byte_cnt <= byte_cnt + 1;

                    if (byte_cnt > 2'b10) begin
                        valid <= 0;
                    end
                    else begin
                        valid <= 1;
                    end

                end
                
                WAIT_RELEASE: begin
                    valid <= 0;
                    data_out <= 0;
                    // 等待request信号释放
                end
            endcase
        end
    end
    
    // 下一状态逻辑
    always @(*) begin
        case(state)
            IDLE: begin
                // 检测request信号的上升沿
                if (request && !request_last)
                    next_state = SEND;
                else
                    next_state = IDLE;
            end
            
            SEND: begin
                // 3个字节全部发送完成后
                if (byte_cnt == 2'b11)
                    next_state = WAIT_RELEASE;
                else
                    next_state = SEND;
            end
            
            WAIT_RELEASE: begin
                // 等待request信号被释放（回到低电平）
                if (!request)
                    next_state = IDLE;
                else
                    next_state = WAIT_RELEASE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
endmodule