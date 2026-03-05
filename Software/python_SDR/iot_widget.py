# 文件名: py代码/iot_widget.py

from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QPushButton, QLabel,
                             QHBoxLayout, QFrame)
from PyQt6.QtCore import pyqtSignal, Qt, QTimer, QSize
from PyQt6.QtGui import QPainter, QColor, QBrush, QPen
import time


class BulbWidget(QWidget):
    """
    自定义绘制的灯泡控件
    """

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setMinimumSize(100, 150)
        self._is_on = False

    def set_on(self, is_on):
        if self._is_on != is_on:
            self._is_on = is_on
            self.update()  # 触发重绘

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)

        # 定义颜色
        if self._is_on:
            # 亮起：黄色核心，带光晕
            color = QColor(255, 235, 59)
            glow_color = QColor(255, 235, 59, 100)
        else:
            # 熄灭：纯黑色
            color = QColor(20, 20, 20)
            glow_color = Qt.GlobalColor.transparent

        # 绘制中心圆 (灯泡主体)
        center_x = self.width() // 2
        center_y = self.height() // 2 - 20
        radius = 40

        # 如果亮起，先画光晕
        if self._is_on:
            painter.setPen(Qt.PenStyle.NoPen)
            painter.setBrush(QBrush(glow_color))
            painter.drawEllipse(center_x - radius - 10, center_y - radius - 10,
                                (radius + 10) * 2, (radius + 10) * 2)

        # 画灯泡实体
        painter.setPen(QPen(Qt.GlobalColor.gray, 2))
        painter.setBrush(QBrush(color))
        painter.drawEllipse(center_x - radius, center_y - radius, radius * 2, radius * 2)

        # 画底座 (简单的矩形)
        base_w = 30
        base_h = 25
        base_x = center_x - base_w // 2
        base_y = center_y + radius - 5

        painter.setBrush(QBrush(QColor(80, 80, 80)))  # 深灰色底座
        painter.drawRect(base_x, base_y, base_w, base_h)

        # 底座螺纹线
        painter.setPen(QPen(QColor(150, 150, 150), 1))
        painter.drawLine(base_x, base_y + 8, base_x + base_w, base_y + 8)
        painter.drawLine(base_x, base_y + 16, base_x + base_w, base_y + 16)


class IoTWidget(QWidget):
    """
    无线物联网控制页面
    """
    # 信号：发送串口指令
    send_command_signal = pyqtSignal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.init_ui()

        # 轮询定时器
        self.poll_timer = QTimer()
        self.poll_timer.setInterval(500)  # 0.5秒 = 500ms
        self.poll_timer.timeout.connect(self.send_poll_query)

    def init_ui(self):
        main_layout = QVBoxLayout(self)

        # --- 顶部控制栏 ---
        top_bar = QHBoxLayout()
        top_bar.setAlignment(Qt.AlignmentFlag.AlignLeft)

        self.btn_toggle = QPushButton("启动监控")
        self.btn_toggle.setCheckable(True)
        self.btn_toggle.setFixedSize(120, 40)
        # 样式表：未选中灰色，选中变绿
        self.btn_toggle.setStyleSheet("""
            QPushButton {
                background-color: #95a5a6; /* 默认灰色 */
                color: white;
                border-radius: 5px;
                font-weight: bold;
            }
            QPushButton:checked {
                background-color: #2ecc71; /* 激活绿色 */
            }
            QPushButton:hover {
                border: 2px solid white;
            }
        """)

        self.btn_toggle.clicked.connect(self.on_toggle_clicked)

        top_bar.addWidget(self.btn_toggle)
        main_layout.addLayout(top_bar)

        # --- 中间显示区域 ---
        center_layout = QVBoxLayout()
        center_layout.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self.lbl_status = QLabel("系统待机")
        self.lbl_status.setStyleSheet("color: #aaa; font-size: 14pt;")
        self.lbl_status.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self.bulb = BulbWidget()

        center_layout.addStretch()
        center_layout.addWidget(self.bulb)
        center_layout.addWidget(self.lbl_status)
        center_layout.addStretch()

        main_layout.addLayout(center_layout)

    def on_toggle_clicked(self, checked):
        if checked:
            # === 按钮变绿 (开启) ===
            self.btn_toggle.setText("监控运行中")
            self.lbl_status.setText("正在配置 RX 频率...")

            # 1. 发送 RX 本振设置指令 (根据 params_widget 的逻辑，这里发送 'rx_lo_freq=434')
            #    注意：具体数值格式取决于单片机解析，这里假设它能识别 '434' 代表 434MHz
            #    或者如果是 Hz，可能是 434000000。这里按题目要求发送 "434M" 相关的设置。
            #    参考 params_widget，命令格式通常是 key=value。
            self.send_command_signal.emit("rx_lo_freq=434")
            time.sleep(2)  # 短暂等待，确保指令发送顺序
            self.send_command_signal.emit("query_led_state=1")
            # 2. 启动定时器 (稍微延迟一点启动，给本振设置留点时间)
            QTimer.singleShot(200, self.start_polling)

        else:
            # === 按钮恢复 (关闭) ===
            self.btn_toggle.setText("启动监控")
            self.lbl_status.setText("系统待机")

            # 停止轮询
            self.poll_timer.stop()

            # 灯泡熄灭
            self.bulb.set_on(False)

            # 系统结束后发送指令 ---
            self.send_command_signal.emit("query_led_state=0")

    def start_polling(self):
        if self.btn_toggle.isChecked():
            self.lbl_status.setText("正在轮询状态...")
            self.poll_timer.start()

    def send_poll_query(self):
        # 发送查询指令
        self.send_command_signal.emit("query_led_state?")

    def handle_response(self, value_str):
        """
        处理来自 MainWindow (SerialWorker) 的响应数据
        value_str: 可能是 "1", "0" 或者带杂乱字符的 "1\x01"
        """
        # 只有在开启状态下才处理
        if not self.btn_toggle.isChecked():
            return

        # --- [!! 修改开始 !!] ---
        # 原始数据可能包含隐形字符 (如 \x01, \r, \n 等)，导致 "1" != "1\x01"
        # 方案：只判断字符串中是否“包含” 1 或 0，或者清洗字符串

        # 调试打印，方便你看清到底收到了什么
        print(f"[IoT] Raw value received: {repr(value_str)}")

        if "1" in value_str:
            self.bulb.set_on(True)
            self.lbl_status.setText("状态: 灯泡点亮 (1)")
        elif "0" in value_str:
            self.bulb.set_on(False)
            self.lbl_status.setText("状态: 灯泡熄灭 (0)")
        # --- [!! 修改结束 !!] ---