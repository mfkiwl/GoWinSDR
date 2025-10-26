from PyQt6.QtWidgets import QWidget, QVBoxLayout, QTextEdit, QGroupBox
from PyQt6.QtCore import QDateTime


class LogWidget(QWidget):
    """
    状态日志区 (右下角)
    """

    def __init__(self, parent=None):
        super().__init__(parent)
        self.init_ui()

    def init_ui(self):
        group = QGroupBox("状态日志")
        layout = QVBoxLayout(group)

        self.log_edit = QTextEdit()
        self.log_edit.setReadOnly(True)
        layout.addWidget(self.log_edit)

        # 设置主布局
        main_layout = QVBoxLayout(self)
        main_layout.addWidget(group)

    def append_log(self, message):
        """
        公共方法，用于添加日志
        """
        time_str = QDateTime.currentDateTime().toString("hh:mm:ss")
        self.log_edit.append(f"[{time_str}] {message}")
        # 自动滚动到底部
        self.log_edit.verticalScrollBar().setValue(self.log_edit.verticalScrollBar().maximum())
