# 文件名: py代码/params_widget.py
# (已修改：添加了“隐形”LAN按钮)

from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QGridLayout, QLabel,
                             QComboBox, QPushButton, QLineEdit, QGroupBox,
                             QTabWidget, QScrollArea, QFrame, QHBoxLayout)
from PyQt6.QtCore import pyqtSignal, Qt


class ParamsWidget(QWidget):
    """
    参数配置区 (AD9363 专用版)
    """
    send_command_signal = pyqtSignal(str)
    query_all_signal = pyqtSignal()

    # --- [!! 新增 !!] ---
    # 定义信号: (bool)
    # 当 "LAN" 按钮被切换时发出
    lan_mode_toggled = pyqtSignal(bool)

    # --- [!! 结束新增 !!] ---

    def __init__(self, parent=None):
        super().__init__(parent)
        self.init_ui()

    def init_ui(self):
        main_layout = QVBoxLayout(self)
        group = QGroupBox("AD9363 参数配置")
        group_layout = QVBoxLayout(group)
        self.tabs = QTabWidget()
        self.tx_tab = QScrollArea()
        self.rx_tab = QScrollArea()
        self.tabs.addTab(self.tx_tab, "TX (发射)")
        self.tabs.addTab(self.rx_tab, "RX (接收)")

        # --- [!! 新增: 添加P2P局域网模式按钮 !!] ---
        self.btn_lan_mode = QPushButton("LAN")
        self.btn_lan_mode.setCheckable(True)
        self.btn_lan_mode.setToolTip("切换到局域网P2P模式 (隐形)")
        # 设置样式使其 "很不显眼"
        self.btn_lan_mode.setStyleSheet("""
            QPushButton {
                background-color: transparent;
                border: 0px solid #555; /* 灰色边框 */
                color: transparent; /* 灰色文字 */
                padding: 1px 4px;
                max-width: 35px;
                font-size: 8pt;
            }
            QPushButton:checked {
                background-color: transparent; /* 激活时变为蓝色 */
                color: transparent;
                border: 0px solid #007bff;
                font-weight: bold;
            }
        """)

        # 将按钮放置在 Tab 控件的右上角 (你画红圈的位置)
        self.tabs.setCornerWidget(self.btn_lan_mode, Qt.Corner.TopRightCorner)

        # 连接信号
        self.btn_lan_mode.toggled.connect(self.lan_mode_toggled.emit)
        # --- [!! 结束新增 !!] ---

        self.tx_tab.setWidgetResizable(True)
        self.rx_tab.setWidgetResizable(True)
        self.init_tx_tab()
        self.init_rx_tab()
        group_layout.addWidget(self.tabs)
        self.btn_query_all = QPushButton("手动查询所有参数")
        group_layout.addWidget(self.btn_query_all)
        main_layout.addWidget(group)
        self.btn_query_all.clicked.connect(self.query_all_signal.emit)
        self.set_enabled(False)

    def create_param_entry(self, label, command_name):
        # (此方法保持不变)
        h_layout = QHBoxLayout()
        h_layout.addWidget(QLabel(label))
        line_edit = QLineEdit()
        line_edit.setPlaceholderText("N/A")
        h_layout.addWidget(line_edit)
        btn_set = QPushButton("Set")
        print(f"[ParamsWidget] Creating button for: {command_name}, Button Obj: {btn_set}")
        btn_set.clicked.connect(lambda checked=False, cmd=command_name, le=line_edit:
                                self.emit_set_command(cmd, le.text())
                                )
        print(f"[ParamsWidget] Connected clicked signal for: {command_name}")
        h_layout.addWidget(btn_set)
        return h_layout, line_edit

    def emit_set_command(self, command, value):
        # (此方法保持不变)
        command_str = f"{command}={value}"
        print(f"[ParamsWidget] emit_set_command called for: {command_str}")
        self.send_command_signal.emit(command_str)

    def init_tx_tab(self):
        # (此方法保持不变)
        tx_widget = QWidget()
        tx_layout = QVBoxLayout(tx_widget)
        layout, self.le_tx_lo_freq = self.create_param_entry("TX LO Freq (MHz):", "tx_lo_freq")
        tx_layout.addLayout(layout)
        layout, self.le_tx_samp_freq = self.create_param_entry("TX Samp Freq (Hz):", "tx_samp_freq")
        tx_layout.addLayout(layout)
        layout, self.le_tx_rf_bw = self.create_param_entry("TX RF BW (Hz):", "tx_rf_bandwidth")
        tx_layout.addLayout(layout)
        layout, self.le_tx1_atten = self.create_param_entry("TX1 Atten (mdB):", "tx1_attenuation")
        tx_layout.addLayout(layout)
        layout, self.le_tx2_atten = self.create_param_entry("TX2 Atten (mdB):", "tx2_attenuation")
        tx_layout.addLayout(layout)
        layout, self.le_tx_fir_en = self.create_param_entry("TX FIR (1/0):", "tx_fir_en")
        tx_layout.addLayout(layout)
        layout, self.le_dds_tx1_t1_freq = self.create_param_entry("DDS T1 Freq (Hz):", "dds_tx1_tone1_freq")
        tx_layout.addLayout(layout)
        layout, self.le_dds_tx2_t1_freq = self.create_param_entry("DDS T2 Freq (Hz):", "dds_tx2_tone1_freq")
        tx_layout.addLayout(layout)
        tx_layout.addStretch()
        self.tx_tab.setWidget(tx_widget)

    def init_rx_tab(self):
        # (此方法保持不变)
        rx_widget = QWidget()
        rx_layout = QVBoxLayout(rx_widget)
        layout, self.le_rx_lo_freq = self.create_param_entry("RX LO Freq (MHz):", "rx_lo_freq")
        rx_layout.addLayout(layout)
        layout, self.le_rx_samp_freq = self.create_param_entry("RX Samp Freq (Hz):", "rx_samp_freq")
        rx_layout.addLayout(layout)
        layout, self.le_rx_rf_bw = self.create_param_entry("RX RF BW (Hz):", "rx_rf_bandwidth")
        rx_layout.addLayout(layout)
        layout, self.le_rx1_gc_mode = self.create_param_entry("RX1 GC Mode:", "rx1_gc_mode")
        rx_layout.addLayout(layout)
        layout, self.le_rx1_rf_gain = self.create_param_entry("RX1 RF Gain:", "rx1_rf_gain")
        rx_layout.addLayout(layout)
        layout, self.le_rx2_gc_mode = self.create_param_entry("RX2 GC Mode:", "rx2_gc_mode")
        rx_layout.addLayout(layout)
        layout, self.le_rx2_rf_gain = self.create_param_entry("RX2 RF Gain:", "rx2_rf_gain")
        rx_layout.addLayout(layout)
        layout, self.le_rx_fir_en = self.create_param_entry("RX FIR (1/0):", "rx_fir_en")
        rx_layout.addLayout(layout)
        rx_layout.addStretch()
        self.rx_tab.setWidget(rx_widget)

    def set_enabled(self, enabled):
        # (此方法保持不变, 它的 findChildren 逻辑会自动包含新按钮)
        print(f"[ParamsWidget] set_enabled called with: {enabled}")
        self.setEnabled(enabled)
        for child in self.findChildren(QWidget):
            # 确保我们不会意外地禁用父容器本身
            if child != self and isinstance(child, (QPushButton, QLineEdit, QComboBox, QTabWidget, QScrollArea)):
                child.setEnabled(enabled)
        # --- 简化结束 ---

    # --- (公共更新方法保持不变) ---
    def update_tx_lo_freq(self, value):
        self.le_tx_lo_freq.setText(value)

    def update_tx_samp_freq(self, value):
        self.le_tx_samp_freq.setText(value)

    def update_tx_rf_bw(self, value):
        self.le_tx_rf_bw.setText(value)

    def update_tx1_atten(self, value):
        self.le_tx1_atten.setText(value)

    def update_tx2_atten(self, value):
        self.le_tx2_atten.setText(value)

    def update_tx_fir_en(self, value):
        self.le_tx_fir_en.setText(value)

    def update_rx_lo_freq(self, value):
        self.le_rx_lo_freq.setText(value)

    def update_rx_samp_freq(self, value):
        self.le_rx_samp_freq.setText(value)

    def update_rx_rf_bw(self, value):
        self.le_rx_rf_bw.setText(value)

    def update_rx1_gc_mode(self, value):
        self.le_rx1_gc_mode.setText(value)

    def update_rx2_gc_mode(self, value):
        self.le_rx2_gc_mode.setText(value)

    def update_rx1_rf_gain(self, value):
        self.le_rx1_rf_gain.setText(value)

    def update_rx2_rf_gain(self, value):
        self.le_rx2_rf_gain.setText(value)

    def update_rx_fir_en(self, value):
        self.le_rx_fir_en.setText(value)

    def update_dds_tx1_t1_freq(self, value):
        self.le_dds_tx1_t1_freq.setText(value)

    def update_dds_tx2_t1_freq(self, value):
        self.le_dds_tx2_t1_freq.setText(value)

    def clear_all_fields(self):
        # (此方法保持不变)
        for le in self.findChildren(QLineEdit):
            le.setText("")
            le.setPlaceholderText("N/A")