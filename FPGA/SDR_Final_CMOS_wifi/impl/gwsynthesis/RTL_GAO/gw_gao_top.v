module gw_gao(
    \adc_data_out_i1[11] ,
    \adc_data_out_i1[10] ,
    \adc_data_out_i1[9] ,
    \adc_data_out_i1[8] ,
    \adc_data_out_i1[7] ,
    \adc_data_out_i1[6] ,
    \adc_data_out_i1[5] ,
    \adc_data_out_i1[4] ,
    \adc_data_out_i1[3] ,
    \adc_data_out_i1[2] ,
    \adc_data_out_i1[1] ,
    \adc_data_out_i1[0] ,
    \adc_data_out_q1[11] ,
    \adc_data_out_q1[10] ,
    \adc_data_out_q1[9] ,
    \adc_data_out_q1[8] ,
    \adc_data_out_q1[7] ,
    \adc_data_out_q1[6] ,
    \adc_data_out_q1[5] ,
    \adc_data_out_q1[4] ,
    \adc_data_out_q1[3] ,
    \adc_data_out_q1[2] ,
    \adc_data_out_q1[1] ,
    \adc_data_out_q1[0] ,
    \dac_data_in_i1[11] ,
    \dac_data_in_i1[10] ,
    \dac_data_in_i1[9] ,
    \dac_data_in_i1[8] ,
    \dac_data_in_i1[7] ,
    \dac_data_in_i1[6] ,
    \dac_data_in_i1[5] ,
    \dac_data_in_i1[4] ,
    \dac_data_in_i1[3] ,
    \dac_data_in_i1[2] ,
    \dac_data_in_i1[1] ,
    \dac_data_in_i1[0] ,
    \dac_data_in_q1[11] ,
    \dac_data_in_q1[10] ,
    \dac_data_in_q1[9] ,
    \dac_data_in_q1[8] ,
    \dac_data_in_q1[7] ,
    \dac_data_in_q1[6] ,
    \dac_data_in_q1[5] ,
    \dac_data_in_q1[4] ,
    \dac_data_in_q1[3] ,
    \dac_data_in_q1[2] ,
    \dac_data_in_q1[1] ,
    \dac_data_in_q1[0] ,
    \eth_rx_data[7] ,
    \eth_rx_data[6] ,
    \eth_rx_data[5] ,
    \eth_rx_data[4] ,
    \eth_rx_data[3] ,
    \eth_rx_data[2] ,
    \eth_rx_data[1] ,
    \eth_rx_data[0] ,
    eth_rx_frame_end,
    eth_rx_data_valid,
    dac_in_valid,
    \fifo_out[31] ,
    \fifo_out[30] ,
    \fifo_out[29] ,
    \fifo_out[28] ,
    \fifo_out[27] ,
    \fifo_out[26] ,
    \fifo_out[25] ,
    \fifo_out[24] ,
    \fifo_out[23] ,
    \fifo_out[22] ,
    \fifo_out[21] ,
    \fifo_out[20] ,
    \fifo_out[19] ,
    \fifo_out[18] ,
    \fifo_out[17] ,
    \fifo_out[16] ,
    \fifo_out[15] ,
    \fifo_out[14] ,
    \fifo_out[13] ,
    \fifo_out[12] ,
    \fifo_out[11] ,
    \fifo_out[10] ,
    \fifo_out[9] ,
    \fifo_out[8] ,
    \fifo_out[7] ,
    \fifo_out[6] ,
    \fifo_out[5] ,
    \fifo_out[4] ,
    \fifo_out[3] ,
    \fifo_out[2] ,
    \fifo_out[1] ,
    \fifo_out[0] ,
    rx_data_valid_extended,
    tx_data_valid_r,
    wifi_frame_start,
    tx_data_valid,
    data_clk,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \adc_data_out_i1[11] ;
input \adc_data_out_i1[10] ;
input \adc_data_out_i1[9] ;
input \adc_data_out_i1[8] ;
input \adc_data_out_i1[7] ;
input \adc_data_out_i1[6] ;
input \adc_data_out_i1[5] ;
input \adc_data_out_i1[4] ;
input \adc_data_out_i1[3] ;
input \adc_data_out_i1[2] ;
input \adc_data_out_i1[1] ;
input \adc_data_out_i1[0] ;
input \adc_data_out_q1[11] ;
input \adc_data_out_q1[10] ;
input \adc_data_out_q1[9] ;
input \adc_data_out_q1[8] ;
input \adc_data_out_q1[7] ;
input \adc_data_out_q1[6] ;
input \adc_data_out_q1[5] ;
input \adc_data_out_q1[4] ;
input \adc_data_out_q1[3] ;
input \adc_data_out_q1[2] ;
input \adc_data_out_q1[1] ;
input \adc_data_out_q1[0] ;
input \dac_data_in_i1[11] ;
input \dac_data_in_i1[10] ;
input \dac_data_in_i1[9] ;
input \dac_data_in_i1[8] ;
input \dac_data_in_i1[7] ;
input \dac_data_in_i1[6] ;
input \dac_data_in_i1[5] ;
input \dac_data_in_i1[4] ;
input \dac_data_in_i1[3] ;
input \dac_data_in_i1[2] ;
input \dac_data_in_i1[1] ;
input \dac_data_in_i1[0] ;
input \dac_data_in_q1[11] ;
input \dac_data_in_q1[10] ;
input \dac_data_in_q1[9] ;
input \dac_data_in_q1[8] ;
input \dac_data_in_q1[7] ;
input \dac_data_in_q1[6] ;
input \dac_data_in_q1[5] ;
input \dac_data_in_q1[4] ;
input \dac_data_in_q1[3] ;
input \dac_data_in_q1[2] ;
input \dac_data_in_q1[1] ;
input \dac_data_in_q1[0] ;
input \eth_rx_data[7] ;
input \eth_rx_data[6] ;
input \eth_rx_data[5] ;
input \eth_rx_data[4] ;
input \eth_rx_data[3] ;
input \eth_rx_data[2] ;
input \eth_rx_data[1] ;
input \eth_rx_data[0] ;
input eth_rx_frame_end;
input eth_rx_data_valid;
input dac_in_valid;
input \fifo_out[31] ;
input \fifo_out[30] ;
input \fifo_out[29] ;
input \fifo_out[28] ;
input \fifo_out[27] ;
input \fifo_out[26] ;
input \fifo_out[25] ;
input \fifo_out[24] ;
input \fifo_out[23] ;
input \fifo_out[22] ;
input \fifo_out[21] ;
input \fifo_out[20] ;
input \fifo_out[19] ;
input \fifo_out[18] ;
input \fifo_out[17] ;
input \fifo_out[16] ;
input \fifo_out[15] ;
input \fifo_out[14] ;
input \fifo_out[13] ;
input \fifo_out[12] ;
input \fifo_out[11] ;
input \fifo_out[10] ;
input \fifo_out[9] ;
input \fifo_out[8] ;
input \fifo_out[7] ;
input \fifo_out[6] ;
input \fifo_out[5] ;
input \fifo_out[4] ;
input \fifo_out[3] ;
input \fifo_out[2] ;
input \fifo_out[1] ;
input \fifo_out[0] ;
input rx_data_valid_extended;
input tx_data_valid_r;
input wifi_frame_start;
input tx_data_valid;
input data_clk;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \adc_data_out_i1[11] ;
wire \adc_data_out_i1[10] ;
wire \adc_data_out_i1[9] ;
wire \adc_data_out_i1[8] ;
wire \adc_data_out_i1[7] ;
wire \adc_data_out_i1[6] ;
wire \adc_data_out_i1[5] ;
wire \adc_data_out_i1[4] ;
wire \adc_data_out_i1[3] ;
wire \adc_data_out_i1[2] ;
wire \adc_data_out_i1[1] ;
wire \adc_data_out_i1[0] ;
wire \adc_data_out_q1[11] ;
wire \adc_data_out_q1[10] ;
wire \adc_data_out_q1[9] ;
wire \adc_data_out_q1[8] ;
wire \adc_data_out_q1[7] ;
wire \adc_data_out_q1[6] ;
wire \adc_data_out_q1[5] ;
wire \adc_data_out_q1[4] ;
wire \adc_data_out_q1[3] ;
wire \adc_data_out_q1[2] ;
wire \adc_data_out_q1[1] ;
wire \adc_data_out_q1[0] ;
wire \dac_data_in_i1[11] ;
wire \dac_data_in_i1[10] ;
wire \dac_data_in_i1[9] ;
wire \dac_data_in_i1[8] ;
wire \dac_data_in_i1[7] ;
wire \dac_data_in_i1[6] ;
wire \dac_data_in_i1[5] ;
wire \dac_data_in_i1[4] ;
wire \dac_data_in_i1[3] ;
wire \dac_data_in_i1[2] ;
wire \dac_data_in_i1[1] ;
wire \dac_data_in_i1[0] ;
wire \dac_data_in_q1[11] ;
wire \dac_data_in_q1[10] ;
wire \dac_data_in_q1[9] ;
wire \dac_data_in_q1[8] ;
wire \dac_data_in_q1[7] ;
wire \dac_data_in_q1[6] ;
wire \dac_data_in_q1[5] ;
wire \dac_data_in_q1[4] ;
wire \dac_data_in_q1[3] ;
wire \dac_data_in_q1[2] ;
wire \dac_data_in_q1[1] ;
wire \dac_data_in_q1[0] ;
wire \eth_rx_data[7] ;
wire \eth_rx_data[6] ;
wire \eth_rx_data[5] ;
wire \eth_rx_data[4] ;
wire \eth_rx_data[3] ;
wire \eth_rx_data[2] ;
wire \eth_rx_data[1] ;
wire \eth_rx_data[0] ;
wire eth_rx_frame_end;
wire eth_rx_data_valid;
wire dac_in_valid;
wire \fifo_out[31] ;
wire \fifo_out[30] ;
wire \fifo_out[29] ;
wire \fifo_out[28] ;
wire \fifo_out[27] ;
wire \fifo_out[26] ;
wire \fifo_out[25] ;
wire \fifo_out[24] ;
wire \fifo_out[23] ;
wire \fifo_out[22] ;
wire \fifo_out[21] ;
wire \fifo_out[20] ;
wire \fifo_out[19] ;
wire \fifo_out[18] ;
wire \fifo_out[17] ;
wire \fifo_out[16] ;
wire \fifo_out[15] ;
wire \fifo_out[14] ;
wire \fifo_out[13] ;
wire \fifo_out[12] ;
wire \fifo_out[11] ;
wire \fifo_out[10] ;
wire \fifo_out[9] ;
wire \fifo_out[8] ;
wire \fifo_out[7] ;
wire \fifo_out[6] ;
wire \fifo_out[5] ;
wire \fifo_out[4] ;
wire \fifo_out[3] ;
wire \fifo_out[2] ;
wire \fifo_out[1] ;
wire \fifo_out[0] ;
wire rx_data_valid_extended;
wire tx_data_valid_r;
wire wifi_frame_start;
wire tx_data_valid;
wire data_clk;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top_0  u_la0_top(
    .control(control0[9:0]),
    .trig0_i(wifi_frame_start),
    .trig1_i(tx_data_valid),
    .trig2_i(eth_rx_data_valid),
    .trig5_i(data_clk),
    .data_i({\adc_data_out_i1[11] ,\adc_data_out_i1[10] ,\adc_data_out_i1[9] ,\adc_data_out_i1[8] ,\adc_data_out_i1[7] ,\adc_data_out_i1[6] ,\adc_data_out_i1[5] ,\adc_data_out_i1[4] ,\adc_data_out_i1[3] ,\adc_data_out_i1[2] ,\adc_data_out_i1[1] ,\adc_data_out_i1[0] ,\adc_data_out_q1[11] ,\adc_data_out_q1[10] ,\adc_data_out_q1[9] ,\adc_data_out_q1[8] ,\adc_data_out_q1[7] ,\adc_data_out_q1[6] ,\adc_data_out_q1[5] ,\adc_data_out_q1[4] ,\adc_data_out_q1[3] ,\adc_data_out_q1[2] ,\adc_data_out_q1[1] ,\adc_data_out_q1[0] ,\dac_data_in_i1[11] ,\dac_data_in_i1[10] ,\dac_data_in_i1[9] ,\dac_data_in_i1[8] ,\dac_data_in_i1[7] ,\dac_data_in_i1[6] ,\dac_data_in_i1[5] ,\dac_data_in_i1[4] ,\dac_data_in_i1[3] ,\dac_data_in_i1[2] ,\dac_data_in_i1[1] ,\dac_data_in_i1[0] ,\dac_data_in_q1[11] ,\dac_data_in_q1[10] ,\dac_data_in_q1[9] ,\dac_data_in_q1[8] ,\dac_data_in_q1[7] ,\dac_data_in_q1[6] ,\dac_data_in_q1[5] ,\dac_data_in_q1[4] ,\dac_data_in_q1[3] ,\dac_data_in_q1[2] ,\dac_data_in_q1[1] ,\dac_data_in_q1[0] ,\eth_rx_data[7] ,\eth_rx_data[6] ,\eth_rx_data[5] ,\eth_rx_data[4] ,\eth_rx_data[3] ,\eth_rx_data[2] ,\eth_rx_data[1] ,\eth_rx_data[0] ,eth_rx_frame_end,eth_rx_data_valid,dac_in_valid,\fifo_out[31] ,\fifo_out[30] ,\fifo_out[29] ,\fifo_out[28] ,\fifo_out[27] ,\fifo_out[26] ,\fifo_out[25] ,\fifo_out[24] ,\fifo_out[23] ,\fifo_out[22] ,\fifo_out[21] ,\fifo_out[20] ,\fifo_out[19] ,\fifo_out[18] ,\fifo_out[17] ,\fifo_out[16] ,\fifo_out[15] ,\fifo_out[14] ,\fifo_out[13] ,\fifo_out[12] ,\fifo_out[11] ,\fifo_out[10] ,\fifo_out[9] ,\fifo_out[8] ,\fifo_out[7] ,\fifo_out[6] ,\fifo_out[5] ,\fifo_out[4] ,\fifo_out[3] ,\fifo_out[2] ,\fifo_out[1] ,\fifo_out[0] ,rx_data_valid_extended,tx_data_valid_r}),
    .clk_i(data_clk)
);

endmodule
