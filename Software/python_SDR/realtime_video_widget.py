# 文件名: py代码/realtime_video_widget.py
# (已修复: 修正了 __init__ 中 black_pixmap 的初始化顺序)

from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout,
                             QPushButton, QGroupBox, QLabel)
from PyQt6.QtCore import pyqtSignal, pyqtSlot, Qt
from PyQt6.QtGui import QImage, QPixmap


class RealtimeVideoWidget(QWidget):
    """
    实时视频传输的UI (选项卡)
    """
    # 信号:
    start_tx_streaming = pyqtSignal()
    stop_tx_streaming = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.is_enabled = False

        # --- [!! 关键修复 !!] ---
        # 必须在 init_ui() 之前 创建 black_pixmap, 因为 init_ui() 会使用它
        self.black_pixmap = self._create_black_pixmap()
        self.init_ui()
        # --- [!! 修复结束 !!] ---

    def _create_black_pixmap(self, w=640, h=480):
        """创建一个黑色的 QPixmap 作为占位符"""
        pixmap = QPixmap(w, h)
        pixmap.fill(Qt.GlobalColor.black)
        return pixmap

    def init_ui(self):
        main_layout = QHBoxLayout(self)

        # --- 发射 (TX) ---
        tx_group = QGroupBox("实时发射 (摄像头)")
        tx_layout = QVBoxLayout(tx_group)

        self.btn_start_tx = QPushButton("开始实时发射")
        self.btn_start_tx.setCheckable(True)
        self.btn_start_tx.toggled.connect(self.on_tx_toggled)

        self.local_video_label = QLabel("等待本地摄像头...")
        self.local_video_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.local_video_label.setScaledContents(True)
        self.local_video_label.setStyleSheet("background-color: black; color: white;")
        self.local_video_label.setMinimumSize(320, 240)
        self.local_video_label.setPixmap(self.black_pixmap)  # <--- Bug 发生在这里

        tx_layout.addWidget(self.btn_start_tx)
        tx_layout.addWidget(self.local_video_label, 1)  # 允许缩放

        # --- 接收 (RX) ---
        rx_group = QGroupBox("实时接收 (网络)")
        rx_layout = QVBoxLayout(rx_group)

        self.remote_video_label = QLabel("等待网络视频流...")
        self.remote_video_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.remote_video_label.setScaledContents(True)
        self.remote_video_label.setStyleSheet("background-color: black; color: white;")
        self.remote_video_label.setMinimumSize(320, 240)
        self.remote_video_label.setPixmap(self.black_pixmap)

        rx_layout.addWidget(self.remote_video_label, 1)  # 允许缩放

        main_layout.addWidget(tx_group, 1)  # 允许缩放
        main_layout.addWidget(rx_group, 1)  # 允许缩放

        self.set_enabled(False)  # 默认禁用

    def on_tx_toggled(self, checked):
        if checked:
            self.btn_start_tx.setText("停止发射")
            self.start_tx_streaming.emit()
        else:
            self.btn_start_tx.setText("开始实时发射")
            self.stop_tx_streaming.emit()
            # 停止时，重置为黑屏
            self.local_video_label.setPixmap(self.black_pixmap)
            self.local_video_label.setText("本地摄像头已停止")

    @pyqtSlot(QImage)
    def on_local_frame_update(self, qimage: QImage):
        """[槽] 更新本地摄像头波形图"""
        if self.btn_start_tx.isChecked() and not qimage.isNull():
            self.local_video_label.setPixmap(QPixmap.fromImage(qimage))

    @pyqtSlot(QImage)
    def on_remote_frame_update(self, qimage: QImage):
        """[槽] 更新接收到的网络视频帧"""
        if self.is_enabled:
            if not qimage.isNull():
                self.remote_video_label.setPixmap(QPixmap.fromImage(qimage))
            else:
                self.remote_video_label.setText("收到损坏的帧")

    def set_enabled(self, enabled):
        """由主窗口调用，在连接后启用"""
        self.is_enabled = enabled
        self.btn_start_tx.setEnabled(enabled)

        if not enabled:
            # 如果禁用了，确保按钮恢复到未选中状态
            if self.btn_start_tx.isChecked():
                self.btn_start_tx.setChecked(False)
            # 重置屏幕
            self.local_video_label.setPixmap(self.black_pixmap)
            self.local_video_label.setText("等待网络连接...")
            self.remote_video_label.setPixmap(self.black_pixmap)
            self.remote_video_label.setText("等待网络连接...")