module gw_gao(
    \eth_inst/tx_data[7] ,
    \eth_inst/tx_data[6] ,
    \eth_inst/tx_data[5] ,
    \eth_inst/tx_data[4] ,
    \eth_inst/tx_data[3] ,
    \eth_inst/tx_data[2] ,
    \eth_inst/tx_data[1] ,
    \eth_inst/tx_data[0] ,
    \eth_inst/rx_data[7] ,
    \eth_inst/rx_data[6] ,
    \eth_inst/rx_data[5] ,
    \eth_inst/rx_data[4] ,
    \eth_inst/rx_data[3] ,
    \eth_inst/rx_data[2] ,
    \eth_inst/rx_data[1] ,
    \eth_inst/rx_data[0] ,
    led_rx,
    led_tx,
    rx_data_valid,
    rx_frame_start,
    rx_frame_end,
    tx_ready,
    rx_active,
    tx_active,
    \eth_inst/gmii_rxd[7] ,
    \eth_inst/gmii_rxd[6] ,
    \eth_inst/gmii_rxd[5] ,
    \eth_inst/gmii_rxd[4] ,
    \eth_inst/gmii_rxd[3] ,
    \eth_inst/gmii_rxd[2] ,
    \eth_inst/gmii_rxd[1] ,
    \eth_inst/gmii_rxd[0] ,
    \eth_inst/gmii_rxdv ,
    \eth_inst/rx_state[3] ,
    \eth_inst/rx_state[2] ,
    \eth_inst/rx_state[1] ,
    \eth_inst/rx_state[0] ,
    \eth_inst/tx_data_valid ,
    \eth_inst/tx_buf_ready ,
    \eth_inst/rx_cnt[15] ,
    \eth_inst/rx_cnt[14] ,
    \eth_inst/rx_cnt[13] ,
    \eth_inst/rx_cnt[12] ,
    \eth_inst/rx_cnt[11] ,
    \eth_inst/rx_cnt[10] ,
    \eth_inst/rx_cnt[9] ,
    \eth_inst/rx_cnt[8] ,
    \eth_inst/rx_cnt[7] ,
    \eth_inst/rx_cnt[6] ,
    \eth_inst/rx_cnt[5] ,
    \eth_inst/rx_cnt[4] ,
    \eth_inst/rx_cnt[3] ,
    \eth_inst/rx_cnt[2] ,
    \eth_inst/rx_cnt[1] ,
    \eth_inst/rx_cnt[0] ,
    \eth_inst/rx_data_valid_reg ,
    \eth_inst/rx_dest_port[15] ,
    \eth_inst/rx_dest_port[14] ,
    \eth_inst/rx_dest_port[13] ,
    \eth_inst/rx_dest_port[12] ,
    \eth_inst/rx_dest_port[11] ,
    \eth_inst/rx_dest_port[10] ,
    \eth_inst/rx_dest_port[9] ,
    \eth_inst/rx_dest_port[8] ,
    \eth_inst/rx_dest_port[7] ,
    \eth_inst/rx_dest_port[6] ,
    \eth_inst/rx_dest_port[5] ,
    \eth_inst/rx_dest_port[4] ,
    \eth_inst/rx_dest_port[3] ,
    \eth_inst/rx_dest_port[2] ,
    \eth_inst/rx_dest_port[1] ,
    \eth_inst/rx_dest_port[0] ,
    \eth_inst/clk_125m ,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \eth_inst/tx_data[7] ;
input \eth_inst/tx_data[6] ;
input \eth_inst/tx_data[5] ;
input \eth_inst/tx_data[4] ;
input \eth_inst/tx_data[3] ;
input \eth_inst/tx_data[2] ;
input \eth_inst/tx_data[1] ;
input \eth_inst/tx_data[0] ;
input \eth_inst/rx_data[7] ;
input \eth_inst/rx_data[6] ;
input \eth_inst/rx_data[5] ;
input \eth_inst/rx_data[4] ;
input \eth_inst/rx_data[3] ;
input \eth_inst/rx_data[2] ;
input \eth_inst/rx_data[1] ;
input \eth_inst/rx_data[0] ;
input led_rx;
input led_tx;
input rx_data_valid;
input rx_frame_start;
input rx_frame_end;
input tx_ready;
input rx_active;
input tx_active;
input \eth_inst/gmii_rxd[7] ;
input \eth_inst/gmii_rxd[6] ;
input \eth_inst/gmii_rxd[5] ;
input \eth_inst/gmii_rxd[4] ;
input \eth_inst/gmii_rxd[3] ;
input \eth_inst/gmii_rxd[2] ;
input \eth_inst/gmii_rxd[1] ;
input \eth_inst/gmii_rxd[0] ;
input \eth_inst/gmii_rxdv ;
input \eth_inst/rx_state[3] ;
input \eth_inst/rx_state[2] ;
input \eth_inst/rx_state[1] ;
input \eth_inst/rx_state[0] ;
input \eth_inst/tx_data_valid ;
input \eth_inst/tx_buf_ready ;
input \eth_inst/rx_cnt[15] ;
input \eth_inst/rx_cnt[14] ;
input \eth_inst/rx_cnt[13] ;
input \eth_inst/rx_cnt[12] ;
input \eth_inst/rx_cnt[11] ;
input \eth_inst/rx_cnt[10] ;
input \eth_inst/rx_cnt[9] ;
input \eth_inst/rx_cnt[8] ;
input \eth_inst/rx_cnt[7] ;
input \eth_inst/rx_cnt[6] ;
input \eth_inst/rx_cnt[5] ;
input \eth_inst/rx_cnt[4] ;
input \eth_inst/rx_cnt[3] ;
input \eth_inst/rx_cnt[2] ;
input \eth_inst/rx_cnt[1] ;
input \eth_inst/rx_cnt[0] ;
input \eth_inst/rx_data_valid_reg ;
input \eth_inst/rx_dest_port[15] ;
input \eth_inst/rx_dest_port[14] ;
input \eth_inst/rx_dest_port[13] ;
input \eth_inst/rx_dest_port[12] ;
input \eth_inst/rx_dest_port[11] ;
input \eth_inst/rx_dest_port[10] ;
input \eth_inst/rx_dest_port[9] ;
input \eth_inst/rx_dest_port[8] ;
input \eth_inst/rx_dest_port[7] ;
input \eth_inst/rx_dest_port[6] ;
input \eth_inst/rx_dest_port[5] ;
input \eth_inst/rx_dest_port[4] ;
input \eth_inst/rx_dest_port[3] ;
input \eth_inst/rx_dest_port[2] ;
input \eth_inst/rx_dest_port[1] ;
input \eth_inst/rx_dest_port[0] ;
input \eth_inst/clk_125m ;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \eth_inst/tx_data[7] ;
wire \eth_inst/tx_data[6] ;
wire \eth_inst/tx_data[5] ;
wire \eth_inst/tx_data[4] ;
wire \eth_inst/tx_data[3] ;
wire \eth_inst/tx_data[2] ;
wire \eth_inst/tx_data[1] ;
wire \eth_inst/tx_data[0] ;
wire \eth_inst/rx_data[7] ;
wire \eth_inst/rx_data[6] ;
wire \eth_inst/rx_data[5] ;
wire \eth_inst/rx_data[4] ;
wire \eth_inst/rx_data[3] ;
wire \eth_inst/rx_data[2] ;
wire \eth_inst/rx_data[1] ;
wire \eth_inst/rx_data[0] ;
wire led_rx;
wire led_tx;
wire rx_data_valid;
wire rx_frame_start;
wire rx_frame_end;
wire tx_ready;
wire rx_active;
wire tx_active;
wire \eth_inst/gmii_rxd[7] ;
wire \eth_inst/gmii_rxd[6] ;
wire \eth_inst/gmii_rxd[5] ;
wire \eth_inst/gmii_rxd[4] ;
wire \eth_inst/gmii_rxd[3] ;
wire \eth_inst/gmii_rxd[2] ;
wire \eth_inst/gmii_rxd[1] ;
wire \eth_inst/gmii_rxd[0] ;
wire \eth_inst/gmii_rxdv ;
wire \eth_inst/rx_state[3] ;
wire \eth_inst/rx_state[2] ;
wire \eth_inst/rx_state[1] ;
wire \eth_inst/rx_state[0] ;
wire \eth_inst/tx_data_valid ;
wire \eth_inst/tx_buf_ready ;
wire \eth_inst/rx_cnt[15] ;
wire \eth_inst/rx_cnt[14] ;
wire \eth_inst/rx_cnt[13] ;
wire \eth_inst/rx_cnt[12] ;
wire \eth_inst/rx_cnt[11] ;
wire \eth_inst/rx_cnt[10] ;
wire \eth_inst/rx_cnt[9] ;
wire \eth_inst/rx_cnt[8] ;
wire \eth_inst/rx_cnt[7] ;
wire \eth_inst/rx_cnt[6] ;
wire \eth_inst/rx_cnt[5] ;
wire \eth_inst/rx_cnt[4] ;
wire \eth_inst/rx_cnt[3] ;
wire \eth_inst/rx_cnt[2] ;
wire \eth_inst/rx_cnt[1] ;
wire \eth_inst/rx_cnt[0] ;
wire \eth_inst/rx_data_valid_reg ;
wire \eth_inst/rx_dest_port[15] ;
wire \eth_inst/rx_dest_port[14] ;
wire \eth_inst/rx_dest_port[13] ;
wire \eth_inst/rx_dest_port[12] ;
wire \eth_inst/rx_dest_port[11] ;
wire \eth_inst/rx_dest_port[10] ;
wire \eth_inst/rx_dest_port[9] ;
wire \eth_inst/rx_dest_port[8] ;
wire \eth_inst/rx_dest_port[7] ;
wire \eth_inst/rx_dest_port[6] ;
wire \eth_inst/rx_dest_port[5] ;
wire \eth_inst/rx_dest_port[4] ;
wire \eth_inst/rx_dest_port[3] ;
wire \eth_inst/rx_dest_port[2] ;
wire \eth_inst/rx_dest_port[1] ;
wire \eth_inst/rx_dest_port[0] ;
wire \eth_inst/clk_125m ;
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
    .trig0_i({\eth_inst/rx_dest_port[15] ,\eth_inst/rx_dest_port[14] ,\eth_inst/rx_dest_port[13] ,\eth_inst/rx_dest_port[12] ,\eth_inst/rx_dest_port[11] ,\eth_inst/rx_dest_port[10] ,\eth_inst/rx_dest_port[9] ,\eth_inst/rx_dest_port[8] ,\eth_inst/rx_dest_port[7] ,\eth_inst/rx_dest_port[6] ,\eth_inst/rx_dest_port[5] ,\eth_inst/rx_dest_port[4] ,\eth_inst/rx_dest_port[3] ,\eth_inst/rx_dest_port[2] ,\eth_inst/rx_dest_port[1] ,\eth_inst/rx_dest_port[0] }),
    .data_i({\eth_inst/tx_data[7] ,\eth_inst/tx_data[6] ,\eth_inst/tx_data[5] ,\eth_inst/tx_data[4] ,\eth_inst/tx_data[3] ,\eth_inst/tx_data[2] ,\eth_inst/tx_data[1] ,\eth_inst/tx_data[0] ,\eth_inst/rx_data[7] ,\eth_inst/rx_data[6] ,\eth_inst/rx_data[5] ,\eth_inst/rx_data[4] ,\eth_inst/rx_data[3] ,\eth_inst/rx_data[2] ,\eth_inst/rx_data[1] ,\eth_inst/rx_data[0] ,led_rx,led_tx,rx_data_valid,rx_frame_start,rx_frame_end,tx_ready,rx_active,tx_active,\eth_inst/gmii_rxd[7] ,\eth_inst/gmii_rxd[6] ,\eth_inst/gmii_rxd[5] ,\eth_inst/gmii_rxd[4] ,\eth_inst/gmii_rxd[3] ,\eth_inst/gmii_rxd[2] ,\eth_inst/gmii_rxd[1] ,\eth_inst/gmii_rxd[0] ,\eth_inst/gmii_rxdv ,\eth_inst/rx_state[3] ,\eth_inst/rx_state[2] ,\eth_inst/rx_state[1] ,\eth_inst/rx_state[0] ,\eth_inst/tx_data_valid ,\eth_inst/tx_buf_ready ,\eth_inst/rx_cnt[15] ,\eth_inst/rx_cnt[14] ,\eth_inst/rx_cnt[13] ,\eth_inst/rx_cnt[12] ,\eth_inst/rx_cnt[11] ,\eth_inst/rx_cnt[10] ,\eth_inst/rx_cnt[9] ,\eth_inst/rx_cnt[8] ,\eth_inst/rx_cnt[7] ,\eth_inst/rx_cnt[6] ,\eth_inst/rx_cnt[5] ,\eth_inst/rx_cnt[4] ,\eth_inst/rx_cnt[3] ,\eth_inst/rx_cnt[2] ,\eth_inst/rx_cnt[1] ,\eth_inst/rx_cnt[0] ,\eth_inst/rx_data_valid_reg }),
    .clk_i(\eth_inst/clk_125m )
);

endmodule
