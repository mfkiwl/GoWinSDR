from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout,
                             QLineEdit, QPushButton, QFileDialog, QGroupBox,
                             QLabel, QProgressBar)
from PyQt6.QtCore import pyqtSignal
import os


class FileSendWidget(QWidget):
    """
    专门用于文件发送的UI (带进度条和速率显示)
    """
    # 信号: (file_path)
    send_file_clicked = pyqtSignal(str)

    def __init__(self, parent = None):
        super().__init__(parent)
        self.is_enabled = False
        self.init_ui()
        self.setFixedHeight(450)

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

        # === 文件信息显示区域 ===
        self.file_info_group = QGroupBox("文件信息")
        self.file_info_group.setVisible(False)
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

        # === 新增: 传输进度区域 ===
        self.progress_group = QGroupBox("传输进度")
        self.progress_group.setVisible(False)
        progress_layout = QVBoxLayout(self.progress_group)
        progress_layout.setSpacing(8)
        progress_layout.setContentsMargins(10, 10, 10, 10)

        # 进度条
        self.progress_bar = QProgressBar()
        self.progress_bar.setMinimum(0)
        self.progress_bar.setMaximum(100)
        self.progress_bar.setValue(0)
        self.progress_bar.setTextVisible(True)
        self.progress_bar.setFormat("%p%")
        progress_layout.addWidget(self.progress_bar)

        # 传输信息
        info_layout = QHBoxLayout()

        # 已发送 / 总大小
        self.lbl_progress_info = QLabel("准备发送...")
        self.lbl_progress_info.setStyleSheet("color: #555;")
        info_layout.addWidget(self.lbl_progress_info)
        info_layout.addStretch()

        # 实时速率
        self.lbl_speed = QLabel("速率: -- MB/s")
        self.lbl_speed.setStyleSheet("color: #0066cc; font-weight: bold;")
        info_layout.addWidget(self.lbl_speed)

        progress_layout.addLayout(info_layout)

        # 预计剩余时间
        time_layout = QHBoxLayout()
        self.lbl_time_remaining = QLabel("预计剩余: --")
        self.lbl_time_remaining.setStyleSheet("color: #666;")
        time_layout.addWidget(self.lbl_time_remaining)
        time_layout.addStretch()
        progress_layout.addLayout(time_layout)

        layout.addWidget(self.progress_group)
        # === 结束新增 ===

        # 添加弹性空间
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
        self.set_enabled(False)

    def browse_file(self):
        file_path, _ = QFileDialog.getOpenFileName(self, "选择文件", "", "所有文件 (*)")
        if file_path:
            self.txt_file_path.setText(file_path)
            self.update_file_info(file_path)
            # 重置进度显示
            self.reset_progress()
            if self.is_enabled:
                self.btn_send.setEnabled(True)

    def update_file_info(self, file_path):
        """更新文件信息显示"""
        try:
            file_name = os.path.basename(file_path)
            file_size = os.path.getsize(file_path)
            file_ext = os.path.splitext(file_path)[1]

            size_str = self.format_file_size(file_size)

            self.lbl_file_name.setText(file_name)
            self.lbl_file_size.setText(size_str)
            self.lbl_file_type.setText(file_ext if file_ext else "无扩展名")
            self.lbl_full_path.setText(file_path)

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

    def on_send_click(self):
        file_path = self.txt_file_path.text()
        if file_path:
            self.start_transfer()
            self.send_file_clicked.emit(file_path)

    def set_enabled(self, enabled):
        """由主窗口调用,在连接后启用"""
        self.is_enabled = enabled
        self.btn_browse.setEnabled(enabled)
        self.btn_send.setEnabled(enabled and bool(self.txt_file_path.text()))

    # === 新增: 进度控制方法 ===
    def start_transfer(self):
        """开始传输时调用"""
        self.progress_group.setVisible(True)
        self.progress_bar.setValue(0)
        self.lbl_progress_info.setText("正在发送...")
        self.lbl_speed.setText("速率: -- MB/s")
        self.lbl_time_remaining.setText("预计剩余: 计算中...")
        self.btn_send.setEnabled(False)

    def update_progress(self, sent_bytes, total_bytes, speed_mbps):
        """
        更新进度信息
        :param sent_bytes: 已发送字节数
        :param total_bytes: 总字节数
        :param speed_mbps: 实时速率 (Mbps)
        """
        if total_bytes == 0:
            return

        # 更新进度条
        progress = int((sent_bytes / total_bytes) * 100)
        self.progress_bar.setValue(progress)

        # 更新已发送信息
        sent_str = self.format_file_size(sent_bytes)
        total_str = self.format_file_size(total_bytes)
        self.lbl_progress_info.setText(f"{sent_str} / {total_str}")

        # 更新速率 (显示为 Mbps)
        self.lbl_speed.setText(f"速率: {speed_mbps:.2f} Mbps")

        # 计算预计剩余时间
        if speed_mbps > 0:
            remaining_bytes = total_bytes - sent_bytes
            remaining_bits = remaining_bytes * 8
            remaining_seconds = remaining_bits / (speed_mbps * 1_000_000)

            if remaining_seconds < 60:
                time_str = f"{remaining_seconds:.1f} 秒"
            elif remaining_seconds < 3600:
                time_str = f"{remaining_seconds / 60:.1f} 分钟"
            else:
                time_str = f"{remaining_seconds / 3600:.1f} 小时"

            self.lbl_time_remaining.setText(f"预计剩余: {time_str}")
        else:
            self.lbl_time_remaining.setText("预计剩余: 计算中...")

    def finish_transfer(self, success = True, message = ""):
        """传输完成时调用"""
        if success:
            self.progress_bar.setValue(100)
            self.lbl_progress_info.setText("传输完成!")
            self.lbl_progress_info.setStyleSheet("color: green; font-weight: bold;")
            self.lbl_time_remaining.setText("已完成")
        else:
            self.lbl_progress_info.setText(f"传输失败: {message}")
            self.lbl_progress_info.setStyleSheet("color: red; font-weight: bold;")
            self.lbl_time_remaining.setText("已中断")

        self.btn_send.setEnabled(True)

    def reset_progress(self):
        """重置进度显示"""
        self.progress_group.setVisible(False)
        self.progress_bar.setValue(0)
        self.lbl_progress_info.setText("准备发送...")
        self.lbl_progress_info.setStyleSheet("color: #555;")
        self.lbl_speed.setText("速率: -- MB/s")
        self.lbl_time_remaining.setText("预计剩余: --")
    # === 结束新增 ===