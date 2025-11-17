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

    output                              led           ,
    output                              trig_out                           
    );

assign trig_out = tx_data_valid;
//  wire                                    clk_40M                    ;

    // Gowin_PLL pll0(
    // .clkin                             (sys_clk                   ),//input  clkin
    // .clkout0                           (clk_40M                   ),//output  clkout0
    // .mdclk                             (sys_clk                   ) //input  mdclk
    // );


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

//     // 30分频方波 (divide-by-30) from clk_40M -> data_clk
// reg                    [   4:0]         div_cnt_30                 ;
// reg                                     data_clk_r                 ;

//     always @(posedge clk_40M or negedge rst_n) begin
//         if (!rst_n) begin
//             div_cnt_30  <= 5'd0;
//             data_clk_r  <= 1'b0;
//         end else begin
//             if (div_cnt_30 == 5'd14) begin
//                 div_cnt_30 <= 5'd0;
//                 data_clk_r <= ~data_clk_r;                          // toggle every 15 cycles -> period = 30 cycles
//             end else begin
//                 div_cnt_30 <= div_cnt_30 + 1'b1;
//             end
//         end
//     end


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

    DDS_II_Top your_instance_name(
    .clk_i                             (data_clk                  ),//input clk_i
    .rst_n_i                           (rst_n                     ),//input rst_n_i
    .sine_o                            (sine                      ),//output [11:0] sine_o
    .data_valid_o                      (                          ) //output data_valid_o
    );

    assign      en_agc      = 1'b0        ;
    assign      sync_in     = 1'b1        ;
    assign      reset       = 1'b1        ;


localparam                              integer SYS_CLK_FREQ_HZ = 50_000_000;// adjust if sys_clk differs
localparam                              integer TEST_CLK_FREQ_HZ = 1_500_000;
localparam                              integer DIV_HALF = SYS_CLK_FREQ_HZ / (2 * TEST_CLK_FREQ_HZ);// toggle every DIV_HALF cycles

reg                    [  31:0]         test_div_cnt               ;
reg                                     test_clk_reg               ;
wire                                    test_clk = test_clk_reg    ;

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            test_div_cnt <= 32'd0;
            test_clk_reg <= 1'b0;
        end else begin
            if (test_div_cnt >= DIV_HALF - 1) begin
                test_div_cnt <= 32'd0;
                test_clk_reg <= ~test_clk_reg;
            end else begin
                test_div_cnt <= test_div_cnt + 1'b1;
            end
        end
    end

    // Instantiate rf_rxt module
wire                                    rx_data_out                ;
wire                                    rx_data_valid              ;
wire                                    rx_data_missing            ;
wire                                    rx_clk_out                 ;

