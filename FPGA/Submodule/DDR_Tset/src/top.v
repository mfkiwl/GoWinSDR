module top (
    // 系统时钟和复位
    input wire sys_clk,                  // 系统时钟 50MHz
    input wire rst_n,
    
    // DDR3物理接口
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
    output [2-1:0] ddr_dm,
    inout  [16-1:0] ddr_dq,
    inout  [2-1:0] ddr_dqs,
    inout  [2-1:0] ddr_dqs_n,
    
    // 测试状态输出
    output wire test_done,
    output wire test_pass,
    output wire [7:0] led                // LED指示灯
);

    // 参数定义
    parameter DATA_WIDTH = 64;
    parameter TEST_DATA_NUM = 1024;      // 测试数据数量
    
    // 内部信号
    wire clk_100m;                       // 用户时钟域 100MHz
    wire pll_locked;
    
    // 写接口信号
    reg wr_en;
    reg [DATA_WIDTH-1:0] wr_data;
    wire wr_full;
    wire wr_almost_full;
    
    // 读接口信号
    reg rd_en;
    wire [DATA_WIDTH-1:0] rd_data;
    wire rd_empty;
    wire rd_almost_empty;
    wire rd_data_valid;
    
    // 状态信号
    wire [31:0] fifo_count;
    wire [2:0] fifo_state;
    wire ddr_init_done;
    
    // 测试状态机
    localparam IDLE      = 3'd0;
    localparam WAIT_INIT = 3'd1;
    localparam WRITE     = 3'd2;
    localparam WAIT_DATA = 3'd3;
    localparam READ      = 3'd4;
    localparam COMPARE   = 3'd5;
    localparam DONE      = 3'd6;
    
    reg [2:0] test_state;
    reg [15:0] wr_cnt;
    reg [15:0] rd_cnt;
    reg [DATA_WIDTH-1:0] expected_data;
    reg test_pass_reg;
    reg test_done_reg;
    reg [DATA_WIDTH-1:0] test_pattern;
    
    assign test_pass = test_pass_reg;
    assign test_done = test_done_reg;
    
    Gowin_PLL_Test your_instance_name(
        .clkin(sys_clk), //input  clkin
        .clkout0(clk_100m), //output  clkout0
        .mdclk(sys_clk) //input  mdclk
    );
    
    // DDR3 FIFO实例化
    DDR3_LARGE_FIFO #(
        .DATA_WIDTH(DATA_WIDTH),
        .DDR_DATA_WIDTH(128),
        .DDR_ADDR_WIDTH(28),
        .FIFO_DEPTH(2**24)
    ) u_ddr3_fifo (
        .sys_clk(sys_clk),
        .clk(clk_100m),
        .rst_n(rst_n),
        
        .wr_en(wr_en),
        .wr_data(wr_data),
        .wr_full(wr_full),
        .wr_almost_full(wr_almost_full),
        
        .rd_en(rd_en),
        .rd_data(rd_data),
        .rd_empty(rd_empty),
        .rd_almost_empty(rd_almost_empty),
        .rd_data_valid(rd_data_valid),
        
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
        
        .fifo_count(fifo_count),
        .fifo_state(fifo_state),
        .ddr_init_done(ddr_init_done)
    );
    
    // 测试数据生成(伪随机模式)
    always @(posedge clk_100m or negedge rst_n) begin
        if (!rst_n) begin
            test_pattern <= 64'h0123456789ABCDEF;
        end else if (wr_en) begin
            test_pattern <= {test_pattern[62:0], test_pattern[63] ^ test_pattern[62] ^ test_pattern[60] ^ test_pattern[59]};
        end
    end
    
    // 测试状态机
    always @(posedge clk_100m or negedge rst_n) begin
        if (!rst_n) begin
            test_state <= IDLE;
            wr_en <= 1'b0;
            rd_en <= 1'b0;
            wr_data <= 64'd0;
            wr_cnt <= 16'd0;
            rd_cnt <= 16'd0;
            expected_data <= 64'h0123456789ABCDEF;
            test_pass_reg <= 1'b0;
            test_done_reg <= 1'b0;
        end else begin
            case (test_state)
                IDLE: begin
                    test_state <= WAIT_INIT;
                    test_pass_reg <= 1'b1;
                end
                
                WAIT_INIT: begin
                    if (ddr_init_done) begin
                        test_state <= WRITE;
                        wr_cnt <= 16'd0;
                    end
                end
                
                WRITE: begin
                    if (!wr_full && wr_cnt < TEST_DATA_NUM) begin
                        wr_en <= 1'b1;
                        wr_data <= test_pattern;
                        wr_cnt <= wr_cnt + 1'b1;
                    end else begin
                        wr_en <= 1'b0;
                        if (wr_cnt >= TEST_DATA_NUM) begin
                            test_state <= WAIT_DATA;
                        end
                    end
                end
                
                WAIT_DATA: begin
                    if (!rd_empty) begin
                        test_state <= READ;
                        rd_cnt <= 16'd0;
                    end
                end
                
                READ: begin
                    if (!rd_empty && rd_cnt < TEST_DATA_NUM) begin
                        rd_en <= 1'b1;
                        test_state <= COMPARE;
                    end else if (rd_cnt >= TEST_DATA_NUM) begin
                        rd_en <= 1'b0;
                        test_state <= DONE;
                    end
                end
                
                COMPARE: begin
                    if (rd_data_valid) begin
                        if (rd_data !== expected_data) begin
                            test_pass_reg <= 1'b0;
                        end
                        expected_data <= {expected_data[62:0], expected_data[63] ^ expected_data[62] ^ expected_data[60] ^ expected_data[59]};
                        rd_cnt <= rd_cnt + 1'b1;
                        test_state <= READ;
                    end
                end
                
                DONE: begin
                    rd_en <= 1'b0;
                    test_done_reg <= 1'b1;
                end
                
                default: test_state <= IDLE;
            endcase
        end
    end

endmodule