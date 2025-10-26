    module top (
        input                               sys_clk                    ,
        input                               rst_n                      ,

        // RX Port
        input                               rx_clk_in_p                ,
        input              [  11:0]         rx_data_in                 ,
        input                               rx_frame_in_p              ,

        // TX Port
        output             [  11:0]         tx_data_out                ,
        output                              tx_clk_out_p               ,
        output                              tx_frame_out_p             ,//fb

        output                              en_agc                     ,
        output reg                          enable                     ,
        output reg                          txnrx                      ,
        output                              reset                      ,
        output                              sync_in                    ,

        output                              led                         
    );

    wire                                    clk_40M                    ;

    Gowin_PLL pll0(
        .clkin                             (sys_clk                   ),//input  clkin
        .clkout0                           (clk_40M                   ),//output  clkout0
        .mdclk                             (sys_clk                   ) //input  mdclk
    );


    assign gclk_div = sys_clk;                                          //50Mhz  

    wire                                    data_clk                   ;
    wire                   [  11:0]         sine                       ;

    wire                   [  11:0]         adc_data_out_i1            ;
    wire                   [  11:0]         adc_data_out_q1            ;
    wire                                    adc_out_valid              ;
    wire                                    adc_status                 ;

    wire                   [  11:0]         dac_data_in_i1             ;
    wire                   [  11:0]         dac_data_in_q1             ;
    reg                                     dac_in_valid               ;

    assign      dac_r1_mode = 1'b1        ;
    assign      adc_r1_mode = 1'b1        ;

    // 30分频方波 (divide-by-30) from clk_40M -> data_clk
    reg                    [   4:0]         div_cnt_30                 ;
    reg                                     data_clk_r                 ;

    always @(posedge clk_40M or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt_30  <= 5'd0;
            data_clk_r  <= 1'b0;
        end else begin
            if (div_cnt_30 == 5'd14) begin
                div_cnt_30 <= 5'd0;
                data_clk_r <= ~data_clk_r;                              // toggle every 15 cycles -> period = 30 cycles
            end else begin
                div_cnt_30 <= div_cnt_30 + 1'b1;
            end
        end
    end

    assign dac_data_in_i1 = sine;
    assign dac_data_in_q1 = sine;

    ad9363_dev_cmos u_ad9363_dev_cmos(
        .rst_n                             (rst_n                     ),
        //差分时钟转为单端时钟data_clk
        .data_clk                          (     data_clk      ),
        //Rx Port
        .rx_data_in                        (rx_data_in                ),
        .rx_clk_in_p                       (rx_clk_in_p               ),
        .rx_frame_in_p                     (rx_frame_in_p             ),
        //6位转换12数据
        .adc_data_out_i1                   (adc_data_out_i1           ),
        .adc_data_out_q1                   (adc_data_out_q1           ),
        .adc_out_valid                     (adc_out_valid             ),
        .adc_status                        (adc_status                ),
        //需要 数 模 转换的数据 12位转6位
        .dac_data_in_i1                    (dac_data_in_i1            ),
        .dac_data_in_q1                    (dac_data_in_q1            ),
        .dac_in_valid                      (dac_in_valid              ),
        //12位以及转换为6位的数据
        .tx_data_out                       (tx_data_out               ),
        .tx_clk_out_p                      (tx_clk_out_p              ),
        .tx_frame_out_p                    (tx_frame_out_p            ) 
    );


    always @(posedge gclk_div) begin
        if(rst_n == 1'b1) begin
            dac_in_valid <= 1'b1;
        end
        else;
    end

    always @(posedge gclk_div or negedge rst_n)
    begin
        if(!rst_n)begin
        txnrx <= 1'b0;
        enable<= 1'b0;
        end
        else begin
            txnrx <= 1'b1;
            enable<= 1'b0;
        end
    end

    reg                    [  23:0]         led_cnt                    ;
    reg                                     led_blink                  ;

    always @(posedge data_clk or negedge rst_n) begin
        if (!rst_n) begin
            led_cnt   <= 24'd0;
            led_blink <= 1'b0;
        end else begin
            if (led_cnt == 24'd9_999_999) begin
                led_cnt   <= 24'd0;
                led_blink <= ~led_blink;
            end else begin
                led_cnt <= led_cnt + 1'b1;
            end
        end
    end

    assign led = led_blink;

    DDS_II_Top your_instance_name(
        .clk_i                             (data_clk                  ),//input clk_i
        .rst_n_i                           (rst_n                     ),//input rst_n_i
        .sine_o                            (sine                      ),//output [11:0] sine_o
        .data_valid_o                      (                          ) //output data_valid_o
    );

    assign      en_agc      = 1'b0        ;
    assign      sync_in     = 1'b1        ;
    assign      reset       = 1'b1        ;

    endmodule