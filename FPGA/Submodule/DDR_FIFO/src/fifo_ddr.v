module DDR3_LARGE_FIFO #(
    parameter WR_DATA_WIDTH = 64,        // 写端口数据宽度(可配置)
    parameter RD_DATA_WIDTH = 64,        // 读端口数据宽度(可配置)
    parameter DDR_DATA_WIDTH = 128,      // DDR3数据宽度(修改为128位)
    parameter DDR_ADDR_WIDTH = 28,       // DDR3地址宽度(修改为28位)
    parameter FIFO_DEPTH = 2**24         // FIFO深度(地址空间,单位:DDR burst)
)(
    // 系统时钟和复位
    input wire sys_clk,                  // 系统时钟 50MHz
    input wire wr_clk,                   // 写时钟域
    input wire rd_clk,                   // 读时钟域
    input wire rst_n,
    
    // 写接口(以太网输入)
    input wire wr_en,
    input wire [WR_DATA_WIDTH-1:0] wr_data,
    output wire wr_full,
    output wire wr_almost_full,          // 几乎满标志
    
    // 读接口(无线发送)
    input wire rd_en,
    output reg [RD_DATA_WIDTH-1:0] rd_data,
    output wire rd_empty,
    output wire rd_almost_empty,         // 几乎空标志
    output reg rd_data_valid,
    
    // DDR3物理接口(修改为新的位宽)
    output [14-1:0] ddr_addr,
    output [3-1:0] ddr_bank,
    output ddr_cs,
    output ddr_ras,
    output ddr_cas,
    output ddr_we,
    output ddr_ck,
    output ddr_ck_n,
    output ddr_cke,
    output ddr_odt,
    output ddr_reset_n,
    output [2-1:0] ddr_dm,               // 修改为2位
    inout  [16-1:0] ddr_dq,              // 修改为16位
    inout  [2-1:0] ddr_dqs,              // 修改为2位
    inout  [2-1:0] ddr_dqs_n,            // 修改为2位
    
    // 状态输出
    output wire [31:0] fifo_count,       // FIFO中的数据量
    output wire [2:0] fifo_state,
    output wire ddr_init_done            // DDR初始化完成标志
);

// =====================================================
// 内部时钟和复位信号
// =====================================================
wire clk100M;
wire memory_clk;
wire pll_lock;
wire pll_stop;
wire ddr_clk;
wire init_calib_complete;
wire ddr_rst;

assign ddr_init_done = init_calib_complete;

// =====================================================
// PLL例化 - 生成DDR所需时钟
// =====================================================
Gowin_PLL u_pll(
    .clkin(sys_clk),
    .clkout0(),
    .clkout1(clk100M),
    .clkout2(memory_clk),
    .lock(pll_lock),
    .mdclk(sys_clk),
    .reset(~rst_n)
);

// =====================================================
// DDR3控制器接口信号
// =====================================================
wire cmd_ready;
wire wr_data_rdy;
wire [2:0] app_cmd;
wire app_en;
wire [DDR_ADDR_WIDTH-1:0] app_addr;
wire [DDR_DATA_WIDTH-1:0] app_wdf_data;
wire app_wdf_wren;
wire app_wdf_end;
wire [DDR_DATA_WIDTH/8-1:0] app_wdf_mask;
wire [DDR_DATA_WIDTH-1:0] app_rd_data;
wire app_rd_data_valid;
wire rd_data_end;
wire app_burst;
wire sr_ack;
wire ref_ack;

