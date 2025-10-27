from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QGridLayout, QLabel,
                             QLineEdit, QPushButton, QSpinBox, QGroupBox)
from PyQt6.QtCore import pyqtSignal


class EthernetWidget(QWidget):
    """
    网络配置区 (UDP)
    """
    # 信号: (listen_ip, listen_port, fpga_ip, fpga_port)
    start_listening_clicked = pyqtSignal(str, int, str, int)
    stop_listening_clicked = pyqtSignal()
    send_command_clicked = pyqtSignal(str)  # 用于测试

    def __init__(self, parent=None):
        super().__init__(parent)
        self.init_ui()

    def init_ui(self):
        main_layout = QVBoxLayout(self)

        # --- FPGA 目标地址 (用于发送命令) ---
        group_fpga = QGroupBox("FPGA 目标地址 (用于发送)")
        layout_fpga = QGridLayout(group_fpga)

        layout_fpga.addWidget(QLabel("FPGA IP:"), 0, 0)
        self.txt_fpga_ip = QLineEdit("192.168.1.100")
        layout_fpga.addWidget(self.txt_fpga_ip, 0, 1)

        layout_fpga.addWidget(QLabel("FPGA 端口:"), 1, 0)
        self.spin_fpga_port = QSpinBox()
        self.spin_fpga_port.setRange(1, 65535)
        self.spin_fpga_port.setValue(8080)
        layout_fpga.addWidget(self.spin_fpga_port, 1, 1)

        # --- 本地监听设置 (用于接收视频) ---
        group_local = QGroupBox("本地监听设置 (用于接收)")
        layout_local = QGridLayout(group_local)

        layout_local.addWidget(QLabel("本地 IP:"), 0, 0)
        self.txt_listen_ip = QLineEdit("0.0.0.0")
        layout_local.addWidget(self.txt_listen_ip, 0, 1)

        layout_local.addWidget(QLabel("本地端口:"), 1, 0)
        self.spin_listen_port = QSpinBox()
        self.spin_listen_port.setRange(1, 65535)
        self.spin_listen_port.setValue(8081)
        layout_local.addWidget(self.spin_listen_port, 1, 1)

        # --- 控制按钮 ---
        self.btn_start = QPushButton("开始监听 (UDP)")
        self.btn_stop = QPushButton("停止监听")
        self.btn_stop.setEnabled(False)

        self.btn_send_cmd = QPushButton("发送测试命令")
        self.btn_send_cmd.setEnabled(False)  # 监听开始后才启用

        main_layout.addWidget(group_fpga)
        main_layout.addWidget(group_local)
        main_layout.addWidget(self.btn_start)
        main_layout.addWidget(self.btn_stop)
        main_layout.addWidget(self.btn_send_cmd)

        # 连接信号
        self.btn_start.clicked.connect(self.on_start_click)
        self.btn_stop.clicked.connect(self.on_stop_click)
        self.btn_send_cmd.clicked.connect(
            lambda: self.send_command_clicked.emit("TEST_CMD_FROM_APP")
        )

    def on_start_click(self):
        self.start_listening_clicked.emit(
            self.txt_listen_ip.text(),
            self.spin_listen_port.value(),
            self.txt_fpga_ip.text(),
            self.spin_fpga_port.value()
        )

    def on_stop_click(self):
        self.stop_listening_clicked.emit()

    def set_connection_state(self, listening):
        """
        由主窗口调用，更新UI状态
        """
        self.btn_start.setEnabled(not listening)
        self.btn_stop.setEnabled(listening)
        self.btn_send_cmd.setEnabled(listening)  # 监听时才可发送

        # 监听时不应更改设置
        self.txt_fpga_ip.setEnabled(not listening)
        self.spin_fpga_port.setEnabled(not listening)
        self.txt_listen_ip.setEnabled(not listening)
        self.spin_listen_port.setEnabled(not listening)

