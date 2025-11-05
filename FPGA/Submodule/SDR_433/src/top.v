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

    // RGMII接口
    input               RGMII_RXCLK,
    input [3:0]         RGMII_RXD,
    input               RGMII_RXDV,
    output              RGMII_GTXCLK,
    output [3:0]        RGMII_TXD,
    output              RGMII_TXEN,
    output              RGMII_RST_N,

    output                              led                         
    );

    assign gclk_div = sys_clk;                                      //50Mhz  

wire                                    data_clk                   ;
wire                   [  11:0]         sine                       ;

wire                   [  11:0]         adc_data_out_i1            ;
wire                   [  11:0]         adc_data_out_q1            ;
wire                                    adc_out_valid              ;
wire                                    adc_status                 ;

wire                   [  11:0]         dac_data_in_i1             ;
wire                   [  11:0]         dac_data_in_q1             ;
wire                                    dac_in_valid               ;
    assign      dac_r1_mode = 1'b1        ;
    assign      adc_r1_mode = 1'b1        ;



    ad9363_dev_cmos u_ad9363_dev_cmos(
    .rst_n                             (rst_n                     ),
        //差分时钟转为单端时钟data_clk
    .data_clk                          (data_clk                  ),
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

    assign      en_agc      = 1'b0        ;
    assign      sync_in     = 1'b1        ;
    assign      reset       = 1'b1        ;

wire demod_data_valid;
wire [11:0] demod_data;

demod_433 u_demod_433 (
    .sys_clk            (data_clk                   ),
    .rst_n              (rst_n                      ),

    .adc_data_i1        (adc_data_out_i1           ),
    .adc_data_q1        (adc_data_out_q1           ),
    .adc_data_valid     (adc_out_valid             ),

    .demod_data         (demod_data                 ),
    .demod_data_valid   (demod_data_valid           )
    );

endmodule