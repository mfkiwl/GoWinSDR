# 文件名: py代码/main_window.py
# (已修复: 1. 修正了 camera_worker 的 'finished' 信号连接。 2. 确保了 camera_worker 的槽连接类型。)
# (已修复: 3. 解耦了 audio_chunk_received 和 UI 绘图, 修复了实时音频GUI阻塞问题)
# (已修复: 4. [新] 修复了因循环依赖导致的 AttributeError)


from PyQt6.QtWidgets import (QMainWindow, QWidget, QHBoxLayout, QVBoxLayout,
                             QSplitter, QTabWidget)
from PyQt6.QtCore import QThread, Qt, QTimer, pyqtSlot
import numpy as np
import threading

from config_widget import ConfigWidget
from params_widget import ParamsWidget
from text_audio_widget import TextAudioWidget
from file_send_widget import FileSendWidget
from file_receive_widget import FileReceiveWidget
from log_widget import LogWidget
from serial_worker import SerialWorker
from ethernet_widget import EthernetWidget
from video_widget import VideoWidget
from ethernet_worker import EthernetWorker
from audio_worker import AudioWorker
from realtime_audio_widget import RealtimeAudioWidget
from audio_stream_worker import AudioInputWorker, AudioOutputWorker
from audio_stream_worker import DTYPE as AUDIO_STREAM_DTYPE
from audio_stream_worker import CHANNELS as AUDIO_STREAM_CHANNELS

# --- [!! 新增: 导入新模块 !!] ---
from realtime_video_widget import RealtimeVideoWidget
from camera_worker import CameraWorker

# --- [!! 结束新增 !!] ---

try:
    from ad9363_config import AD9363_GET_COMMANDS
