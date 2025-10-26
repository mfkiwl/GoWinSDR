from PyQt6.QtWidgets import QWidget, QVBoxLayout, QLabel, QGroupBox
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QImage, QPixmap


class VideoWidget(QWidget):
    """
    视频显示区 (右上 - Tab 2)
    """

    def __init__(self, parent=None):
        super().__init__(parent)
        self.init_ui()

    def init_ui(self):
        # 使用 QGroupBox 保持样式统一
        group = QGroupBox("视频监控")
        layout = QVBoxLayout(group)

        self.video_label = QLabel("等待网络视频流...")
        self.video_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.video_label.setScaledContents(True)  # 自动缩放图像
        self.video_label.setStyleSheet("background-color: black; color: white;")
        self.video_label.setMinimumSize(640, 480)  # 设置一个最小尺寸

        layout.addWidget(self.video_label)

        # 设置主布局
        main_layout = QVBoxLayout(self)
        main_layout.addWidget(group)

    def update_frame(self, qimage: QImage):
        """
        公共槽函数，用于在GUI线程中更新视频帧
        """
        if not qimage.isNull():
            # QImage -> QPixmap
            pixmap = QPixmap.fromImage(qimage)
            self.video_label.setPixmap(pixmap)
        else:
            self.video_label.setText("收到损坏的帧")
