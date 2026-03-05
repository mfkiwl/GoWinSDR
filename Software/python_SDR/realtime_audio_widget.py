# 文件名: realtime_audio_widget.py
# (已修改：添加音源选择下拉框，支持选择麦克风或系统内录设备)

from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout,
                             QPushButton, QGroupBox, QComboBox, QLabel, QSizePolicy)
from PyQt6.QtCore import pyqtSignal, pyqtSlot
import numpy as np
import sounddevice as sd
from waveform_widget import WaveformWidget


class RealtimeAudioWidget(QWidget):
    """
    实时语音传输的UI (选项卡)
    """
    # 信号: start_tx_streaming 现在携带一个 int 参数 (设备索引)
    start_tx_streaming = pyqtSignal(int)
    stop_tx_streaming = pyqtSignal()
    start_rx_playback = pyqtSignal()
    stop_rx_playback = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.is_enabled = False
        self.device_list = []
        self.init_ui()

    def init_ui(self):
        main_layout = QHBoxLayout(self)

        # --- 发射 (TX) ---
        tx_group = QGroupBox("实时发射 (音频源)")
        tx_layout = QVBoxLayout(tx_group)

        # [新增] 顶部控制栏 (标签 + 下拉框 + 按钮)
        tx_control_layout = QHBoxLayout()

        # 1. 标签
        tx_control_layout.addWidget(QLabel("输入源:"))

        # 2. 音源选择下拉框
        self.combo_source = QComboBox()
        self.combo_source.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
        self.refresh_input_devices() # 填充设备列表
        tx_control_layout.addWidget(self.combo_source)

        # 3. 开始/停止按钮 (变窄)
        self.btn_start_tx = QPushButton("开始发射")
        self.btn_start_tx.setCheckable(True)
        self.btn_start_tx.setFixedWidth(200) # 限制宽度
        self.btn_start_tx.toggled.connect(self.on_tx_toggled)
        tx_control_layout.addWidget(self.btn_start_tx)

        # 将控制栏加入主垂直布局
        tx_layout.addLayout(tx_control_layout)

        # 4. 波形图
        self.tx_waveform = WaveformWidget()
        tx_layout.addWidget(self.tx_waveform)

        # --- 接收 (RX) ---
        rx_group = QGroupBox("实时接收 (扬声器)")
        rx_layout = QVBoxLayout(rx_group)

        # 接收端的控制栏
        rx_control_layout = QHBoxLayout()
        self.btn_start_rx = QPushButton("开始实时播放")
        self.btn_start_rx.setCheckable(True)
        self.btn_start_rx.toggled.connect(self.on_rx_toggled)
        rx_control_layout.addWidget(self.btn_start_rx)
        rx_control_layout.addStretch() # 让按钮靠左

        rx_layout.addLayout(rx_control_layout)

        self.rx_waveform = WaveformWidget()

        rx_layout.addWidget(self.btn_start_rx)
        rx_layout.addWidget(self.rx_waveform)

        main_layout.addWidget(tx_group)
        main_layout.addWidget(rx_group)

        self.set_enabled(False)  # 默认禁用

    def refresh_input_devices(self):
        """获取系统音频输入设备并填充下拉框"""
        self.combo_source.clear()
        self.device_list = []

        try:
            devices = sd.query_devices()
            # 获取默认输入设备索引
            default_input = sd.default.device[0]

            for idx, dev in enumerate(devices):
                # 过滤条件：必须有输入通道
                if dev['max_input_channels'] > 0:
                    name = dev['name']
                    api = dev.get('hostapi', -1)
                    # 尝试获取API名称 (如 MME, WASAPI, DirectSound)以区分
                    # 注意：system loopback 往往在 Windows WASAPI 下可见

                    display_text = f"{idx}: {name}"

                    # 标记默认设备
                    if idx == default_input:
                        display_text += " [默认]"

                    self.combo_source.addItem(display_text, idx) # UserData 存储设备ID

                    # 如果是默认设备，自动选中
                    if idx == default_input:
                        self.combo_source.setCurrentIndex(self.combo_source.count() - 1)

            # 添加一个特殊的刷新选项（可选，这里暂不加，用户重启软件即可）
        except Exception as e:
            self.combo_source.addItem(f"获取设备失败: {e}", -1)

    def on_tx_toggled(self, checked):
        if checked:
            self.btn_start_tx.setText("停止发射")
            self.combo_source.setEnabled(False) # 运行时禁止切换

            # 获取选中的设备ID
            device_idx = self.combo_source.currentData()
            if device_idx is None:
                device_idx = -1 # 让 worker 使用默认

            self.start_tx_streaming.emit(int(device_idx))
        else:
            self.btn_start_tx.setText("开始发射")
            self.combo_source.setEnabled(True)
            self.stop_tx_streaming.emit()

    def on_rx_toggled(self, checked):
        if checked:
            self.btn_start_rx.setText("停止播放")
            self.start_rx_playback.emit()
        else:
            self.btn_start_rx.setText("开始实时播放")
            self.stop_rx_playback.emit()

    @pyqtSlot(object)
    def on_tx_waveform_update(self, chunk_array: np.ndarray):
        """[槽] 更新发射波形图"""
        if self.btn_start_tx.isChecked():
            self.tx_waveform.update_waveform(chunk_array)

    @pyqtSlot(object)
    def on_rx_waveform_update(self, chunk_array: np.ndarray):
        """[槽] 更新接收波形图"""
        if self.btn_start_rx.isChecked():
            self.rx_waveform.update_waveform(chunk_array)

    def set_enabled(self, enabled):
        """由主窗口调用，在连接后启用"""
        self.is_enabled = enabled
        self.btn_start_tx.setEnabled(enabled)
        self.combo_source.setEnabled(enabled) # 同时也启用下拉框
        self.btn_start_rx.setEnabled(enabled)

        # 如果禁用了，确保按钮恢复到未选中状态
        if not enabled:
            if self.btn_start_tx.isChecked():
                self.btn_start_tx.setChecked(False)
            if self.btn_start_rx.isChecked():
                self.btn_start_rx.setChecked(False)