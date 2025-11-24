module demod_433 (
    input                               sys_clk                    ,
    input                               rst_n                      ,

    input              [  11:0]         adc_data_i1                ,
    input              [  11:0]         adc_data_q1                ,
    input                               adc_data_valid             ,

    output reg                          demod_data          
    );

    // 功率阈值参数 (可根据实际需求调整)
    parameter POWER_THRESHOLD = 24'd1000000;  // 功率阈值
    parameter AVG_SHIFT = 6;                   // 平均滤波位移 (2^6=64次平均)

    // 内部信号
    reg signed [11:0] i_data;
    reg signed [11:0] q_data;
    reg [23:0] i_square;
    reg [23:0] q_square;
    reg [24:0] power_inst;       // 瞬时功率 (I^2 + Q^2)
    reg [27:0] power_acc;        // 功率累加器
    reg [AVG_SHIFT-1:0] avg_cnt; // 平均计数器
    reg [23:0] power_avg;        // 平均功率
    
    // 数据锁存
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            i_data <= 12'd0;
            q_data <= 12'd0;
        end else if (adc_data_valid) begin
            i_data <= adc_data_i1;
            q_data <= adc_data_q1;
        end
    end
    
    // 计算I和Q的平方
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            i_square <= 24'd0;
            q_square <= 24'd0;
        end else if (adc_data_valid) begin
            i_square <= i_data * i_data;
            q_square <= q_data * q_data;
        end
    end
    
    // 计算瞬时功率 (I^2 + Q^2)
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            power_inst <= 25'd0;
        end else if (adc_data_valid) begin
            power_inst <= i_square + q_square;
        end
    end
    
    // 功率平均滤波
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            power_acc <= 28'd0;
            avg_cnt <= {AVG_SHIFT{1'b0}};
            power_avg <= 24'd0;
        end else if (adc_data_valid) begin
            if (avg_cnt == {AVG_SHIFT{1'b1}}) begin
                // 计算平均值并复位累加器
                power_avg <= power_acc[27:AVG_SHIFT];
                power_acc <= {{3{1'b0}}, power_inst};
                avg_cnt <= {AVG_SHIFT{1'b0}};
            end else begin
                // 累加功率
                power_acc <= power_acc + power_inst;
                avg_cnt <= avg_cnt + 1'b1;
            end
        end
    end
    
    // 功率阈值比较输出
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            demod_data <= 1'b0;
        end else begin
            if (power_avg > POWER_THRESHOLD)
                demod_data <= 1'b1;  // 功率超过阈值，输出高电平
            else
                demod_data <= 1'b0;  // 功率低于阈值，输出低电平
        end
    end

endmodule