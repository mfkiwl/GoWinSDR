module gw_gao(
    \fifo_wr_data[7] ,
    \fifo_wr_data[6] ,
    \fifo_wr_data[5] ,
    \fifo_wr_data[4] ,
    \fifo_wr_data[3] ,
    \fifo_wr_data[2] ,
    \fifo_wr_data[1] ,
    \fifo_wr_data[0] ,
    fifo_wr_en,
    fifo_wr_full,
    fifo_wr_almost_full,
    \fifo_rd_data[7] ,
    \fifo_rd_data[6] ,
    \fifo_rd_data[5] ,
    \fifo_rd_data[4] ,
    \fifo_rd_data[3] ,
    \fifo_rd_data[2] ,
    \fifo_rd_data[1] ,
    \fifo_rd_data[0] ,
    fifo_rd_en,
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
    \u_ddr3_fifo/app_cmd[2] ,
    \u_ddr3_fifo/app_cmd[1] ,
    \u_ddr3_fifo/app_cmd[0] ,
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
    \eth_tx_data[7] ,
    \eth_tx_data[6] ,
    \eth_tx_data[5] ,
    \eth_tx_data[4] ,
    \eth_tx_data[3] ,
    \eth_tx_data[2] ,
    \eth_tx_data[1] ,
    \eth_tx_data[0] ,
    eth_tx_data_valid,
    eth_tx_frame_start,
    eth_tx_ready,
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
    \u_ddr3_fifo/app_rd_data_valid ,
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
input fifo_wr_en;
input fifo_wr_full;
input fifo_wr_almost_full;
input \fifo_rd_data[7] ;
input \fifo_rd_data[6] ;
input \fifo_rd_data[5] ;
input \fifo_rd_data[4] ;
input \fifo_rd_data[3] ;
input \fifo_rd_data[2] ;
input \fifo_rd_data[1] ;
input \fifo_rd_data[0] ;
input fifo_rd_en;
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
input \u_ddr3_fifo/app_cmd[2] ;
input \u_ddr3_fifo/app_cmd[1] ;
input \u_ddr3_fifo/app_cmd[0] ;
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
input \eth_tx_data[7] ;
input \eth_tx_data[6] ;
input \eth_tx_data[5] ;
input \eth_tx_data[4] ;
input \eth_tx_data[3] ;
input \eth_tx_data[2] ;
input \eth_tx_data[1] ;
input \eth_tx_data[0] ;
input eth_tx_data_valid;
input eth_tx_frame_start;
input eth_tx_ready;
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
input \u_ddr3_fifo/app_rd_data_valid ;
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
wire fifo_wr_en;
wire fifo_wr_full;
wire fifo_wr_almost_full;
wire \fifo_rd_data[7] ;
wire \fifo_rd_data[6] ;
wire \fifo_rd_data[5] ;
wire \fifo_rd_data[4] ;
wire \fifo_rd_data[3] ;
wire \fifo_rd_data[2] ;
wire \fifo_rd_data[1] ;
wire \fifo_rd_data[0] ;
wire fifo_rd_en;
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
wire \u_ddr3_fifo/app_cmd[2] ;
wire \u_ddr3_fifo/app_cmd[1] ;
wire \u_ddr3_fifo/app_cmd[0] ;
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
wire \eth_tx_data[7] ;
wire \eth_tx_data[6] ;
wire \eth_tx_data[5] ;
wire \eth_tx_data[4] ;
wire \eth_tx_data[3] ;
wire \eth_tx_data[2] ;
wire \eth_tx_data[1] ;
wire \eth_tx_data[0] ;
wire eth_tx_data_valid;
wire eth_tx_frame_start;
wire eth_tx_ready;
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
wire \u_ddr3_fifo/app_rd_data_valid ;
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
    .data_i({\fifo_wr_data[7] ,\fifo_wr_data[6] ,\fifo_wr_data[5] ,\fifo_wr_data[4] ,\fifo_wr_data[3] ,\fifo_wr_data[2] ,\fifo_wr_data[1] ,\fifo_wr_data[0] ,fifo_wr_en,fifo_wr_full,fifo_wr_almost_full,\fifo_rd_data[7] ,\fifo_rd_data[6] ,\fifo_rd_data[5] ,\fifo_rd_data[4] ,\fifo_rd_data[3] ,\fifo_rd_data[2] ,\fifo_rd_data[1] ,\fifo_rd_data[0] ,fifo_rd_en,fifo_rd_empty,fifo_rd_almost_empty,fifo_rd_data_valid,\fifo_count[31] ,\fifo_count[30] ,\fifo_count[29] ,\fifo_count[28] ,\fifo_count[27] ,\fifo_count[26] ,\fifo_count[25] ,\fifo_count[24] ,\fifo_count[23] ,\fifo_count[22] ,\fifo_count[21] ,\fifo_count[20] ,\fifo_count[19] ,\fifo_count[18] ,\fifo_count[17] ,\fifo_count[16] ,\fifo_count[15] ,\fifo_count[14] ,\fifo_count[13] ,\fifo_count[12] ,\fifo_count[11] ,\fifo_count[10] ,\fifo_count[9] ,\fifo_count[8] ,\fifo_count[7] ,\fifo_count[6] ,\fifo_count[5] ,\fifo_count[4] ,\fifo_count[3] ,\fifo_count[2] ,\fifo_count[1] ,\fifo_count[0] ,\fifo_state[2] ,\fifo_state[1] ,\fifo_state[0] ,ddr_init_done,rst_n,\u_ddr3_fifo/app_cmd[2] ,\u_ddr3_fifo/app_cmd[1] ,\u_ddr3_fifo/app_cmd[0] ,\u_ddr3_fifo/state[2] ,\u_ddr3_fifo/state[1] ,\u_ddr3_fifo/state[0] ,\u_ddr3_fifo/wr_buffer_cnt[4] ,\u_ddr3_fifo/wr_buffer_cnt[3] ,\u_ddr3_fifo/wr_buffer_cnt[2] ,\u_ddr3_fifo/wr_buffer_cnt[1] ,\u_ddr3_fifo/wr_buffer_cnt[0] ,\u_ddr3_fifo/wr_req_fifo_wr ,\tx_state[2] ,\tx_state[1] ,\tx_state[0] ,\eth_tx_data[7] ,\eth_tx_data[6] ,\eth_tx_data[5] ,\eth_tx_data[4] ,\eth_tx_data[3] ,\eth_tx_data[2] ,\eth_tx_data[1] ,\eth_tx_data[0] ,eth_tx_data_valid,eth_tx_frame_start,eth_tx_ready,\u_ddr3_fifo/rd_buffer_cnt[4] ,\u_ddr3_fifo/rd_buffer_cnt[3] ,\u_ddr3_fifo/rd_buffer_cnt[2] ,\u_ddr3_fifo/rd_buffer_cnt[1] ,\u_ddr3_fifo/rd_buffer_cnt[0] ,\u_ddr3_fifo/rd_buf_fifo_empty ,\u_ddr3_fifo/rd_empty ,\u_ddr3_fifo/rd_buffer_empty ,\u_ddr3_fifo/rd_buf_fifo_wr ,\u_ddr3_fifo/rd_buf_fifo_rd ,\u_ddr3_fifo/rd_buf_fifo_full ,\u_ddr3_fifo/rd_buf_fifo_count[8] ,\u_ddr3_fifo/rd_buf_fifo_count[7] ,\u_ddr3_fifo/rd_buf_fifo_count[6] ,\u_ddr3_fifo/rd_buf_fifo_count[5] ,\u_ddr3_fifo/rd_buf_fifo_count[4] ,\u_ddr3_fifo/rd_buf_fifo_count[3] ,\u_ddr3_fifo/rd_buf_fifo_count[2] ,\u_ddr3_fifo/rd_buf_fifo_count[1] ,\u_ddr3_fifo/rd_buf_fifo_count[0] ,\u_ddr3_fifo/rd_buf_fifo_almost_empty ,\u_ddr3_fifo/app_rd_data_valid }),
    .clk_i(RGMII_GTXCLK)
);

endmodule
