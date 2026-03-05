create_clock -name eth_clk125rx -period 8.0 -waveform {0 4.0} [get_ports {RGMII_RXCLK}]
create_clock -name eth_clk125tx -period 8.0 -waveform {0 4.0} [get_ports {RGMII_GTXCLK}]

set_input_delay -clock {eth_clk125rx} -max 3.500 [get_ports {RGMII_RXD[*] RGMII_RXDV}]

set_input_delay -clock {eth_clk125rx} -min 1.000 [get_ports {RGMII_RXD[*] RGMII_RXDV}]
set_input_delay -clock {eth_clk125rx} -clock_fall -max 3.500 [get_ports {RGMII_RXD[*] RGMII_RXDV}] -add_delay
set_input_delay -clock {eth_clk125rx} -clock_fall -min 1.000 [get_ports {RGMII_RXD[*] RGMII_RXDV}] -add_delay
