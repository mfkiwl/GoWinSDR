from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout,
                             QPushButton, QFileDialog, QGroupBox,
                             QTableWidget, QAbstractItemView, QHeaderView,
                             QTableWidgetItem, QProgressBar, QLabel)
from PyQt6.QtCore import pyqtSignal, QDateTime, Qt


class FileReceiveWidget(QWidget):
    """
    专门用于文件接收的UI (带进度条和速率显示)
    """
    # 信号: (bool)
    enable_reception_changed = pyqtSignal(bool)

    def __init__(self, parent = None):
        super().__init__(parent)
        self.is_enabled = False
        self.received_files = []  # 存储 (filename, timestamp, file_data)
        self.init_ui()

    def init_ui(self):
        group = QGroupBox("接收文件")
        layout = QVBoxLayout(group)

        # --- 启用/禁用 切换按钮 ---
        self.btn_toggle_receive = QPushButton("启用文件接收")
        self.btn_toggle_receive.setCheckable(True)
        self.btn_toggle_receive.toggled.connect(self.on_toggle_receive)
        layout.addWidget(self.btn_toggle_receive)

        # === 进度区域（保持不变）===
        self.progress_group = QGroupBox("接收进度")
        self.progress_group.setVisible(False)
        progress_layout = QVBoxLayout(self.progress_group)
        progress_layout.setSpacing(8)
        progress_layout.setContentsMargins(10, 10, 10, 10)

        self.lbl_current_file = QLabel("等待接收...")
        self.lbl_current_file.setStyleSheet("font-weight: bold; color: #333;")
        progress_layout.addWidget(self.lbl_current_file)

        self.progress_bar = QProgressBar()
        self.progress_bar.setMinimum(0)
        self.progress_bar.setMaximum(100)
        self.progress_bar.setValue(0)
        self.progress_bar.setTextVisible(True)
        self.progress_bar.setFormat("%p%")
        progress_layout.addWidget(self.progress_bar)

        info_layout = QHBoxLayout()
        self.lbl_progress_info = QLabel("等待数据...")
        self.lbl_progress_info.setStyleSheet("color: #555;")
        info_layout.addWidget(self.lbl_progress_info)
        info_layout.addStretch()

        self.lbl_speed = QLabel("速率: -- Mbps")
        self.lbl_speed.setStyleSheet("color: #0066cc; font-weight: bold;")
        info_layout.addWidget(self.lbl_speed)
        progress_layout.addLayout(info_layout)

        time_layout = QHBoxLayout()
        self.lbl_time_remaining = QLabel("预计剩余: --")
        self.lbl_time_remaining.setStyleSheet("color: #666;")
        time_layout.addWidget(self.lbl_time_remaining)
        time_layout.addStretch()
        progress_layout.addLayout(time_layout)

        layout.addWidget(self.progress_group)

        # --- 文件列表（修改部分）---
        self.table_files = QTableWidget()
        self.table_files.setColumnCount(3)
        self.table_files.setHorizontalHeaderLabels(["文件名", "大小", "接收时间"])  # 简化标题
        self.table_files.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.table_files.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)

        # 🔥 关键修改：设置列宽
        # 文件名：自动拉伸填充剩余空间
        self.table_files.horizontalHeader().setSectionResizeMode(0, QHeaderView.ResizeMode.Stretch)

        # 大小：固定宽度 100 像素（足够显示数字）
        self.table_files.horizontalHeader().setSectionResizeMode(1, QHeaderView.ResizeMode.Fixed)
        self.table_files.setColumnWidth(1, 100)

        # 接收时间：固定宽度 160 像素（显示完整时间戳）
        self.table_files.horizontalHeader().setSectionResizeMode(2, QHeaderView.ResizeMode.Fixed)
        self.table_files.setColumnWidth(2, 160)

        layout.addWidget(self.table_files)

        # --- 保存按钮（保持不变）---
        self.btn_save = QPushButton("保存选中的文件")
        self.btn_save.setEnabled(False)
        self.btn_save.setMinimumHeight(35)
        layout.addWidget(self.btn_save)

        # 设置主布局
        main_layout = QVBoxLayout(self)
        main_layout.addWidget(group)

        # 连接信号
        self.table_files.itemSelectionChanged.connect(
            lambda: self.btn_save.setEnabled(len(self.table_files.selectedItems()) > 0)
        )
        self.btn_save.clicked.connect(self.save_selected_file)

        self.set_enabled(False)

    def on_toggle_receive(self, checked):
        if checked:
            self.btn_toggle_receive.setText("文件接收中 (点击停止)")
            self.enable_reception_changed.emit(True)
        else:
            self.btn_toggle_receive.setText("启用文件接收")
            self.enable_reception_changed.emit(False)
            self.reset_progress()

    def add_received_file(self, filename, file_data):
        """[公共槽] 由 MainWindow 连接到 Worker 的信号"""
        timestamp = QDateTime.currentDateTime()
        file_size = len(file_data)

        # 1. 存储数据
        self.received_files.append((filename, timestamp, file_data))

        # 2. 更新表格
        row = self.table_files.rowCount()
        self.table_files.insertRow(row)
        self.table_files.setItem(row, 0, QTableWidgetItem(filename))
        self.table_files.setItem(row, 1, QTableWidgetItem(str(file_size)))
        self.table_files.setItem(row, 2, QTableWidgetItem(timestamp.toString("yyyy-MM-dd hh:mm:ss")))
        self.table_files.scrollToBottom()

    def save_selected_file(self):
        selected_rows = self.table_files.selectionModel().selectedRows()
        if not selected_rows:
            return

        row_index = selected_rows[0].row()

        if row_index >= len(self.received_files):
            return

        filename, timestamp, file_data = self.received_files[row_index]

        save_path, _ = QFileDialog.getSaveFileName(self, "保存文件", filename, "所有文件 (*)")

        if save_path:
            try:
                with open(save_path, 'wb') as f:
                    f.write(file_data)
            except Exception as e:
                print(f"File save error: {e}")

    def set_enabled(self, enabled):
        """由主窗口调用,在连接后启用"""
        self.is_enabled = enabled
        self.btn_toggle_receive.setEnabled(enabled)
        self.btn_save.setEnabled(enabled and len(self.table_files.selectedItems()) > 0)
        self.table_files.setEnabled(enabled)

        if not enabled:
            self.btn_toggle_receive.setChecked(False)
            self.reset_progress()

    # === 新增: 进度控制方法 ===
    def start_receiving(self, filename, total_size):
        """开始接收文件时调用"""
        self.progress_group.setVisible(True)
        self.lbl_current_file.setText(f"正在接收: {filename}")
        self.progress_bar.setValue(0)

        size_str = self.format_file_size(total_size)
        self.lbl_progress_info.setText(f"0 B / {size_str}")
        self.lbl_speed.setText("速率: -- Mbps")
        self.lbl_time_remaining.setText("预计剩余: 计算中...")

    def update_progress(self, received_bytes, total_bytes, speed_mbps):
        """
        更新接收进度
        :param received_bytes: 已接收字节数
        :param total_bytes: 总字节数
        :param speed_mbps: 实时速率 (Mbps)
        """
        if total_bytes == 0:
            return

        # 更新进度条
        progress = int((received_bytes / total_bytes) * 100)
        self.progress_bar.setValue(progress)

        # 更新已接收信息
        recv_str = self.format_file_size(received_bytes)
        total_str = self.format_file_size(total_bytes)
        self.lbl_progress_info.setText(f"{recv_str} / {total_str}")

        # 更新速率 (显示为 Mbps)
        self.lbl_speed.setText(f"速率: {speed_mbps:.2f} Mbps")

        # 计算预计剩余时间
        if speed_mbps > 0:
            remaining_bytes = total_bytes - received_bytes
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

    def finish_receiving(self, success = True, message = ""):
        """接收完成时调用"""
        if success:
            self.progress_bar.setValue(100)
            self.lbl_current_file.setText("接收完成!")
            self.lbl_current_file.setStyleSheet("font-weight: bold; color: green;")
            self.lbl_progress_info.setText("文件已保存到列表")
            self.lbl_progress_info.setStyleSheet("color: green;")
            self.lbl_time_remaining.setText("已完成")
        else:
            self.lbl_current_file.setText(f"接收失败: {message}")
            self.lbl_current_file.setStyleSheet("font-weight: bold; color: red;")
            self.lbl_time_remaining.setText("已中断")

    def reset_progress(self):
        """重置进度显示"""
        self.progress_group.setVisible(False)
        self.progress_bar.setValue(0)
        self.lbl_current_file.setText("等待接收...")
        self.lbl_current_file.setStyleSheet("font-weight: bold; color: #333;")
        self.lbl_progress_info.setText("等待数据...")
        self.lbl_progress_info.setStyleSheet("color: #555;")
        self.lbl_speed.setText("速率: -- Mbps")
        self.lbl_time_remaining.setText("预计剩余: --")

    def format_file_size(self, size_bytes):
        """格式化文件大小"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.2f} PB"
    # === 结束新增 ===