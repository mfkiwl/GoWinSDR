"""
存储所有 AD9363 需要在连接时查询的 "GET" 命令
"""

AD9363_GET_COMMANDS = [
    # TX
    "tx_lo_freq?",
    "tx_samp_freq?",
    "tx_rf_bandwidth?",
    "tx1_attenuation?",
    "tx2_attenuation?",
    "tx_fir_en?",

    # RX
    "rx_lo_freq?",
    "rx_samp_freq?",
    "rx_rf_bandwidth?",
    "rx1_gc_mode?",
    "rx2_gc_mode?",
    "rx1_rf_gain?",
    "rx2_rf_gain?",
    "rx_fir_en?",

    # DDS (只查询关键的)
    "dds_tx1_tone1_freq?",
    "dds_tx2_tone1_freq?",
]
