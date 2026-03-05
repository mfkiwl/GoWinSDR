// =====================================================
// DDR FIFO 测试顶层模块
// 集成DDR3_LARGE_FIFO和测试模块
// =====================================================
module top_test (
    // 系统时钟和复位
    input wire sys_clk,              // 50MHz系统时钟
    input wire rst_n,                // 复位信号(低有效)
    
    // DDR3物理接口
    output [13:0] ddr_addr,
    output [2:0] ddr_bank,
    output ddr_cs,
    output ddr_ras,
    output ddr_cas,
    output ddr_we,
    output ddr_ck,
    output ddr_ck_n,
    output ddr_cke,
    output ddr_odt,
    output ddr_reset_n,
    output [1:0] ddr_dm,
    inout  [15:0] ddr_dq,
    inout  [1:0] ddr_dqs,
    inout  [1:0] ddr_dqs_n
);

// LED状态指示
wire led_init_done;       // DDR初始化完成
wire led_test_running;    // 测试运行中
wire led_test_pass;       // 测试通过
wire led_test_fail;        // 测试失败

// =====================================================
// 参数配置
// =====================================================
localparam WR_DATA_WIDTH = 64;
localparam RD_DATA_WIDTH = 64;
localparam TEST_DATA_COUNT = 2048;  // 测试2048个数据

// =====================================================
// 时钟生成 - 这里使用简单的时钟分频示例
// 实际应用中可能需要PLL生成不同频率
// =====================================================
reg [7:0] clk_div_wr;
reg [7:0] clk_div_rd;
reg wr_clk_reg;
reg rd_clk_reg;

// 写时钟生成 (例: 25MHz)
always @(posedge sys_clk or negedge rst_n) begin
    if (~rst_n) begin
        clk_div_wr <= 0;
        wr_clk_reg <= 0;
    end else begin
        if (clk_div_wr >= 1) begin  // 分频为sys_clk/2
            clk_div_wr <= 0;
            wr_clk_reg <= ~wr_clk_reg;
        end else begin
            clk_div_wr <= clk_div_wr + 1;
        end
    end
end

// 读时钟生成 (例: 16.7MHz)
always @(posedge sys_clk or negedge rst_n) begin
    if (~rst_n) begin
        clk_div_rd <= 0;
        rd_clk_reg <= 0;
    end else begin
        if (clk_div_rd >= 2) begin  // 分频为sys_clk/3
            clk_div_rd <= 0;
            rd_clk_reg <= ~rd_clk_reg;
        end else begin
            clk_div_rd <= clk_div_rd + 1;
        end
    end
end

wire wr_clk = wr_clk_reg;
wire rd_clk = rd_clk_reg;

// =====================================================
// 内部测试启动信号生成
// DDR初始化完成后自动启动测试
// =====================================================
reg test_start_reg;
reg ddr_init_done_d1;

always @(posedge sys_clk or negedge rst_n) begin
    if (~rst_n) begin
        ddr_init_done_d1 <= 1'b0;
        test_start_reg <= 1'b0;
    end else begin
        ddr_init_done_d1 <= ddr_init_done;
        // 检测DDR初始化完成的上升沿,生成一个周期的启动脉冲
        if (ddr_init_done && ~ddr_init_done_d1) begin
            test_start_reg <= 1'b1;
        end else begin
            test_start_reg <= 1'b0;
        end
    end
end

wire test_start = test_start_reg;

// =====================================================
// FIFO接口信号
// =====================================================
wire wr_en;
wire [WR_DATA_WIDTH-1:0] wr_data;
wire wr_full;
wire wr_almost_full;

wire rd_en;
wire [RD_DATA_WIDTH-1:0] rd_data;
wire rd_empty;
wire rd_almost_empty;
wire rd_data_valid;

wire [31:0] fifo_count;
wire [2:0] fifo_state;
wire ddr_init_done;

// 测试状态信号
wire test_running;
wire test_done;
wire test_pass;
wire test_fail;
wire [31:0] write_count;
wire [31:0] read_count;
wire [31:0] error_count;
wire [31:0] first_error_addr;
wire [RD_DATA_WIDTH-1:0] first_error_expected;
wire [RD_DATA_WIDTH-1:0] first_error_actual;

// =====================================================
// DDR3 FIFO 例化
// =====================================================
DDR3_LARGE_FIFO #(
    .WR_DATA_WIDTH(WR_DATA_WIDTH),
    .RD_DATA_WIDTH(RD_DATA_WIDTH),
    .DDR_DATA_WIDTH(128),
    .DDR_ADDR_WIDTH(28),
    .FIFO_DEPTH(2**24)
) u_ddr_fifo (
    .sys_clk(sys_clk),
    .wr_clk(wr_clk),
    .rd_clk(rd_clk),
    .rst_n(rst_n),
    
    // 写接口
    .wr_en(wr_en),
    .wr_data(wr_data),
    .wr_full(wr_full),
    .wr_almost_full(wr_almost_full),
    
    // 读接口
    .rd_en(rd_en),
    .rd_data(rd_data),
    .rd_empty(rd_empty),
    .rd_almost_empty(rd_almost_empty),
    .rd_data_valid(rd_data_valid),
    
    // DDR3物理接口
    .ddr_addr(ddr_addr),
    .ddr_bank(ddr_bank),
    .ddr_cs(ddr_cs),
    .ddr_ras(ddr_ras),
    .ddr_cas(ddr_cas),
    .ddr_we(ddr_we),
    .ddr_ck(ddr_ck),
    .ddr_ck_n(ddr_ck_n),
    .ddr_cke(ddr_cke),
    .ddr_odt(ddr_odt),
    .ddr_reset_n(ddr_reset_n),
    .ddr_dm(ddr_dm),
    .ddr_dq(ddr_dq),
    .ddr_dqs(ddr_dqs),
    .ddr_dqs_n(ddr_dqs_n),
    
    // 状态输出
    .fifo_count(fifo_count),
    .fifo_state(fifo_state),
    .ddr_init_done(ddr_init_done)
);

// =====================================================
// 测试模块例化
// =====================================================
ddr_fifo_test #(
    .WR_DATA_WIDTH(WR_DATA_WIDTH),
    .RD_DATA_WIDTH(RD_DATA_WIDTH),
    .TEST_DATA_COUNT(TEST_DATA_COUNT)
) u_test (
    .sys_clk(sys_clk),
    .wr_clk(wr_clk),
    .rd_clk(rd_clk),
    .rst_n(rst_n),
    .test_start(test_start),
    
    // FIFO写接口
    .wr_en(wr_en),
    .wr_data(wr_data),
    .wr_full(wr_full),
    .wr_almost_full(wr_almost_full),
    
    // FIFO读接口
    .rd_en(rd_en),
    .rd_data(rd_data),
    .rd_empty(rd_empty),
    .rd_almost_empty(rd_almost_empty),
    .rd_data_valid(rd_data_valid),
    
    // FIFO状态
    .fifo_count(fifo_count),
    .ddr_init_done(ddr_init_done),
    
    // 测试状态输出
    .test_running(test_running),
    .test_done(test_done),
    .test_pass(test_pass),
    .test_fail(test_fail),
    .write_count(write_count),
    .read_count(read_count),
    .error_count(error_count),
    .first_error_addr(first_error_addr),
    .first_error_expected(first_error_expected),
    .first_error_actual(first_error_actual)
);

// =====================================================
// LED状态指示
// =====================================================
assign led_init_done = ddr_init_done;
assign led_test_running = test_running;
assign led_test_pass = test_pass;
assign led_test_fail = test_fail;

endmodule
