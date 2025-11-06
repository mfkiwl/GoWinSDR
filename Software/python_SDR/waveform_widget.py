# 文件名: waveform_widget.py
# (已添加增益/灵敏度控制)

import numpy as np
from PyQt6.QtWidgets import QWidget
from PyQt6.QtGui import QPainter, QColor, QPen, QBrush, QPixmap
from PyQt6.QtCore import Qt, pyqtSlot, QSize


class WaveformWidget(QWidget):
    """
    一个简单的窗口部件，用于使用 NumPy 实时绘制音频波形图。
    """

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setMinimumSize(200, 100)
        self.pen = QPen(QColor("#a6e22e"))  # 亮绿色
        self.pen.setWidth(1)
        self.brush = QBrush(QColor("#272822"))  # 深色背景
        self.buffer = np.array([])

        # --- [!! 可调参数 !!] ---
        #
        # 调整这个值来改变灵敏度
        # 1.0 = 无增益
        # 5.0 = 放大 5 倍
        #
        self.gain = 5.0
        # --- [!! 结束可调参数 !!] ---

        # 预先创建一个 Pixmap 作为绘图缓冲区，以提高性能
        self._pixmap = QPixmap(self.size())
        self._pixmap.fill(self.brush.color())

    def sizeHint(self):
        return QSize(400, 150)

    def resizeEvent(self, event):
        """当窗口大小改变时，重新创建缓冲区"""
        self._pixmap = QPixmap(event.size())
        self.redraw_pixmap()
        super().resizeEvent(event)

    @pyqtSlot(object)
    def update_waveform(self, new_chunk: np.ndarray):
        """
        公共槽：用新的音频块更新波形。
        期望的 new_chunk 是一个 1D NumPy 数组 (例如, np.float32)。
        """
        # (展平逻辑保持不变)
        if new_chunk.ndim > 1:
            new_chunk = new_chunk.flatten()

        self.buffer = new_chunk
        self.redraw_pixmap()

    def redraw_pixmap(self):
        """在后台 Pixmap 上重绘波形"""
        self._pixmap.fill(self.brush.color())
        painter = QPainter(self._pixmap)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)

        if self.buffer.size == 0:
            painter.end()
            self.update()  # 触发 paintEvent
            return

        w = self.width()
        h = self.height()
        h_half = h // 2

        # (采样/插值逻辑保持不变)
        if self.buffer.size > w:
            step = self.buffer.size / w
            indices = (np.arange(w) * step).astype(int)
            samples = self.buffer[indices]
        else:
            x_old = np.linspace(0, self.buffer.size - 1, num=self.buffer.size)
            x_new = np.linspace(0, self.buffer.size - 1, num=w)
            samples = np.interp(x_new, x_old, self.buffer)

        # --- [!! 新增: 应用增益和裁剪 !!] ---

        # 1. 应用增益
        amplified_samples = samples * self.gain

        # 2. 裁剪 (Clipping)
        #    使用 np.clip 将值限制在 [-1.0, 1.0] 范围内
        #    这样放大的信号就不会超出绘图区域
        clipped_samples = np.clip(amplified_samples, -1.0, 1.0)

        # --- [!! 结束新增 !!] ---

        painter.setPen(self.pen)

        # 计算所有点
        points = []

        # --- [!! 修改 !!] ---
        # (使用 clipped_samples 而不是 samples)
        for x, sample in enumerate(clipped_samples):
            # --- [!! 结束修改 !!] ---

            # 'sample' 是被放大并裁剪过的
            y = h_half - int(sample * h_half)
            points.append((x, y))

        # 绘制线条
        for i in range(len(points) - 1):
            painter.drawLine(points[i][0], points[i][1], points[i + 1][0], points[i + 1][1])

        painter.end()
        self.update()  # 触发 paintEvent

    def paintEvent(self, event):
        """将预先绘制的 Pixmap 绘制到窗口上"""
        painter = QPainter(self)
        painter.drawPixmap(0, 0, self._pixmap)