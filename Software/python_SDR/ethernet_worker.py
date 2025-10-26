import socket
import time
from PyQt6.QtCore import QObject, pyqtSignal
from PyQt6.QtGui import QImage


class EthernetWorker(QObject):
    """
    网络工作线程
    处理所有TCP Socket的读写操作
    """
    # 定义信号
    connected = pyqtSignal()
    disconnected = pyqtSignal()
    log_received = pyqtSignal(str)  # 用于发送日志
    video_frame_ready = pyqtSignal(QImage)  # 用于发送视频帧
    error_occurred = pyqtSignal(str)
    finished = pyqtSignal()

    def __init__(self):
        super().__init__()
        self.sock = None
        self._running = False
        self.ip = ""
        self.port = 0

    def connect_tcp(self, ip, port):
        """
        尝试连接到TCP服务器 (FPGA)
        """
        self.ip = ip
        self.port = port

        if self.sock:
            self.disconnect_tcp()

        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            # 设置一个合理的超时时间
            self.sock.settimeout(5.0)
            self.sock.connect((self.ip, self.port))

            # 连接成功后，可以设置为非阻塞或保持阻塞
            # 我们在这里保持阻塞，因为recv()将在一个专用线程中运行
            self.sock.settimeout(None)

            self._running = True
            self.connected.emit()
            self.log_received.emit(f"成功连接到 {self.ip}:{self.port}")
            # 启动读取循环
            self.run_read_loop()

        except socket.timeout:
            self.error_occurred.emit("连接超时")
            self.sock = None
        except Exception as e:
            self.error_occurred.emit(f"连接失败: {e}")
            self.sock = None

    def disconnect_tcp(self):
        """
        断开TCP连接
        """
        self._running = False
        if self.sock:
            try:
                self.sock.shutdown(socket.SHUT_RDWR)
                self.sock.close()
            except Exception as e:
                self.error_occurred.emit(f"关闭Socket时出错: {e}")
            self.sock = None

    def run_read_loop(self):
        """
        循环读取TCP数据。
        假设视频数据是JPEG帧 (以 \xff\xd8 开始, 以 \xff\xd9 结束)
        """
        buffer = b''
        while self._running:
            try:
                # 阻塞式读取
                data = self.sock.recv(4096)
                if not data:
                    # 连接被对方关闭
                    self.log_received.emit("连接被远端关闭")
                    self._running = False
                    break

                buffer += data

                # 寻找JPEG帧
                start_index = buffer.find(b'\xff\xd8')
                end_index = buffer.find(b'\xff\xd9')

                if start_index != -1 and end_index != -1 and end_index > start_index:
                    jpg_data = buffer[start_index: end_index + 2]
                    buffer = buffer[end_index + 2:]  # 保留缓冲区剩余部分

                    # 将原始JPG数据转换为QImage
                    image = QImage()
                    image.loadFromData(jpg_data, "JPEG")

                    if not image.isNull():
                        self.video_frame_ready.emit(image)
                    else:
                        self.log_received.emit("[警告] 收到损坏的JPEG帧")

            except Exception as e:
                if self._running:  # 只有在非主动断开时才报告错误
                    self.error_occurred.emit(f"TCP读取错误: {e}")
                self._running = False

        # 循环结束
        self.disconnected.emit()
        self.finished.emit()
        self.sock = None
        self.log_received.emit("网络连接已断开")

    def send_command(self, cmd_str):
        """
        发送控制命令 (例如：控制云台，调整参数等)
        """
        if self.sock and self._running:
            try:
                self.sock.sendall(cmd_str.encode('utf-8') + b'\n')
                self.log_received.emit(f"-> [TCP发送]: {cmd_str}")
            except Exception as e:
                self.error_occurred.emit(f"TCP发送失败: {e}")
        else:
            self.error_occurred.emit("发送失败: TCP未连接")
