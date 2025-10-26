from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QGridLayout, QLabel,
                             QLineEdit, QPushButton, QSpinBox, QGroupBox)
from PyQt6.QtCore import pyqtSignal


class EthernetWidget(QWidget):
    """
    网络配置区 (左侧)
    包含 IP、端口和连接按钮
    """
    # 信号: (ip, port)
    connect_clicked = pyqtSignal(str, int)
    disconnect_clicked = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.init_ui()

    def init_ui(self):
        group = QGroupBox("网络配置 (TCP)")
        layout = QVBoxLayout(group)

        grid = QGridLayout()
        grid.addWidget(QLabel("FPGA IP:"), 0, 0)
        self.txt_ip = QLineEdit("192.168.1.100")
        grid.addWidget(self.txt_ip, 0, 1)

        grid.addWidget(QLabel("端口:"), 1, 0)
        self.spin_port = QSpinBox()
        self.spin_port.setRange(1, 65535)
        self.spin_port.setValue(8080)
        grid.addWidget(self.spin_port, 1, 1)

        self.btn_connect = QPushButton("连接TCP")
        self.btn_disconnect = QPushButton("断开连接")
        self.btn_disconnect.setEnabled(False)

        layout.addLayout(grid)
        layout.addWidget(self.btn_connect)
        layout.addWidget(self.btn_disconnect)

        # 设置主布局
        main_layout = QVBoxLayout(self)
        main_layout.addWidget(group)

        # 连接信号
        self.btn_connect.clicked.connect(self.on_connect_click)
        self.btn_disconnect.clicked.connect(self.on_disconnect_click)

    def on_connect_click(self):
        ip = self.txt_ip.text()
        port = self.spin_port.value()
        if ip:
            self.connect_clicked.emit(ip, port)

    def on_disconnect_click(self):
        self.disconnect_clicked.emit()

    def set_connection_state(self, connected):
        """
        由主窗口调用，更新UI状态
        """
        self.btn_connect.setEnabled(not connected)
        self.btn_disconnect.setEnabled(connected)
        self.txt_ip.setEnabled(not connected)
        self.spin_port.setEnabled(not connected)