except ImportError:
    print("警告: 未找到 ad9363_config.py, 参数自动查询功能将无法使用。")
    AD9363_GET_COMMANDS = []


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("FPGA 无线通信上位机 (AD9363) - [串口+UDP]")
        self.setGeometry(100, 100, 1200, 800)
        self.query_list = []

        self.init_ui()

        # --- [!! 关键修复 4 !!] ---
        # 1. 先调用所有的 setup 函数, 它们只负责 *创建* worker
        self.setup_serial_thread()
        self.setup_ethernet_thread()
        self.setup_audio_thread()
        self.setup_audio_stream_threads()
        self.setup_camera_thread()

        # 2. 现在所有的 worker 都已存在,
        #    在这里集中处理所有 *跨线程* 的信号连接
        try:
            # (Ethernet -> Audio Output)
            self.eth_worker.audio_chunk_received.connect(
                self.audio_output_worker.receive_and_play_chunk, Qt.ConnectionType.QueuedConnection
            )

            # (Audio Input -> Ethernet)
            self.audio_input_worker.chunk_ready_bytes.connect(self.eth_worker.send_audio_chunk)

            # (Camera -> Ethernet)
            self.camera_worker.jpeg_bytes_ready.connect(self.eth_worker.send_video_frame)

            self.log_widget.append_log("跨线程信号连接成功")

        except AttributeError as e:
            self.log_widget.append_log(f"[严重错误] 无法连接跨线程信号: {e}")
            self.log_widget.append_log("这可能是由于某个 Worker 未能正确初始化。")
        # --- [!! 修复结束 !!] ---

    def init_ui(self):
        # (此方法保持不变)
        left_panel = QWidget()
        left_layout = QVBoxLayout(left_panel)
        left_panel.setMaximumWidth(380)
        self.config_widget = ConfigWidget()
        self.ethernet_widget = EthernetWidget()
        self.params_widget = ParamsWidget()
        left_layout.addWidget(self.config_widget)
        left_layout.addWidget(self.ethernet_widget)
        left_layout.addWidget(self.params_widget)
        left_layout.addStretch()
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        self.tab_widget = QTabWidget()
        self.file_tab_content = QWidget()
        file_tab_layout = QVBoxLayout(self.file_tab_content)
        self.text_audio_widget = TextAudioWidget()
        self.file_send_widget = FileSendWidget()
        self.file_receive_widget = FileReceiveWidget()
        file_tab_layout.addWidget(self.text_audio_widget)
        file_horizontal_container = QWidget()
        file_horizontal_layout = QHBoxLayout(file_horizontal_container)
        file_horizontal_layout.addWidget(self.file_send_widget)
        file_horizontal_layout.addWidget(self.file_receive_widget)
        file_horizontal_layout.setSpacing(10)
        file_horizontal_layout.setContentsMargins(0, 0, 0, 0)
        file_tab_layout.addWidget(file_horizontal_container)
        file_tab_layout.addStretch()
        self.video_widget = VideoWidget()
        self.realtime_audio_widget = RealtimeAudioWidget()
        self.realtime_video_widget = RealtimeVideoWidget()
        self.tab_widget.addTab(self.file_tab_content, "文件、文本及录音")
        self.tab_widget.addTab(self.video_widget, "网络视频监控 (UDP)")
        self.tab_widget.addTab(self.realtime_audio_widget, "实时语音")
        self.tab_widget.addTab(self.realtime_video_widget, "实时视频")
        self.log_widget = LogWidget()
        splitter = QSplitter(Qt.Orientation.Vertical)
        splitter.addWidget(self.tab_widget)
        splitter.addWidget(self.log_widget)
        splitter.setSizes([500, 300])
        right_layout.addWidget(splitter)
        main_widget = QWidget()
        main_layout = QHBoxLayout(main_widget)
        main_layout.addWidget(left_panel)
        main_layout.addWidget(right_panel, stretch=1)
        self.setCentralWidget(main_widget)

    def setup_serial_thread(self):
        # (此方法保持不变)
        self.serial_thread = QThread()
        self.serial_worker = SerialWorker()
        self.serial_worker.moveToThread(self.serial_thread)
        self.serial_worker.connected.connect(self.on_serial_connected)
        self.serial_worker.disconnected.connect(self.on_serial_disconnected)
        self.serial_worker.log_received.connect(self.log_widget.append_log)
        self.serial_worker.error_occurred.connect(self.on_serial_error)
        self.serial_worker.param_response_received.connect(self.on_param_response)
        self.serial_thread.started.connect(lambda: self.log_widget.append_log("串口线程启动"))
        self.serial_worker.finished.connect(self.serial_thread.quit)
        self.serial_worker.finished.connect(self.serial_worker.deleteLater)
        self.serial_thread.finished.connect(self.serial_thread.deleteLater)
        self.config_widget.connect_clicked.connect(self.serial_worker.connect_serial)
        self.config_widget.disconnect_clicked.connect(self.serial_worker.disconnect_serial)
        self.params_widget.send_command_signal.connect(self._handle_param_set_command)
        self.params_widget.query_all_signal.connect(self.query_all_parameters)
        self.serial_thread.start()

    @pyqtSlot(str)
    def _handle_param_set_command(self, command_str):
        # (此方法保持不变)
        print(f"[MainWindow] Intermediate slot received: {command_str}")
        if self.serial_worker:
            self.serial_worker.send_data(command_str)
        else:
            self.log_widget.append_log("[错误] 无法发送命令: SerialWorker 不存在")

    def setup_ethernet_thread(self):
        # (此方法已修改)
        self.eth_thread = QThread()
        self.eth_worker = EthernetWorker()
        self.eth_worker.moveToThread(self.eth_thread)
        # --- 连接内部信号 ---
        self.eth_worker.started.connect(self.on_eth_started)
        self.eth_worker.stopped.connect(self.on_eth_stopped)
        self.eth_worker.log_received.connect(self.log_widget.append_log)
        self.eth_worker.video_frame_ready.connect(self.video_widget.update_frame)
        self.eth_worker.video_frame_ready.connect(self.realtime_video_widget.on_remote_frame_update)
        self.eth_worker.error_occurred.connect(self.on_eth_error)
        self.eth_worker.file_received.connect(self.file_receive_widget.add_received_file)

        # --- [!! 关键修复 4 !!] ---
        # 移除了导致 AttributeError 的跨线程连接
        # self.eth_worker.audio_chunk_received.connect(...)
        # --- [!! 修复结束 !!] ---

        # --- 连接来自 UI 的信号 ---
        self.ethernet_widget.start_listening_clicked.connect(
            self.eth_worker.start_listening, Qt.ConnectionType.QueuedConnection
        )
        self.ethernet_widget.stop_listening_clicked.connect(
            self.eth_worker.stop_listening, Qt.ConnectionType.QueuedConnection
        )
        self.ethernet_widget.send_command_clicked.connect(
            self.eth_worker.send_command, Qt.ConnectionType.QueuedConnection
        )
        self.text_audio_widget.send_text_clicked.connect(self.eth_worker.send_command)
        self.file_send_widget.send_file_clicked.connect(self.eth_worker.send_file_udp)
        self.file_receive_widget.enable_reception_changed.connect(self.eth_worker.set_file_reception_enabled)
        self.params_widget.lan_mode_toggled.connect(self.eth_worker.set_lan_mode)

        self.eth_thread.start()
        self.log_widget.append_log("网络线程启动")

    def setup_audio_thread(self):
        # (此方法保持不变)
        self.audio_worker = AudioWorker()
        self.text_audio_widget.start_audio_recording.connect(self.audio_worker.start_recording)
        self.text_audio_widget.stop_audio_recording.connect(self.audio_worker.stop_recording)
        self.audio_worker.audio_recorded.connect(self.send_audio_data)  #
        self.audio_worker.error_occurred.connect(self.log_widget.append_log)

    def setup_audio_stream_threads(self):
        # (此方法已修改)
        self.audio_input_thread = QThread()
        self.audio_input_worker = AudioInputWorker()
        self.audio_input_worker.moveToThread(self.audio_input_thread)
        self.audio_output_thread = QThread()
        self.audio_output_worker = AudioOutputWorker()
        self.audio_output_worker.moveToThread(self.audio_output_thread)

        # --- 连接 UI 和 内部 信号 ---
        self.realtime_audio_widget.start_tx_streaming.connect(self.audio_input_worker.start_streaming)
        self.realtime_audio_widget.stop_tx_streaming.connect(self.audio_input_worker.stop_streaming)

        # --- [!! 关键修复 4 !!] ---
        # 移除了导致 AttributeError 的跨线程连接
        # self.audio_input_worker.chunk_ready_bytes.connect(self.eth_worker.send_audio_chunk)
        # --- [!! 修复结束 !!] ---

        self.audio_input_worker.chunk_ready_array.connect(self.realtime_audio_widget.on_tx_waveform_update)
        self.audio_input_worker.error_occurred.connect(self.log_widget.append_log)
        self.realtime_audio_widget.start_rx_playback.connect(self.audio_output_worker.start_playback)
        self.realtime_audio_widget.stop_rx_playback.connect(self.audio_output_worker.stop_playback)
        self.audio_output_worker.error_occurred.connect(self.log_widget.append_log)

        # (连接 'waveform_ready' 信号, 这是 UI 解耦修复的一部分)
        self.audio_output_worker.waveform_ready.connect(
            self.realtime_audio_widget.on_rx_waveform_update
        )

        self.audio_input_thread.start()
        self.audio_output_thread.start()
        self.log_widget.append_log("实时音频流线程启动")

    def setup_camera_thread(self):
        # (此方法已修改)
        self.camera_thread = QThread()
        self.camera_worker = CameraWorker()
        self.camera_worker.moveToThread(self.camera_thread)

        # --- 连接 UI 和 内部 信号 ---
        self.realtime_video_widget.start_tx_streaming.connect(
            self.camera_worker.start_streaming, Qt.ConnectionType.QueuedConnection)
        self.realtime_video_widget.stop_tx_streaming.connect(
            self.camera_worker.stop_streaming, Qt.ConnectionType.QueuedConnection)

        self.camera_worker.frame_ready.connect(self.realtime_video_widget.on_local_frame_update)

        # --- [!! 关键修复 4 !!] ---
        # 移除了导致 AttributeError 的跨线程连接
        # self.camera_worker.jpeg_bytes_ready.connect(self.eth_worker.send_video_frame)
        # --- [!! 修复结束 !!] ---

        self.camera_worker.error_occurred.connect(self.log_widget.append_log)
        self.camera_thread.started.connect(lambda: self.log_widget.append_log("摄像头线程启动"))

        # (线程生命周期连接 - 保持不变)
        self.camera_worker.finished.connect(self.camera_thread.quit)
        self.camera_thread.finished.connect(self.camera_worker.deleteLater)
        self.camera_thread.finished.connect(self.camera_thread.deleteLater)

        self.camera_thread.start()

    # (on_audio_chunk_received 方法保持被弃用的状态)
    @pyqtSlot(bytes)
    def on_audio_chunk_received(self, chunk_bytes: bytes):
        """
        此方法已被弃用...
        """
        pass

    def send_audio_data(self, audio_data: bytes):
        # (此方法保持不变 - 按照你的要求, 未修复阻塞)
        self.log_widget.append_log("音频录制完成，正在通过UDP发送...")
        if self.eth_worker:
            try:
                self.eth_worker.send_audio_udp(audio_data)
            except Exception as e:
                self.log_widget.append_log(f"音频数据发送失败: {e}")
        else:
            self.log_widget.append_log("没有活动的网络连接，无法发送音频数据。")

    def on_serial_connected(self, message):
        # (此方法保持不变)
        self.log_widget.append_log(message)
        self.config_widget.set_connection_state(True)
        self.params_widget.set_enabled(True)
        self.log_widget.append_log("连接成功, 正在查询 AD9363 参数...")
        QTimer.singleShot(100, self.query_all_parameters)

    def on_serial_disconnected(self):
        # (此方法保持不变)
        self.log_widget.append_log("串口已断开")
        self.config_widget.set_connection_state(False)
        self.params_widget.set_enabled(False)
        self.params_widget.clear_all_fields()
        self.query_list.clear()

    def on_serial_error(self, message):
        # (此方法保持不变)
        self.log_widget.append_log(f"[串口错误] {message}")
        if "连接失败" in message or "读取错误" in message:
            self.on_serial_disconnected()

    def on_eth_started(self):
        # (此方法已修改, 保持不变)
        self.log_widget.append_log("UDP 监听已开始")
        self.ethernet_widget.set_connection_state(True)
        self.text_audio_widget.set_enabled(True)
        self.file_send_widget.set_enabled(True)
        self.file_receive_widget.set_enabled(True)
        self.realtime_audio_widget.set_enabled(True)
        self.realtime_video_widget.set_enabled(True)

    def on_eth_stopped(self):
        # (此方法已修改, f保持不变)
        self.log_widget.append_log("UDP 监听已停止")
        self.ethernet_widget.set_connection_state(False)
        self.text_audio_widget.set_enabled(False)
        self.file_send_widget.set_enabled(False)
        self.file_receive_widget.set_enabled(False)
        self.realtime_audio_widget.set_enabled(False)
        self.realtime_video_widget.set_enabled(False)

    def on_eth_error(self, message):
        # (此方法保持不变)
        self.log_widget.append_log(f"[网络错误] {message}")
        if "绑定失败" in message:
            self.on_eth_stopped()

    # --- 查询状态机 (保持不变) ---
    def query_all_parameters(self):
        # (此方法保持不变)
        if not (self.serial_worker and self.serial_worker.serial and self.serial_worker.serial.is_open):
            self.log_widget.append_log("无法查询: 串口未连接")
            return
        if not AD9363_GET_COMMANDS:
            self.log_widget.append_log("[警告] ad9363_config.py 为空, 没有参数可查询。")
            return
        self.log_widget.append_log("--- 开始查询所有参数 ---")
        self.query_list = AD9363_GET_COMMANDS.copy()
        self.send_next_query()

    def send_next_query(self):
        # (此方法保持不变)
        if not self.query_list:
            self.log_widget.append_log("--- 参数查询完毕 ---")
            return
        command = self.query_list.pop(0)
        self.serial_worker.send_data(command)

    def on_param_response(self, command, value):
        # (此方法保持不变)
        self.log_widget.append_log(f"[响应]: {command} = {value}")
        if command == "tx_lo_freq":
            self.params_widget.update_tx_lo_freq(value)
        elif command == "tx_samp_freq":
            self.params_widget.update_tx_samp_freq(value)
        elif command == "tx_rf_bandwidth":
            self.params_widget.update_tx_rf_bw(value)
        elif command == "tx1_attenuation":
            self.params_widget.update_tx1_atten(value)
        elif command == "tx2_attenuation":
            self.params_widget.update_tx2_atten(value)
        elif command == "tx_fir_en":
            self.params_widget.update_tx_fir_en(value)
        elif command == "rx_lo_freq":
            self.params_widget.update_rx_lo_freq(value)
        elif command == "rx_samp_freq":
            self.params_widget.update_rx_samp_freq(value)
        elif command == "rx_rf_bandwidth":
            self.params_widget.update_rx_rf_bw(value)
        elif command == "rx1_gc_mode":
            self.params_widget.update_rx1_gc_mode(value)
        elif command == "rx2_gc_mode":
            self.params_widget.update_rx2_gc_mode(value)
        elif command == "rx1_rf_gain":
            self.params_widget.update_rx1_rf_gain(value)
        elif command == "rx2_rf_gain":
            self.params_widget.update_rx2_rf_gain(value)
        elif command == "rx_fir_en":
            self.params_widget.update_rx_fir_en(value)
        elif command == "dds_tx1_tone1_freq":
            self.params_widget.update_dds_tx1_t1_freq(value)
        elif command == "dds_tx2_tone1_freq":
            self.params_widget.update_dds_tx2_t1_freq(value)
        QTimer.singleShot(10, self.send_next_query)

    def closeEvent(self, event):
        # (此方法已修改, 保持不变)
        self.log_widget.append_log("正在关闭应用程序...")
        self.query_list.clear()

        try:
            if hasattr(self, 'audio_input_worker'): self.audio_input_worker.stop_streaming()
            if hasattr(self, 'audio_output_worker'): self.audio_output_worker.stop_playback()
        except Exception:
            pass

        # --- [!! 新增 !!] ---
        try:
            if hasattr(self, 'camera_worker'): self.camera_worker.stop_streaming()
        except Exception:
            pass
        # --- [!! 结束新增 !!] ---

        if hasattr(self, 'serial_thread') and self.serial_thread.isRunning():
            self.serial_worker.disconnect_serial()
            self.serial_thread.quit()
            if not self.serial_thread.wait(2000): self.serial_thread.terminate()
        try:
            if hasattr(self, 'eth_worker'): self.eth_worker.stop_listening()
        except Exception:
            pass
        if hasattr(self, "eth_thread") and self.eth_thread.isRunning():
            self.eth_thread.quit()
            if not self.eth_thread.wait(2000):
                self.log_widget.append_log("网络线程未能正常停止，将强制终止")
                self.eth_thread.terminate()
        if hasattr(self, "audio_input_thread") and self.audio_input_thread.isRunning():
            self.audio_input_thread.quit()
            if not self.audio_input_thread.wait(1000): self.audio_input_thread.terminate()
        if hasattr(self, "audio_output_thread") and self.audio_output_thread.isRunning():
            self.audio_output_thread.quit()
            if not self.audio_output_thread.wait(1000): self.audio_output_thread.terminate()

        # --- [!! 新增 !!] ---
        if hasattr(self, "camera_thread") and self.camera_thread.isRunning():
            # 确保在退出前停止 worker
            if hasattr(self, 'camera_worker'): self.camera_worker.stop_streaming()
            self.camera_thread.quit()
            if not self.camera_thread.wait(2000):  # 给2秒钟时间让循环停止
                self.log_widget.append_log("摄像头线程未能正常停止，将强制终止")
                self.camera_thread.terminate()
        # --- [!! 结束新增 !!] ---

        event.accept()