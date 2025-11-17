module gw_gao(
    \fifo_wr_data[7] ,
    \fifo_wr_data[6] ,
    \fifo_wr_data[5] ,
    \fifo_wr_data[4] ,
    \fifo_wr_data[3] ,
    \fifo_wr_data[2] ,
    \fifo_wr_data[1] ,
    \fifo_wr_data[0] ,
    fifo_wr_almost_full,
    \fifo_rd_data[7] ,
    \fifo_rd_data[6] ,
    \fifo_rd_data[5] ,
    \fifo_rd_data[4] ,
    \fifo_rd_data[3] ,
    \fifo_rd_data[2] ,
    \fifo_rd_data[1] ,
    \fifo_rd_data[0] ,
    fifo_rd_empty,
    fifo_rd_almost_empty,
    fifo_rd_data_valid,
    \fifo_count[31] ,
    \fifo_count[30] ,
    \fifo_count[29] ,
    \fifo_count[28] ,
    \fifo_count[27] ,
    \fifo_count[26] ,
    \fifo_count[25] ,
    \fifo_count[24] ,
    \fifo_count[23] ,
    \fifo_count[22] ,
    \fifo_count[21] ,
    \fifo_count[20] ,
    \fifo_count[19] ,
    \fifo_count[18] ,
    \fifo_count[17] ,
    \fifo_count[16] ,
    \fifo_count[15] ,
    \fifo_count[14] ,
    \fifo_count[13] ,
    \fifo_count[12] ,
    \fifo_count[11] ,
    \fifo_count[10] ,
    \fifo_count[9] ,
    \fifo_count[8] ,
    \fifo_count[7] ,
    \fifo_count[6] ,
    \fifo_count[5] ,
    \fifo_count[4] ,
    \fifo_count[3] ,
    \fifo_count[2] ,
    \fifo_count[1] ,
    \fifo_count[0] ,
    \fifo_state[2] ,
    \fifo_state[1] ,
    \fifo_state[0] ,
    ddr_init_done,
    rst_n,
    \u_ddr3_fifo/state[2] ,
    \u_ddr3_fifo/state[1] ,
    \u_ddr3_fifo/state[0] ,
    \u_ddr3_fifo/wr_buffer_cnt[4] ,
    \u_ddr3_fifo/wr_buffer_cnt[3] ,
    \u_ddr3_fifo/wr_buffer_cnt[2] ,
    \u_ddr3_fifo/wr_buffer_cnt[1] ,
    \u_ddr3_fifo/wr_buffer_cnt[0] ,
    \u_ddr3_fifo/wr_req_fifo_wr ,
    \tx_state[2] ,
    \tx_state[1] ,
    \tx_state[0] ,
    \u_ddr3_fifo/rd_buffer_cnt[4] ,
    \u_ddr3_fifo/rd_buffer_cnt[3] ,
    \u_ddr3_fifo/rd_buffer_cnt[2] ,
    \u_ddr3_fifo/rd_buffer_cnt[1] ,
    \u_ddr3_fifo/rd_buffer_cnt[0] ,
    \u_ddr3_fifo/rd_buf_fifo_empty ,
    \u_ddr3_fifo/rd_empty ,
    \u_ddr3_fifo/rd_buffer_empty ,
    \u_ddr3_fifo/rd_buf_fifo_wr ,
    \u_ddr3_fifo/rd_buf_fifo_rd ,
    \u_ddr3_fifo/rd_buf_fifo_full ,
    \u_ddr3_fifo/rd_buf_fifo_count[8] ,
    \u_ddr3_fifo/rd_buf_fifo_count[7] ,
    \u_ddr3_fifo/rd_buf_fifo_count[6] ,
    \u_ddr3_fifo/rd_buf_fifo_count[5] ,
    \u_ddr3_fifo/rd_buf_fifo_count[4] ,
    \u_ddr3_fifo/rd_buf_fifo_count[3] ,
    \u_ddr3_fifo/rd_buf_fifo_count[2] ,
    \u_ddr3_fifo/rd_buf_fifo_count[1] ,
    \u_ddr3_fifo/rd_buf_fifo_count[0] ,
    \u_ddr3_fifo/rd_buf_fifo_almost_empty ,
    \u_ddr3_fifo/app_rd_data[127] ,
    \u_ddr3_fifo/app_rd_data[126] ,
    \u_ddr3_fifo/app_rd_data[125] ,
    \u_ddr3_fifo/app_rd_data[124] ,
    \u_ddr3_fifo/app_rd_data[123] ,
    \u_ddr3_fifo/app_rd_data[122] ,
    \u_ddr3_fifo/app_rd_data[121] ,
    \u_ddr3_fifo/app_rd_data[120] ,
    \u_ddr3_fifo/app_rd_data[119] ,
    \u_ddr3_fifo/app_rd_data[118] ,
    \u_ddr3_fifo/app_rd_data[117] ,
    \u_ddr3_fifo/app_rd_data[116] ,
    \u_ddr3_fifo/app_rd_data[115] ,
    \u_ddr3_fifo/app_rd_data[114] ,
    \u_ddr3_fifo/app_rd_data[113] ,
    \u_ddr3_fifo/app_rd_data[112] ,
    \u_ddr3_fifo/app_rd_data[111] ,
    \u_ddr3_fifo/app_rd_data[110] ,
    \u_ddr3_fifo/app_rd_data[109] ,
    \u_ddr3_fifo/app_rd_data[108] ,
    \u_ddr3_fifo/app_rd_data[107] ,
    \u_ddr3_fifo/app_rd_data[106] ,
    \u_ddr3_fifo/app_rd_data[105] ,
    \u_ddr3_fifo/app_rd_data[104] ,
    \u_ddr3_fifo/app_rd_data[103] ,
    \u_ddr3_fifo/app_rd_data[102] ,
    \u_ddr3_fifo/app_rd_data[101] ,
    \u_ddr3_fifo/app_rd_data[100] ,
    \u_ddr3_fifo/app_rd_data[99] ,
    \u_ddr3_fifo/app_rd_data[98] ,
    \u_ddr3_fifo/app_rd_data[97] ,
    \u_ddr3_fifo/app_rd_data[96] ,
    \u_ddr3_fifo/app_rd_data[95] ,
    \u_ddr3_fifo/app_rd_data[94] ,
    \u_ddr3_fifo/app_rd_data[93] ,
    \u_ddr3_fifo/app_rd_data[92] ,
    \u_ddr3_fifo/app_rd_data[91] ,
    \u_ddr3_fifo/app_rd_data[90] ,
    \u_ddr3_fifo/app_rd_data[89] ,
    \u_ddr3_fifo/app_rd_data[88] ,
    \u_ddr3_fifo/app_rd_data[87] ,
    \u_ddr3_fifo/app_rd_data[86] ,
    \u_ddr3_fifo/app_rd_data[85] ,
    \u_ddr3_fifo/app_rd_data[84] ,
    \u_ddr3_fifo/app_rd_data[83] ,
    \u_ddr3_fifo/app_rd_data[82] ,
    \u_ddr3_fifo/app_rd_data[81] ,
    \u_ddr3_fifo/app_rd_data[80] ,
    \u_ddr3_fifo/app_rd_data[79] ,
    \u_ddr3_fifo/app_rd_data[78] ,
    \u_ddr3_fifo/app_rd_data[77] ,
    \u_ddr3_fifo/app_rd_data[76] ,
    \u_ddr3_fifo/app_rd_data[75] ,
    \u_ddr3_fifo/app_rd_data[74] ,
    \u_ddr3_fifo/app_rd_data[73] ,
    \u_ddr3_fifo/app_rd_data[72] ,
    \u_ddr3_fifo/app_rd_data[71] ,
    \u_ddr3_fifo/app_rd_data[70] ,
    \u_ddr3_fifo/app_rd_data[69] ,
    \u_ddr3_fifo/app_rd_data[68] ,
    \u_ddr3_fifo/app_rd_data[67] ,
    \u_ddr3_fifo/app_rd_data[66] ,
    \u_ddr3_fifo/app_rd_data[65] ,
    \u_ddr3_fifo/app_rd_data[64] ,
    \u_ddr3_fifo/app_rd_data[63] ,
    \u_ddr3_fifo/app_rd_data[62] ,
    \u_ddr3_fifo/app_rd_data[61] ,
    \u_ddr3_fifo/app_rd_data[60] ,
    \u_ddr3_fifo/app_rd_data[59] ,
    \u_ddr3_fifo/app_rd_data[58] ,
    \u_ddr3_fifo/app_rd_data[57] ,
    \u_ddr3_fifo/app_rd_data[56] ,
    \u_ddr3_fifo/app_rd_data[55] ,
    \u_ddr3_fifo/app_rd_data[54] ,
    \u_ddr3_fifo/app_rd_data[53] ,
    \u_ddr3_fifo/app_rd_data[52] ,
    \u_ddr3_fifo/app_rd_data[51] ,
    \u_ddr3_fifo/app_rd_data[50] ,
    \u_ddr3_fifo/app_rd_data[49] ,
    \u_ddr3_fifo/app_rd_data[48] ,
    \u_ddr3_fifo/app_rd_data[47] ,
    \u_ddr3_fifo/app_rd_data[46] ,
    \u_ddr3_fifo/app_rd_data[45] ,
    \u_ddr3_fifo/app_rd_data[44] ,
    \u_ddr3_fifo/app_rd_data[43] ,
    \u_ddr3_fifo/app_rd_data[42] ,
    \u_ddr3_fifo/app_rd_data[41] ,
    \u_ddr3_fifo/app_rd_data[40] ,
    \u_ddr3_fifo/app_rd_data[39] ,
    \u_ddr3_fifo/app_rd_data[38] ,
    \u_ddr3_fifo/app_rd_data[37] ,
    \u_ddr3_fifo/app_rd_data[36] ,
    \u_ddr3_fifo/app_rd_data[35] ,
    \u_ddr3_fifo/app_rd_data[34] ,
    \u_ddr3_fifo/app_rd_data[33] ,
    \u_ddr3_fifo/app_rd_data[32] ,
    \u_ddr3_fifo/app_rd_data[31] ,
    \u_ddr3_fifo/app_rd_data[30] ,
    \u_ddr3_fifo/app_rd_data[29] ,
    \u_ddr3_fifo/app_rd_data[28] ,
    \u_ddr3_fifo/app_rd_data[27] ,
    \u_ddr3_fifo/app_rd_data[26] ,
    \u_ddr3_fifo/app_rd_data[25] ,
    \u_ddr3_fifo/app_rd_data[24] ,
    \u_ddr3_fifo/app_rd_data[23] ,
    \u_ddr3_fifo/app_rd_data[22] ,
    \u_ddr3_fifo/app_rd_data[21] ,
    \u_ddr3_fifo/app_rd_data[20] ,
    \u_ddr3_fifo/app_rd_data[19] ,
    \u_ddr3_fifo/app_rd_data[18] ,
    \u_ddr3_fifo/app_rd_data[17] ,
    \u_ddr3_fifo/app_rd_data[16] ,
    \u_ddr3_fifo/app_rd_data[15] ,
    \u_ddr3_fifo/app_rd_data[14] ,
    \u_ddr3_fifo/app_rd_data[13] ,
    \u_ddr3_fifo/app_rd_data[12] ,
    \u_ddr3_fifo/app_rd_data[11] ,
    \u_ddr3_fifo/app_rd_data[10] ,
    \u_ddr3_fifo/app_rd_data[9] ,
    \u_ddr3_fifo/app_rd_data[8] ,
    \u_ddr3_fifo/app_rd_data[7] ,
    \u_ddr3_fifo/app_rd_data[6] ,
    \u_ddr3_fifo/app_rd_data[5] ,
    \u_ddr3_fifo/app_rd_data[4] ,
    \u_ddr3_fifo/app_rd_data[3] ,
    \u_ddr3_fifo/app_rd_data[2] ,
    \u_ddr3_fifo/app_rd_data[1] ,
    \u_ddr3_fifo/app_rd_data[0] ,
    \u_ddr3_fifo/app_rd_data_valid ,
    \eth_tx_data[7] ,
    \eth_tx_data[6] ,
    \eth_tx_data[5] ,
    \eth_tx_data[4] ,
    \eth_tx_data[3] ,
    \eth_tx_data[2] ,
    \eth_tx_data[1] ,
    \eth_tx_data[0] ,
    eth_tx_data_valid,
    eth_tx_ready,
    eth_tx_frame_start,
    fifo_rd_en,
    fifo_wr_en,
    \u_ddr3_fifo/wr_buffer_full ,
    eth_rx_data_valid,
    RGMII_GTXCLK,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \fifo_wr_data[7] ;
input \fifo_wr_data[6] ;
input \fifo_wr_data[5] ;
input \fifo_wr_data[4] ;
input \fifo_wr_data[3] ;
input \fifo_wr_data[2] ;
input \fifo_wr_data[1] ;
input \fifo_wr_data[0] ;
input fifo_wr_almost_full;
input \fifo_rd_data[7] ;
input \fifo_rd_data[6] ;
input \fifo_rd_data[5] ;
input \fifo_rd_data[4] ;
input \fifo_rd_data[3] ;
input \fifo_rd_data[2] ;
input \fifo_rd_data[1] ;
input \fifo_rd_data[0] ;
input fifo_rd_empty;
input fifo_rd_almost_empty;
input fifo_rd_data_valid;
input \fifo_count[31] ;
input \fifo_count[30] ;
input \fifo_count[29] ;
input \fifo_count[28] ;
input \fifo_count[27] ;
input \fifo_count[26] ;
input \fifo_count[25] ;
input \fifo_count[24] ;
input \fifo_count[23] ;
input \fifo_count[22] ;
input \fifo_count[21] ;
input \fifo_count[20] ;
input \fifo_count[19] ;
input \fifo_count[18] ;
input \fifo_count[17] ;
input \fifo_count[16] ;
input \fifo_count[15] ;
input \fifo_count[14] ;
input \fifo_count[13] ;
input \fifo_count[12] ;
input \fifo_count[11] ;
input \fifo_count[10] ;
input \fifo_count[9] ;
input \fifo_count[8] ;
input \fifo_count[7] ;
input \fifo_count[6] ;
input \fifo_count[5] ;
input \fifo_count[4] ;
input \fifo_count[3] ;
input \fifo_count[2] ;
input \fifo_count[1] ;
input \fifo_count[0] ;
input \fifo_state[2] ;
input \fifo_state[1] ;
input \fifo_state[0] ;
input ddr_init_done;
input rst_n;
input \u_ddr3_fifo/state[2] ;
input \u_ddr3_fifo/state[1] ;
input \u_ddr3_fifo/state[0] ;
input \u_ddr3_fifo/wr_buffer_cnt[4] ;
input \u_ddr3_fifo/wr_buffer_cnt[3] ;
input \u_ddr3_fifo/wr_buffer_cnt[2] ;
input \u_ddr3_fifo/wr_buffer_cnt[1] ;
input \u_ddr3_fifo/wr_buffer_cnt[0] ;
input \u_ddr3_fifo/wr_req_fifo_wr ;
input \tx_state[2] ;
input \tx_state[1] ;
input \tx_state[0] ;
input \u_ddr3_fifo/rd_buffer_cnt[4] ;
input \u_ddr3_fifo/rd_buffer_cnt[3] ;
input \u_ddr3_fifo/rd_buffer_cnt[2] ;
input \u_ddr3_fifo/rd_buffer_cnt[1] ;
input \u_ddr3_fifo/rd_buffer_cnt[0] ;
input \u_ddr3_fifo/rd_buf_fifo_empty ;
input \u_ddr3_fifo/rd_empty ;
input \u_ddr3_fifo/rd_buffer_empty ;
input \u_ddr3_fifo/rd_buf_fifo_wr ;
input \u_ddr3_fifo/rd_buf_fifo_rd ;
input \u_ddr3_fifo/rd_buf_fifo_full ;
input \u_ddr3_fifo/rd_buf_fifo_count[8] ;
input \u_ddr3_fifo/rd_buf_fifo_count[7] ;
input \u_ddr3_fifo/rd_buf_fifo_count[6] ;
input \u_ddr3_fifo/rd_buf_fifo_count[5] ;
input \u_ddr3_fifo/rd_buf_fifo_count[4] ;
input \u_ddr3_fifo/rd_buf_fifo_count[3] ;
input \u_ddr3_fifo/rd_buf_fifo_count[2] ;
input \u_ddr3_fifo/rd_buf_fifo_count[1] ;
input \u_ddr3_fifo/rd_buf_fifo_count[0] ;
input \u_ddr3_fifo/rd_buf_fifo_almost_empty ;
input \u_ddr3_fifo/app_rd_data[127] ;
input \u_ddr3_fifo/app_rd_data[126] ;
input \u_ddr3_fifo/app_rd_data[125] ;
input \u_ddr3_fifo/app_rd_data[124] ;
input \u_ddr3_fifo/app_rd_data[123] ;
input \u_ddr3_fifo/app_rd_data[122] ;
input \u_ddr3_fifo/app_rd_data[121] ;
input \u_ddr3_fifo/app_rd_data[120] ;
input \u_ddr3_fifo/app_rd_data[119] ;
input \u_ddr3_fifo/app_rd_data[118] ;
input \u_ddr3_fifo/app_rd_data[117] ;
input \u_ddr3_fifo/app_rd_data[116] ;
input \u_ddr3_fifo/app_rd_data[115] ;
input \u_ddr3_fifo/app_rd_data[114] ;
input \u_ddr3_fifo/app_rd_data[113] ;
input \u_ddr3_fifo/app_rd_data[112] ;
input \u_ddr3_fifo/app_rd_data[111] ;
input \u_ddr3_fifo/app_rd_data[110] ;
input \u_ddr3_fifo/app_rd_data[109] ;
input \u_ddr3_fifo/app_rd_data[108] ;
input \u_ddr3_fifo/app_rd_data[107] ;
input \u_ddr3_fifo/app_rd_data[106] ;
input \u_ddr3_fifo/app_rd_data[105] ;
input \u_ddr3_fifo/app_rd_data[104] ;
input \u_ddr3_fifo/app_rd_data[103] ;
input \u_ddr3_fifo/app_rd_data[102] ;
input \u_ddr3_fifo/app_rd_data[101] ;
input \u_ddr3_fifo/app_rd_data[100] ;
input \u_ddr3_fifo/app_rd_data[99] ;
input \u_ddr3_fifo/app_rd_data[98] ;
input \u_ddr3_fifo/app_rd_data[97] ;
input \u_ddr3_fifo/app_rd_data[96] ;
input \u_ddr3_fifo/app_rd_data[95] ;
input \u_ddr3_fifo/app_rd_data[94] ;
input \u_ddr3_fifo/app_rd_data[93] ;
input \u_ddr3_fifo/app_rd_data[92] ;
input \u_ddr3_fifo/app_rd_data[91] ;
input \u_ddr3_fifo/app_rd_data[90] ;
input \u_ddr3_fifo/app_rd_data[89] ;
input \u_ddr3_fifo/app_rd_data[88] ;
input \u_ddr3_fifo/app_rd_data[87] ;
input \u_ddr3_fifo/app_rd_data[86] ;
input \u_ddr3_fifo/app_rd_data[85] ;
input \u_ddr3_fifo/app_rd_data[84] ;
input \u_ddr3_fifo/app_rd_data[83] ;
input \u_ddr3_fifo/app_rd_data[82] ;
input \u_ddr3_fifo/app_rd_data[81] ;
input \u_ddr3_fifo/app_rd_data[80] ;
input \u_ddr3_fifo/app_rd_data[79] ;
input \u_ddr3_fifo/app_rd_data[78] ;
input \u_ddr3_fifo/app_rd_data[77] ;
input \u_ddr3_fifo/app_rd_data[76] ;
input \u_ddr3_fifo/app_rd_data[75] ;
input \u_ddr3_fifo/app_rd_data[74] ;
input \u_ddr3_fifo/app_rd_data[73] ;
input \u_ddr3_fifo/app_rd_data[72] ;
input \u_ddr3_fifo/app_rd_data[71] ;
input \u_ddr3_fifo/app_rd_data[70] ;
input \u_ddr3_fifo/app_rd_data[69] ;
input \u_ddr3_fifo/app_rd_data[68] ;
input \u_ddr3_fifo/app_rd_data[67] ;
input \u_ddr3_fifo/app_rd_data[66] ;
input \u_ddr3_fifo/app_rd_data[65] ;
input \u_ddr3_fifo/app_rd_data[64] ;
input \u_ddr3_fifo/app_rd_data[63] ;
input \u_ddr3_fifo/app_rd_data[62] ;
input \u_ddr3_fifo/app_rd_data[61] ;
input \u_ddr3_fifo/app_rd_data[60] ;
input \u_ddr3_fifo/app_rd_data[59] ;
input \u_ddr3_fifo/app_rd_data[58] ;
input \u_ddr3_fifo/app_rd_data[57] ;
input \u_ddr3_fifo/app_rd_data[56] ;
input \u_ddr3_fifo/app_rd_data[55] ;
input \u_ddr3_fifo/app_rd_data[54] ;
input \u_ddr3_fifo/app_rd_data[53] ;
input \u_ddr3_fifo/app_rd_data[52] ;
input \u_ddr3_fifo/app_rd_data[51] ;
input \u_ddr3_fifo/app_rd_data[50] ;
input \u_ddr3_fifo/app_rd_data[49] ;
input \u_ddr3_fifo/app_rd_data[48] ;
input \u_ddr3_fifo/app_rd_data[47] ;
input \u_ddr3_fifo/app_rd_data[46] ;
input \u_ddr3_fifo/app_rd_data[45] ;
input \u_ddr3_fifo/app_rd_data[44] ;
input \u_ddr3_fifo/app_rd_data[43] ;
input \u_ddr3_fifo/app_rd_data[42] ;
input \u_ddr3_fifo/app_rd_data[41] ;
input \u_ddr3_fifo/app_rd_data[40] ;
input \u_ddr3_fifo/app_rd_data[39] ;
input \u_ddr3_fifo/app_rd_data[38] ;
input \u_ddr3_fifo/app_rd_data[37] ;
input \u_ddr3_fifo/app_rd_data[36] ;
input \u_ddr3_fifo/app_rd_data[35] ;
input \u_ddr3_fifo/app_rd_data[34] ;
input \u_ddr3_fifo/app_rd_data[33] ;
input \u_ddr3_fifo/app_rd_data[32] ;
input \u_ddr3_fifo/app_rd_data[31] ;
input \u_ddr3_fifo/app_rd_data[30] ;
input \u_ddr3_fifo/app_rd_data[29] ;
input \u_ddr3_fifo/app_rd_data[28] ;
input \u_ddr3_fifo/app_rd_data[27] ;
input \u_ddr3_fifo/app_rd_data[26] ;
input \u_ddr3_fifo/app_rd_data[25] ;
input \u_ddr3_fifo/app_rd_data[24] ;
input \u_ddr3_fifo/app_rd_data[23] ;
input \u_ddr3_fifo/app_rd_data[22] ;
input \u_ddr3_fifo/app_rd_data[21] ;
input \u_ddr3_fifo/app_rd_data[20] ;
input \u_ddr3_fifo/app_rd_data[19] ;
input \u_ddr3_fifo/app_rd_data[18] ;
input \u_ddr3_fifo/app_rd_data[17] ;
input \u_ddr3_fifo/app_rd_data[16] ;
input \u_ddr3_fifo/app_rd_data[15] ;
input \u_ddr3_fifo/app_rd_data[14] ;
input \u_ddr3_fifo/app_rd_data[13] ;
input \u_ddr3_fifo/app_rd_data[12] ;
input \u_ddr3_fifo/app_rd_data[11] ;
input \u_ddr3_fifo/app_rd_data[10] ;
input \u_ddr3_fifo/app_rd_data[9] ;
input \u_ddr3_fifo/app_rd_data[8] ;
input \u_ddr3_fifo/app_rd_data[7] ;
input \u_ddr3_fifo/app_rd_data[6] ;
input \u_ddr3_fifo/app_rd_data[5] ;
input \u_ddr3_fifo/app_rd_data[4] ;
input \u_ddr3_fifo/app_rd_data[3] ;
input \u_ddr3_fifo/app_rd_data[2] ;
input \u_ddr3_fifo/app_rd_data[1] ;
input \u_ddr3_fifo/app_rd_data[0] ;
input \u_ddr3_fifo/app_rd_data_valid ;
input \eth_tx_data[7] ;
input \eth_tx_data[6] ;
input \eth_tx_data[5] ;
input \eth_tx_data[4] ;
input \eth_tx_data[3] ;
input \eth_tx_data[2] ;
input \eth_tx_data[1] ;
input \eth_tx_data[0] ;
input eth_tx_data_valid;
input eth_tx_ready;
input eth_tx_frame_start;
input fifo_rd_en;
input fifo_wr_en;
input \u_ddr3_fifo/wr_buffer_full ;
input eth_rx_data_valid;
input RGMII_GTXCLK;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \fifo_wr_data[7] ;
wire \fifo_wr_data[6] ;
wire \fifo_wr_data[5] ;
wire \fifo_wr_data[4] ;
wire \fifo_wr_data[3] ;
wire \fifo_wr_data[2] ;
wire \fifo_wr_data[1] ;
wire \fifo_wr_data[0] ;
wire fifo_wr_almost_full;
wire \fifo_rd_data[7] ;
wire \fifo_rd_data[6] ;
wire \fifo_rd_data[5] ;
wire \fifo_rd_data[4] ;
wire \fifo_rd_data[3] ;
wire \fifo_rd_data[2] ;
wire \fifo_rd_data[1] ;
wire \fifo_rd_data[0] ;
wire fifo_rd_empty;
wire fifo_rd_almost_empty;
wire fifo_rd_data_valid;
wire \fifo_count[31] ;
wire \fifo_count[30] ;
wire \fifo_count[29] ;
wire \fifo_count[28] ;
wire \fifo_count[27] ;
wire \fifo_count[26] ;
wire \fifo_count[25] ;
wire \fifo_count[24] ;
wire \fifo_count[23] ;
wire \fifo_count[22] ;
wire \fifo_count[21] ;
wire \fifo_count[20] ;
wire \fifo_count[19] ;
wire \fifo_count[18] ;
wire \fifo_count[17] ;
wire \fifo_count[16] ;
wire \fifo_count[15] ;
wire \fifo_count[14] ;
wire \fifo_count[13] ;
wire \fifo_count[12] ;
wire \fifo_count[11] ;
wire \fifo_count[10] ;
wire \fifo_count[9] ;
wire \fifo_count[8] ;
wire \fifo_count[7] ;
wire \fifo_count[6] ;
wire \fifo_count[5] ;
wire \fifo_count[4] ;
wire \fifo_count[3] ;
wire \fifo_count[2] ;
wire \fifo_count[1] ;
wire \fifo_count[0] ;
wire \fifo_state[2] ;
wire \fifo_state[1] ;
wire \fifo_state[0] ;
wire ddr_init_done;
wire rst_n;
wire \u_ddr3_fifo/state[2] ;
wire \u_ddr3_fifo/state[1] ;
wire \u_ddr3_fifo/state[0] ;
wire \u_ddr3_fifo/wr_buffer_cnt[4] ;
wire \u_ddr3_fifo/wr_buffer_cnt[3] ;
wire \u_ddr3_fifo/wr_buffer_cnt[2] ;
wire \u_ddr3_fifo/wr_buffer_cnt[1] ;
wire \u_ddr3_fifo/wr_buffer_cnt[0] ;
wire \u_ddr3_fifo/wr_req_fifo_wr ;
wire \tx_state[2] ;
wire \tx_state[1] ;
wire \tx_state[0] ;
wire \u_ddr3_fifo/rd_buffer_cnt[4] ;
wire \u_ddr3_fifo/rd_buffer_cnt[3] ;
wire \u_ddr3_fifo/rd_buffer_cnt[2] ;
wire \u_ddr3_fifo/rd_buffer_cnt[1] ;
wire \u_ddr3_fifo/rd_buffer_cnt[0] ;
wire \u_ddr3_fifo/rd_buf_fifo_empty ;
wire \u_ddr3_fifo/rd_empty ;
wire \u_ddr3_fifo/rd_buffer_empty ;
wire \u_ddr3_fifo/rd_buf_fifo_wr ;
wire \u_ddr3_fifo/rd_buf_fifo_rd ;
wire \u_ddr3_fifo/rd_buf_fifo_full ;
wire \u_ddr3_fifo/rd_buf_fifo_count[8] ;
wire \u_ddr3_fifo/rd_buf_fifo_count[7] ;
wire \u_ddr3_fifo/rd_buf_fifo_count[6] ;
wire \u_ddr3_fifo/rd_buf_fifo_count[5] ;
wire \u_ddr3_fifo/rd_buf_fifo_count[4] ;
wire \u_ddr3_fifo/rd_buf_fifo_count[3] ;
wire \u_ddr3_fifo/rd_buf_fifo_count[2] ;
wire \u_ddr3_fifo/rd_buf_fifo_count[1] ;
wire \u_ddr3_fifo/rd_buf_fifo_count[0] ;
wire \u_ddr3_fifo/rd_buf_fifo_almost_empty ;
wire \u_ddr3_fifo/app_rd_data[127] ;
wire \u_ddr3_fifo/app_rd_data[126] ;
wire \u_ddr3_fifo/app_rd_data[125] ;
wire \u_ddr3_fifo/app_rd_data[124] ;
wire \u_ddr3_fifo/app_rd_data[123] ;
wire \u_ddr3_fifo/app_rd_data[122] ;
wire \u_ddr3_fifo/app_rd_data[121] ;
wire \u_ddr3_fifo/app_rd_data[120] ;
wire \u_ddr3_fifo/app_rd_data[119] ;
wire \u_ddr3_fifo/app_rd_data[118] ;
wire \u_ddr3_fifo/app_rd_data[117] ;
wire \u_ddr3_fifo/app_rd_data[116] ;
wire \u_ddr3_fifo/app_rd_data[115] ;
wire \u_ddr3_fifo/app_rd_data[114] ;
wire \u_ddr3_fifo/app_rd_data[113] ;
wire \u_ddr3_fifo/app_rd_data[112] ;
wire \u_ddr3_fifo/app_rd_data[111] ;
wire \u_ddr3_fifo/app_rd_data[110] ;
wire \u_ddr3_fifo/app_rd_data[109] ;
wire \u_ddr3_fifo/app_rd_data[108] ;
wire \u_ddr3_fifo/app_rd_data[107] ;
wire \u_ddr3_fifo/app_rd_data[106] ;
wire \u_ddr3_fifo/app_rd_data[105] ;
wire \u_ddr3_fifo/app_rd_data[104] ;
wire \u_ddr3_fifo/app_rd_data[103] ;
wire \u_ddr3_fifo/app_rd_data[102] ;
wire \u_ddr3_fifo/app_rd_data[101] ;
wire \u_ddr3_fifo/app_rd_data[100] ;
wire \u_ddr3_fifo/app_rd_data[99] ;
wire \u_ddr3_fifo/app_rd_data[98] ;
wire \u_ddr3_fifo/app_rd_data[97] ;
wire \u_ddr3_fifo/app_rd_data[96] ;
wire \u_ddr3_fifo/app_rd_data[95] ;
wire \u_ddr3_fifo/app_rd_data[94] ;
wire \u_ddr3_fifo/app_rd_data[93] ;
wire \u_ddr3_fifo/app_rd_data[92] ;
wire \u_ddr3_fifo/app_rd_data[91] ;
wire \u_ddr3_fifo/app_rd_data[90] ;
wire \u_ddr3_fifo/app_rd_data[89] ;
wire \u_ddr3_fifo/app_rd_data[88] ;
wire \u_ddr3_fifo/app_rd_data[87] ;
wire \u_ddr3_fifo/app_rd_data[86] ;
wire \u_ddr3_fifo/app_rd_data[85] ;
wire \u_ddr3_fifo/app_rd_data[84] ;
wire \u_ddr3_fifo/app_rd_data[83] ;
wire \u_ddr3_fifo/app_rd_data[82] ;
wire \u_ddr3_fifo/app_rd_data[81] ;
wire \u_ddr3_fifo/app_rd_data[80] ;
wire \u_ddr3_fifo/app_rd_data[79] ;
wire \u_ddr3_fifo/app_rd_data[78] ;
wire \u_ddr3_fifo/app_rd_data[77] ;
wire \u_ddr3_fifo/app_rd_data[76] ;
wire \u_ddr3_fifo/app_rd_data[75] ;
wire \u_ddr3_fifo/app_rd_data[74] ;
wire \u_ddr3_fifo/app_rd_data[73] ;
wire \u_ddr3_fifo/app_rd_data[72] ;
wire \u_ddr3_fifo/app_rd_data[71] ;
wire \u_ddr3_fifo/app_rd_data[70] ;
wire \u_ddr3_fifo/app_rd_data[69] ;
wire \u_ddr3_fifo/app_rd_data[68] ;
wire \u_ddr3_fifo/app_rd_data[67] ;
wire \u_ddr3_fifo/app_rd_data[66] ;
wire \u_ddr3_fifo/app_rd_data[65] ;
wire \u_ddr3_fifo/app_rd_data[64] ;
wire \u_ddr3_fifo/app_rd_data[63] ;
wire \u_ddr3_fifo/app_rd_data[62] ;
wire \u_ddr3_fifo/app_rd_data[61] ;
wire \u_ddr3_fifo/app_rd_data[60] ;
wire \u_ddr3_fifo/app_rd_data[59] ;
wire \u_ddr3_fifo/app_rd_data[58] ;
wire \u_ddr3_fifo/app_rd_data[57] ;
wire \u_ddr3_fifo/app_rd_data[56] ;
wire \u_ddr3_fifo/app_rd_data[55] ;
wire \u_ddr3_fifo/app_rd_data[54] ;
wire \u_ddr3_fifo/app_rd_data[53] ;
wire \u_ddr3_fifo/app_rd_data[52] ;
wire \u_ddr3_fifo/app_rd_data[51] ;
wire \u_ddr3_fifo/app_rd_data[50] ;
wire \u_ddr3_fifo/app_rd_data[49] ;
wire \u_ddr3_fifo/app_rd_data[48] ;
wire \u_ddr3_fifo/app_rd_data[47] ;
wire \u_ddr3_fifo/app_rd_data[46] ;
wire \u_ddr3_fifo/app_rd_data[45] ;
wire \u_ddr3_fifo/app_rd_data[44] ;
wire \u_ddr3_fifo/app_rd_data[43] ;
wire \u_ddr3_fifo/app_rd_data[42] ;
wire \u_ddr3_fifo/app_rd_data[41] ;
wire \u_ddr3_fifo/app_rd_data[40] ;
wire \u_ddr3_fifo/app_rd_data[39] ;
wire \u_ddr3_fifo/app_rd_data[38] ;
wire \u_ddr3_fifo/app_rd_data[37] ;
wire \u_ddr3_fifo/app_rd_data[36] ;
wire \u_ddr3_fifo/app_rd_data[35] ;
wire \u_ddr3_fifo/app_rd_data[34] ;
wire \u_ddr3_fifo/app_rd_data[33] ;
wire \u_ddr3_fifo/app_rd_data[32] ;
wire \u_ddr3_fifo/app_rd_data[31] ;
wire \u_ddr3_fifo/app_rd_data[30] ;
wire \u_ddr3_fifo/app_rd_data[29] ;
wire \u_ddr3_fifo/app_rd_data[28] ;
wire \u_ddr3_fifo/app_rd_data[27] ;
wire \u_ddr3_fifo/app_rd_data[26] ;
wire \u_ddr3_fifo/app_rd_data[25] ;
wire \u_ddr3_fifo/app_rd_data[24] ;
wire \u_ddr3_fifo/app_rd_data[23] ;
wire \u_ddr3_fifo/app_rd_data[22] ;
wire \u_ddr3_fifo/app_rd_data[21] ;
wire \u_ddr3_fifo/app_rd_data[20] ;
wire \u_ddr3_fifo/app_rd_data[19] ;
wire \u_ddr3_fifo/app_rd_data[18] ;
wire \u_ddr3_fifo/app_rd_data[17] ;
wire \u_ddr3_fifo/app_rd_data[16] ;
wire \u_ddr3_fifo/app_rd_data[15] ;
wire \u_ddr3_fifo/app_rd_data[14] ;
wire \u_ddr3_fifo/app_rd_data[13] ;
wire \u_ddr3_fifo/app_rd_data[12] ;
wire \u_ddr3_fifo/app_rd_data[11] ;
wire \u_ddr3_fifo/app_rd_data[10] ;
wire \u_ddr3_fifo/app_rd_data[9] ;
wire \u_ddr3_fifo/app_rd_data[8] ;
wire \u_ddr3_fifo/app_rd_data[7] ;
wire \u_ddr3_fifo/app_rd_data[6] ;
wire \u_ddr3_fifo/app_rd_data[5] ;
wire \u_ddr3_fifo/app_rd_data[4] ;
wire \u_ddr3_fifo/app_rd_data[3] ;
wire \u_ddr3_fifo/app_rd_data[2] ;
wire \u_ddr3_fifo/app_rd_data[1] ;
wire \u_ddr3_fifo/app_rd_data[0] ;
wire \u_ddr3_fifo/app_rd_data_valid ;
wire \eth_tx_data[7] ;
wire \eth_tx_data[6] ;
wire \eth_tx_data[5] ;
wire \eth_tx_data[4] ;
wire \eth_tx_data[3] ;
wire \eth_tx_data[2] ;
wire \eth_tx_data[1] ;
wire \eth_tx_data[0] ;
wire eth_tx_data_valid;
wire eth_tx_ready;
wire eth_tx_frame_start;
wire fifo_rd_en;
wire fifo_wr_en;
wire \u_ddr3_fifo/wr_buffer_full ;
wire eth_rx_data_valid;
wire RGMII_GTXCLK;
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
    .trig0_i(eth_rx_data_valid),
    .data_i({\fifo_wr_data[7] ,\fifo_wr_data[6] ,\fifo_wr_data[5] ,\fifo_wr_data[4] ,\fifo_wr_data[3] ,\fifo_wr_data[2] ,\fifo_wr_data[1] ,\fifo_wr_data[0] ,fifo_wr_almost_full,\fifo_rd_data[7] ,\fifo_rd_data[6] ,\fifo_rd_data[5] ,\fifo_rd_data[4] ,\fifo_rd_data[3] ,\fifo_rd_data[2] ,\fifo_rd_data[1] ,\fifo_rd_data[0] ,fifo_rd_empty,fifo_rd_almost_empty,fifo_rd_data_valid,\fifo_count[31] ,\fifo_count[30] ,\fifo_count[29] ,\fifo_count[28] ,\fifo_count[27] ,\fifo_count[26] ,\fifo_count[25] ,\fifo_count[24] ,\fifo_count[23] ,\fifo_count[22] ,\fifo_count[21] ,\fifo_count[20] ,\fifo_count[19] ,\fifo_count[18] ,\fifo_count[17] ,\fifo_count[16] ,\fifo_count[15] ,\fifo_count[14] ,\fifo_count[13] ,\fifo_count[12] ,\fifo_count[11] ,\fifo_count[10] ,\fifo_count[9] ,\fifo_count[8] ,\fifo_count[7] ,\fifo_count[6] ,\fifo_count[5] ,\fifo_count[4] ,\fifo_count[3] ,\fifo_count[2] ,\fifo_count[1] ,\fifo_count[0] ,\fifo_state[2] ,\fifo_state[1] ,\fifo_state[0] ,ddr_init_done,rst_n,\u_ddr3_fifo/state[2] ,\u_ddr3_fifo/state[1] ,\u_ddr3_fifo/state[0] ,\u_ddr3_fifo/wr_buffer_cnt[4] ,\u_ddr3_fifo/wr_buffer_cnt[3] ,\u_ddr3_fifo/wr_buffer_cnt[2] ,\u_ddr3_fifo/wr_buffer_cnt[1] ,\u_ddr3_fifo/wr_buffer_cnt[0] ,\u_ddr3_fifo/wr_req_fifo_wr ,\tx_state[2] ,\tx_state[1] ,\tx_state[0] ,\u_ddr3_fifo/rd_buffer_cnt[4] ,\u_ddr3_fifo/rd_buffer_cnt[3] ,\u_ddr3_fifo/rd_buffer_cnt[2] ,\u_ddr3_fifo/rd_buffer_cnt[1] ,\u_ddr3_fifo/rd_buffer_cnt[0] ,\u_ddr3_fifo/rd_buf_fifo_empty ,\u_ddr3_fifo/rd_empty ,\u_ddr3_fifo/rd_buffer_empty ,\u_ddr3_fifo/rd_buf_fifo_wr ,\u_ddr3_fifo/rd_buf_fifo_rd ,\u_ddr3_fifo/rd_buf_fifo_full ,\u_ddr3_fifo/rd_buf_fifo_count[8] ,\u_ddr3_fifo/rd_buf_fifo_count[7] ,\u_ddr3_fifo/rd_buf_fifo_count[6] ,\u_ddr3_fifo/rd_buf_fifo_count[5] ,\u_ddr3_fifo/rd_buf_fifo_count[4] ,\u_ddr3_fifo/rd_buf_fifo_count[3] ,\u_ddr3_fifo/rd_buf_fifo_count[2] ,\u_ddr3_fifo/rd_buf_fifo_count[1] ,\u_ddr3_fifo/rd_buf_fifo_count[0] ,\u_ddr3_fifo/rd_buf_fifo_almost_empty ,\u_ddr3_fifo/app_rd_data[127] ,\u_ddr3_fifo/app_rd_data[126] ,\u_ddr3_fifo/app_rd_data[125] ,\u_ddr3_fifo/app_rd_data[124] ,\u_ddr3_fifo/app_rd_data[123] ,\u_ddr3_fifo/app_rd_data[122] ,\u_ddr3_fifo/app_rd_data[121] ,\u_ddr3_fifo/app_rd_data[120] ,\u_ddr3_fifo/app_rd_data[119] ,\u_ddr3_fifo/app_rd_data[118] ,\u_ddr3_fifo/app_rd_data[117] ,\u_ddr3_fifo/app_rd_data[116] ,\u_ddr3_fifo/app_rd_data[115] ,\u_ddr3_fifo/app_rd_data[114] ,\u_ddr3_fifo/app_rd_data[113] ,\u_ddr3_fifo/app_rd_data[112] ,\u_ddr3_fifo/app_rd_data[111] ,\u_ddr3_fifo/app_rd_data[110] ,\u_ddr3_fifo/app_rd_data[109] ,\u_ddr3_fifo/app_rd_data[108] ,\u_ddr3_fifo/app_rd_data[107] ,\u_ddr3_fifo/app_rd_data[106] ,\u_ddr3_fifo/app_rd_data[105] ,\u_ddr3_fifo/app_rd_data[104] ,\u_ddr3_fifo/app_rd_data[103] ,\u_ddr3_fifo/app_rd_data[102] ,\u_ddr3_fifo/app_rd_data[101] ,\u_ddr3_fifo/app_rd_data[100] ,\u_ddr3_fifo/app_rd_data[99] ,\u_ddr3_fifo/app_rd_data[98] ,\u_ddr3_fifo/app_rd_data[97] ,\u_ddr3_fifo/app_rd_data[96] ,\u_ddr3_fifo/app_rd_data[95] ,\u_ddr3_fifo/app_rd_data[94] ,\u_ddr3_fifo/app_rd_data[93] ,\u_ddr3_fifo/app_rd_data[92] ,\u_ddr3_fifo/app_rd_data[91] ,\u_ddr3_fifo/app_rd_data[90] ,\u_ddr3_fifo/app_rd_data[89] ,\u_ddr3_fifo/app_rd_data[88] ,\u_ddr3_fifo/app_rd_data[87] ,\u_ddr3_fifo/app_rd_data[86] ,\u_ddr3_fifo/app_rd_data[85] ,\u_ddr3_fifo/app_rd_data[84] ,\u_ddr3_fifo/app_rd_data[83] ,\u_ddr3_fifo/app_rd_data[82] ,\u_ddr3_fifo/app_rd_data[81] ,\u_ddr3_fifo/app_rd_data[80] ,\u_ddr3_fifo/app_rd_data[79] ,\u_ddr3_fifo/app_rd_data[78] ,\u_ddr3_fifo/app_rd_data[77] ,\u_ddr3_fifo/app_rd_data[76] ,\u_ddr3_fifo/app_rd_data[75] ,\u_ddr3_fifo/app_rd_data[74] ,\u_ddr3_fifo/app_rd_data[73] ,\u_ddr3_fifo/app_rd_data[72] ,\u_ddr3_fifo/app_rd_data[71] ,\u_ddr3_fifo/app_rd_data[70] ,\u_ddr3_fifo/app_rd_data[69] ,\u_ddr3_fifo/app_rd_data[68] ,\u_ddr3_fifo/app_rd_data[67] ,\u_ddr3_fifo/app_rd_data[66] ,\u_ddr3_fifo/app_rd_data[65] ,\u_ddr3_fifo/app_rd_data[64] ,\u_ddr3_fifo/app_rd_data[63] ,\u_ddr3_fifo/app_rd_data[62] ,\u_ddr3_fifo/app_rd_data[61] ,\u_ddr3_fifo/app_rd_data[60] ,\u_ddr3_fifo/app_rd_data[59] ,\u_ddr3_fifo/app_rd_data[58] ,\u_ddr3_fifo/app_rd_data[57] ,\u_ddr3_fifo/app_rd_data[56] ,\u_ddr3_fifo/app_rd_data[55] ,\u_ddr3_fifo/app_rd_data[54] ,\u_ddr3_fifo/app_rd_data[53] ,\u_ddr3_fifo/app_rd_data[52] ,\u_ddr3_fifo/app_rd_data[51] ,\u_ddr3_fifo/app_rd_data[50] ,\u_ddr3_fifo/app_rd_data[49] ,\u_ddr3_fifo/app_rd_data[48] ,\u_ddr3_fifo/app_rd_data[47] ,\u_ddr3_fifo/app_rd_data[46] ,\u_ddr3_fifo/app_rd_data[45] ,\u_ddr3_fifo/app_rd_data[44] ,\u_ddr3_fifo/app_rd_data[43] ,\u_ddr3_fifo/app_rd_data[42] ,\u_ddr3_fifo/app_rd_data[41] ,\u_ddr3_fifo/app_rd_data[40] ,\u_ddr3_fifo/app_rd_data[39] ,\u_ddr3_fifo/app_rd_data[38] ,\u_ddr3_fifo/app_rd_data[37] ,\u_ddr3_fifo/app_rd_data[36] ,\u_ddr3_fifo/app_rd_data[35] ,\u_ddr3_fifo/app_rd_data[34] ,\u_ddr3_fifo/app_rd_data[33] ,\u_ddr3_fifo/app_rd_data[32] ,\u_ddr3_fifo/app_rd_data[31] ,\u_ddr3_fifo/app_rd_data[30] ,\u_ddr3_fifo/app_rd_data[29] ,\u_ddr3_fifo/app_rd_data[28] ,\u_ddr3_fifo/app_rd_data[27] ,\u_ddr3_fifo/app_rd_data[26] ,\u_ddr3_fifo/app_rd_data[25] ,\u_ddr3_fifo/app_rd_data[24] ,\u_ddr3_fifo/app_rd_data[23] ,\u_ddr3_fifo/app_rd_data[22] ,\u_ddr3_fifo/app_rd_data[21] ,\u_ddr3_fifo/app_rd_data[20] ,\u_ddr3_fifo/app_rd_data[19] ,\u_ddr3_fifo/app_rd_data[18] ,\u_ddr3_fifo/app_rd_data[17] ,\u_ddr3_fifo/app_rd_data[16] ,\u_ddr3_fifo/app_rd_data[15] ,\u_ddr3_fifo/app_rd_data[14] ,\u_ddr3_fifo/app_rd_data[13] ,\u_ddr3_fifo/app_rd_data[12] ,\u_ddr3_fifo/app_rd_data[11] ,\u_ddr3_fifo/app_rd_data[10] ,\u_ddr3_fifo/app_rd_data[9] ,\u_ddr3_fifo/app_rd_data[8] ,\u_ddr3_fifo/app_rd_data[7] ,\u_ddr3_fifo/app_rd_data[6] ,\u_ddr3_fifo/app_rd_data[5] ,\u_ddr3_fifo/app_rd_data[4] ,\u_ddr3_fifo/app_rd_data[3] ,\u_ddr3_fifo/app_rd_data[2] ,\u_ddr3_fifo/app_rd_data[1] ,\u_ddr3_fifo/app_rd_data[0] ,\u_ddr3_fifo/app_rd_data_valid ,\eth_tx_data[7] ,\eth_tx_data[6] ,\eth_tx_data[5] ,\eth_tx_data[4] ,\eth_tx_data[3] ,\eth_tx_data[2] ,\eth_tx_data[1] ,\eth_tx_data[0] ,eth_tx_data_valid,eth_tx_ready,eth_tx_frame_start,fifo_rd_en,fifo_wr_en,\u_ddr3_fifo/wr_buffer_full }),
    .clk_i(RGMII_GTXCLK)
);

endmodule