// =====================================================
// DDR3控制器例化(使用新的IP核模板)
// =====================================================
DDR3_Memory_Interface_Top u_ddr3 (
    .clk             (clk100M),
    .pll_stop        (pll_stop),
    .memory_clk      (memory_clk),
    .pll_lock        (pll_lock),
    .rst_n           (rst_n),
    .clk_out         (ddr_clk),
    .ddr_rst         (ddr_rst),
    .init_calib_complete(init_calib_complete),
    .cmd_ready       (cmd_ready),
    .cmd             (app_cmd),
    .cmd_en          (app_en),
    .addr            (app_addr),
    .wr_data_rdy     (wr_data_rdy),
    .wr_data         (app_wdf_data),
    .wr_data_en      (app_wdf_wren),
    .wr_data_end     (app_wdf_end),
    .wr_data_mask    (app_wdf_mask),
    .rd_data         (app_rd_data),
    .rd_data_valid   (app_rd_data_valid),
    .rd_data_end     (rd_data_end),
    .sr_req          (1'b0),
    .ref_req         (1'b0),
    .sr_ack          (sr_ack),
    .ref_ack         (ref_ack),
    .burst           (app_burst),
    // DDR物理接口
    .O_ddr_addr      (ddr_addr),
    .O_ddr_ba        (ddr_bank),
    .O_ddr_cs_n      (ddr_cs),
    .O_ddr_ras_n     (ddr_ras),
    .O_ddr_cas_n     (ddr_cas),
    .O_ddr_we_n      (ddr_we),
    .O_ddr_clk       (ddr_ck),
    .O_ddr_clk_n     (ddr_ck_n),
    .O_ddr_cke       (ddr_cke),
    .O_ddr_odt       (ddr_odt),
    .O_ddr_reset_n   (ddr_reset_n),
    .O_ddr_dqm       (ddr_dm),
    .IO_ddr_dq       (ddr_dq),
    .IO_ddr_dqs      (ddr_dqs),
    .IO_ddr_dqs_n    (ddr_dqs_n)
);

assign app_wdf_mask = 0;  // 不屏蔽任何字节
assign app_burst = 0;     // 不使用burst模式

// =====================================================
// 参数定义
// =====================================================
localparam WR_WORDS_PER_DDR = DDR_DATA_WIDTH / WR_DATA_WIDTH;  // 每个DDR数据包含多少个写数据
localparam RD_WORDS_PER_DDR = DDR_DATA_WIDTH / RD_DATA_WIDTH;  // 每个DDR数据包含多少个读数据
localparam ALMOST_FULL_THRESHOLD = FIFO_DEPTH - 256;            // 几乎满阈值
localparam ALMOST_EMPTY_THRESHOLD = 256;                        // 几乎空阈值

// 写缓冲计数器位宽
localparam WR_CNT_WIDTH = (WR_WORDS_PER_DDR == 1) ? 1 : $clog2(WR_WORDS_PER_DDR) + 1;
localparam RD_CNT_WIDTH = (RD_WORDS_PER_DDR == 1) ? 1 : $clog2(RD_WORDS_PER_DDR) + 1;

// 状态机定义
localparam STATE_IDLE         = 3'd0;
localparam STATE_WRITE_BUFFER = 3'd1;
localparam STATE_WRITE_DDR    = 3'd2;
localparam STATE_READ_DDR     = 3'd3;
localparam STATE_READ_BUFFER  = 3'd4;

reg [2:0] state;
assign fifo_state = state;

// =====================================================
// 写缓冲区(写时钟域 -> DDR时钟域)
// =====================================================
reg [DDR_DATA_WIDTH-1:0] wr_buffer;
reg [WR_CNT_WIDTH-1:0] wr_buffer_cnt;
wire wr_buffer_full = (wr_buffer_cnt == WR_WORDS_PER_DDR);

// 跨时钟域同步FIFO - 写请求
wire wr_req_fifo_full;
wire wr_req_fifo_empty;
wire wr_req_fifo_wr;
wire wr_req_fifo_rd;
wire [DDR_DATA_WIDTH-1:0] wr_req_fifo_din;
wire [DDR_DATA_WIDTH-1:0] wr_req_fifo_dout;
wire [8:0] wr_req_fifo_count;

ASYNC_FIFO #(
    .DWIDTH(DDR_DATA_WIDTH),
    .AWIDTH(8),
    .ALMOST_EMPTY_THRESHOLD(4)
) u_wr_req_fifo (
    .wr_clk(wr_clk),
    .rd_clk(ddr_clk),
    .rst_n(rst_n),
    .wr_en(wr_req_fifo_wr),
    .rd_en(wr_req_fifo_rd),
    .wr_data(wr_req_fifo_din),
    .rd_data(wr_req_fifo_dout),
    .full(wr_req_fifo_full),
    .empty(wr_req_fifo_empty),
    .almost_empty(),
    .count(wr_req_fifo_count)
);

// =====================================================
// 读缓冲区(DDR时钟域 -> 读时钟域)
// =====================================================
wire rd_buf_fifo_full;
wire rd_buf_fifo_empty;
wire rd_buf_fifo_almost_empty;
wire rd_buf_fifo_wr;
wire rd_buf_fifo_rd;
wire [DDR_DATA_WIDTH-1:0] rd_buf_fifo_din;
wire [DDR_DATA_WIDTH-1:0] rd_buf_fifo_dout;
wire [8:0] rd_buf_fifo_count;

ASYNC_FIFO #(
    .DWIDTH(DDR_DATA_WIDTH),
    .AWIDTH(8),  // 256深度
    .ALMOST_EMPTY_THRESHOLD(32)  // 当FIFO中数据少于32个时触发almost_empty
) u_rd_buf_fifo (
    .wr_clk(ddr_clk),
    .rd_clk(rd_clk),
    .rst_n(rst_n),
    .wr_en(rd_buf_fifo_wr),
    .rd_en(rd_buf_fifo_rd),
    .wr_data(rd_buf_fifo_din),
    .rd_data(rd_buf_fifo_dout),
    .full(rd_buf_fifo_full),
    .empty(rd_buf_fifo_empty),
    .almost_empty(rd_buf_fifo_almost_empty),
    .count(rd_buf_fifo_count)
);

