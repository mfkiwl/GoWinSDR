from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout,
                             QLineEdit, QPushButton, QFileDialog, QGroupBox)
from PyQt6.QtCore import pyqtSignal


class FileSendWidget(QWidget):
    """
    专门用于文件发送的UI
    """
    # 信号: (file_path)
    send_file_clicked = pyqtSignal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.is_enabled = False
        self.init_ui()

    def init_ui(self):
        group = QGroupBox("发送文件")
        layout = QVBoxLayout(group)

        # --- 文件传输 ---
        file_layout = QHBoxLayout()
        self.txt_file_path = QLineEdit()
        self.txt_file_path.setReadOnly(True)
        self.txt_file_path.setPlaceholderText("请选择要发送的文件...")
        file_layout.addWidget(self.txt_file_path)

        self.btn_browse = QPushButton("浏览...")
        file_layout.addWidget(self.btn_browse)

        self.btn_send = QPushButton("发送文件")
        self.btn_send.setEnabled(False)

        layout.addLayout(file_layout)
        layout.addWidget(self.btn_send)

        # 设置主布局
        main_layout = QVBoxLayout(self)
        main_layout.addWidget(group)

        # 连接信号
        self.btn_browse.clicked.connect(self.browse_file)
        self.btn_send.clicked.connect(self.on_send_click)

        self.set_enabled(False)  # 默认禁用

    def browse_file(self):
        file_path, _ = QFileDialog.getOpenFileName(self, "选择文件", "", "所有文件 (*)")
        if file_path:
            self.txt_file_path.setText(file_path)
            if self.is_enabled:
                self.btn_send.setEnabled(True)

    def on_send_click(self):
        file_path = self.txt_file_path.text()
        if file_path:
            self.send_file_clicked.emit(file_path)

    def set_enabled(self, enabled):
        """
        由主窗口调用，在连接后启用
        """
        self.is_enabled = enabled
        self.btn_browse.setEnabled(enabled)
        # 只有在选择了文件并且已连接时才启用发送按钮
        self.btn_send.setEnabled(enabled and bool(self.txt_file_path.text()))
