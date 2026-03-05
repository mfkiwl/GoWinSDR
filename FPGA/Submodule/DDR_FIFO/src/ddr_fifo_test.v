// =====================================================
// DDR FIFO 读写测试模块
// 功能: 自动生成测试数据,写入FIFO,读出并验证
// =====================================================
module ddr_fifo_test #(
    parameter WR_DATA_WIDTH = 64,
    parameter RD_DATA_WIDTH = 64,
    parameter TEST_DATA_COUNT = 1024  // 测试数据量
)(
    input wire sys_clk,
    input wire wr_clk,
    input wire rd_clk,
    input wire rst_n,
    input wire test_start,           // 测试启动信号
    
    // FIFO写接口
    output reg wr_en,
    output reg [WR_DATA_WIDTH-1:0] wr_data,
    input wire wr_full,
    input wire wr_almost_full,
    
    // FIFO读接口
    output reg rd_en,
    input wire [RD_DATA_WIDTH-1:0] rd_data,
    input wire rd_empty,
    input wire rd_almost_empty,
    input wire rd_data_valid,
    
    // FIFO状态
    input wire [31:0] fifo_count,
    input wire ddr_init_done,
    
    // 测试状态输出
    output reg test_running,         // 测试运行中
    output reg test_done,            // 测试完成
    output reg test_pass,            // 测试通过
    output reg test_fail,            // 测试失败
    output reg [31:0] write_count,   // 已写入数据量
    output reg [31:0] read_count,    // 已读出数据量
    output reg [31:0] error_count,   // 错误计数
    output reg [31:0] first_error_addr, // 第一个错误地址
    output reg [RD_DATA_WIDTH-1:0] first_error_expected, // 第一个错误的期望值
    output reg [RD_DATA_WIDTH-1:0] first_error_actual    // 第一个错误的实际值
);

// =====================================================
// 写端口逻辑 (wr_clk 时钟域)
// =====================================================
reg [31:0] wr_addr;
reg wr_test_start_sync1, wr_test_start_sync2;
reg wr_phase_done;
reg [WR_DATA_WIDTH-1:0] wr_data_gen;

// 同步test_start到写时钟域
always @(posedge wr_clk or negedge rst_n) begin
    if (~rst_n) begin
        wr_test_start_sync1 <= 0;
        wr_test_start_sync2 <= 0;
    end else begin
        wr_test_start_sync1 <= test_start;
        wr_test_start_sync2 <= wr_test_start_sync1;
    end
end

