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

// costas costas_u0 (
//     .rst_n(rst_n),
//     .sample_clk(sample_clk),
//     .sample_i1(adc_data_in_i1),
//     .sample_q1(adc_data_in_q1),
//     .data_out_i(costas_out_i),
//     .data_out_q(costas_out_q)
// );

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

// Generate bit_clk_m2 (double frequency of bit_clk)
reg                    [  31:0]         bit_counter_m2             ;
localparam                              BIT_CLK_M2_DIV = SAMPLE_RATE / (BIT_RATE * 2);

always @(posedge sample_clk or negedge rst_n) begin
    if (!rst_n) begin
        bit_counter_m2 <= 32'd0;
        bit_clk_m2 <= 1'b0;
    end
    else begin
        if (bit_counter_m2 >= (BIT_CLK_M2_DIV - 1)) begin
            bit_counter_m2 <= 32'd0;
            bit_clk_m2 <= ~bit_clk_m2;
        end
        else begin
            bit_counter_m2 <= bit_counter_m2 + 1'd1;
        end
    end
end

// QPSK mapping: 00->(-1,-1), 01->(-1,1), 10->(1,-1), 11->(1,1)
always @(posedge bit_clk) begin
    case(tx_data_iq)
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
    else if (qpsk_idle_flag) begin
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

assign dac_data_out_i1 = qpsk_i_reg;
assign dac_data_out_q1 = qpsk_q_reg;
assign dac_out_valid = qpsk_valid;


wire                   [   1:0]         tx_data_iq                 ;
wire                                    empty_flag                 ;
wire                                    tx_fifo_full               ;
assign tx_data_ready = ~tx_fifo_full;

    fifo_tx fifo_tx_u0(
    .Data                              ({tx_data_in[1:0], tx_data_in[3:2], tx_data_in[5:4], tx_data_in[7:6]} ),//input [7:0] Data
    .WrClk                             (tx_clk_in                 ),//input WrClk
    .RdClk                             (bit_clk                   ),//input RdClk
    .WrEn                              (tx_data_valid             ),//input WrEn
    .RdEn                              (1'b1                      ),//input RdEn
    .Q                                 (tx_data_iq                ),//output [1:0] Q
    .Empty                             (empty_flag                ),//output Empty
    .Full                              (tx_fifo_full              ) //output Full
    );

    // QPSK Demodulation
reg             signed [  11:0]         demod_i, demod_q           ;
reg                    [   1:0]         demod_data                 ;
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
            demod_data <= 2'b00;
            demod_valid <= 1'b0;
        end
        else if (adc_in_valid) begin
            case ({demod_i[11], demod_q[11]})                       // Check sign bits
                2'b00: demod_data <= 2'b11;                         // I>=0, Q>=0 -> 11
                2'b01: demod_data <= 2'b10;                         // I>=0, Q<0  -> 10
                2'b10: demod_data <= 2'b01;                         // I<0,  Q>=0 -> 01
                2'b11: demod_data <= 2'b00;                         // I<0,  Q<0  -> 00
            endcase
            demod_valid <= 1'b1;
        end
        else begin
            demod_valid <= 1'b0;
        end
    end

wire                                    rx_fifo_empty              ;
assign rx_clk_out = bit_clk_m2;

assign rx_data_valid = ~rx_fifo_empty;
    // FIFO for demodulated data output
    fifo_rx fifo_rx_u0(
    .Data                              ({demod_data[0], demod_data[1]}),//input [1:0] Data
    .WrClk                             (demod_bit_clk             ),//input WrClk
    .RdClk                             (bit_clk_m2                ),//input RdClk
    .WrEn                              (demod_valid               ),//input WrEn
    .RdEn                              (1'b1                      ),//input RdEn
    .Q                                 (rx_data_out               ),//output [0:0] Q
    .Empty                             (rx_fifo_empty             ),//output Empty
    .Full                              (rx_data_missing           ) //output Full
    );

// reg cnt_bits;
// reg [1:0] demod_data_reg;

// always @(posedge bit_clk_m2 or negedge rst_n) begin
//     if (!rst_n) begin
//         rx_data_out <= 1'b0;
//         cnt_bits <= 1'b0;
//     end
//     else begin
//         if (cnt_bits == 1'b0) begin

//             rx_data_out <= demod_data_reg[1];
//             cnt_bits <= 1'b1;
//         end
//         else begin
//             demod_data_reg <= demod_data;
//             rx_data_out <= demod_data_reg[0];
//             cnt_bits <= 1'b0;
//         end
//     end
// end

endmodule