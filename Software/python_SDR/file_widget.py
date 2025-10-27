from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout, QLabel,
                             QLineEdit, QPushButton, QFileDialog, QGroupBox)
from PyQt6.QtCore import pyqtSignal


class FileWidget(QWidget):
    """
    文件传输区 (右上角)
    """
    # 信号: (file_path)
    send_file_clicked = pyqtSignal(str)
    send_text_clicked = pyqtSignal(str)
    start_audio_recording = pyqtSignal()
    stop_audio_recording = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.init_ui()

    def init_ui(self):
        group = QGroupBox("传输文件、文本及语音")
        layout = QVBoxLayout(group)

        # --- 文本传输 ---
        text_layout = QHBoxLayout()
        self.txt_message = QLineEdit()
        self.txt_message.setPlaceholderText("请输入要发送的文本...")
        text_layout.addWidget(self.txt_message)

        self.btn_send_text = QPushButton("发送文本")
        self.btn_send_text.setEnabled(False)
        text_layout.addWidget(self.btn_send_text)

        layout.addLayout(text_layout)

        # --- 语音传输 ---
        audio_layout = QHBoxLayout()
        self.btn_start_recording = QPushButton("开始录制")
        self.btn_stop_recording = QPushButton("停止录制")
        self.btn_stop_recording.setEnabled(False)

        audio_layout.addWidget(self.btn_start_recording)
        audio_layout.addWidget(self.btn_stop_recording)

        layout.addLayout(audio_layout)

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
        self.txt_message.textChanged.connect(self.on_text_changed)
        self.btn_send_text.clicked.connect(self.on_send_text_click)
        self.btn_browse.clicked.connect(self.browse_file)
        self.btn_send.clicked.connect(self.on_send_click)
        self.btn_start_recording.clicked.connect(self.on_start_recording)
        self.btn_stop_recording.clicked.connect(self.on_stop_recording)

        self.set_enabled(False)  # 默认禁用

    def on_text_changed(self, text):
        self.btn_send_text.setEnabled(bool(text.strip()))

    def on_send_text_click(self):
        text = self.txt_message.text().strip()
        if text:
            self.send_text_clicked.emit(text)

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

    def on_start_recording(self):
        self.start_audio_recording.emit()
        self.btn_start_recording.setEnabled(False)
        self.btn_stop_recording.setEnabled(True)

    def on_stop_recording(self):
        self.stop_audio_recording.emit()
        self.btn_start_recording.setEnabled(True)
        self.btn_stop_recording.setEnabled(False)

    def set_enabled(self, enabled):
        """
        由主窗口调用，在连接后启用
        """
        self.is_enabled = enabled
        self.txt_message.setEnabled(enabled)
        self.btn_send_text.setEnabled(enabled and bool(self.txt_message.text().strip()))
        self.btn_browse.setEnabled(enabled)
        self.btn_send.setEnabled(enabled and bool(self.txt_file_path.text()))
        self.btn_start_recording.setEnabled(enabled)
        self.btn_stop_recording.setEnabled(False)