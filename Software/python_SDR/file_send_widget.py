from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout,
                             QLineEdit, QPushButton, QFileDialog, QGroupBox,
                             QLabel, QTextEdit)
from PyQt6.QtCore import pyqtSignal
import os


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
        self.setFixedHeight(380)

    def init_ui(self):
        group = QGroupBox("发送文件")
        layout = QVBoxLayout(group)

        # --- 文件选择 ---
        file_layout = QHBoxLayout()
        self.txt_file_path = QLineEdit()
        self.txt_file_path.setReadOnly(True)
        self.txt_file_path.setPlaceholderText("请选择要发送的文件...")
        file_layout.addWidget(self.txt_file_path)

        self.btn_browse = QPushButton("浏览...")
        file_layout.addWidget(self.btn_browse)

        layout.addLayout(file_layout)

        # === 新增: 文件信息显示区域 ===
        self.file_info_group = QGroupBox("文件信息")
        self.file_info_group.setVisible(False)  # 默认隐藏
        file_info_layout = QVBoxLayout(self.file_info_group)
        file_info_layout.setSpacing(5)
        file_info_layout.setContentsMargins(10, 10, 10, 10)

        # 文件名
        name_layout = QHBoxLayout()
        name_layout.addWidget(QLabel("文件名:"))
        self.lbl_file_name = QLabel("")
        self.lbl_file_name.setStyleSheet("font-weight: bold;")
        name_layout.addWidget(self.lbl_file_name)
        name_layout.addStretch()
        file_info_layout.addLayout(name_layout)

        # 文件大小
        size_layout = QHBoxLayout()
        size_layout.addWidget(QLabel("文件大小:"))
        self.lbl_file_size = QLabel("")
        size_layout.addWidget(self.lbl_file_size)
        size_layout.addStretch()
        file_info_layout.addLayout(size_layout)

        # 文件类型
        type_layout = QHBoxLayout()
        type_layout.addWidget(QLabel("文件类型:"))
        self.lbl_file_type = QLabel("")
        type_layout.addWidget(self.lbl_file_type)
        type_layout.addStretch()
        file_info_layout.addLayout(type_layout)

        # 完整路径
        path_layout = QVBoxLayout()
        path_layout.addWidget(QLabel("完整路径:"))
        self.lbl_full_path = QLabel("")
        self.lbl_full_path.setWordWrap(True)
        self.lbl_full_path.setStyleSheet("color: gray; font-size: 10px;")
        path_layout.addWidget(self.lbl_full_path)
        file_info_layout.addLayout(path_layout)

        layout.addWidget(self.file_info_group)
        # === 结束新增 ===

        # 添加弹性空间，将按钮推到底部
        layout.addStretch()

        # 发送按钮
        self.btn_send = QPushButton("发送文件")
        self.btn_send.setEnabled(False)
        self.btn_send.setMinimumHeight(35)
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
            self.update_file_info(file_path)  # === 新增: 更新文件信息 ===
            if self.is_enabled:
                self.btn_send.setEnabled(True)

    # === 新增: 更新文件信息的方法 ===
    def update_file_info(self, file_path):
        """更新文件信息显示"""
        try:
            # 获取文件信息
            file_name = os.path.basename(file_path)
            file_size = os.path.getsize(file_path)
            file_ext = os.path.splitext(file_path)[1]

            # 格式化文件大小
            size_str = self.format_file_size(file_size)

            # 更新标签
            self.lbl_file_name.setText(file_name)
            self.lbl_file_size.setText(size_str)
            self.lbl_file_type.setText(file_ext if file_ext else "无扩展名")
            self.lbl_full_path.setText(file_path)

            # 显示文件信息组
            self.file_info_group.setVisible(True)

        except Exception as e:
            self.lbl_file_name.setText("错误")
            self.lbl_file_size.setText(f"无法读取: {str(e)}")
            self.lbl_file_type.setText("未知")
            self.lbl_full_path.setText(file_path)
            self.file_info_group.setVisible(True)

    def format_file_size(self, size_bytes):
        """格式化文件大小"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.2f} PB"
    # === 结束新增 ===

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