// 读时钟域的读缓冲
reg [DDR_DATA_WIDTH-1:0] rd_buffer;
reg [RD_CNT_WIDTH-1:0] rd_buffer_cnt;
wire rd_buffer_empty = (rd_buffer_cnt == 0);

// =====================================================
// 地址管理和数据计数(在DDR时钟域)
// =====================================================
reg [DDR_ADDR_WIDTH-1:0] wr_addr;  // 写地址指针
reg [DDR_ADDR_WIDTH-1:0] rd_addr;  // 读地址指针
reg [31:0] data_count;              // 数据计数(DDR时钟域)

// 数据计数同步到写时钟域
reg [31:0] data_count_wr_sync1, data_count_wr_sync2;
always @(posedge wr_clk or negedge rst_n) begin
    if (~rst_n) begin
        data_count_wr_sync1 <= 0;
        data_count_wr_sync2 <= 0;
    end else begin
        data_count_wr_sync1 <= data_count;
        data_count_wr_sync2 <= data_count_wr_sync1;
    end
end

// 数据计数同步到读时钟域
reg [31:0] data_count_rd_sync1, data_count_rd_sync2;
always @(posedge rd_clk or negedge rst_n) begin
    if (~rst_n) begin
        data_count_rd_sync1 <= 0;
        data_count_rd_sync2 <= 0;
    end else begin
        data_count_rd_sync1 <= data_count;
        data_count_rd_sync2 <= data_count_rd_sync1;
    end
end

assign fifo_count = data_count_rd_sync2;

// FIFO满空判断
assign wr_full = (data_count_wr_sync2 >= FIFO_DEPTH - 2) || wr_req_fifo_full;
assign wr_almost_full = (data_count_wr_sync2 >= ALMOST_FULL_THRESHOLD);
assign rd_empty = (data_count_rd_sync2 == 0) && rd_buffer_empty && rd_buf_fifo_empty;
assign rd_almost_empty = (data_count_rd_sync2 <= ALMOST_EMPTY_THRESHOLD);

