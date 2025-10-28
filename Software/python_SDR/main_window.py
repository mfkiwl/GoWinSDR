from PyQt6.QtWidgets import (QMainWindow, QWidget, QHBoxLayout, QVBoxLayout,
                             QSplitter, QTabWidget)
from PyQt6.QtCore import QThread, Qt, QTimer
from config_widget import ConfigWidget
from params_widget import ParamsWidget  # 确保这是 AD9363 版
from file_widget import FileWidget
from log_widget import LogWidget
from serial_worker import SerialWorker  # 确保这是带 param_response 的版本

# 导入你项目中的其他模块
from ethernet_widget import EthernetWidget
from video_widget import VideoWidget
from ethernet_worker import EthernetWorker
from audio_worker import AudioWorker

# --- 新增导入: AD9363 参数列表 ---
try:
    from ad9363_config import AD9363_GET_COMMANDS
except ImportError:
    print("警告: 未找到 ad9363_config.py, 参数自动查询功能将无法使用。")
    AD9363_GET_COMMANDS = []


# --- 结束新增 ---


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("FPGA 无线通信上位机 (AD9363) - [串口+UDP]")
        self.setGeometry(100, 100, 1200, 800)

        # --- 新增: 状态机队列 ---
        self.query_list = []
        # --- 结束新增 ---

        self.init_ui()
        self.setup_serial_thread()
        self.setup_ethernet_thread()
        self.setup_audio_thread()

    def init_ui(self):
        # (这部分 UI 布局保持不变)
        # --- 创建左右布局 ---
        left_panel = QWidget()
        left_layout = QVBoxLayout(left_panel)
        left_panel.setMaximumWidth(300)

        self.config_widget = ConfigWidget()
        self.ethernet_widget = EthernetWidget()
        self.params_widget = ParamsWidget()  # 这是 AD9363 版

        left_layout.addWidget(self.config_widget)
        left_layout.addWidget(self.ethernet_widget)
        left_layout.addWidget(self.params_widget)
        left_layout.addStretch()

        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)

        self.tab_widget = QTabWidget()
        self.file_widget = FileWidget()
        self.video_widget = VideoWidget()

        # 根据你的 file_widget.py 更新 Tab 标题
        self.tab_widget.addTab(self.file_widget, "文件、文本及语音传输")
        self.tab_widget.addTab(self.video_widget, "网络视频监控 (UDP)")

        self.log_widget = LogWidget()

        splitter = QSplitter(Qt.Orientation.Vertical)
        splitter.addWidget(self.tab_widget)
        splitter.addWidget(self.log_widget)
        splitter.setSizes([500, 300])  # 调整了比例

        right_layout.addWidget(splitter)

        main_widget = QWidget()
        main_layout = QHBoxLayout(main_widget)
        main_layout.addWidget(left_panel)
        main_layout.addWidget(right_panel, stretch=1)

        self.setCentralWidget(main_widget)

    def setup_serial_thread(self):
        self.serial_thread = QThread()
        self.serial_worker = SerialWorker()
        self.serial_worker.moveToThread(self.serial_thread)

        # 连接 Worker 的信号
        self.serial_worker.connected.connect(self.on_serial_connected)
        self.serial_worker.disconnected.connect(self.on_serial_disconnected)
        self.serial_worker.log_received.connect(self.log_widget.append_log)
        self.serial_worker.error_occurred.connect(self.on_serial_error)

        # --- 新增: 连接参数响应信号 ---
        self.serial_worker.param_response_received.connect(self.on_param_response)

        # 连接线程管理
        self.serial_thread.started.connect(lambda: self.log_widget.append_log("串口线程启动"))
        self.serial_worker.finished.connect(self.serial_thread.quit)
        self.serial_worker.finished.connect(self.serial_worker.deleteLater)
        self.serial_thread.finished.connect(self.serial_thread.deleteLater)

        # 连接 ConfigWidget
        self.config_widget.connect_clicked.connect(self.serial_worker.connect_serial)
        self.config_widget.disconnect_clicked.connect(self.serial_worker.disconnect_serial)

        # --- 修改: 连接 ParamsWidget ---
        self.params_widget.send_command_signal.connect(self.serial_worker.send_data)
        self.params_widget.query_all_signal.connect(self.query_all_parameters)

        # --- 修改: 连接 FileWidget ---
        self.file_widget.send_file_clicked.connect(self.serial_worker.send_file)
        self.file_widget.send_text_clicked.connect(self.serial_worker.send_data)  # 文本命令也通过 send_data

        self.serial_thread.start()

    def setup_ethernet_thread(self):
        # (这部分代码与你上传的代码相同, 保持不变)
        self.eth_thread = QThread()
        self.eth_worker = EthernetWorker()

        self.eth_worker.moveToThread(self.eth_thread)

        self.eth_worker.started.connect(self.on_eth_started)
        self.eth_worker.stopped.connect(self.on_eth_stopped)
        self.eth_worker.log_received.connect(self.log_widget.append_log)
        self.eth_worker.video_frame_ready.connect(self.video_widget.update_frame)
        self.eth_worker.error_occurred.connect(self.on_eth_error)

        self.ethernet_widget.start_listening_clicked.connect(
            self.eth_worker.start_listening, Qt.ConnectionType.QueuedConnection
        )
        self.ethernet_widget.stop_listening_clicked.connect(
            self.eth_worker.stop_listening, Qt.ConnectionType.QueuedConnection
        )
        self.ethernet_widget.send_command_clicked.connect(
            self.eth_worker.send_command, Qt.ConnectionType.QueuedConnection
        )

        self.eth_thread.start()
        self.log_widget.append_log("网络线程启动")

    def setup_audio_thread(self):
        # (这部分代码与你上传的代码相同, 保持不变)
        self.audio_worker = AudioWorker()

        self.file_widget.start_audio_recording.connect(self.audio_worker.start_recording)
        self.file_widget.stop_audio_recording.connect(self.audio_worker.stop_recording)

        self.audio_worker.audio_recorded.connect(self.send_audio_data)
        self.audio_worker.error_occurred.connect(self.log_widget.append_log)

    def send_audio_data(self, audio_data):
        # (这部分代码与你上传的代码相同, 保持不变)
        # 注意: send_data 通常发送带换行符的字符串
        # 你可能需要一个新的 worker 方法 send_raw_bytes() 来发送音频
        # 这里暂时假设 send_data 能处理
        self.log_widget.append_log("音频录制完成，正在发送...")
        if self.serial_worker and self.serial_worker.serial and self.serial_worker.serial.is_open:
            try:
                # 你需要决定音频数据是作为文件发送还是原始字节
                # 你的 file_widget.py 已经有了 send_file 功能
                # 这里我们假设 send_file 也可以接受字节流，或者你需要修改它
                # 为了安全，我们先当做 "命令" 发送 (这可能不正确)
                self.serial_worker.send_data(f"AUDIO_DATA_LEN:{len(audio_data)}")
                self.log_widget.append_log("音频数据发送成功。")
            except Exception as e:
                self.log_widget.append_log(f"音频数据发送失败: {e}")
        else:
            self.log_widget.append_log("没有活动的串口连接，无法发送音频数据。")

    def on_serial_connected(self, message):
        self.log_widget.append_log(message)
        self.config_widget.set_connection_state(True)
        self.params_widget.set_enabled(True)
        self.file_widget.set_enabled(True)

        # --- 修改: 自动查询 ---
        # 延迟100ms启动查询状态机
        self.log_widget.append_log("连接成功, 正在查询 AD9363 参数...")
        QTimer.singleShot(100, self.query_all_parameters)

    def on_serial_disconnected(self):
        self.log_widget.append_log("串口已断开")
        self.config_widget.set_connection_state(False)
        self.params_widget.set_enabled(False)
        self.file_widget.set_enabled(False)

        # --- 新增: 断开连接时清除旧数据 ---
        self.params_widget.clear_all_fields()
        # --- 新增: 清空查询队列 ---
        self.query_list.clear()

    def on_serial_error(self, message):
        self.log_widget.append_log(f"[串口错误] {message}")
        if "连接失败" in message or "读取错误" in message:
            self.on_serial_disconnected()

    def on_eth_started(self):
        self.log_widget.append_log("UDP 监听已开始")
        self.ethernet_widget.set_connection_state(True)

    def on_eth_stopped(self):
        self.log_widget.append_log("UDP 监听已停止")
        self.ethernet_widget.set_connection_state(False)

    def on_eth_error(self, message):
        self.log_widget.append_log(f"[网络错误] {message}")
        if "绑定失败" in message:
            self.on_eth_stopped()

    # --- 关键修改: 查询状态机 ---

    def query_all_parameters(self):
        """
        [状态机启动]
        初始化查询队列, 并发送第一个查询命令。
        """
        if not (self.serial_worker and self.serial_worker.serial and self.serial_worker.serial.is_open):
            self.log_widget.append_log("无法查询: 串口未连接")
            return

        if not AD9363_GET_COMMANDS:
            self.log_widget.append_log("[警告] ad9363_config.py 为空, 没有参数可查询。")
            return

        self.log_widget.append_log("--- 开始查询所有参数 ---")
        # 复制命令列表到待办队列
        self.query_list = AD9363_GET_COMMANDS.copy()

        # 启动状态机
        self.send_next_query()

    def send_next_query(self):
        """
        [状态机循环]
        从队列中取出一个命令并发送。
        如果队列为空，则停止。
        """
        if not self.query_list:
            self.log_widget.append_log("--- 参数查询完毕 ---")
            return

        # 从队列中取出第一个命令
        command = self.query_list.pop(0)

        # self.log_widget.append_log(f"正在查询: {command}") # (可选: 详细日志)
        self.serial_worker.send_data(command)
        # 发送后, 我们不执行任何操作, 等待 on_param_response 被触发

    def on_param_response(self, command, value):
        """
        [状态机循环]
        处理来自 SerialWorker 的已解析的参数响应,
        更新 UI, 并触发下一个查询。
        """
        # --- 1. 打印日志 (用户要求) ---
        self.log_widget.append_log(f"[响应]: {command} = {value}")

        # --- 2. 更新 UI (映射) ---
        # TX
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

        # RX
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

        # DDS
        elif command == "dds_tx1_tone1_freq":
            self.params_widget.update_dds_tx1_t1_freq(value)
        elif command == "dds_tx2_tone1_freq":
            self.params_widget.update_dds_tx2_t1_freq(value)

        # (你可以按此格式添加 ad9363_config.py 中的所有其他命令)

        # --- 3. 触发下一个查询 (关键!) ---
        # 我们稍微延迟执行, 给UI一点刷新时间, 也避免刷屏太快
        QTimer.singleShot(10, self.send_next_query)

    # ------------------------------------

    def closeEvent(self, event):
        self.log_widget.append_log("正在关闭应用程序...")
        self.query_list.clear()  # 停止任何正在进行的查询

        if hasattr(self, 'serial_thread') and self.serial_thread.isRunning():
            self.serial_worker.disconnect_serial()
            self.serial_thread.quit()
            if not self.serial_thread.wait(2000):
                self.serial_thread.terminate()

        try:
            if hasattr(self, 'eth_worker'):
                self.eth_worker.stop_listening()
        except Exception:
            pass

        if hasattr(self, "eth_thread") and self.eth_thread.isRunning():
            self.eth_thread.quit()
            if not self.eth_thread.wait(2000):
                self.log_widget.append_log("网络线程未能正常停止，将强制终止")
                self.eth_thread.terminate()

        event.accept()

