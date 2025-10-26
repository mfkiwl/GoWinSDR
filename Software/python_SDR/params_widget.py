from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QGridLayout, QLabel,
                             QComboBox, QPushButton, QSlider, QSpinBox, QGroupBox)  # <-- 导入 QGroupBox
from PyQt6.QtCore import pyqtSignal, Qt


class ParamsWidget(QWidget):
    """
    参数配置区 (左下角)
    """
    # 信号: (param_name, param_value)
    send_param_clicked = pyqtSignal(str, int)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.init_ui()
        self.is_enabled = False

    def init_ui(self):
        # --- 修改 ---
        group = QGroupBox("参数配置")
        layout = QVBoxLayout(group)  # <-- 布局添加到 GroupBox
        # --- 结束修改 ---

        layout.setContentsMargins(5, 5, 5, 5)

        grid = QGridLayout()
        grid.addWidget(QLabel("增益 (LG):"), 0, 0)
        self.spin_lg = QSpinBox()
        self.spin_lg.setRange(0, 10)
        self.spin_lg.setValue(5)
        grid.addWidget(self.spin_lg, 0, 1)
        self.btn_send_lg = QPushButton("设置")
        grid.addWidget(self.btn_send_lg, 0, 2)

        grid.addWidget(QLabel("带宽 (BW):"), 1, 0)
        self.cb_bw = QComboBox()
        self.cb_bw.addItems(["125 kHz", "250 kHz", "500 kHz"])  # 示例
        grid.addWidget(self.cb_bw, 1, 1)
        self.btn_send_bw = QPushButton("设置")
        grid.addWidget(self.btn_send_bw, 1, 2)

        # ... 在这里添加更多参数 ...

        layout.addLayout(grid)
        # layout.addStretch() # 移除

        # --- 新增 ---
        # 设置主布局
        main_layout = QVBoxLayout(self)
        main_layout.addWidget(group)
        # --- 结束新增 ---

        # 连接信号
        self.btn_send_lg.clicked.connect(
            lambda: self.send_param_clicked.emit("LG", self.spin_lg.value())
        )
        self.btn_send_bw.clicked.connect(
            # 假设我们发送带宽的索引 0, 1, 2
            lambda: self.send_param_clicked.emit("BW", self.cb_bw.currentIndex())
        )

        self.set_enabled(False)  # 默认禁用

    def set_enabled(self, enabled):
        """
        由主窗口调用，在连接后启用
        """
        self.is_enabled = enabled
        for child in self.findChildren(QWidget):
            if isinstance(child, (QComboBox, QPushButton, QSlider, QSpinBox)):
                child.setEnabled(enabled)