// =====================================================
// 写数据缓冲(写时钟域)
// =====================================================
integer i;
always @(posedge wr_clk or negedge rst_n) begin
    if (~rst_n) begin
        wr_buffer <= 0;
        wr_buffer_cnt <= 0;
    end else begin
        if (wr_en && !wr_full) begin
            // 动态计算位置并写入数据
            for (i = 0; i < WR_WORDS_PER_DDR; i = i + 1) begin
                if (wr_buffer_cnt == i) begin
                    wr_buffer[i*WR_DATA_WIDTH +: WR_DATA_WIDTH] <= wr_data;
                end
            end
            
            if (wr_buffer_full) begin
                // 缓冲区满,通过异步FIFO发送到DDR时钟域
                wr_buffer_cnt <= 1;  // 当前数据作为下一个buffer的第一个
            end else begin
                wr_buffer_cnt <= wr_buffer_cnt + 1;
            end
        end
    end
end

assign wr_req_fifo_wr = wr_en && !wr_full && wr_buffer_full;
assign wr_req_fifo_din = wr_buffer;

// =====================================================
// 读数据缓冲(读时钟域) - 修复版
// =====================================================
integer j;
always @(posedge rd_clk or negedge rst_n) begin
    if (~rst_n) begin
        rd_buffer <= 0;
        rd_buffer_cnt <= 0;
        rd_data <= 0;
        rd_data_valid <= 0;
    end else begin
        rd_data_valid <= 0;
        
        // 提前预装载：当计数为1且有读使能时，提前装载下一个数据块
        if (rd_buffer_cnt == 1 && rd_en && !rd_empty && !rd_buf_fifo_empty) begin
            rd_buffer <= rd_buf_fifo_dout;
            rd_buffer_cnt <= RD_WORDS_PER_DDR;
        end
        // 原有的补充逻辑：当缓冲完全为空时装载
        else if (rd_buffer_empty && !rd_buf_fifo_empty) begin
            rd_buffer <= rd_buf_fifo_dout;
            rd_buffer_cnt <= RD_WORDS_PER_DDR;
        end
        
        if (rd_en && !rd_empty) begin
            if (rd_buffer_cnt > 0) begin
                // 从缓冲区读取，动态计算读取位置
                for (j = 0; j < RD_WORDS_PER_DDR; j = j + 1) begin
                    if (rd_buffer_cnt == RD_WORDS_PER_DDR - j) begin
                        rd_data <= rd_buffer[j*RD_DATA_WIDTH +: RD_DATA_WIDTH];
                    end
                end
                
                // 如果刚才已经预装载，则不再递减
                if (!(rd_buffer_cnt == 1 && !rd_buf_fifo_empty)) begin
                    rd_buffer_cnt <= rd_buffer_cnt - 1;
                end
                
                rd_data_valid <= 1;
            end
        end
    end
end

assign rd_buf_fifo_rd = (rd_buffer_empty && !rd_buf_fifo_empty) || 
                        (rd_buffer_cnt == 1 && rd_en && !rd_empty && !rd_buf_fifo_empty);


// =====================================================
// DDR控制状态机(DDR时钟域)
// =====================================================
reg [7:0] wait_cnt;
reg [DDR_DATA_WIDTH-1:0] ddr_wr_data;

reg [2:0] app_cmd_reg;
reg app_en_reg;
reg [DDR_ADDR_WIDTH-1:0] app_addr_reg;
reg [DDR_DATA_WIDTH-1:0] app_wdf_data_reg;
reg app_wdf_wren_reg;
reg app_wdf_end_reg;

assign app_cmd = app_cmd_reg;
assign app_en = app_en_reg;
assign app_addr = app_addr_reg;
assign app_wdf_data = app_wdf_data_reg;
assign app_wdf_wren = app_wdf_wren_reg;
assign app_wdf_end = app_wdf_end_reg;

// 将rd_buf_fifo_almost_empty同步到DDR时钟域
reg rd_buf_almost_empty_sync1, rd_buf_almost_empty_sync2;
always @(posedge ddr_clk or negedge rst_n) begin
    if (~rst_n) begin
        rd_buf_almost_empty_sync1 <= 0;
        rd_buf_almost_empty_sync2 <= 0;
    end else begin
        rd_buf_almost_empty_sync1 <= rd_buf_fifo_almost_empty;
        rd_buf_almost_empty_sync2 <= rd_buf_almost_empty_sync1;
    end
end

