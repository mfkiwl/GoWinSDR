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
    \tx_data_in[7] ,
    \tx_data_in[6] ,
    \tx_data_in[5] ,
    \tx_data_in[4] ,
    \tx_data_in[3] ,
    \tx_data_in[2] ,
    \tx_data_in[1] ,
    \tx_data_in[0] ,
    rx_data_valid,
    tx_data_valid,
    tx_data_ready,
    \u_rf_rxt/tx_data_iq ,
    rx_data_out,
    \u_rf_rxt/demod_data ,
    \u_rf_rxt/decoded_data[1] ,
    \u_rf_rxt/decoded_data[0] ,
    \u_rf_rxt/bit_clk ,
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
    test_clk,
    \u_rf_rxt/costas_u0/sum_a[24] ,
    \u_rf_rxt/costas_u0/sum_a[23] ,
    \u_rf_rxt/costas_u0/sum_a[22] ,
    \u_rf_rxt/costas_u0/sum_a[21] ,
    \u_rf_rxt/costas_u0/sum_a[20] ,
    \u_rf_rxt/costas_u0/sum_a[19] ,
    \u_rf_rxt/costas_u0/sum_a[18] ,
    \u_rf_rxt/costas_u0/sum_a[17] ,
    \u_rf_rxt/costas_u0/sum_a[16] ,
    \u_rf_rxt/costas_u0/sum_a[15] ,
    \u_rf_rxt/costas_u0/sum_a[14] ,
    \u_rf_rxt/costas_u0/sum_a[13] ,
    \u_rf_rxt/costas_u0/sum_a[12] ,
    \u_rf_rxt/costas_u0/sum_a[11] ,
    \u_rf_rxt/costas_u0/sum_a[10] ,
    \u_rf_rxt/costas_u0/sum_a[9] ,
    \u_rf_rxt/costas_u0/sum_a[8] ,
    \u_rf_rxt/costas_u0/sum_a[7] ,
    \u_rf_rxt/costas_u0/sum_a[6] ,
    \u_rf_rxt/costas_u0/sum_a[5] ,
    \u_rf_rxt/costas_u0/sum_a[4] ,
    \u_rf_rxt/costas_u0/sum_a[3] ,
    \u_rf_rxt/costas_u0/sum_a[2] ,
    \u_rf_rxt/costas_u0/sum_a[1] ,
    \u_rf_rxt/costas_u0/sum_a[0] ,
    \u_rf_rxt/costas_u0/sum_b[24] ,
    \u_rf_rxt/costas_u0/sum_b[23] ,
    \u_rf_rxt/costas_u0/sum_b[22] ,
    \u_rf_rxt/costas_u0/sum_b[21] ,
    \u_rf_rxt/costas_u0/sum_b[20] ,
    \u_rf_rxt/costas_u0/sum_b[19] ,
    \u_rf_rxt/costas_u0/sum_b[18] ,
    \u_rf_rxt/costas_u0/sum_b[17] ,
    \u_rf_rxt/costas_u0/sum_b[16] ,
    \u_rf_rxt/costas_u0/sum_b[15] ,
    \u_rf_rxt/costas_u0/sum_b[14] ,
    \u_rf_rxt/costas_u0/sum_b[13] ,
    \u_rf_rxt/costas_u0/sum_b[12] ,
    \u_rf_rxt/costas_u0/sum_b[11] ,
    \u_rf_rxt/costas_u0/sum_b[10] ,
    \u_rf_rxt/costas_u0/sum_b[9] ,
    \u_rf_rxt/costas_u0/sum_b[8] ,
    \u_rf_rxt/costas_u0/sum_b[7] ,
    \u_rf_rxt/costas_u0/sum_b[6] ,
    \u_rf_rxt/costas_u0/sum_b[5] ,
    \u_rf_rxt/costas_u0/sum_b[4] ,
    \u_rf_rxt/costas_u0/sum_b[3] ,
    \u_rf_rxt/costas_u0/sum_b[2] ,
    \u_rf_rxt/costas_u0/sum_b[1] ,
    \u_rf_rxt/costas_u0/sum_b[0] ,
    \u_rf_rxt/costas_u0/loop_flt_in[25] ,
    \u_rf_rxt/costas_u0/loop_flt_in[24] ,
    \u_rf_rxt/costas_u0/loop_flt_in[23] ,
    \u_rf_rxt/costas_u0/loop_flt_in[22] ,
    \u_rf_rxt/costas_u0/loop_flt_in[21] ,
    \u_rf_rxt/costas_u0/loop_flt_in[20] ,
    \u_rf_rxt/costas_u0/loop_flt_in[19] ,
    \u_rf_rxt/costas_u0/loop_flt_in[18] ,
    \u_rf_rxt/costas_u0/loop_flt_in[17] ,
    \u_rf_rxt/costas_u0/loop_flt_in[16] ,
    \u_rf_rxt/costas_u0/loop_flt_in[15] ,
    \u_rf_rxt/costas_u0/loop_flt_in[14] ,
    \u_rf_rxt/costas_u0/loop_flt_in[13] ,
    \u_rf_rxt/costas_u0/loop_flt_in[12] ,
    \u_rf_rxt/costas_u0/loop_flt_in[11] ,
    \u_rf_rxt/costas_u0/loop_flt_in[10] ,
    \u_rf_rxt/costas_u0/loop_flt_in[9] ,
    \u_rf_rxt/costas_u0/loop_flt_in[8] ,
    \u_rf_rxt/costas_u0/loop_flt_in[7] ,
    \u_rf_rxt/costas_u0/loop_flt_in[6] ,
    \u_rf_rxt/costas_u0/loop_flt_in[5] ,
    \u_rf_rxt/costas_u0/loop_flt_in[4] ,
    \u_rf_rxt/costas_u0/loop_flt_in[3] ,
    \u_rf_rxt/costas_u0/loop_flt_in[2] ,
    \u_rf_rxt/costas_u0/loop_flt_in[1] ,
    \u_rf_rxt/costas_u0/loop_flt_in[0] ,
    \u_rf_rxt/costas_u0/pd[23] ,
    \u_rf_rxt/costas_u0/pd[22] ,
    \u_rf_rxt/costas_u0/pd[21] ,
    \u_rf_rxt/costas_u0/pd[20] ,
    \u_rf_rxt/costas_u0/pd[19] ,
    \u_rf_rxt/costas_u0/pd[18] ,
    \u_rf_rxt/costas_u0/pd[17] ,
    \u_rf_rxt/costas_u0/pd[16] ,
    \u_rf_rxt/costas_u0/pd[15] ,
    \u_rf_rxt/costas_u0/pd[14] ,
    \u_rf_rxt/costas_u0/pd[13] ,
    \u_rf_rxt/costas_u0/pd[12] ,
    \u_rf_rxt/costas_u0/pd[11] ,
    \u_rf_rxt/costas_u0/pd[10] ,
    \u_rf_rxt/costas_u0/pd[9] ,
    \u_rf_rxt/costas_u0/pd[8] ,
    \u_rf_rxt/costas_u0/pd[7] ,
    \u_rf_rxt/costas_u0/pd[6] ,
    \u_rf_rxt/costas_u0/pd[5] ,
    \u_rf_rxt/costas_u0/pd[4] ,
    \u_rf_rxt/costas_u0/pd[3] ,
    \u_rf_rxt/costas_u0/pd[2] ,
    \u_rf_rxt/costas_u0/pd[1] ,
    \u_rf_rxt/costas_u0/pd[0] ,
    \u_rf_rxt/costas_u0/dds_cos[11] ,
    \u_rf_rxt/costas_u0/dds_cos[10] ,
    \u_rf_rxt/costas_u0/dds_cos[9] ,
    \u_rf_rxt/costas_u0/dds_cos[8] ,
    \u_rf_rxt/costas_u0/dds_cos[7] ,
    \u_rf_rxt/costas_u0/dds_cos[6] ,
    \u_rf_rxt/costas_u0/dds_cos[5] ,
    \u_rf_rxt/costas_u0/dds_cos[4] ,
    \u_rf_rxt/costas_u0/dds_cos[3] ,
    \u_rf_rxt/costas_u0/dds_cos[2] ,
    \u_rf_rxt/costas_u0/dds_cos[1] ,
    \u_rf_rxt/costas_u0/dds_cos[0] ,
    \u_rf_rxt/costas_u0/dds_sin[11] ,
    \u_rf_rxt/costas_u0/dds_sin[10] ,
    \u_rf_rxt/costas_u0/dds_sin[9] ,
    \u_rf_rxt/costas_u0/dds_sin[8] ,
    \u_rf_rxt/costas_u0/dds_sin[7] ,
    \u_rf_rxt/costas_u0/dds_sin[6] ,
    \u_rf_rxt/costas_u0/dds_sin[5] ,
    \u_rf_rxt/costas_u0/dds_sin[4] ,
    \u_rf_rxt/costas_u0/dds_sin[3] ,
    \u_rf_rxt/costas_u0/dds_sin[2] ,
    \u_rf_rxt/costas_u0/dds_sin[1] ,
    \u_rf_rxt/costas_u0/dds_sin[0] ,
    \u_rf_rxt/costas_out_i_dbg[11] ,
    \u_rf_rxt/costas_out_i_dbg[10] ,
    \u_rf_rxt/costas_out_i_dbg[9] ,
    \u_rf_rxt/costas_out_i_dbg[8] ,
    \u_rf_rxt/costas_out_i_dbg[7] ,
    \u_rf_rxt/costas_out_i_dbg[6] ,
    \u_rf_rxt/costas_out_i_dbg[5] ,
    \u_rf_rxt/costas_out_i_dbg[4] ,
    \u_rf_rxt/costas_out_i_dbg[3] ,
    \u_rf_rxt/costas_out_i_dbg[2] ,
    \u_rf_rxt/costas_out_i_dbg[1] ,
    \u_rf_rxt/costas_out_i_dbg[0] ,
    \u_rf_rxt/costas_out_q_dbg[11] ,
    \u_rf_rxt/costas_out_q_dbg[10] ,
    \u_rf_rxt/costas_out_q_dbg[9] ,
    \u_rf_rxt/costas_out_q_dbg[8] ,
    \u_rf_rxt/costas_out_q_dbg[7] ,
    \u_rf_rxt/costas_out_q_dbg[6] ,
    \u_rf_rxt/costas_out_q_dbg[5] ,
    \u_rf_rxt/costas_out_q_dbg[4] ,
    \u_rf_rxt/costas_out_q_dbg[3] ,
    \u_rf_rxt/costas_out_q_dbg[2] ,
    \u_rf_rxt/costas_out_q_dbg[1] ,
    \u_rf_rxt/costas_out_q_dbg[0] ,
    \u_calibration/freq_out[23] ,
    \u_calibration/freq_out[22] ,
    \u_calibration/freq_out[21] ,
    \u_calibration/freq_out[20] ,
    \u_calibration/freq_out[19] ,
    \u_calibration/freq_out[18] ,
    \u_calibration/freq_out[17] ,
    \u_calibration/freq_out[16] ,
    \u_calibration/freq_out[15] ,
    \u_calibration/freq_out[14] ,
    \u_calibration/freq_out[13] ,
    \u_calibration/freq_out[12] ,
    \u_calibration/freq_out[11] ,
    \u_calibration/freq_out[10] ,
    \u_calibration/freq_out[9] ,
    \u_calibration/freq_out[8] ,
    \u_calibration/freq_out[7] ,
    \u_calibration/freq_out[6] ,
    \u_calibration/freq_out[5] ,
    \u_calibration/freq_out[4] ,
    \u_calibration/freq_out[3] ,
    \u_calibration/freq_out[2] ,
    \u_calibration/freq_out[1] ,
    \u_calibration/freq_out[0] ,
    \u_calibration/envelop[11] ,
    \u_calibration/envelop[10] ,
    \u_calibration/envelop[9] ,
    \u_calibration/envelop[8] ,
    \u_calibration/envelop[7] ,
    \u_calibration/envelop[6] ,
    \u_calibration/envelop[5] ,
    \u_calibration/envelop[4] ,
    \u_calibration/envelop[3] ,
    \u_calibration/envelop[2] ,
    \u_calibration/envelop[1] ,
    \u_calibration/envelop[0] ,
    \u_rf_data_depacketizer/pack_state[2] ,
    \u_rf_data_depacketizer/pack_state[1] ,
    \u_rf_data_depacketizer/pack_state[0] ,
    \eth_inst/gmii_rxdv ,
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
input \tx_data_in[7] ;
input \tx_data_in[6] ;
input \tx_data_in[5] ;
input \tx_data_in[4] ;
input \tx_data_in[3] ;
input \tx_data_in[2] ;
input \tx_data_in[1] ;
input \tx_data_in[0] ;
input rx_data_valid;
input tx_data_valid;
input tx_data_ready;
input \u_rf_rxt/tx_data_iq ;
input rx_data_out;
input \u_rf_rxt/demod_data ;
input \u_rf_rxt/decoded_data[1] ;
input \u_rf_rxt/decoded_data[0] ;
input \u_rf_rxt/bit_clk ;
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
input test_clk;
input \u_rf_rxt/costas_u0/sum_a[24] ;
input \u_rf_rxt/costas_u0/sum_a[23] ;
input \u_rf_rxt/costas_u0/sum_a[22] ;
input \u_rf_rxt/costas_u0/sum_a[21] ;
input \u_rf_rxt/costas_u0/sum_a[20] ;
input \u_rf_rxt/costas_u0/sum_a[19] ;
input \u_rf_rxt/costas_u0/sum_a[18] ;
input \u_rf_rxt/costas_u0/sum_a[17] ;
input \u_rf_rxt/costas_u0/sum_a[16] ;
input \u_rf_rxt/costas_u0/sum_a[15] ;
input \u_rf_rxt/costas_u0/sum_a[14] ;
input \u_rf_rxt/costas_u0/sum_a[13] ;
input \u_rf_rxt/costas_u0/sum_a[12] ;
input \u_rf_rxt/costas_u0/sum_a[11] ;
input \u_rf_rxt/costas_u0/sum_a[10] ;
input \u_rf_rxt/costas_u0/sum_a[9] ;
input \u_rf_rxt/costas_u0/sum_a[8] ;
input \u_rf_rxt/costas_u0/sum_a[7] ;
input \u_rf_rxt/costas_u0/sum_a[6] ;
input \u_rf_rxt/costas_u0/sum_a[5] ;
input \u_rf_rxt/costas_u0/sum_a[4] ;
input \u_rf_rxt/costas_u0/sum_a[3] ;
input \u_rf_rxt/costas_u0/sum_a[2] ;
input \u_rf_rxt/costas_u0/sum_a[1] ;
input \u_rf_rxt/costas_u0/sum_a[0] ;
input \u_rf_rxt/costas_u0/sum_b[24] ;
input \u_rf_rxt/costas_u0/sum_b[23] ;
input \u_rf_rxt/costas_u0/sum_b[22] ;
input \u_rf_rxt/costas_u0/sum_b[21] ;
input \u_rf_rxt/costas_u0/sum_b[20] ;
input \u_rf_rxt/costas_u0/sum_b[19] ;
input \u_rf_rxt/costas_u0/sum_b[18] ;
input \u_rf_rxt/costas_u0/sum_b[17] ;
input \u_rf_rxt/costas_u0/sum_b[16] ;
input \u_rf_rxt/costas_u0/sum_b[15] ;
input \u_rf_rxt/costas_u0/sum_b[14] ;
input \u_rf_rxt/costas_u0/sum_b[13] ;
input \u_rf_rxt/costas_u0/sum_b[12] ;
input \u_rf_rxt/costas_u0/sum_b[11] ;
input \u_rf_rxt/costas_u0/sum_b[10] ;
input \u_rf_rxt/costas_u0/sum_b[9] ;
input \u_rf_rxt/costas_u0/sum_b[8] ;
input \u_rf_rxt/costas_u0/sum_b[7] ;
input \u_rf_rxt/costas_u0/sum_b[6] ;
input \u_rf_rxt/costas_u0/sum_b[5] ;
input \u_rf_rxt/costas_u0/sum_b[4] ;
input \u_rf_rxt/costas_u0/sum_b[3] ;
input \u_rf_rxt/costas_u0/sum_b[2] ;
input \u_rf_rxt/costas_u0/sum_b[1] ;
input \u_rf_rxt/costas_u0/sum_b[0] ;
input \u_rf_rxt/costas_u0/loop_flt_in[25] ;
input \u_rf_rxt/costas_u0/loop_flt_in[24] ;
input \u_rf_rxt/costas_u0/loop_flt_in[23] ;
input \u_rf_rxt/costas_u0/loop_flt_in[22] ;
input \u_rf_rxt/costas_u0/loop_flt_in[21] ;
input \u_rf_rxt/costas_u0/loop_flt_in[20] ;
input \u_rf_rxt/costas_u0/loop_flt_in[19] ;
input \u_rf_rxt/costas_u0/loop_flt_in[18] ;
input \u_rf_rxt/costas_u0/loop_flt_in[17] ;
input \u_rf_rxt/costas_u0/loop_flt_in[16] ;
input \u_rf_rxt/costas_u0/loop_flt_in[15] ;
input \u_rf_rxt/costas_u0/loop_flt_in[14] ;
input \u_rf_rxt/costas_u0/loop_flt_in[13] ;
input \u_rf_rxt/costas_u0/loop_flt_in[12] ;
input \u_rf_rxt/costas_u0/loop_flt_in[11] ;
input \u_rf_rxt/costas_u0/loop_flt_in[10] ;
input \u_rf_rxt/costas_u0/loop_flt_in[9] ;
input \u_rf_rxt/costas_u0/loop_flt_in[8] ;
input \u_rf_rxt/costas_u0/loop_flt_in[7] ;
input \u_rf_rxt/costas_u0/loop_flt_in[6] ;
input \u_rf_rxt/costas_u0/loop_flt_in[5] ;
input \u_rf_rxt/costas_u0/loop_flt_in[4] ;
input \u_rf_rxt/costas_u0/loop_flt_in[3] ;
input \u_rf_rxt/costas_u0/loop_flt_in[2] ;
input \u_rf_rxt/costas_u0/loop_flt_in[1] ;
input \u_rf_rxt/costas_u0/loop_flt_in[0] ;
input \u_rf_rxt/costas_u0/pd[23] ;
input \u_rf_rxt/costas_u0/pd[22] ;
input \u_rf_rxt/costas_u0/pd[21] ;
input \u_rf_rxt/costas_u0/pd[20] ;
input \u_rf_rxt/costas_u0/pd[19] ;
input \u_rf_rxt/costas_u0/pd[18] ;
input \u_rf_rxt/costas_u0/pd[17] ;
input \u_rf_rxt/costas_u0/pd[16] ;
input \u_rf_rxt/costas_u0/pd[15] ;
input \u_rf_rxt/costas_u0/pd[14] ;
input \u_rf_rxt/costas_u0/pd[13] ;
input \u_rf_rxt/costas_u0/pd[12] ;
input \u_rf_rxt/costas_u0/pd[11] ;
input \u_rf_rxt/costas_u0/pd[10] ;
input \u_rf_rxt/costas_u0/pd[9] ;
input \u_rf_rxt/costas_u0/pd[8] ;
input \u_rf_rxt/costas_u0/pd[7] ;
input \u_rf_rxt/costas_u0/pd[6] ;
input \u_rf_rxt/costas_u0/pd[5] ;
input \u_rf_rxt/costas_u0/pd[4] ;
input \u_rf_rxt/costas_u0/pd[3] ;
input \u_rf_rxt/costas_u0/pd[2] ;
input \u_rf_rxt/costas_u0/pd[1] ;
input \u_rf_rxt/costas_u0/pd[0] ;
input \u_rf_rxt/costas_u0/dds_cos[11] ;
input \u_rf_rxt/costas_u0/dds_cos[10] ;
input \u_rf_rxt/costas_u0/dds_cos[9] ;
input \u_rf_rxt/costas_u0/dds_cos[8] ;
input \u_rf_rxt/costas_u0/dds_cos[7] ;
input \u_rf_rxt/costas_u0/dds_cos[6] ;
input \u_rf_rxt/costas_u0/dds_cos[5] ;
input \u_rf_rxt/costas_u0/dds_cos[4] ;
input \u_rf_rxt/costas_u0/dds_cos[3] ;
input \u_rf_rxt/costas_u0/dds_cos[2] ;
input \u_rf_rxt/costas_u0/dds_cos[1] ;
input \u_rf_rxt/costas_u0/dds_cos[0] ;
input \u_rf_rxt/costas_u0/dds_sin[11] ;
input \u_rf_rxt/costas_u0/dds_sin[10] ;
input \u_rf_rxt/costas_u0/dds_sin[9] ;
input \u_rf_rxt/costas_u0/dds_sin[8] ;
input \u_rf_rxt/costas_u0/dds_sin[7] ;
input \u_rf_rxt/costas_u0/dds_sin[6] ;
input \u_rf_rxt/costas_u0/dds_sin[5] ;
input \u_rf_rxt/costas_u0/dds_sin[4] ;
input \u_rf_rxt/costas_u0/dds_sin[3] ;
input \u_rf_rxt/costas_u0/dds_sin[2] ;
input \u_rf_rxt/costas_u0/dds_sin[1] ;
input \u_rf_rxt/costas_u0/dds_sin[0] ;
input \u_rf_rxt/costas_out_i_dbg[11] ;
input \u_rf_rxt/costas_out_i_dbg[10] ;
input \u_rf_rxt/costas_out_i_dbg[9] ;
input \u_rf_rxt/costas_out_i_dbg[8] ;
input \u_rf_rxt/costas_out_i_dbg[7] ;
input \u_rf_rxt/costas_out_i_dbg[6] ;
input \u_rf_rxt/costas_out_i_dbg[5] ;
input \u_rf_rxt/costas_out_i_dbg[4] ;
input \u_rf_rxt/costas_out_i_dbg[3] ;
input \u_rf_rxt/costas_out_i_dbg[2] ;
input \u_rf_rxt/costas_out_i_dbg[1] ;
input \u_rf_rxt/costas_out_i_dbg[0] ;
input \u_rf_rxt/costas_out_q_dbg[11] ;
input \u_rf_rxt/costas_out_q_dbg[10] ;
input \u_rf_rxt/costas_out_q_dbg[9] ;
input \u_rf_rxt/costas_out_q_dbg[8] ;
input \u_rf_rxt/costas_out_q_dbg[7] ;
input \u_rf_rxt/costas_out_q_dbg[6] ;
input \u_rf_rxt/costas_out_q_dbg[5] ;
input \u_rf_rxt/costas_out_q_dbg[4] ;
input \u_rf_rxt/costas_out_q_dbg[3] ;
input \u_rf_rxt/costas_out_q_dbg[2] ;
input \u_rf_rxt/costas_out_q_dbg[1] ;
input \u_rf_rxt/costas_out_q_dbg[0] ;
input \u_calibration/freq_out[23] ;
input \u_calibration/freq_out[22] ;
input \u_calibration/freq_out[21] ;
input \u_calibration/freq_out[20] ;
input \u_calibration/freq_out[19] ;
input \u_calibration/freq_out[18] ;
input \u_calibration/freq_out[17] ;
input \u_calibration/freq_out[16] ;
input \u_calibration/freq_out[15] ;
input \u_calibration/freq_out[14] ;
input \u_calibration/freq_out[13] ;
input \u_calibration/freq_out[12] ;
input \u_calibration/freq_out[11] ;
input \u_calibration/freq_out[10] ;
input \u_calibration/freq_out[9] ;
input \u_calibration/freq_out[8] ;
input \u_calibration/freq_out[7] ;
input \u_calibration/freq_out[6] ;
input \u_calibration/freq_out[5] ;
input \u_calibration/freq_out[4] ;
input \u_calibration/freq_out[3] ;
input \u_calibration/freq_out[2] ;
input \u_calibration/freq_out[1] ;
input \u_calibration/freq_out[0] ;
input \u_calibration/envelop[11] ;
input \u_calibration/envelop[10] ;
input \u_calibration/envelop[9] ;
input \u_calibration/envelop[8] ;
input \u_calibration/envelop[7] ;
input \u_calibration/envelop[6] ;
input \u_calibration/envelop[5] ;
input \u_calibration/envelop[4] ;
input \u_calibration/envelop[3] ;
input \u_calibration/envelop[2] ;
input \u_calibration/envelop[1] ;
input \u_calibration/envelop[0] ;
input \u_rf_data_depacketizer/pack_state[2] ;
input \u_rf_data_depacketizer/pack_state[1] ;
input \u_rf_data_depacketizer/pack_state[0] ;
input \eth_inst/gmii_rxdv ;
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
wire \tx_data_in[7] ;
wire \tx_data_in[6] ;
wire \tx_data_in[5] ;
wire \tx_data_in[4] ;
wire \tx_data_in[3] ;
wire \tx_data_in[2] ;
wire \tx_data_in[1] ;
wire \tx_data_in[0] ;
wire rx_data_valid;
wire tx_data_valid;
wire tx_data_ready;
wire \u_rf_rxt/tx_data_iq ;
wire rx_data_out;
wire \u_rf_rxt/demod_data ;
wire \u_rf_rxt/decoded_data[1] ;
wire \u_rf_rxt/decoded_data[0] ;
wire \u_rf_rxt/bit_clk ;
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
wire test_clk;
wire \u_rf_rxt/costas_u0/sum_a[24] ;
wire \u_rf_rxt/costas_u0/sum_a[23] ;
wire \u_rf_rxt/costas_u0/sum_a[22] ;
wire \u_rf_rxt/costas_u0/sum_a[21] ;
wire \u_rf_rxt/costas_u0/sum_a[20] ;
wire \u_rf_rxt/costas_u0/sum_a[19] ;
wire \u_rf_rxt/costas_u0/sum_a[18] ;
wire \u_rf_rxt/costas_u0/sum_a[17] ;
wire \u_rf_rxt/costas_u0/sum_a[16] ;
wire \u_rf_rxt/costas_u0/sum_a[15] ;
wire \u_rf_rxt/costas_u0/sum_a[14] ;
wire \u_rf_rxt/costas_u0/sum_a[13] ;
wire \u_rf_rxt/costas_u0/sum_a[12] ;
wire \u_rf_rxt/costas_u0/sum_a[11] ;
wire \u_rf_rxt/costas_u0/sum_a[10] ;
wire \u_rf_rxt/costas_u0/sum_a[9] ;
wire \u_rf_rxt/costas_u0/sum_a[8] ;
wire \u_rf_rxt/costas_u0/sum_a[7] ;
wire \u_rf_rxt/costas_u0/sum_a[6] ;
wire \u_rf_rxt/costas_u0/sum_a[5] ;
wire \u_rf_rxt/costas_u0/sum_a[4] ;
wire \u_rf_rxt/costas_u0/sum_a[3] ;
wire \u_rf_rxt/costas_u0/sum_a[2] ;
wire \u_rf_rxt/costas_u0/sum_a[1] ;
wire \u_rf_rxt/costas_u0/sum_a[0] ;
wire \u_rf_rxt/costas_u0/sum_b[24] ;
wire \u_rf_rxt/costas_u0/sum_b[23] ;
wire \u_rf_rxt/costas_u0/sum_b[22] ;
wire \u_rf_rxt/costas_u0/sum_b[21] ;
wire \u_rf_rxt/costas_u0/sum_b[20] ;
wire \u_rf_rxt/costas_u0/sum_b[19] ;
wire \u_rf_rxt/costas_u0/sum_b[18] ;
wire \u_rf_rxt/costas_u0/sum_b[17] ;
wire \u_rf_rxt/costas_u0/sum_b[16] ;
wire \u_rf_rxt/costas_u0/sum_b[15] ;
wire \u_rf_rxt/costas_u0/sum_b[14] ;
wire \u_rf_rxt/costas_u0/sum_b[13] ;
wire \u_rf_rxt/costas_u0/sum_b[12] ;
wire \u_rf_rxt/costas_u0/sum_b[11] ;
wire \u_rf_rxt/costas_u0/sum_b[10] ;
wire \u_rf_rxt/costas_u0/sum_b[9] ;
wire \u_rf_rxt/costas_u0/sum_b[8] ;
wire \u_rf_rxt/costas_u0/sum_b[7] ;
wire \u_rf_rxt/costas_u0/sum_b[6] ;
wire \u_rf_rxt/costas_u0/sum_b[5] ;
wire \u_rf_rxt/costas_u0/sum_b[4] ;
wire \u_rf_rxt/costas_u0/sum_b[3] ;
wire \u_rf_rxt/costas_u0/sum_b[2] ;
wire \u_rf_rxt/costas_u0/sum_b[1] ;
wire \u_rf_rxt/costas_u0/sum_b[0] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[25] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[24] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[23] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[22] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[21] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[20] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[19] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[18] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[17] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[16] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[15] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[14] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[13] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[12] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[11] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[10] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[9] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[8] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[7] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[6] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[5] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[4] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[3] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[2] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[1] ;
wire \u_rf_rxt/costas_u0/loop_flt_in[0] ;
wire \u_rf_rxt/costas_u0/pd[23] ;
wire \u_rf_rxt/costas_u0/pd[22] ;
wire \u_rf_rxt/costas_u0/pd[21] ;
wire \u_rf_rxt/costas_u0/pd[20] ;
wire \u_rf_rxt/costas_u0/pd[19] ;
wire \u_rf_rxt/costas_u0/pd[18] ;
wire \u_rf_rxt/costas_u0/pd[17] ;
wire \u_rf_rxt/costas_u0/pd[16] ;
wire \u_rf_rxt/costas_u0/pd[15] ;
wire \u_rf_rxt/costas_u0/pd[14] ;
wire \u_rf_rxt/costas_u0/pd[13] ;
wire \u_rf_rxt/costas_u0/pd[12] ;
wire \u_rf_rxt/costas_u0/pd[11] ;
wire \u_rf_rxt/costas_u0/pd[10] ;
wire \u_rf_rxt/costas_u0/pd[9] ;
wire \u_rf_rxt/costas_u0/pd[8] ;
wire \u_rf_rxt/costas_u0/pd[7] ;
wire \u_rf_rxt/costas_u0/pd[6] ;
wire \u_rf_rxt/costas_u0/pd[5] ;
wire \u_rf_rxt/costas_u0/pd[4] ;
wire \u_rf_rxt/costas_u0/pd[3] ;
wire \u_rf_rxt/costas_u0/pd[2] ;
wire \u_rf_rxt/costas_u0/pd[1] ;
wire \u_rf_rxt/costas_u0/pd[0] ;
wire \u_rf_rxt/costas_u0/dds_cos[11] ;
wire \u_rf_rxt/costas_u0/dds_cos[10] ;
wire \u_rf_rxt/costas_u0/dds_cos[9] ;
wire \u_rf_rxt/costas_u0/dds_cos[8] ;
wire \u_rf_rxt/costas_u0/dds_cos[7] ;
wire \u_rf_rxt/costas_u0/dds_cos[6] ;
wire \u_rf_rxt/costas_u0/dds_cos[5] ;
wire \u_rf_rxt/costas_u0/dds_cos[4] ;
wire \u_rf_rxt/costas_u0/dds_cos[3] ;
wire \u_rf_rxt/costas_u0/dds_cos[2] ;
wire \u_rf_rxt/costas_u0/dds_cos[1] ;
wire \u_rf_rxt/costas_u0/dds_cos[0] ;
wire \u_rf_rxt/costas_u0/dds_sin[11] ;
wire \u_rf_rxt/costas_u0/dds_sin[10] ;
wire \u_rf_rxt/costas_u0/dds_sin[9] ;
wire \u_rf_rxt/costas_u0/dds_sin[8] ;
wire \u_rf_rxt/costas_u0/dds_sin[7] ;
wire \u_rf_rxt/costas_u0/dds_sin[6] ;
wire \u_rf_rxt/costas_u0/dds_sin[5] ;
wire \u_rf_rxt/costas_u0/dds_sin[4] ;
wire \u_rf_rxt/costas_u0/dds_sin[3] ;
wire \u_rf_rxt/costas_u0/dds_sin[2] ;
wire \u_rf_rxt/costas_u0/dds_sin[1] ;
wire \u_rf_rxt/costas_u0/dds_sin[0] ;
wire \u_rf_rxt/costas_out_i_dbg[11] ;
wire \u_rf_rxt/costas_out_i_dbg[10] ;
wire \u_rf_rxt/costas_out_i_dbg[9] ;
wire \u_rf_rxt/costas_out_i_dbg[8] ;
wire \u_rf_rxt/costas_out_i_dbg[7] ;
wire \u_rf_rxt/costas_out_i_dbg[6] ;
wire \u_rf_rxt/costas_out_i_dbg[5] ;
wire \u_rf_rxt/costas_out_i_dbg[4] ;
wire \u_rf_rxt/costas_out_i_dbg[3] ;
wire \u_rf_rxt/costas_out_i_dbg[2] ;
wire \u_rf_rxt/costas_out_i_dbg[1] ;
wire \u_rf_rxt/costas_out_i_dbg[0] ;
wire \u_rf_rxt/costas_out_q_dbg[11] ;
wire \u_rf_rxt/costas_out_q_dbg[10] ;
wire \u_rf_rxt/costas_out_q_dbg[9] ;
wire \u_rf_rxt/costas_out_q_dbg[8] ;
wire \u_rf_rxt/costas_out_q_dbg[7] ;
wire \u_rf_rxt/costas_out_q_dbg[6] ;
wire \u_rf_rxt/costas_out_q_dbg[5] ;
wire \u_rf_rxt/costas_out_q_dbg[4] ;
wire \u_rf_rxt/costas_out_q_dbg[3] ;
wire \u_rf_rxt/costas_out_q_dbg[2] ;
wire \u_rf_rxt/costas_out_q_dbg[1] ;
wire \u_rf_rxt/costas_out_q_dbg[0] ;
wire \u_calibration/freq_out[23] ;
wire \u_calibration/freq_out[22] ;
wire \u_calibration/freq_out[21] ;
wire \u_calibration/freq_out[20] ;
wire \u_calibration/freq_out[19] ;
wire \u_calibration/freq_out[18] ;
wire \u_calibration/freq_out[17] ;
wire \u_calibration/freq_out[16] ;
wire \u_calibration/freq_out[15] ;
wire \u_calibration/freq_out[14] ;
wire \u_calibration/freq_out[13] ;
wire \u_calibration/freq_out[12] ;
wire \u_calibration/freq_out[11] ;
wire \u_calibration/freq_out[10] ;
wire \u_calibration/freq_out[9] ;
wire \u_calibration/freq_out[8] ;
wire \u_calibration/freq_out[7] ;
wire \u_calibration/freq_out[6] ;
wire \u_calibration/freq_out[5] ;
wire \u_calibration/freq_out[4] ;
wire \u_calibration/freq_out[3] ;
wire \u_calibration/freq_out[2] ;
wire \u_calibration/freq_out[1] ;
wire \u_calibration/freq_out[0] ;
wire \u_calibration/envelop[11] ;
wire \u_calibration/envelop[10] ;
wire \u_calibration/envelop[9] ;
wire \u_calibration/envelop[8] ;
wire \u_calibration/envelop[7] ;
wire \u_calibration/envelop[6] ;
wire \u_calibration/envelop[5] ;
wire \u_calibration/envelop[4] ;
wire \u_calibration/envelop[3] ;
wire \u_calibration/envelop[2] ;
wire \u_calibration/envelop[1] ;
wire \u_calibration/envelop[0] ;
wire \u_rf_data_depacketizer/pack_state[2] ;
wire \u_rf_data_depacketizer/pack_state[1] ;
wire \u_rf_data_depacketizer/pack_state[0] ;
wire \eth_inst/gmii_rxdv ;
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
    .trig0_i({\u_rf_data_depacketizer/pack_state[2] ,\u_rf_data_depacketizer/pack_state[1] ,\u_rf_data_depacketizer/pack_state[0] }),
    .trig1_i(tx_data_valid),
    .trig2_i(eth_rx_data_valid),
    .trig3_i(\eth_inst/gmii_rxdv ),
    .trig4_i({\u_rf_data_depacketizer/pack_state[2] ,\u_rf_data_depacketizer/pack_state[1] ,\u_rf_data_depacketizer/pack_state[0] }),
    .trig5_i(data_clk),
    .data_i({\adc_data_out_i1[11] ,\adc_data_out_i1[10] ,\adc_data_out_i1[9] ,\adc_data_out_i1[8] ,\adc_data_out_i1[7] ,\adc_data_out_i1[6] ,\adc_data_out_i1[5] ,\adc_data_out_i1[4] ,\adc_data_out_i1[3] ,\adc_data_out_i1[2] ,\adc_data_out_i1[1] ,\adc_data_out_i1[0] ,\adc_data_out_q1[11] ,\adc_data_out_q1[10] ,\adc_data_out_q1[9] ,\adc_data_out_q1[8] ,\adc_data_out_q1[7] ,\adc_data_out_q1[6] ,\adc_data_out_q1[5] ,\adc_data_out_q1[4] ,\adc_data_out_q1[3] ,\adc_data_out_q1[2] ,\adc_data_out_q1[1] ,\adc_data_out_q1[0] ,\dac_data_in_i1[11] ,\dac_data_in_i1[10] ,\dac_data_in_i1[9] ,\dac_data_in_i1[8] ,\dac_data_in_i1[7] ,\dac_data_in_i1[6] ,\dac_data_in_i1[5] ,\dac_data_in_i1[4] ,\dac_data_in_i1[3] ,\dac_data_in_i1[2] ,\dac_data_in_i1[1] ,\dac_data_in_i1[0] ,\dac_data_in_q1[11] ,\dac_data_in_q1[10] ,\dac_data_in_q1[9] ,\dac_data_in_q1[8] ,\dac_data_in_q1[7] ,\dac_data_in_q1[6] ,\dac_data_in_q1[5] ,\dac_data_in_q1[4] ,\dac_data_in_q1[3] ,\dac_data_in_q1[2] ,\dac_data_in_q1[1] ,\dac_data_in_q1[0] ,\tx_data_in[7] ,\tx_data_in[6] ,\tx_data_in[5] ,\tx_data_in[4] ,\tx_data_in[3] ,\tx_data_in[2] ,\tx_data_in[1] ,\tx_data_in[0] ,rx_data_valid,tx_data_valid,tx_data_ready,\u_rf_rxt/tx_data_iq ,rx_data_out,\u_rf_rxt/demod_data ,\u_rf_rxt/decoded_data[1] ,\u_rf_rxt/decoded_data[0] ,\u_rf_rxt/bit_clk ,\eth_rx_data[7] ,\eth_rx_data[6] ,\eth_rx_data[5] ,\eth_rx_data[4] ,\eth_rx_data[3] ,\eth_rx_data[2] ,\eth_rx_data[1] ,\eth_rx_data[0] ,eth_rx_frame_end,eth_rx_data_valid,test_clk,\u_rf_rxt/costas_u0/sum_a[24] ,\u_rf_rxt/costas_u0/sum_a[23] ,\u_rf_rxt/costas_u0/sum_a[22] ,\u_rf_rxt/costas_u0/sum_a[21] ,\u_rf_rxt/costas_u0/sum_a[20] ,\u_rf_rxt/costas_u0/sum_a[19] ,\u_rf_rxt/costas_u0/sum_a[18] ,\u_rf_rxt/costas_u0/sum_a[17] ,\u_rf_rxt/costas_u0/sum_a[16] ,\u_rf_rxt/costas_u0/sum_a[15] ,\u_rf_rxt/costas_u0/sum_a[14] ,\u_rf_rxt/costas_u0/sum_a[13] ,\u_rf_rxt/costas_u0/sum_a[12] ,\u_rf_rxt/costas_u0/sum_a[11] ,\u_rf_rxt/costas_u0/sum_a[10] ,\u_rf_rxt/costas_u0/sum_a[9] ,\u_rf_rxt/costas_u0/sum_a[8] ,\u_rf_rxt/costas_u0/sum_a[7] ,\u_rf_rxt/costas_u0/sum_a[6] ,\u_rf_rxt/costas_u0/sum_a[5] ,\u_rf_rxt/costas_u0/sum_a[4] ,\u_rf_rxt/costas_u0/sum_a[3] ,\u_rf_rxt/costas_u0/sum_a[2] ,\u_rf_rxt/costas_u0/sum_a[1] ,\u_rf_rxt/costas_u0/sum_a[0] ,\u_rf_rxt/costas_u0/sum_b[24] ,\u_rf_rxt/costas_u0/sum_b[23] ,\u_rf_rxt/costas_u0/sum_b[22] ,\u_rf_rxt/costas_u0/sum_b[21] ,\u_rf_rxt/costas_u0/sum_b[20] ,\u_rf_rxt/costas_u0/sum_b[19] ,\u_rf_rxt/costas_u0/sum_b[18] ,\u_rf_rxt/costas_u0/sum_b[17] ,\u_rf_rxt/costas_u0/sum_b[16] ,\u_rf_rxt/costas_u0/sum_b[15] ,\u_rf_rxt/costas_u0/sum_b[14] ,\u_rf_rxt/costas_u0/sum_b[13] ,\u_rf_rxt/costas_u0/sum_b[12] ,\u_rf_rxt/costas_u0/sum_b[11] ,\u_rf_rxt/costas_u0/sum_b[10] ,\u_rf_rxt/costas_u0/sum_b[9] ,\u_rf_rxt/costas_u0/sum_b[8] ,\u_rf_rxt/costas_u0/sum_b[7] ,\u_rf_rxt/costas_u0/sum_b[6] ,\u_rf_rxt/costas_u0/sum_b[5] ,\u_rf_rxt/costas_u0/sum_b[4] ,\u_rf_rxt/costas_u0/sum_b[3] ,\u_rf_rxt/costas_u0/sum_b[2] ,\u_rf_rxt/costas_u0/sum_b[1] ,\u_rf_rxt/costas_u0/sum_b[0] ,\u_rf_rxt/costas_u0/loop_flt_in[25] ,\u_rf_rxt/costas_u0/loop_flt_in[24] ,\u_rf_rxt/costas_u0/loop_flt_in[23] ,\u_rf_rxt/costas_u0/loop_flt_in[22] ,\u_rf_rxt/costas_u0/loop_flt_in[21] ,\u_rf_rxt/costas_u0/loop_flt_in[20] ,\u_rf_rxt/costas_u0/loop_flt_in[19] ,\u_rf_rxt/costas_u0/loop_flt_in[18] ,\u_rf_rxt/costas_u0/loop_flt_in[17] ,\u_rf_rxt/costas_u0/loop_flt_in[16] ,\u_rf_rxt/costas_u0/loop_flt_in[15] ,\u_rf_rxt/costas_u0/loop_flt_in[14] ,\u_rf_rxt/costas_u0/loop_flt_in[13] ,\u_rf_rxt/costas_u0/loop_flt_in[12] ,\u_rf_rxt/costas_u0/loop_flt_in[11] ,\u_rf_rxt/costas_u0/loop_flt_in[10] ,\u_rf_rxt/costas_u0/loop_flt_in[9] ,\u_rf_rxt/costas_u0/loop_flt_in[8] ,\u_rf_rxt/costas_u0/loop_flt_in[7] ,\u_rf_rxt/costas_u0/loop_flt_in[6] ,\u_rf_rxt/costas_u0/loop_flt_in[5] ,\u_rf_rxt/costas_u0/loop_flt_in[4] ,\u_rf_rxt/costas_u0/loop_flt_in[3] ,\u_rf_rxt/costas_u0/loop_flt_in[2] ,\u_rf_rxt/costas_u0/loop_flt_in[1] ,\u_rf_rxt/costas_u0/loop_flt_in[0] ,\u_rf_rxt/costas_u0/pd[23] ,\u_rf_rxt/costas_u0/pd[22] ,\u_rf_rxt/costas_u0/pd[21] ,\u_rf_rxt/costas_u0/pd[20] ,\u_rf_rxt/costas_u0/pd[19] ,\u_rf_rxt/costas_u0/pd[18] ,\u_rf_rxt/costas_u0/pd[17] ,\u_rf_rxt/costas_u0/pd[16] ,\u_rf_rxt/costas_u0/pd[15] ,\u_rf_rxt/costas_u0/pd[14] ,\u_rf_rxt/costas_u0/pd[13] ,\u_rf_rxt/costas_u0/pd[12] ,\u_rf_rxt/costas_u0/pd[11] ,\u_rf_rxt/costas_u0/pd[10] ,\u_rf_rxt/costas_u0/pd[9] ,\u_rf_rxt/costas_u0/pd[8] ,\u_rf_rxt/costas_u0/pd[7] ,\u_rf_rxt/costas_u0/pd[6] ,\u_rf_rxt/costas_u0/pd[5] ,\u_rf_rxt/costas_u0/pd[4] ,\u_rf_rxt/costas_u0/pd[3] ,\u_rf_rxt/costas_u0/pd[2] ,\u_rf_rxt/costas_u0/pd[1] ,\u_rf_rxt/costas_u0/pd[0] ,\u_rf_rxt/costas_u0/dds_cos[11] ,\u_rf_rxt/costas_u0/dds_cos[10] ,\u_rf_rxt/costas_u0/dds_cos[9] ,\u_rf_rxt/costas_u0/dds_cos[8] ,\u_rf_rxt/costas_u0/dds_cos[7] ,\u_rf_rxt/costas_u0/dds_cos[6] ,\u_rf_rxt/costas_u0/dds_cos[5] ,\u_rf_rxt/costas_u0/dds_cos[4] ,\u_rf_rxt/costas_u0/dds_cos[3] ,\u_rf_rxt/costas_u0/dds_cos[2] ,\u_rf_rxt/costas_u0/dds_cos[1] ,\u_rf_rxt/costas_u0/dds_cos[0] ,\u_rf_rxt/costas_u0/dds_sin[11] ,\u_rf_rxt/costas_u0/dds_sin[10] ,\u_rf_rxt/costas_u0/dds_sin[9] ,\u_rf_rxt/costas_u0/dds_sin[8] ,\u_rf_rxt/costas_u0/dds_sin[7] ,\u_rf_rxt/costas_u0/dds_sin[6] ,\u_rf_rxt/costas_u0/dds_sin[5] ,\u_rf_rxt/costas_u0/dds_sin[4] ,\u_rf_rxt/costas_u0/dds_sin[3] ,\u_rf_rxt/costas_u0/dds_sin[2] ,\u_rf_rxt/costas_u0/dds_sin[1] ,\u_rf_rxt/costas_u0/dds_sin[0] ,\u_rf_rxt/costas_out_i_dbg[11] ,\u_rf_rxt/costas_out_i_dbg[10] ,\u_rf_rxt/costas_out_i_dbg[9] ,\u_rf_rxt/costas_out_i_dbg[8] ,\u_rf_rxt/costas_out_i_dbg[7] ,\u_rf_rxt/costas_out_i_dbg[6] ,\u_rf_rxt/costas_out_i_dbg[5] ,\u_rf_rxt/costas_out_i_dbg[4] ,\u_rf_rxt/costas_out_i_dbg[3] ,\u_rf_rxt/costas_out_i_dbg[2] ,\u_rf_rxt/costas_out_i_dbg[1] ,\u_rf_rxt/costas_out_i_dbg[0] ,\u_rf_rxt/costas_out_q_dbg[11] ,\u_rf_rxt/costas_out_q_dbg[10] ,\u_rf_rxt/costas_out_q_dbg[9] ,\u_rf_rxt/costas_out_q_dbg[8] ,\u_rf_rxt/costas_out_q_dbg[7] ,\u_rf_rxt/costas_out_q_dbg[6] ,\u_rf_rxt/costas_out_q_dbg[5] ,\u_rf_rxt/costas_out_q_dbg[4] ,\u_rf_rxt/costas_out_q_dbg[3] ,\u_rf_rxt/costas_out_q_dbg[2] ,\u_rf_rxt/costas_out_q_dbg[1] ,\u_rf_rxt/costas_out_q_dbg[0] ,\u_calibration/freq_out[23] ,\u_calibration/freq_out[22] ,\u_calibration/freq_out[21] ,\u_calibration/freq_out[20] ,\u_calibration/freq_out[19] ,\u_calibration/freq_out[18] ,\u_calibration/freq_out[17] ,\u_calibration/freq_out[16] ,\u_calibration/freq_out[15] ,\u_calibration/freq_out[14] ,\u_calibration/freq_out[13] ,\u_calibration/freq_out[12] ,\u_calibration/freq_out[11] ,\u_calibration/freq_out[10] ,\u_calibration/freq_out[9] ,\u_calibration/freq_out[8] ,\u_calibration/freq_out[7] ,\u_calibration/freq_out[6] ,\u_calibration/freq_out[5] ,\u_calibration/freq_out[4] ,\u_calibration/freq_out[3] ,\u_calibration/freq_out[2] ,\u_calibration/freq_out[1] ,\u_calibration/freq_out[0] ,\u_calibration/envelop[11] ,\u_calibration/envelop[10] ,\u_calibration/envelop[9] ,\u_calibration/envelop[8] ,\u_calibration/envelop[7] ,\u_calibration/envelop[6] ,\u_calibration/envelop[5] ,\u_calibration/envelop[4] ,\u_calibration/envelop[3] ,\u_calibration/envelop[2] ,\u_calibration/envelop[1] ,\u_calibration/envelop[0] }),
    .clk_i(\u_rf_rxt/bit_clk )
);

endmodule
