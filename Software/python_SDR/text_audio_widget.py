from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout, QLabel,
                             QLineEdit, QPushButton, QFileDialog, QGroupBox)
from PyQt6.QtCore import pyqtSignal

# --- 修复: 类名从 FileWidget 更改为 TextAudioWidget ---
class TextAudioWidget(QWidget):
    """
    传输文本和录制语音的UI
    (原 file_widget.py, 已移除文件发送功能)
    """
    send_text_clicked = pyqtSignal(str)
    start_audio_recording = pyqtSignal()
    stop_audio_recording = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.is_enabled = False # 内部状态
        self.init_ui()
        self.setFixedHeight(150)

    def init_ui(self):
        # --- 修改: 组标题 ---
        group = QGroupBox("发送文本及语音")
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

        # --- 文件传输 (已移除) ---

        # 设置主布局
        main_layout = QVBoxLayout(self)
        main_layout.addWidget(group)

        # 连接信号
        self.txt_message.textChanged.connect(self.on_text_changed)
        self.btn_send_text.clicked.connect(self.on_send_text_click)
        self.btn_start_recording.clicked.connect(self.on_start_recording)
        self.btn_stop_recording.clicked.connect(self.on_stop_recording)

        self.set_enabled(False)  # 默认禁用

    def on_text_changed(self, text):
        # --- 修复: 检查 self.is_enabled ---
        if self.is_enabled: # 只有在启用时才更新
            self.btn_send_text.setEnabled(bool(text.strip()))
        # --- 结束修复 ---

    def on_send_text_click(self):
        text = self.txt_message.text().strip()
        if text:
            self.send_text_clicked.emit(text)

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
        # 保持 "发送文本" 按钮的状态依赖于文本内容
        self.btn_send_text.setEnabled(enabled and bool(self.txt_message.text().strip()))
        self.btn_start_recording.setEnabled(enabled)
        # 停止录制按钮只有在开始后才启用，所以这里保持禁用
        self.btn_stop_recording.setEnabled(False)