assign wr_req_fifo_rd = (state == STATE_WRITE_DDR) && cmd_ready && wr_data_rdy && !wr_req_fifo_empty;
assign rd_buf_fifo_wr = (state == STATE_READ_BUFFER) && app_rd_data_valid;
assign rd_buf_fifo_din = app_rd_data;

localparam RD_BURST_CNT = 4;  // 每次空闲时连续读取4个burst
reg [2:0] rd_burst_remain;    // 剩余连续读取次数

always @(posedge ddr_clk or negedge rst_n) begin
    if (~rst_n) begin
        state <= STATE_IDLE;
        app_cmd_reg <= 0;
        app_en_reg <= 0;
        app_addr_reg <= 0;
        app_wdf_data_reg <= 0;
        app_wdf_wren_reg <= 0;
        app_wdf_end_reg <= 0;
        wr_addr <= 0;
        rd_addr <= 0;
        data_count <= 0;
        wait_cnt <= 0;
        ddr_wr_data <= 0;
        rd_burst_remain <= 0;
    end else begin
        case (state)
            STATE_IDLE: begin
                app_en_reg <= 0;
                app_wdf_wren_reg <= 0;
                app_wdf_end_reg <= 0;
                
                if (init_calib_complete) begin
                    // 优先处理写操作
                    if (!wr_req_fifo_empty && data_count < FIFO_DEPTH) begin
                        state <= STATE_WRITE_DDR;
                        ddr_wr_data <= wr_req_fifo_dout;
                        wait_cnt <= 0;
                        rd_burst_remain <= 0;  // 重置连续读计数
                    end
                    // 按需读取策略：当读缓冲快要空时从DDR读取
                    else if (rd_buf_almost_empty_sync2 && !rd_buf_fifo_full && data_count > 0) begin
                        state <= STATE_READ_DDR;
                        wait_cnt <= 0;
                        // 设置连续读取次数
                        if (rd_burst_remain == 0) begin
                            rd_burst_remain <= RD_BURST_CNT;
                        end
                    end
                end
            end
            
            STATE_WRITE_DDR: begin
                if (cmd_ready && wr_data_rdy) begin
                    app_cmd_reg <= 3'd0;
                    app_en_reg <= 1;
                    app_addr_reg <= wr_addr;
                    app_wdf_data_reg <= ddr_wr_data;
                    app_wdf_wren_reg <= 1;
                    app_wdf_end_reg <= 1;
                    
                    if (wr_addr >= FIFO_DEPTH * 8 - 8) begin
                        wr_addr <= 0;
                    end else begin
                        wr_addr <= wr_addr + 8;
                    end
                    
                    data_count <= data_count + 1;
                    state <= STATE_IDLE;
                end else begin
                    app_en_reg <= 0;
                    app_wdf_wren_reg <= 0;
                    app_wdf_end_reg <= 0;
                    
                    if (wait_cnt >= 255) begin
                        state <= STATE_IDLE;
                    end else begin
                        wait_cnt <= wait_cnt + 1;
                    end
                end
            end
            
            STATE_READ_DDR: begin
                if (cmd_ready) begin
                    app_cmd_reg <= 3'd1;
                    app_en_reg <= 1;
                    app_addr_reg <= rd_addr;
                    
                    if (rd_addr >= FIFO_DEPTH * 8 - 8) begin
                        rd_addr <= 0;
                    end else begin
                        rd_addr <= rd_addr + 8;
                    end
                    
                    state <= STATE_READ_BUFFER;
                    wait_cnt <= 0;
                end else begin
                    app_en_reg <= 0;
                    
                    if (wait_cnt >= 255) begin
                        state <= STATE_IDLE;
                        rd_burst_remain <= 0;
                    end else begin
                        wait_cnt <= wait_cnt + 1;
                    end
                end
            end
            
            STATE_READ_BUFFER: begin
                app_en_reg <= 0;
                
                if (app_rd_data_valid) begin
                    data_count <= data_count - 1;
                    
                    // 检查是否继续连续读取
                    if (rd_burst_remain > 1 && !rd_buf_fifo_full && data_count > 1) begin
                        rd_burst_remain <= rd_burst_remain - 1;
                        state <= STATE_READ_DDR;  // 直接进入下一次读取
                        wait_cnt <= 0;
                    end else begin
                        rd_burst_remain <= 0;
                        state <= STATE_IDLE;
                    end
                end else begin
                    if (wait_cnt >= 255) begin
                        state <= STATE_IDLE;
                        rd_burst_remain <= 0;
                    end else begin
                        wait_cnt <= wait_cnt + 1;
                    end
                end
            end
            
            default: begin
                state <= STATE_IDLE;
                rd_burst_remain <= 0;
            end
        endcase
    end
