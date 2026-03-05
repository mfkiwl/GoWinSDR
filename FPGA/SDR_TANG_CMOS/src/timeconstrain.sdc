create_clock -name {RX_CLK_125M} -period 8.000 [get_ports {RGMII_RXCLK}]

set_input_delay -clock {RX_CLK_125M} -max 3.500 [get_ports {RGMII_RXD[*] RGMII_RXDV}]

set_input_delay -clock {RX_CLK_125M} -min 1.000 [get_ports {RGMII_RXD[*] RGMII_RXDV}]

set_input_delay -clock {RX_CLK_125M} -clock_fall -max 3.500 [get_ports {RGMII_RXD[*] RGMII_RXDV}] -add_delay
set_input_delay -clock {RX_CLK_125M} -clock_fall -min 1.000 [get_ports {RGMII_RXD[*] RGMII_RXDV}] -add_delay