wire                   [   7:0]         tx_data_in                 ;
wire                                    tx_data_valid              ;
wire                                    tx_data_ready              ;

    rf_rxt #(
    .SAMPLE_RATE                       (32'd30720000              ),
    .BIT_RATE                          (32'd8000000               ) // 8Mbps for testing
    ) u_rf_rxt (
    .clk                               (sys_clk                   ),
    .rst_n                             (rst_n                     ),
    .sample_clk                        (data_clk                  ),
        
        // RX DATA Port
    .rx_data_out                       (rx_data_out               ),
    .rx_clk_out                        (rx_clk_out                ),
    .rx_data_valid                     (rx_data_valid             ),
    .rx_data_missing                   (rx_data_missing           ),
        
        // RX Signal Input
    .adc_data_in_i1                    (adc_data_out_i1           ),
    .adc_data_in_q1                    (adc_data_out_q1           ),
    .adc_in_valid                      (adc_out_valid             ),
        
        // TX DATA Port
    .tx_data_in                        (tx_data_in                ),
    .tx_clk_in                         (test_clk                  ),
    .tx_data_valid                     (tx_data_valid             ),
    .tx_data_ready                     (tx_data_ready             ),
        
        // TX Signal Output
    .dac_data_out_i1                   (dac_data_in_i1            ),
    .dac_data_out_q1                   (dac_data_in_q1            ),
    .dac_out_valid                     (dac_in_valid              ) 
    );


wire [7:0]  eth_rx_data;
wire        eth_rx_data_valid;
wire        eth_rx_frame_start;
wire        eth_rx_frame_end;
wire        eth_tx_ready;
wire        eth_rx_active;
wire        eth_tx_active;
wire [7:0]  eth_tx_data;
wire        eth_tx_data_valid;
wire        eth_tx_frame_start;
wire PHY_CLK;

// 实例化以太网收发模块
eth_transceiver #(
    .BOARD_MAC  (48'h11_45_14_19_19_81),
    .BOARD_IP   ({8'd192, 8'd168, 8'd3, 8'd2}),
    .BOARD_PORT (16'h8000)
) eth_inst (
    .sys_clk            (sys_clk        ),
    .rst_n              (rst_n          ),
    
    .PHY_CLK            (PHY_CLK        ),
    .RGMII_RXCLK        (RGMII_RXCLK    ),
    .RGMII_RXD          (RGMII_RXD      ),
    .RGMII_RXDV         (RGMII_RXDV     ),
    .RGMII_GTXCLK       (RGMII_GTXCLK   ),
    .RGMII_TXD          (RGMII_TXD      ),
    .RGMII_TXEN         (RGMII_TXEN     ),
    .RGMII_RST_N        (RGMII_RST_N    ),
    
    .tx_data            (eth_tx_data    ),  
    .tx_data_valid      (eth_tx_data_valid),
    .tx_frame_start     (eth_tx_frame_start),
    .tx_ready           (eth_tx_ready   ),
    
    .rx_data            (eth_rx_data        ),
    .rx_data_valid      (eth_rx_data_valid  ),
    .rx_frame_start     (eth_rx_frame_start ),
    .rx_frame_end       (eth_rx_frame_end   ),
    
    .rx_active          (   ),
    .tx_active          (   )
);

// Instantiate rf_data_processor module
wire        fifo_almost_full;

rf_data_processor #(
    .FRAME_HEAD(32'hEB90CAD3),
    .FRAME_TAIL(32'h55AA5C4B)
) u_rf_data_processor (
    // Ethernet RX clock domain
    .eth_rx_clk         (RGMII_RXCLK),
    .eth_rx_rst_n       (rst_n),
    .rx_data            (eth_rx_data),
    .rx_data_valid      (eth_rx_data_valid),
    .rx_frame_start     (eth_rx_frame_start),
    .rx_frame_end       (eth_rx_frame_end),
    
    // RF TX clock domain
    .rf_tx_clk          (test_clk),
    .rf_tx_rst_n        (rst_n),
    .rf_tx_data         (tx_data_in),
    .rf_tx_valid        (tx_data_valid),
    .fifo_almost_full   (fifo_almost_full)
);

// Instantiate rf_data_depacketizer module
wire        depack_frame_error;
wire [15:0] depack_frame_length;

rf_data_depacketizer #(
    .FRAME_HEAD         (32'hEB90CAD3),
    .FRAME_TAIL         (32'h55AA5C4B),
    .TIMEOUT_CNT        (32'd65535)
) u_rf_data_depacketizer (
    // RF RX clock domain
    .rf_rx_clk          (rx_clk_out),
    .rf_rx_rst_n        (rst_n),
    .rf_rx_data         (rx_data_out),
    .rf_rx_valid        (rx_data_valid),
    
    // Ethernet TX clock domain
    .eth_tx_clk         (RGMII_GTXCLK),
    .eth_tx_rst_n       (rst_n),
    .tx_data            (eth_tx_data),
    .tx_data_valid      (eth_tx_data_valid),
    .tx_frame_start     (eth_tx_frame_start),
    .tx_ready           (eth_tx_ready),
    
    // Status indicators
    .frame_error        (depack_frame_error),
    .frame_length       (depack_frame_length)
);

    
    endmodule