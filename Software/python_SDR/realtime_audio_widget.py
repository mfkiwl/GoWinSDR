# 文件名: realtime_audio_widget.py

from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout,
                             QPushButton, QGroupBox)
from PyQt6.QtCore import pyqtSignal, pyqtSlot
import numpy as np
from waveform_widget import WaveformWidget


class RealtimeAudioWidget(QWidget):
    """
    实时语音传输的UI (选项卡)
    """
    # 信号:
    start_tx_streaming = pyqtSignal()
    stop_tx_streaming = pyqtSignal()
    start_rx_playback = pyqtSignal()
    stop_rx_playback = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.is_enabled = False
        self.init_ui()

    def init_ui(self):
        main_layout = QHBoxLayout(self)

        # --- 发射 (TX) ---
        tx_group = QGroupBox("实时发射 (麦克风)")
        tx_layout = QVBoxLayout(tx_group)

        self.btn_start_tx = QPushButton("开始实时发射")
        self.btn_start_tx.setCheckable(True)
        self.btn_start_tx.toggled.connect(self.on_tx_toggled)

        self.tx_waveform = WaveformWidget()

        tx_layout.addWidget(self.btn_start_tx)
        tx_layout.addWidget(self.tx_waveform)

        # --- 接收 (RX) ---
        rx_group = QGroupBox("实时接收 (扬声器)")
        rx_layout = QVBoxLayout(rx_group)

        self.btn_start_rx = QPushButton("开始实时播放")
        self.btn_start_rx.setCheckable(True)
        self.btn_start_rx.toggled.connect(self.on_rx_toggled)

        self.rx_waveform = WaveformWidget()

        rx_layout.addWidget(self.btn_start_rx)
        rx_layout.addWidget(self.rx_waveform)

        main_layout.addWidget(tx_group)
        main_layout.addWidget(rx_group)

        self.set_enabled(False)  # 默认禁用

    def on_tx_toggled(self, checked):
        if checked:
            self.btn_start_tx.setText("停止发射")
            self.start_tx_streaming.emit()
        else:
            self.btn_start_tx.setText("开始实时发射")
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
        self.btn_start_rx.setEnabled(enabled)

        # 如果禁用了，确保按钮恢复到未选中状态
        if not enabled:
            if self.btn_start_tx.isChecked():
                self.btn_start_tx.setChecked(False)
            if self.btn_start_rx.isChecked():
                self.btn_start_rx.setChecked(False)