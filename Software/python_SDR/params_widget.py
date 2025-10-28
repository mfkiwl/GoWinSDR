from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QGridLayout, QLabel,
                             QComboBox, QPushButton, QLineEdit, QGroupBox,
                             QTabWidget, QScrollArea, QFrame, QHBoxLayout)
from PyQt6.QtCore import pyqtSignal, Qt


class ParamsWidget(QWidget):
    """
    参数配置区 (AD9363 专用版)
    """
    # 信号: 发送格式化好的命令 (例如 "tx_lo_freq=1000")
    send_command_signal = pyqtSignal(str)
    # 信号: 请求查询所有参数
    query_all_signal = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.init_ui()

    def init_ui(self):
        main_layout = QVBoxLayout(self)

        group = QGroupBox("AD9363 参数配置")
        group_layout = QVBoxLayout(group)

        # 使用 Tab 来组织 TX 和 RX
        self.tabs = QTabWidget()

        # --- 创建 TX 和 RX 的 Tab ---
        self.tx_tab = QScrollArea()
        self.rx_tab = QScrollArea()
        self.tabs.addTab(self.tx_tab, "TX (发射)")
        self.tabs.addTab(self.rx_tab, "RX (接收)")

        self.tx_tab.setWidgetResizable(True)
        self.rx_tab.setWidgetResizable(True)

        self.init_tx_tab()  # 初始化 TX Tab 的内容
        self.init_rx_tab()  # 初始化 RX Tab 的内容

        group_layout.addWidget(self.tabs)

        # --- 手动查询按钮 ---
        self.btn_query_all = QPushButton("手动查询所有参数")
        group_layout.addWidget(self.btn_query_all)

        main_layout.addWidget(group)

        # 连接信号
        self.btn_query_all.clicked.connect(self.query_all_signal.emit)

        self.set_enabled(False)  # 默认禁用

    def create_param_entry(self, label, command_name):
        """
        辅助函数: 创建一个 "标签 - 输入框 - 设置按钮" 的 UI 行
        """
        h_layout = QHBoxLayout()
        h_layout.addWidget(QLabel(label))

        line_edit = QLineEdit()
        line_edit.setPlaceholderText("N/A")
        h_layout.addWidget(line_edit)

        btn_set = QPushButton("Set")

        # --- 关键修复 (lambda 闭包问题) ---
        # 我们将 command_name 和 line_edit 作为默认参数传递
        # 以便在创建 lambda 时“捕获”它们的当前值
        btn_set.clicked.connect(lambda checked=False, cmd=command_name, le=line_edit:
                                self.send_command_signal.emit(f"{cmd}={le.text()}")
                                )
        # --- 修复结束 ---

        h_layout.addWidget(btn_set)

        return h_layout, line_edit

    def init_tx_tab(self):
        tx_widget = QWidget()
        tx_layout = QVBoxLayout(tx_widget)

        # --- TX LO Freq ---
        layout, self.le_tx_lo_freq = self.create_param_entry("TX LO Freq (MHz):", "tx_lo_freq")
        tx_layout.addLayout(layout)

        # --- TX Samp Freq ---
        layout, self.le_tx_samp_freq = self.create_param_entry("TX Samp Freq (Hz):", "tx_samp_freq")
        tx_layout.addLayout(layout)

        # --- TX RF Bandwidth ---
        layout, self.le_tx_rf_bw = self.create_param_entry("TX RF BW (Hz):", "tx_rf_bandwidth")
        tx_layout.addLayout(layout)

        # --- TX1 Attenuation ---
        layout, self.le_tx1_atten = self.create_param_entry("TX1 Atten (mdB):", "tx1_attenuation")
        tx_layout.addLayout(layout)

        # --- TX2 Attenuation ---
        layout, self.le_tx2_atten = self.create_param_entry("TX2 Atten (mdB):", "tx2_attenuation")
        tx_layout.addLayout(layout)

        # --- TX FIR Enable ---
        layout, self.le_tx_fir_en = self.create_param_entry("TX FIR (1/0):", "tx_fir_en")
        tx_layout.addLayout(layout)

        # --- DDS TX1 Tone1 Freq ---
        layout, self.le_dds_tx1_t1_freq = self.create_param_entry("DDS T1 Freq (Hz):", "dds_tx1_tone1_freq")
        tx_layout.addLayout(layout)

        # --- DDS TX2 Tone1 Freq ---
        layout, self.le_dds_tx2_t1_freq = self.create_param_entry("DDS T2 Freq (Hz):", "dds_tx2_tone1_freq")
        tx_layout.addLayout(layout)

        tx_layout.addStretch()
        self.tx_tab.setWidget(tx_widget)

    def init_rx_tab(self):
        rx_widget = QWidget()
        rx_layout = QVBoxLayout(rx_widget)

        # --- RX LO Freq ---
        layout, self.le_rx_lo_freq = self.create_param_entry("RX LO Freq (MHz):", "rx_lo_freq")
        rx_layout.addLayout(layout)

        # --- RX Samp Freq ---
        layout, self.le_rx_samp_freq = self.create_param_entry("RX Samp Freq (Hz):", "rx_samp_freq")
        rx_layout.addLayout(layout)

        # --- RX RF Bandwidth ---
        layout, self.le_rx_rf_bw = self.create_param_entry("RX RF BW (Hz):", "rx_rf_bandwidth")
        rx_layout.addLayout(layout)

        # --- RX1 Gain Control Mode ---
        layout, self.le_rx1_gc_mode = self.create_param_entry("RX1 GC Mode:", "rx1_gc_mode")
        rx_layout.addLayout(layout)

        # --- RX1 RF Gain ---
        layout, self.le_rx1_rf_gain = self.create_param_entry("RX1 RF Gain:", "rx1_rf_gain")
        rx_layout.addLayout(layout)

        # --- RX2 Gain Control Mode ---
        layout, self.le_rx2_gc_mode = self.create_param_entry("RX2 GC Mode:", "rx2_gc_mode")
        rx_layout.addLayout(layout)

        # --- RX2 RF Gain ---
        layout, self.le_rx2_rf_gain = self.create_param_entry("RX2 RF Gain:", "rx2_rf_gain")
        rx_layout.addLayout(layout)

        # --- RX FIR Enable ---
        layout, self.le_rx_fir_en = self.create_param_entry("RX FIR (1/0):", "rx_fir_en")
        rx_layout.addLayout(layout)

        rx_layout.addStretch()
        self.rx_tab.setWidget(rx_widget)

    def set_enabled(self, enabled):
        """
        由主窗口调用，在连接后启用
        """
        self.setEnabled(enabled)
        # 遍历所有子控件 (按钮, 输入框等)
        for child in self.findChildren(QWidget):
            if isinstance(child, (QPushButton, QLineEdit, QComboBox, QTabWidget, QScrollArea)):
                child.setEnabled(enabled)

    # --- 公共更新方法 (由 MainWindow 调用) ---
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
        """ 在断开连接时清除所有字段 """
        for le in self.findChildren(QLineEdit):
            le.setText("")
            le.setPlaceholderText("N/A")

