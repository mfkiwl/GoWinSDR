module rf_rxt #(
    parameter                           SAMPLE_RATE = 32'd30720000 ,
    parameter                           BIT_RATE    = 32'd1000000   
)(
    input                               clk                        ,
    input                               rst_n                      ,
    input                               sample_clk                 ,

    // RX DATA Port
    output                              rx_data_out                ,
    output                              rx_clk_out                 ,
    output                              rx_data_valid              ,
    output                              rx_data_missing            ,

    // RX Signal Input
    input              [  11:0]         adc_data_in_i1             ,
    input              [  11:0]         adc_data_in_q1             ,
    input                               adc_in_valid               ,

    // TX DATA Port
    input              [   7:0]         tx_data_in                 ,
    input                               tx_clk_in                  ,
    input                               tx_data_valid              ,
    output                              tx_data_ready              ,

    // TX Signal Output
    output             [  11:0]         dac_data_out_i1            ,
    output             [  11:0]         dac_data_out_q1            ,
    output                              dac_out_valid               
);


wire signed [11:0] costas_out_i;
wire signed [11:0] costas_out_q;


assign costas_out_i = adc_data_in_i1;
assign costas_out_q = adc_data_in_q1;

// QPSK Modulation
reg             signed [  11:0]         qpsk_i, qpsk_q             ;
reg             signed [  11:0]         qpsk_i_reg, qpsk_q_reg     ;
reg                                     qpsk_valid                 ;

reg                                     bit_clk                    ;
reg                                     bit_clk_m2                 ;
reg                    [  31:0]         bit_counter                ;
localparam                              BIT_CLK_DIV = SAMPLE_RATE / BIT_RATE;

always @(posedge sample_clk or negedge rst_n) begin
    if (!rst_n) begin
        bit_counter <= 32'd0;
        bit_clk <= 1'b0;
    end
    else begin
        if (bit_counter >= (BIT_CLK_DIV - 1)) begin
            bit_counter <= 32'd0;
            bit_clk <= ~bit_clk;
        end
        else if (bit_counter >= (BIT_CLK_DIV / 2 - 1)) begin
            bit_counter <= bit_counter + 1'd1;
        end
        else begin
            bit_counter <= bit_counter + 1'd1;
        end
    end
end


// QPSK mapping: 00->(-1,-1), 01->(-1,1), 10->(1,-1), 11->(1,1)
always @(posedge bit_clk) begin
    case(tx_data_iq_diff)
        2'b00: begin
            qpsk_i = -12'd1448;                                     // -1/sqrt(2) * 2048
            qpsk_q = -12'd1448;
        end
        2'b01: begin
            qpsk_i = -12'd1448;
            qpsk_q = 12'd1448;                                      // 1/sqrt(2) * 2048
        end
        2'b10: begin
            qpsk_i = 12'd1448;
            qpsk_q = -12'd1448;
        end
        2'b11: begin
            qpsk_i = 12'd1448;
            qpsk_q = 12'd1448;
        end
    endcase
end

reg qpsk_idle_flag;
reg qpsk_idle_flag_reg;
always @(posedge bit_clk or negedge rst_n) begin
    if (!rst_n) begin
        qpsk_idle_flag <= 1'b1;
        qpsk_idle_flag_reg <= 1'b1;
    end
    else if (empty_flag) begin
        qpsk_idle_flag_reg <= 1'b1;
        qpsk_idle_flag <= qpsk_idle_flag_reg;
    end
    else begin
        qpsk_idle_flag_reg <= 1'b0;
        qpsk_idle_flag <= 1'b0;
    end
end

always @(posedge sample_clk or negedge rst_n) begin
    if (!rst_n) begin
        qpsk_i_reg <= 12'd0;
        qpsk_q_reg <= 12'd0;
        qpsk_valid <= 1'b0;
    end
    else if (!tx_encoder_valid) begin
        qpsk_i_reg <= 12'd0;
        qpsk_q_reg <= 12'd0;
        qpsk_valid <= 1'b1;
    end
    else begin
        qpsk_i_reg <= qpsk_i;
        qpsk_q_reg <= qpsk_q;
        qpsk_valid <= 1'b1;
    end
