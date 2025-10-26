from PyQt6.QtWidgets import (QMainWindow, QWidget, QHBoxLayout, QVBoxLayout,
                             QSplitter, QTabWidget)  # <-- 导入 QTabWidget
from PyQt6.QtCore import QThread, Qt
from config_widget import ConfigWidget
from params_widget import ParamsWidget
from file_widget import FileWidget
from log_widget import LogWidget
from serial_worker import SerialWorker

# --- 新增导入 ---
from ethernet_widget import EthernetWidget
from video_widget import VideoWidget
from ethernet_worker import EthernetWorker


# --- 结束新增 ---

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("FPGA 无线通信上位机 (PyQt6) - [串口+网络]")
        self.setGeometry(100, 100, 1200, 800)  # 窗口改大一点

        self.init_ui()
        self.setup_serial_thread()
        self.setup_ethernet_thread()  # <-- 启动新线程

    def init_ui(self):
        # --- 创建左右布局 ---
        left_panel = QWidget()
        left_layout = QVBoxLayout(left_panel)
        left_panel.setMaximumWidth(300)  # 限制左侧宽度

        self.config_widget = ConfigWidget()
        self.ethernet_widget = EthernetWidget()  # <-- 新增
        self.params_widget = ParamsWidget()

        left_layout.addWidget(self.config_widget)
        left_layout.addWidget(self.ethernet_widget)  # <-- 新增
        left_layout.addWidget(self.params_widget)
        left_layout.addStretch()

        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)

        # --- 右侧布局大修改：使用 QTabWidget ---
        self.tab_widget = QTabWidget()
        self.file_widget = FileWidget()
        self.video_widget = VideoWidget()  # <-- 新增

        self.tab_widget.addTab(self.file_widget, "串口文件传输")
        self.tab_widget.addTab(self.video_widget, "网络视频监控")

        self.log_widget = LogWidget()
        # --- 结束修改 ---

        # 使用 QSplitter 使 Tab区 和 日志区 可以调整大小
        splitter = QSplitter(Qt.Orientation.Vertical)
        splitter.addWidget(self.tab_widget)  # <-- 修改
        splitter.addWidget(self.log_widget)
        splitter.setSizes([500, 300])  # 初始大小

        right_layout.addWidget(splitter)

        # --- 组合主布局 ---
        main_widget = QWidget()
        main_layout = QHBoxLayout(main_widget)
        main_layout.addWidget(left_panel)
        main_layout.addWidget(right_panel, stretch=1)  # 右侧占满

        self.setCentralWidget(main_widget)

    def setup_serial_thread(self):
        self.serial_thread = QThread()
        self.serial_worker = SerialWorker()

        self.serial_worker.moveToThread(self.serial_thread)

        # --- 连接 Worker 的信号 ---
        self.serial_worker.connected.connect(self.on_serial_connected)
        self.serial_worker.disconnected.connect(self.on_serial_disconnected)
        self.serial_worker.log_received.connect(self.log_widget.append_log)
        self.serial_worker.error_occurred.connect(self.on_serial_error)

        # --- 连接线程管理信号 ---
        self.serial_thread.started.connect(lambda: self.log_widget.append_log("串口线程启动"))
        self.serial_worker.finished.connect(self.serial_thread.quit)
        self.serial_worker.finished.connect(self.serial_worker.deleteLater)
        self.serial_thread.finished.connect(self.serial_thread.deleteLater)

        # --- 连接UI控件到Worker的槽 ---
        self.config_widget.connect_clicked.connect(self.serial_worker.connect_serial)
        self.config_widget.disconnect_clicked.connect(self.serial_worker.disconnect_serial)

        self.params_widget.send_param_clicked.connect(self.send_parameter)
        self.file_widget.send_file_clicked.connect(self.serial_worker.send_file)

        # 启动线程
        self.serial_thread.start()

    # --- 新增: setup_ethernet_thread ---
    def setup_ethernet_thread(self):
        self.eth_thread = QThread()
        self.eth_worker = EthernetWorker()

        self.eth_worker.moveToThread(self.eth_thread)

        # --- 连接 Worker 的信号 ---
        self.eth_worker.connected.connect(self.on_eth_connected)
        self.eth_worker.disconnected.connect(self.on_eth_disconnected)
        self.eth_worker.log_received.connect(self.log_widget.append_log)
        self.eth_worker.video_frame_ready.connect(self.video_widget.update_frame)
        self.eth_worker.error_occurred.connect(self.on_eth_error)

        # --- 连接线程管理信号 ---
        self.eth_thread.started.connect(lambda: self.log_widget.append_log("网络线程启动"))
        self.eth_worker.finished.connect(self.eth_thread.quit)
        self.eth_worker.finished.connect(self.eth_worker.deleteLater)
        self.eth_thread.finished.connect(self.eth_thread.deleteLater)

        # --- 连接UI控件到Worker的槽 ---
        self.ethernet_widget.connect_clicked.connect(self.eth_worker.connect_tcp)
        self.ethernet_widget.disconnect_clicked.connect(self.eth_worker.disconnect_tcp)

        # 你也可以在这里连接其他控制信号, e.g.:
        # self.some_control_button.clicked.connect(lambda: self.eth_worker.send_command("START_SCAN"))

        # 启动线程
        self.eth_thread.start()

    # --- 结束新增 ---

    # --- 串口槽函数 ---
    def on_serial_connected(self, message):
        self.log_widget.append_log(message)
        self.config_widget.set_connection_state(True)
        self.params_widget.set_enabled(True)
        self.file_widget.set_enabled(True)  # 只启用文件传输

    def on_serial_disconnected(self):
        self.log_widget.append_log("串口已断开")
        self.config_widget.set_connection_state(False)
        self.params_widget.set_enabled(False)
        self.file_widget.set_enabled(False)

    def on_serial_error(self, message):
        self.log_widget.append_log(f"[串口错误] {message}")
        if "连接失败" in message or "读取错误" in message:
            self.on_serial_disconnected()

    # --- 新增: 网络槽函数 ---
    def on_eth_connected(self):
        self.log_widget.append_log("TCP网络已连接")
        self.ethernet_widget.set_connection_state(True)
        # 可以在这里启用网络相关的控制按钮
        # self.video_widget.set_enabled(True)

    def on_eth_disconnected(self):
        self.log_widget.append_log("TCP网络已断开")
        self.ethernet_widget.set_connection_state(False)

    def on_eth_error(self, message):
        self.log_widget.append_log(f"[网络错误] {message}")
        self.on_eth_disconnected()  # 发生错误时自动更新UI为断开状态

    # --- 结束新增 ---

    def send_parameter(self, name, value):
        """
        将参数格式化为命令字符串发送
        (你需要根据FPGA的协议修改这里的命令格式)
        """
        # 示例命令格式: "SET <NAME> <VALUE>"
        command = f"SET {name} {value}"

        # *** 逻辑修改：你需要决定参数是通过串口还是网口发送 ***
        # 这里我们假设参数仍然通过串口发送
        if self.serial_worker and self.serial_worker.serial and self.serial_worker.serial.is_open:
            self.serial_worker.send_data(command)
        # 或者，如果通过网络发送:
        # if self.eth_worker and self.eth_worker.sock:
        #    self.eth_worker.send_command(command)
        else:
            self.log_widget.append_log("[错误] 无法发送参数：没有活动连接")

    def closeEvent(self, event):
        """
        重写关闭事件，确保两个线程都安全退出
        """
        self.log_widget.append_log("正在关闭应用程序...")

        # 停止串口线程
        if self.serial_thread.isRunning():
            self.serial_worker.disconnect_serial()  # 触发 worker 循环停止
            self.serial_thread.quit()
            if not self.serial_thread.wait(2000):  # 等待2秒
                self.log_widget.append_log("串口线程未能正常停止，将强制终止")
                self.serial_thread.terminate()

        # 停止网络线程
        if self.eth_thread.isRunning():
            self.eth_worker.disconnect_tcp()  # 触发 worker 循环停止
            self.eth_thread.quit()
            if not self.eth_thread.wait(2000):  # 等待2秒
                self.log_widget.append_log("网络线程未能正常停止，将强制终止")
                self.eth_thread.terminate()

        event.accept()

