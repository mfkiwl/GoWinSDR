module gw_gao(
    \rx_data_in[11] ,
    \rx_data_in[10] ,
    \rx_data_in[9] ,
    \rx_data_in[8] ,
    \rx_data_in[7] ,
    \rx_data_in[6] ,
    \rx_data_in[5] ,
    \rx_data_in[4] ,
    \rx_data_in[3] ,
    \rx_data_in[2] ,
    \rx_data_in[1] ,
    \rx_data_in[0] ,
    \sine[11] ,
    \sine[10] ,
    \sine[9] ,
    \sine[8] ,
    \sine[7] ,
    \sine[6] ,
    \sine[5] ,
    \sine[4] ,
    \sine[3] ,
    \sine[2] ,
    \sine[1] ,
    \sine[0] ,
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
    sys_clk,
    rst_n,
    rx_clk_in_p,
    rx_frame_in_p,
    data_clk,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \rx_data_in[11] ;
input \rx_data_in[10] ;
input \rx_data_in[9] ;
input \rx_data_in[8] ;
input \rx_data_in[7] ;
input \rx_data_in[6] ;
input \rx_data_in[5] ;
input \rx_data_in[4] ;
input \rx_data_in[3] ;
input \rx_data_in[2] ;
input \rx_data_in[1] ;
input \rx_data_in[0] ;
input \sine[11] ;
input \sine[10] ;
input \sine[9] ;
input \sine[8] ;
input \sine[7] ;
input \sine[6] ;
input \sine[5] ;
input \sine[4] ;
input \sine[3] ;
input \sine[2] ;
input \sine[1] ;
input \sine[0] ;
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
input sys_clk;
input rst_n;
input rx_clk_in_p;
input rx_frame_in_p;
input data_clk;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \rx_data_in[11] ;
wire \rx_data_in[10] ;
wire \rx_data_in[9] ;
wire \rx_data_in[8] ;
wire \rx_data_in[7] ;
wire \rx_data_in[6] ;
wire \rx_data_in[5] ;
wire \rx_data_in[4] ;
wire \rx_data_in[3] ;
wire \rx_data_in[2] ;
wire \rx_data_in[1] ;
wire \rx_data_in[0] ;
wire \sine[11] ;
wire \sine[10] ;
wire \sine[9] ;
wire \sine[8] ;
wire \sine[7] ;
wire \sine[6] ;
wire \sine[5] ;
wire \sine[4] ;
wire \sine[3] ;
wire \sine[2] ;
wire \sine[1] ;
wire \sine[0] ;
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
wire sys_clk;
wire rst_n;
wire rx_clk_in_p;
wire rx_frame_in_p;
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
    .data_i({\rx_data_in[11] ,\rx_data_in[10] ,\rx_data_in[9] ,\rx_data_in[8] ,\rx_data_in[7] ,\rx_data_in[6] ,\rx_data_in[5] ,\rx_data_in[4] ,\rx_data_in[3] ,\rx_data_in[2] ,\rx_data_in[1] ,\rx_data_in[0] ,\sine[11] ,\sine[10] ,\sine[9] ,\sine[8] ,\sine[7] ,\sine[6] ,\sine[5] ,\sine[4] ,\sine[3] ,\sine[2] ,\sine[1] ,\sine[0] ,\adc_data_out_i1[11] ,\adc_data_out_i1[10] ,\adc_data_out_i1[9] ,\adc_data_out_i1[8] ,\adc_data_out_i1[7] ,\adc_data_out_i1[6] ,\adc_data_out_i1[5] ,\adc_data_out_i1[4] ,\adc_data_out_i1[3] ,\adc_data_out_i1[2] ,\adc_data_out_i1[1] ,\adc_data_out_i1[0] ,\adc_data_out_q1[11] ,\adc_data_out_q1[10] ,\adc_data_out_q1[9] ,\adc_data_out_q1[8] ,\adc_data_out_q1[7] ,\adc_data_out_q1[6] ,\adc_data_out_q1[5] ,\adc_data_out_q1[4] ,\adc_data_out_q1[3] ,\adc_data_out_q1[2] ,\adc_data_out_q1[1] ,\adc_data_out_q1[0] ,\dac_data_in_i1[11] ,\dac_data_in_i1[10] ,\dac_data_in_i1[9] ,\dac_data_in_i1[8] ,\dac_data_in_i1[7] ,\dac_data_in_i1[6] ,\dac_data_in_i1[5] ,\dac_data_in_i1[4] ,\dac_data_in_i1[3] ,\dac_data_in_i1[2] ,\dac_data_in_i1[1] ,\dac_data_in_i1[0] ,\dac_data_in_q1[11] ,\dac_data_in_q1[10] ,\dac_data_in_q1[9] ,\dac_data_in_q1[8] ,\dac_data_in_q1[7] ,\dac_data_in_q1[6] ,\dac_data_in_q1[5] ,\dac_data_in_q1[4] ,\dac_data_in_q1[3] ,\dac_data_in_q1[2] ,\dac_data_in_q1[1] ,\dac_data_in_q1[0] ,sys_clk,rst_n,rx_clk_in_p,rx_frame_in_p,data_clk}),
    .clk_i(data_clk)
);

endmodule
