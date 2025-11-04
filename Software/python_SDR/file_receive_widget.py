from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout,
                             QPushButton, QFileDialog, QGroupBox,
                             QTableWidget, QAbstractItemView, QHeaderView,
                             QTableWidgetItem)  # <-- 修复: 导入 QTableWidgetItem
from PyQt6.QtCore import pyqtSignal, QDateTime, Qt


class FileReceiveWidget(QWidget):
    """
    专门用于文件接收的UI
    """
    # 信号: (bool)
    enable_reception_changed = pyqtSignal(bool)

    def __init__(self, parent=None):
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

        # --- 文件列表 ---
        self.table_files = QTableWidget()
        self.table_files.setColumnCount(3)
        self.table_files.setHorizontalHeaderLabels(["文件名", "大小 (Bytes)", "接收时间"])
        self.table_files.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.table_files.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        self.table_files.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        self.table_files.horizontalHeader().setSectionResizeMode(0, QHeaderView.ResizeMode.Interactive)
        self.table_files.horizontalHeader().setSectionResizeMode(2, QHeaderView.ResizeMode.Interactive)

        layout.addWidget(self.table_files)

        # --- 保存按钮 ---
        self.btn_save = QPushButton("保存选中的文件")
        self.btn_save.setEnabled(False)
        layout.addWidget(self.btn_save)

        # 设置主布局
        main_layout = QVBoxLayout(self)
        main_layout.addWidget(group)

        # 连接信号
        self.table_files.itemSelectionChanged.connect(
            lambda: self.btn_save.setEnabled(len(self.table_files.selectedItems()) > 0)
        )
        self.btn_save.clicked.connect(self.save_selected_file)

        self.set_enabled(False)  # 默认禁用

    def on_toggle_receive(self, checked):
        if checked:
            self.btn_toggle_receive.setText("文件接收中 (点击停止)")
            self.enable_reception_changed.emit(True)
        else:
            self.btn_toggle_receive.setText("启用文件接收")
            self.enable_reception_changed.emit(False)

    def add_received_file(self, filename, file_data):
        """
        [公共槽] 由 MainWindow 连接到 Worker 的信号
        """
        timestamp = QDateTime.currentDateTime()
        file_size = len(file_data)

        # 1. 存储数据 (存储原始字节)
        self.received_files.append((filename, timestamp, file_data))

        # 2. 更新表格
        row = self.table_files.rowCount()
        self.table_files.insertRow(row)
        self.table_files.setItem(row, 0, QTableWidgetItem(filename))
        self.table_files.setItem(row, 1, QTableWidgetItem(str(file_size)))
        self.table_files.setItem(row, 2, QTableWidgetItem(timestamp.toString("yyyy-MM-dd hh:mm:ss")))
        self.table_files.scrollToBottom()  # 自动滚动到底部

    def save_selected_file(self):
        selected_rows = self.table_files.selectionModel().selectedRows()
        if not selected_rows:
            return

        # QTableWidget.selectionModel().selectedRows() 返回一个 QModelIndex 列表
        # 我们只需要第一个选中的行号
        row_index = selected_rows[0].row()

        if row_index >= len(self.received_files):
            return  # 索引超出范围 (不应该发生)

        filename, timestamp, file_data = self.received_files[row_index]

        # 弹出保存对话框
        save_path, _ = QFileDialog.getSaveFileName(self, "保存文件", filename, "所有文件 (*)")

        if save_path:
            try:
                with open(save_path, 'wb') as f:
                    f.write(file_data)
                # (可选) 你可以添加一个信号发给 main_window，让它在日志中显示
            except Exception as e:
                # (可选) 同上，发送错误日志
                print(f"File save error: {e}")
                pass

    def set_enabled(self, enabled):
        """
        由主窗口调用，在连接后启用
        """
        self.is_enabled = enabled
        self.btn_toggle_receive.setEnabled(enabled)

        # 只有在启用且有选中项时才启用 "保存" 按钮
        self.btn_save.setEnabled(enabled and len(self.table_files.selectedItems()) > 0)

        # 表格本身在禁用时也应可见
        self.table_files.setEnabled(enabled)

        # 如果禁用了，确保切换按钮也重置为 "off" 状态
        if not enabled:
            self.btn_toggle_receive.setChecked(False)

