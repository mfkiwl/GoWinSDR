from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QGridLayout, QLabel,
                             QComboBox, QPushButton, QGroupBox)  # <-- 导入 QGroupBox
from PyQt6.QtCore import pyqtSignal
from serial_worker import SerialWorker  # 仅用于获取端口列表


class ConfigWidget(QWidget):
    """
    配置区 (左上角)
    包含串口、波特率设置和连接按钮
    """
    # 定义信号: (port, baudrate)
    connect_clicked = pyqtSignal(str, str)
    disconnect_clicked = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.init_ui()

    def init_ui(self):
        # --- 修改 ---
        group = QGroupBox("串口配置")
        layout = QVBoxLayout(group)  # <-- 布局添加到 GroupBox
        # --- 结束修改 ---

        layout.setContentsMargins(5, 5, 5, 5)

        grid = QGridLayout()
        grid.addWidget(QLabel("串口号:"), 0, 0)
        self.cb_ports = QComboBox()
        grid.addWidget(self.cb_ports, 0, 1)

        self.btn_refresh = QPushButton("刷新")
        grid.addWidget(self.btn_refresh, 0, 2)

        grid.addWidget(QLabel("波特率:"), 1, 0)
        self.cb_baudrate = QComboBox()
        self.cb_baudrate.addItems(['9600', '19200', '38400', '57600', '115200', '921600'])
        self.cb_baudrate.setCurrentText("115200")
        grid.addWidget(self.cb_baudrate, 1, 1, 1, 2)

        self.btn_connect = QPushButton("连接")
        self.btn_disconnect = QPushButton("断开连接")
        self.btn_disconnect.setEnabled(False)

        layout.addLayout(grid)
        layout.addWidget(self.btn_connect)
        layout.addWidget(self.btn_disconnect)
        # layout.addStretch() # 移除, GroupBox不需要

        # --- 新增 ---
        # 设置主布局
        main_layout = QVBoxLayout(self)
        main_layout.addWidget(group)
        # --- 结束新增 ---

        # 连接信号
        self.btn_refresh.clicked.connect(self.refresh_ports)
        self.btn_connect.clicked.connect(self.on_connect_click)
        self.btn_disconnect.clicked.connect(self.on_disconnect_click)

        self.refresh_ports()

    def refresh_ports(self):
        self.cb_ports.clear()
        ports = SerialWorker.get_available_ports()
        if ports:
            self.cb_ports.addItems(ports)
        else:
            self.cb_ports.addItem("未找到串口")

    def on_connect_click(self):
        port = self.cb_ports.currentText()
        baud = self.cb_baudrate.currentText()
        if port != "未找到串口":
            self.connect_clicked.emit(port, baud)

    def on_disconnect_click(self):
        self.disconnect_clicked.emit()

    def set_connection_state(self, connected):
        """
        由主窗口调用，更新UI状态
        """
        self.btn_connect.setEnabled(not connected)
        self.btn_disconnect.setEnabled(connected)
        self.cb_ports.setEnabled(not connected)
        self.cb_baudrate.setEnabled(not connected)
        self.btn_refresh.setEnabled(not connected)