end

assign dac_data_out_i1 = rrc_out_i;
assign dac_data_out_q1 = rrc_out_q;
assign dac_out_valid = rrc_out_valid;

wire [11:0] rrc_out_i;
wire [11:0] rrc_out_q;
wire        rrc_out_valid;

Advanced_FIR_Filter_Top rrc_i(
    .clk(sample_clk), //input clk
    .rstn(rst_n), //input rstn
    .fir_rfi_o( ), //output fir_rfi_o
    .fir_valid_i(qpsk_valid), //input fir_valid_i
    .fir_sync_i(1'b1), //input fir_sync_i
    .fir_data_i(qpsk_i_reg), //input [11:0] fir_data_i
    .fir_valid_o(rrc_out_valid), //output fir_valid_o
    .fir_sync_o(    ), //output fir_sync_o
    .fir_data_o(rrc_out_i) //output [11:0] fir_data_o
);

Advanced_FIR_Filter_Top rrc_q(
    .clk(sample_clk), //input clk
    .rstn(rst_n), //input rstn
    .fir_rfi_o( ), //output fir_rfi_o
    .fir_valid_i(qpsk_valid), //input fir_valid_i
    .fir_sync_i(1'b1), //input fir_sync_i
    .fir_data_i(qpsk_q_reg), //input [11:0] fir_data_i
    .fir_valid_o(    ), //output fir_valid_o
    .fir_sync_o(    ), //output fir_sync_o
    .fir_data_o(rrc_out_q) //output [11:0] fir_data_o
);

wire                                    tx_data_iq                 ;
wire                                    empty_flag                 ;
wire                                    tx_fifo_full               ;
assign tx_data_ready = 1'b1;

    fifo_tx fifo_tx_u0(
    .Data                              ({tx_data_in[0], tx_data_in[1], tx_data_in[2], tx_data_in[3],tx_data_in[4],tx_data_in[5],tx_data_in[6],tx_data_in[7]}),//input [7:0] Data
    .WrClk                             (tx_clk_in                 ),//input WrClk
    .RdClk                             (bit_clk                   ),//input RdClk
    .WrEn                              (tx_data_valid             ),//input WrEn
    .RdEn                              (1'b1                      ),//input RdEn
    .Q                                 (tx_data_iq                ),//output [0:0] Q
    .Empty                             (empty_flag                ),//output Empty
    .Full                              (tx_fifo_full              ) //output Full
    );

wire [1:0] tx_data_iq_diff;
wire tx_encoder_valid;

    qpsk_differential_encoder qpsk_diff_encoder_u0 (
        .clk(bit_clk),
        .rst_n(rst_n),
        .data_in({tx_data_iq, tx_data_iq}),
        .data_valid(~qpsk_idle_flag),
        .i_out(tx_data_iq_diff[0]),
        .q_out(tx_data_iq_diff[1]),
        .out_valid(tx_encoder_valid)
    );

    // QPSK Demodulation
reg             signed [  11:0]         demod_i, demod_q           ;
reg                                     demod_data                 ;
reg                                     demod_valid                ;
reg                    [  31:0]         demod_bit_counter          ;
reg                                     demod_bit_clk              ;

    // Generate bit clock for demodulation
    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            demod_bit_counter <= 32'd0;
            demod_bit_clk <= 1'b0;
        end
        else begin
            if (demod_bit_counter >= (BIT_CLK_DIV - 1)) begin
                demod_bit_counter <= 32'd0;
                demod_bit_clk <= ~demod_bit_clk;
            end
            else begin
                demod_bit_counter <= demod_bit_counter + 1'd1;
            end
        end
    end

    // Oversampling and integration for better demodulation
localparam                              SAMPLES_PER_BIT = BIT_CLK_DIV / 2;// Number of samples in half bit period
reg             signed [  23:0]         integrate_i, integrate_q   ;
reg                    [  31:0]         sample_counter             ;
reg                                     integrate_ready            ;
    
    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            integrate_i <= 24'd0;
            integrate_q <= 24'd0;
            sample_counter <= 32'd0;
            integrate_ready <= 1'b0;
        end
        else if (adc_in_valid) begin
            if (sample_counter < SAMPLES_PER_BIT - 1) begin
                // Accumulate samples
                integrate_i <= integrate_i + {{12{costas_out_i[11]}}, costas_out_i};
                integrate_q <= integrate_q + {{12{costas_out_q[11]}}, costas_out_q};
                sample_counter <= sample_counter + 1'd1;
                integrate_ready <= 1'b0;
            end
            else begin
                // Last sample in period, signal ready
                integrate_i <= integrate_i + {{12{costas_out_i[11]}}, costas_out_i};
                integrate_q <= integrate_q + {{12{costas_out_q[11]}}, costas_out_q};
                sample_counter <= 32'd0;
                integrate_ready <= 1'b1;
            end
        end
        else if (integrate_ready) begin
            // Clear after data is captured
            integrate_i <= 24'd0;
            integrate_q <= 24'd0;
            integrate_ready <= 1'b0;
        end
    end
    // Sample and hold ADC data
    always @(posedge demod_bit_clk or negedge rst_n) begin
        if (!rst_n) begin
            demod_i <= 12'd0;
            demod_q <= 12'd0;
        end
        else if (adc_in_valid) begin
            demod_i <= costas_out_i;
            demod_q <= costas_out_q;
        end
    end

    // QPSK decision: determine which quadrant
    always @(posedge demod_bit_clk or negedge rst_n) begin
        if (!rst_n) begin
            demod_data <= 1'b0;
            demod_valid <= 1'b0;
        end
        else if (adc_in_valid) begin
            // case ({demod_i[11], demod_q[11]})                       // Check sign bits
            //     2'b00: demod_data <= 2'b11;                         // I>=0, Q>=0 -> 11
            //     2'b01: demod_data <= 2'b10;                         // I>=0, Q<0  -> 10
            //     2'b10: demod_data <= 2'b01;                         // I<0,  Q>=0 -> 01
            //     2'b11: demod_data <= 2'b00;                         // I<0,  Q<0  -> 00
            // endcase
            case (demod_i[11]) 
                1'b0: demod_data <= 1'b1;
                1'b1: demod_data <= 1'b0;
            endcase
            demod_valid <= 1'b1;
        end
        else begin
            demod_valid <= 1'b0;
        end
    end

wire                                    rx_fifo_empty              ;
assign rx_clk_out = demod_bit_clk;
assign rx_data_out = decoded_data[0];
assign rx_data_valid = decoded_valid;
    // // FIFO for demodulated data output
    // fifo_rx fifo_rx_u0(
    // .Data                              (decoded_data[0]),//input [0:0] Data
    // .WrClk                             (demod_bit_clk             ),//input WrClk
    // .RdClk                             (bit_clk                   ),//input RdClk
    // .WrEn                              (demod_valid               ),//input WrEn
    // .RdEn                              (1'b1                      ),//input RdEn
    // .Q                                 (rx_data_out               ),//output [0:0] Q
    // .Empty                             (rx_fifo_empty             ),//output Empty
    // .Full                              (rx_data_missing           ) //output Full
    // );

wire [1:0] decoded_data;
wire decoded_valid;

qpsk_differential_decoder qpsk_diff_decoder_u0 (
    .clk(demod_bit_clk),
    .rst_n(rst_n),
    .i_in(demod_data),
    .q_in(demod_data),
    .data_valid(demod_valid),
    .data_out(decoded_data),
    .out_valid(decoded_valid)
);



endmodule