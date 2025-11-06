`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/06 11:13:51
// Design Name: 
// Module Name: ser_parral_trans
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ser_parral_trans #(
    parameter SERIAL_WIDTH = 8,
    parameter PARRAL_WIDTH = 72
) (
    input                         clk,
    input                         rst_n,

    output reg [PARRAL_WIDTH-1:0] o_data_parral,
    output                        o_valid_parral_data,

    input                         i_valid_serial_data,
    input  [SERIAL_WIDTH-1:0]     i_data_serial
);

// 参数检查
initial begin
    if (PARRAL_WIDTH % SERIAL_WIDTH != 0) begin
        $error("PARRAL_WIDTH must be divisible by SERIAL_WIDTH!");
    end
end

localparam NUM_CHUNKS = PARRAL_WIDTH / SERIAL_WIDTH;
localparam CNT_WIDTH  = $clog2(NUM_CHUNKS);

reg [PARRAL_WIDTH-1:0] shift_reg;
reg [CNT_WIDTH-1:0]    cnt;
reg valid_sr;

// 输出 valid
assign o_valid_parral_data = valid_sr;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= {PARRAL_WIDTH{1'b0}};
        cnt       <= {CNT_WIDTH{1'b0}};
        o_data_parral <= {PARRAL_WIDTH{1'b0}};
        valid_sr  <= 1'b0;
    end else begin
        // Default: valid拉低
        valid_sr <= 1'b0;

        if (i_valid_serial_data) begin
            // 将新串行数据放入高位，其他数据右移
            shift_reg <= {i_data_serial, shift_reg[PARRAL_WIDTH - 1 : SERIAL_WIDTH]};

            if (cnt == NUM_CHUNKS - 1) begin
                // 这是最后一个数据块
                o_data_parral <= {i_data_serial, shift_reg[PARRAL_WIDTH - 1 : SERIAL_WIDTH]};
                valid_sr <= 1'b1;
                cnt <= {CNT_WIDTH{1'b0}}; // 回绕到0，准备下一组
                $display("[S2P] Output complete at %0t: 0x%0h", $time, {i_data_serial, shift_reg[PARRAL_WIDTH - 1 : SERIAL_WIDTH]});
            end else begin
                // 继续积累
                cnt <= cnt + 1;
                $display("[S2P] Accumulating byte %0d/8 at %0t: data=0x%03h", cnt, $time, i_data_serial);
            end
        end else begin
            // 无有效输入时，计数器不变
            if (cnt > 0) begin
                $display("[S2P] No input but cnt=%0d (waiting for more data)", cnt);
            end
        end
    end
end

endmodule