end

endmodule

// =====================================================
// 异步FIFO模块(用于跨时钟域)
// =====================================================
module ASYNC_FIFO #(
    parameter DWIDTH = 8,
    parameter AWIDTH = 4,
    parameter ALMOST_EMPTY_THRESHOLD = 4
)(
    input wire wr_clk,
    input wire rd_clk,
    input wire rst_n,
    input wire wr_en,
    input wire rd_en,
    input wire [DWIDTH-1:0] wr_data,
    output wire [DWIDTH-1:0] rd_data,
    output wire full,
    output wire empty,
    output wire almost_empty,
    output wire [AWIDTH:0] count
);

reg [DWIDTH-1:0] mem [0:2**AWIDTH-1];
reg [AWIDTH:0] wr_ptr, wr_ptr_gray, wr_ptr_gray_sync1, wr_ptr_gray_sync2;
reg [AWIDTH:0] rd_ptr, rd_ptr_gray, rd_ptr_gray_sync1, rd_ptr_gray_sync2;


function [AWIDTH:0] bin2gray;
    input [AWIDTH:0] bin;
    begin
        bin2gray = bin ^ (bin >> 1);
    end
endfunction

function [AWIDTH:0] gray2bin;
    input [AWIDTH:0] gray;
    integer i;
    begin
        gray2bin[AWIDTH] = gray[AWIDTH];
        for (i = AWIDTH-1; i >= 0; i = i - 1) begin
            gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    end
endfunction

always @(posedge wr_clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr <= 0;
        wr_ptr_gray <= 0;
    end else if (wr_en && !full) begin
        mem[wr_ptr[AWIDTH-1:0]] <= wr_data;
        wr_ptr <= wr_ptr + 1;
        wr_ptr_gray <= bin2gray(wr_ptr + 1);
    end
end

always @(posedge rd_clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_ptr <= 0;
        rd_ptr_gray <= 0;
    end else if (rd_en && !empty) begin
        rd_ptr <= rd_ptr + 1;
        rd_ptr_gray <= bin2gray(rd_ptr + 1);
    end
end


always @(posedge rd_clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr_gray_sync1 <= 0;
        wr_ptr_gray_sync2 <= 0;
    end else begin
        wr_ptr_gray_sync1 <= wr_ptr_gray;
        wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end
end

// Synchronize read pointer to write domain
always @(posedge wr_clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_ptr_gray_sync1 <= 0;
        rd_ptr_gray_sync2 <= 0;
    end else begin
        rd_ptr_gray_sync1 <= rd_ptr_gray;
        rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
end

assign rd_data = mem[rd_ptr[AWIDTH-1:0]];
assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);
assign full = (wr_ptr_gray == {~rd_ptr_gray_sync2[AWIDTH:AWIDTH-1], rd_ptr_gray_sync2[AWIDTH-2:0]});


wire [AWIDTH:0] wr_ptr_bin_sync;
wire [AWIDTH:0] rd_ptr_bin;

assign wr_ptr_bin_sync = gray2bin(wr_ptr_gray_sync2);
assign rd_ptr_bin = rd_ptr;  

wire [AWIDTH:0] fifo_count;
assign fifo_count = wr_ptr_bin_sync - rd_ptr_bin;

assign count = fifo_count;
assign almost_empty = (fifo_count <= ALMOST_EMPTY_THRESHOLD);

endmodule