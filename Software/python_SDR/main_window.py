from PyQt6.QtWidgets import (QMainWindow, QWidget, QHBoxLayout, QVBoxLayout,
                             QSplitter, QTabWidget)
from PyQt6.QtCore import QThread, Qt
from config_widget import ConfigWidget
from params_widget import ParamsWidget
from file_widget import FileWidget
from log_widget import LogWidget
from serial_worker import SerialWorker

from ethernet_widget import EthernetWidget
from video_widget import VideoWidget
from ethernet_worker import EthernetWorker  # 确保这是修改后的 worker


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("FPGA 无线通信上位机- [串口+UDP]")
        self.setGeometry(100, 100, 1200, 800)

        self.init_ui()
        self.setup_serial_thread()
        self.setup_ethernet_thread()  # 启动新线程

    def init_ui(self):
        # --- 创建左右布局 ---
        left_panel = QWidget()
        left_layout = QVBoxLayout(left_panel)
        left_panel.setMaximumWidth(300)

        self.config_widget = ConfigWidget()
        self.ethernet_widget = EthernetWidget()  # 这是新的UDP UI
        self.params_widget = ParamsWidget()

        left_layout.addWidget(self.config_widget)
        left_layout.addWidget(self.ethernet_widget)
        left_layout.addWidget(self.params_widget)
        left_layout.addStretch()

        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)

        self.tab_widget = QTabWidget()
        self.file_widget = FileWidget()
        self.video_widget = VideoWidget()

        self.tab_widget.addTab(self.file_widget, "文件、文本及语音传输")
        self.tab_widget.addTab(self.video_widget, "网络视频监控 (UDP)")

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
        # (这部分代码与之前完全相同，保持不变)
        self.serial_thread = QThread()
        self.serial_worker = SerialWorker()
        self.serial_worker.moveToThread(self.serial_thread)

        self.serial_worker.connected.connect(self.on_serial_connected)
        self.serial_worker.disconnected.connect(self.on_serial_disconnected)
        self.serial_worker.log_received.connect(self.log_widget.append_log)
        self.serial_worker.error_occurred.connect(self.on_serial_error)

        self.serial_thread.started.connect(lambda: self.log_widget.append_log("串口线程启动"))
        self.serial_worker.finished.connect(self.serial_thread.quit)
        self.serial_worker.finished.connect(self.serial_worker.deleteLater)
        self.serial_thread.finished.connect(self.serial_thread.deleteLater)

        self.config_widget.connect_clicked.connect(self.serial_worker.connect_serial)
        self.config_widget.disconnect_clicked.connect(self.serial_worker.disconnect_serial)

        self.params_widget.send_param_clicked.connect(self.send_parameter)
        self.file_widget.send_file_clicked.connect(self.serial_worker.send_file)

        self.serial_thread.start()

    def setup_ethernet_thread(self):
        """
        关键修复：
        - 线程和 worker 保持存活（初始化时启动一次），在 stop 后不再 deleteLater。
        - start_listening/stop_listening/send_command 使用 QueuedConnection，确保在 worker 所在线程中执行。
        - 这样可以在停止后重新配置 IP/port 并再次点击“开始监听”生效。
        """
        self.eth_thread = QThread()
        self.eth_worker = EthernetWorker()

        # 把 worker 移到线程，但不要在停止时自动 delete 或 quit 线程，
        # 以便可以重复使用同一个 worker/线程。
        self.eth_worker.moveToThread(self.eth_thread)

        # 连接 Worker 的信号到 UI/主窗口槽
        self.eth_worker.started.connect(self.on_eth_started)
        self.eth_worker.stopped.connect(self.on_eth_stopped)
        self.eth_worker.log_received.connect(self.log_widget.append_log)
        self.eth_worker.video_frame_ready.connect(self.video_widget.update_frame)
        self.eth_worker.error_occurred.connect(self.on_eth_error)

        # 不再把 finished 连接到线程 quit/deleteLater，这会在第一次停止后销毁 worker/thread
        # 保留 thread 在后台运行，这样可以继续接收 queued calls 到 worker

        # 使用 QueuedConnection 确保调用在 worker 所在线程中执行
        self.ethernet_widget.start_listening_clicked.connect(
            self.eth_worker.start_listening, Qt.ConnectionType.QueuedConnection
        )
        self.ethernet_widget.stop_listening_clicked.connect(
            self.eth_worker.stop_listening, Qt.ConnectionType.QueuedConnection
        )
        self.ethernet_widget.send_command_clicked.connect(
            self.eth_worker.send_command, Qt.ConnectionType.QueuedConnection
        )

        # 启动线程一次（线程保持运行，worker 可重复接受调用）
        self.eth_thread.start()
        self.log_widget.append_log("网络线程启动")

    # --- 串口槽函数 (保持不变) ---
    def on_serial_connected(self, message):
        self.log_widget.append_log(message)
        self.config_widget.set_connection_state(True)
        self.params_widget.set_enabled(True)
        self.file_widget.set_enabled(True)

    def on_serial_disconnected(self):
        self.log_widget.append_log("串口已断开")
        self.config_widget.set_connection_state(False)
        self.params_widget.set_enabled(False)
        self.file_widget.set_enabled(False)

    def on_serial_error(self, message):
        self.log_widget.append_log(f"[串口错误] {message}")
        if "连接失败" in message or "读取错误" in message:
            self.on_serial_disconnected()

    # --- 网络槽函数 (已更新) ---
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

    # --- 结束新增 ---

    def send_parameter(self, name, value):
        command = f"SET {name} {value}"

        # 假设参数仍然通过串口发送
        if self.serial_worker and self.serial_worker.serial and self.serial_worker.serial.is_open:
            self.serial_worker.send_data(command)
        else:
            self.log_widget.append_log("[错误] 无法发送参数：没有活动连接")

    def closeEvent(self, event):
        self.log_widget.append_log("正在关闭应用程序...")

        # 停止串口线程
        if self.serial_thread.isRunning():
            self.serial_worker.disconnect_serial()
            self.serial_thread.quit()
            if not self.serial_thread.wait(2000):
                self.serial_thread.terminate()

        # 停止网络线程：先请求 worker 停止监听，然后停止线程的事件循环并等待退出
        try:
            # 请求停止（queued）
            if self.eth_worker:
                self.eth_worker.stop_listening()
        except Exception:
            pass

        # 现在结束 QThread 的 event loop
        if hasattr(self, "eth_thread") and self.eth_thread.isRunning():
            self.eth_thread.quit()
            if not self.eth_thread.wait(2000):
                self.log_widget.append_log("网络线程未能正常停止，将强制终止")
                self.eth_thread.terminate()

        event.accept()