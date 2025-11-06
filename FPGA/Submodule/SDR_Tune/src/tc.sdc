//# 创建DATA_CLK时钟（30.72MHz）
//create_clock -name data_clk -period 32.552 [get_ports {rx_clk_in_p}]

//# RX数据输入延迟
//set_input_delay -clock data_clk -max 5.0 [get_ports {rx_data_in[*]]
//set_input_delay -clock data_clk -min 1.0 [get_ports [rx_data_in[*]]
//set_input_delay -clock data_clk -max 5.0 [get_ports {rx_frame_in_p}]
//set_input_delay -clock data_clk -min 1.0 [get_ports {rx_frame_in_p]}

//# TX数据输出延迟
//set_output_delay -clock data_clk -max 3.0 [get_ports {tx_data_out[*]]}
//set_output_delay -clock data_clk -min 0.5 [get_ports {tx_data_out[*]]}
//set_output_delay -clock data_clk -max 3.0 [get_ports {tx_frame_out_p]}
//set_output_delay -clock data_clk -min 0.5 [get_ports {tx_frame_out_p]}

//# 设置虚拟时钟
//set_output_delay -clock data_clk -max 3.0 [get_ports {tx_clk_out_p]}