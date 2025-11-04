import socket
import threading
from PyQt6.QtCore import QObject, pyqtSignal
from PyQt6.QtGui import QImage


class EthernetWorker(QObject):
    """
    网络工作线程 (UDP)
    - [修改] 现在会尝试将非视频数据包解码为文本并打印到日志。
    """

    # 定义信号
    started = pyqtSignal()
    stopped = pyqtSignal()
    log_received = pyqtSignal(str)  # 用于发送日志
    video_frame_ready = pyqtSignal(QImage)  # 用于发送视频帧
    error_occurred = pyqtSignal(str)
    finished = pyqtSignal()

    def __init__(self):
        super().__init__()
        self.sock = None
        self._running = False
        self.fpga_addr = None  # (ip, port)
        self._recv_thread = None
        self._lock = threading.Lock()

    def start_listening(self, listen_ip, listen_port, fpga_ip, fpga_port):
        """
        启动接收线程（非阻塞，立即返回）。
        """
        with self._lock:
            if self._recv_thread and self._recv_thread.is_alive():
                self.log_received.emit("[警告] 监听已在运行，请先停止。")
                return

            self.fpga_addr = (fpga_ip, fpga_port)
            self._running = True

            self._recv_thread = threading.Thread(
                target=self._recv_loop, args=(listen_ip, listen_port), daemon=True
            )
            self._recv_thread.start()

        self.started.emit()
        self.log_received.emit(f"UDP 正在监听 {listen_ip}:{listen_port}...")

    def _recv_loop(self, listen_ip, listen_port):
        """
        在独立的 Python 线程中执行接收循环。
        """
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.sock.settimeout(0.5)

            try:
                self.sock.bind((listen_ip, listen_port))
            except Exception as e:
                self.error_occurred.emit(f"UDP 绑定失败: {e}")
                return

            while self._running:
                try:
                    data, addr = self.sock.recvfrom(65536)

                    # --- 关键修改 ---
                    # 尝试将数据作为视频帧处理
                    image = QImage()
                    is_video = image.loadFromData(data, "JPEG")

                    if is_video:
                        # 1. 成功: 这是视频帧
                        self.video_frame_ready.emit(image)
                    else:
                        # 2. 失败: 这不是视频, 尝试解码为文本
                        try:
                            # 假设文本是 utf-8 编码
                            text_message = data.decode('utf-8', errors='ignore').strip()
                            if text_message:
                                # 成功解码为文本, 打印到日志
                                self.log_received.emit(f"[UDP 消息 {addr}]: {text_message}")
                            else:
                                # 是空包或无法解码的二进制数据
                                self.log_received.emit(
                                    f"[UDP 警告] 收到来自 {addr} 的非JPEG/非文本数据包, 大小: {len(data)} 字节")
                        except Exception as e:
                            self.log_received.emit(f"[UDP 警告] 解析来自 {addr} 的数据包时出错: {e}")
                    # --- 修改结束 ---

                except socket.timeout:
                    continue
                except Exception as e:
                    if self._running:
                        self.error_occurred.emit(f"UDP 接收错误: {e}")
                    break

        finally:
            try:
                if self.sock:
                    self.sock.close()
            except Exception:
                pass
            self.sock = None
            self._running = False
            self.stopped.emit()
            self.finished.emit()
            self.log_received.emit("UDP 监听已停止")

    def stop_listening(self):
        """
        停止接收循环并关闭 socket。
        """
        self._running = False
        try:
            if self.sock:
                self.sock.close()
        except Exception:
            pass
        self.log_received.emit("停止请求已发送 -> 正在等待接收线程退出...")

    def send_command(self, cmd_str):
        """
        使用 sendto() 发送UDP命令。
        """
        with self._lock:
            addr = self.fpga_addr
            if not addr:
                self.error_occurred.emit("发送失败: 目标地址未设置")
                return

            try:
                payload = b'\x00' + cmd_str.encode('utf-8') + b'\n'
                if self.sock:
                    # 监听时, 使用现有 socket
                    try:
                        self.sock.sendto(payload, addr)
                    except Exception as e:
                        self.log_received.emit(f"通过监听 socket 发送失败，尝试临时 socket：{e}")
                        tmp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                        tmp.sendto(payload, addr)
                        tmp.close()
                else:
                    # 未监听时, 使用临时 socket
                    tmp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                    tmp.sendto(payload, addr)
                    tmp.close()

                self.log_received.emit(f"-> [UDP发送]: {cmd_str} 至 {addr}")
            except Exception as e:
                self.error_occurred.emit(f"UDP 发送失败: {e}")

