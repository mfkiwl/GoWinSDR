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
    \u_ad9363_dev_cmos/dac_data_in_i1[11] ,
    \u_ad9363_dev_cmos/dac_data_in_i1[10] ,
    \u_ad9363_dev_cmos/dac_data_in_i1[9] ,
    \u_ad9363_dev_cmos/dac_data_in_i1[8] ,
    \u_ad9363_dev_cmos/dac_data_in_i1[7] ,
    \u_ad9363_dev_cmos/dac_data_in_i1[6] ,
    \u_ad9363_dev_cmos/dac_data_in_i1[5] ,
    \u_ad9363_dev_cmos/dac_data_in_i1[4] ,
    \u_ad9363_dev_cmos/dac_data_in_i1[3] ,
    \u_ad9363_dev_cmos/dac_data_in_i1[2] ,
    \u_ad9363_dev_cmos/dac_data_in_i1[1] ,
    \u_ad9363_dev_cmos/dac_data_in_i1[0] ,
    \u_ad9363_dev_cmos/dac_data_in_q1[11] ,
    \u_ad9363_dev_cmos/dac_data_in_q1[10] ,
    \u_ad9363_dev_cmos/dac_data_in_q1[9] ,
    \u_ad9363_dev_cmos/dac_data_in_q1[8] ,
    \u_ad9363_dev_cmos/dac_data_in_q1[7] ,
    \u_ad9363_dev_cmos/dac_data_in_q1[6] ,
    \u_ad9363_dev_cmos/dac_data_in_q1[5] ,
    \u_ad9363_dev_cmos/dac_data_in_q1[4] ,
    \u_ad9363_dev_cmos/dac_data_in_q1[3] ,
    \u_ad9363_dev_cmos/dac_data_in_q1[2] ,
    \u_ad9363_dev_cmos/dac_data_in_q1[1] ,
    \u_ad9363_dev_cmos/dac_data_in_q1[0] ,
    \u_demod_433/magnitude[12] ,
    \u_demod_433/magnitude[11] ,
    \u_demod_433/magnitude[10] ,
    \u_demod_433/magnitude[9] ,
    \u_demod_433/magnitude[8] ,
    \u_demod_433/magnitude[7] ,
    \u_demod_433/magnitude[6] ,
    \u_demod_433/magnitude[5] ,
    \u_demod_433/magnitude[4] ,
    \u_demod_433/magnitude[3] ,
    \u_demod_433/magnitude[2] ,
    \u_demod_433/magnitude[1] ,
    \u_demod_433/magnitude[0] ,
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
input \u_ad9363_dev_cmos/dac_data_in_i1[11] ;
input \u_ad9363_dev_cmos/dac_data_in_i1[10] ;
input \u_ad9363_dev_cmos/dac_data_in_i1[9] ;
input \u_ad9363_dev_cmos/dac_data_in_i1[8] ;
input \u_ad9363_dev_cmos/dac_data_in_i1[7] ;
input \u_ad9363_dev_cmos/dac_data_in_i1[6] ;
input \u_ad9363_dev_cmos/dac_data_in_i1[5] ;
input \u_ad9363_dev_cmos/dac_data_in_i1[4] ;
input \u_ad9363_dev_cmos/dac_data_in_i1[3] ;
input \u_ad9363_dev_cmos/dac_data_in_i1[2] ;
input \u_ad9363_dev_cmos/dac_data_in_i1[1] ;
input \u_ad9363_dev_cmos/dac_data_in_i1[0] ;
input \u_ad9363_dev_cmos/dac_data_in_q1[11] ;
input \u_ad9363_dev_cmos/dac_data_in_q1[10] ;
input \u_ad9363_dev_cmos/dac_data_in_q1[9] ;
input \u_ad9363_dev_cmos/dac_data_in_q1[8] ;
input \u_ad9363_dev_cmos/dac_data_in_q1[7] ;
input \u_ad9363_dev_cmos/dac_data_in_q1[6] ;
input \u_ad9363_dev_cmos/dac_data_in_q1[5] ;
input \u_ad9363_dev_cmos/dac_data_in_q1[4] ;
input \u_ad9363_dev_cmos/dac_data_in_q1[3] ;
input \u_ad9363_dev_cmos/dac_data_in_q1[2] ;
input \u_ad9363_dev_cmos/dac_data_in_q1[1] ;
input \u_ad9363_dev_cmos/dac_data_in_q1[0] ;
input \u_demod_433/magnitude[12] ;
input \u_demod_433/magnitude[11] ;
input \u_demod_433/magnitude[10] ;
input \u_demod_433/magnitude[9] ;
input \u_demod_433/magnitude[8] ;
input \u_demod_433/magnitude[7] ;
input \u_demod_433/magnitude[6] ;
input \u_demod_433/magnitude[5] ;
input \u_demod_433/magnitude[4] ;
input \u_demod_433/magnitude[3] ;
input \u_demod_433/magnitude[2] ;
input \u_demod_433/magnitude[1] ;
input \u_demod_433/magnitude[0] ;
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
wire \u_ad9363_dev_cmos/dac_data_in_i1[11] ;
wire \u_ad9363_dev_cmos/dac_data_in_i1[10] ;
wire \u_ad9363_dev_cmos/dac_data_in_i1[9] ;
wire \u_ad9363_dev_cmos/dac_data_in_i1[8] ;
wire \u_ad9363_dev_cmos/dac_data_in_i1[7] ;
wire \u_ad9363_dev_cmos/dac_data_in_i1[6] ;
wire \u_ad9363_dev_cmos/dac_data_in_i1[5] ;
wire \u_ad9363_dev_cmos/dac_data_in_i1[4] ;
wire \u_ad9363_dev_cmos/dac_data_in_i1[3] ;
wire \u_ad9363_dev_cmos/dac_data_in_i1[2] ;
wire \u_ad9363_dev_cmos/dac_data_in_i1[1] ;
wire \u_ad9363_dev_cmos/dac_data_in_i1[0] ;
wire \u_ad9363_dev_cmos/dac_data_in_q1[11] ;
wire \u_ad9363_dev_cmos/dac_data_in_q1[10] ;
wire \u_ad9363_dev_cmos/dac_data_in_q1[9] ;
wire \u_ad9363_dev_cmos/dac_data_in_q1[8] ;
wire \u_ad9363_dev_cmos/dac_data_in_q1[7] ;
wire \u_ad9363_dev_cmos/dac_data_in_q1[6] ;
wire \u_ad9363_dev_cmos/dac_data_in_q1[5] ;
wire \u_ad9363_dev_cmos/dac_data_in_q1[4] ;
wire \u_ad9363_dev_cmos/dac_data_in_q1[3] ;
wire \u_ad9363_dev_cmos/dac_data_in_q1[2] ;
wire \u_ad9363_dev_cmos/dac_data_in_q1[1] ;
wire \u_ad9363_dev_cmos/dac_data_in_q1[0] ;
wire \u_demod_433/magnitude[12] ;
wire \u_demod_433/magnitude[11] ;
wire \u_demod_433/magnitude[10] ;
wire \u_demod_433/magnitude[9] ;
wire \u_demod_433/magnitude[8] ;
wire \u_demod_433/magnitude[7] ;
wire \u_demod_433/magnitude[6] ;
wire \u_demod_433/magnitude[5] ;
wire \u_demod_433/magnitude[4] ;
wire \u_demod_433/magnitude[3] ;
wire \u_demod_433/magnitude[2] ;
wire \u_demod_433/magnitude[1] ;
wire \u_demod_433/magnitude[0] ;
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
    .trig0_i(data_clk),
    .data_i({\adc_data_out_i1[11] ,\adc_data_out_i1[10] ,\adc_data_out_i1[9] ,\adc_data_out_i1[8] ,\adc_data_out_i1[7] ,\adc_data_out_i1[6] ,\adc_data_out_i1[5] ,\adc_data_out_i1[4] ,\adc_data_out_i1[3] ,\adc_data_out_i1[2] ,\adc_data_out_i1[1] ,\adc_data_out_i1[0] ,\adc_data_out_q1[11] ,\adc_data_out_q1[10] ,\adc_data_out_q1[9] ,\adc_data_out_q1[8] ,\adc_data_out_q1[7] ,\adc_data_out_q1[6] ,\adc_data_out_q1[5] ,\adc_data_out_q1[4] ,\adc_data_out_q1[3] ,\adc_data_out_q1[2] ,\adc_data_out_q1[1] ,\adc_data_out_q1[0] ,\u_ad9363_dev_cmos/dac_data_in_i1[11] ,\u_ad9363_dev_cmos/dac_data_in_i1[10] ,\u_ad9363_dev_cmos/dac_data_in_i1[9] ,\u_ad9363_dev_cmos/dac_data_in_i1[8] ,\u_ad9363_dev_cmos/dac_data_in_i1[7] ,\u_ad9363_dev_cmos/dac_data_in_i1[6] ,\u_ad9363_dev_cmos/dac_data_in_i1[5] ,\u_ad9363_dev_cmos/dac_data_in_i1[4] ,\u_ad9363_dev_cmos/dac_data_in_i1[3] ,\u_ad9363_dev_cmos/dac_data_in_i1[2] ,\u_ad9363_dev_cmos/dac_data_in_i1[1] ,\u_ad9363_dev_cmos/dac_data_in_i1[0] ,\u_ad9363_dev_cmos/dac_data_in_q1[11] ,\u_ad9363_dev_cmos/dac_data_in_q1[10] ,\u_ad9363_dev_cmos/dac_data_in_q1[9] ,\u_ad9363_dev_cmos/dac_data_in_q1[8] ,\u_ad9363_dev_cmos/dac_data_in_q1[7] ,\u_ad9363_dev_cmos/dac_data_in_q1[6] ,\u_ad9363_dev_cmos/dac_data_in_q1[5] ,\u_ad9363_dev_cmos/dac_data_in_q1[4] ,\u_ad9363_dev_cmos/dac_data_in_q1[3] ,\u_ad9363_dev_cmos/dac_data_in_q1[2] ,\u_ad9363_dev_cmos/dac_data_in_q1[1] ,\u_ad9363_dev_cmos/dac_data_in_q1[0] ,\u_demod_433/magnitude[12] ,\u_demod_433/magnitude[11] ,\u_demod_433/magnitude[10] ,\u_demod_433/magnitude[9] ,\u_demod_433/magnitude[8] ,\u_demod_433/magnitude[7] ,\u_demod_433/magnitude[6] ,\u_demod_433/magnitude[5] ,\u_demod_433/magnitude[4] ,\u_demod_433/magnitude[3] ,\u_demod_433/magnitude[2] ,\u_demod_433/magnitude[1] ,\u_demod_433/magnitude[0] }),
    .clk_i(data_clk)
);

endmodule