// 写数据生成和控制
always @(posedge wr_clk or negedge rst_n) begin
    if (~rst_n) begin
        wr_en <= 0;
        wr_data <= 0;
        wr_addr <= 0;
        wr_phase_done <= 0;
        write_count <= 0;
        wr_data_gen <= 0;
    end else begin
        if (wr_test_start_sync2 && !wr_phase_done && ddr_init_done) begin
            // 生成测试数据
            if (!wr_full && wr_addr < TEST_DATA_COUNT) begin
                wr_en <= 1;
                // 生成可预测的测试模式: 地址和反码组合
                if (WR_DATA_WIDTH == 32) begin
                    wr_data <= wr_addr[31:0];
                end else if (WR_DATA_WIDTH == 64) begin
                    wr_data <= {wr_addr[31:0], ~wr_addr[31:0]};
                end else if (WR_DATA_WIDTH == 128) begin
                    wr_data <= {wr_addr[31:0], ~wr_addr[31:0], wr_addr[31:0] + 1, ~(wr_addr[31:0] + 1)};
                end else begin
                    wr_data <= {{(WR_DATA_WIDTH-32){1'b0}}, wr_addr[31:0]};
                end
                wr_addr <= wr_addr + 1;
                write_count <= write_count + 1;
            end else if (wr_addr >= TEST_DATA_COUNT) begin
                wr_en <= 0;
                wr_phase_done <= 1;
            end else begin
                wr_en <= 0;
            end
        end else if (!wr_test_start_sync2) begin
            wr_en <= 0;
            wr_addr <= 0;
            wr_phase_done <= 0;
            write_count <= 0;
        end else begin
            wr_en <= 0;
        end
    end
end

// =====================================================
// 读端口逻辑 (rd_clk 时钟域)
// =====================================================
reg [31:0] rd_addr;
reg rd_test_start_sync1, rd_test_start_sync2;
reg rd_phase_done;
reg wr_phase_done_sync1, wr_phase_done_sync2;
reg [RD_DATA_WIDTH-1:0] expected_data;
reg first_error_captured;

// 同步信号到读时钟域
always @(posedge rd_clk or negedge rst_n) begin
    if (~rst_n) begin
        rd_test_start_sync1 <= 0;
        rd_test_start_sync2 <= 0;
        wr_phase_done_sync1 <= 0;
        wr_phase_done_sync2 <= 0;
    end else begin
        rd_test_start_sync1 <= test_start;
        rd_test_start_sync2 <= rd_test_start_sync1;
        wr_phase_done_sync1 <= wr_phase_done;
        wr_phase_done_sync2 <= wr_phase_done_sync1;
    end
end

// 读数据和验证
always @(posedge rd_clk or negedge rst_n) begin
    if (~rst_n) begin
        rd_en <= 0;
        rd_addr <= 0;
        rd_phase_done <= 0;
        read_count <= 0;
        error_count <= 0;
        first_error_captured <= 0;
        first_error_addr <= 0;
        first_error_expected <= 0;
        first_error_actual <= 0;
    end else begin
        // 等待写阶段完成后开始读
        if (rd_test_start_sync2 && wr_phase_done_sync2 && !rd_phase_done) begin
            if (!rd_empty && rd_addr < TEST_DATA_COUNT) begin
                rd_en <= 1;
            end else if (rd_addr >= TEST_DATA_COUNT) begin
                rd_en <= 0;
                rd_phase_done <= 1;
            end else begin
                rd_en <= 0;
            end
            
            // 验证读出的数据
            if (rd_data_valid) begin
                // 生成期望数据模式
                if (RD_DATA_WIDTH == 32) begin
                    expected_data = rd_addr[31:0];
                end else if (RD_DATA_WIDTH == 64) begin
                    expected_data = {rd_addr[31:0], ~rd_addr[31:0]};
                end else if (RD_DATA_WIDTH == 128) begin
                    expected_data = {rd_addr[31:0], ~rd_addr[31:0], rd_addr[31:0] + 1, ~(rd_addr[31:0] + 1)};
                end else begin
                    expected_data = {{(RD_DATA_WIDTH-32){1'b0}}, rd_addr[31:0]};
                end
                
                if (rd_data !== expected_data) begin
                    error_count <= error_count + 1;
                    // 捕获第一个错误
                    if (!first_error_captured) begin
                        first_error_captured <= 1;
                        first_error_addr <= rd_addr;
                        first_error_expected <= expected_data;
                        first_error_actual <= rd_data;
                    end
                end
                
                rd_addr <= rd_addr + 1;
                read_count <= read_count + 1;
            end
        end else if (!rd_test_start_sync2) begin
            rd_en <= 0;
            rd_addr <= 0;
            rd_phase_done <= 0;
            read_count <= 0;
            error_count <= 0;
            first_error_captured <= 0;
        end else begin
            rd_en <= 0;
        end
    end
end

// =====================================================
// 测试状态控制 (sys_clk 时钟域,或者可以用rd_clk)
// =====================================================
reg test_start_sync1, test_start_sync2;
reg wr_done_sync1, wr_done_sync2;
reg rd_done_sync1, rd_done_sync2;

always @(posedge rd_clk or negedge rst_n) begin
    if (~rst_n) begin
        test_start_sync1 <= 0;
        test_start_sync2 <= 0;
        wr_done_sync1 <= 0;
        wr_done_sync2 <= 0;
        rd_done_sync1 <= 0;
        rd_done_sync2 <= 0;
        test_running <= 0;
        test_done <= 0;
        test_pass <= 0;
        test_fail <= 0;
    end else begin
        test_start_sync1 <= test_start;
        test_start_sync2 <= test_start_sync1;
        wr_done_sync1 <= wr_phase_done;
        wr_done_sync2 <= wr_done_sync1;
        rd_done_sync1 <= rd_phase_done;
        rd_done_sync2 <= rd_done_sync1;
        
        // 测试状态机
        if (test_start_sync2 && !test_done) begin
            test_running <= 1;
        end
        
        if (rd_done_sync2 && !test_done) begin
            test_done <= 1;
            test_running <= 0;
            
            if (error_count == 0) begin
                test_pass <= 1;
                test_fail <= 0;
            end else begin
                test_pass <= 0;
                test_fail <= 1;
            end
        end
        
        // 复位测试状态
        if (!test_start_sync2 && test_done) begin
            test_done <= 0;
            test_pass <= 0;
            test_fail <= 0;
        end
    end
end

endmodule
