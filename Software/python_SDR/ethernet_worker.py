import socket
import threading
import os
import time  # <-- 新增
from PyQt6.QtCore import QObject, pyqtSignal
from PyQt6.QtGui import QImage

# --- 定义安全的数据包大小 ---
CHUNK_SIZE = 256


class EthernetWorker(QObject):
    """
    网络工作线程 (UDP)
    - [修改] 增加了发送文件和音频数据的功能。
    - [修改] 在发送文件/音频的每个数据块后添加了延时。
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
        (此方法保持不变)
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

                    # 尝试将数据作为视频帧处理
                    image = QImage()
                    is_video = image.loadFromData(data, "JPEG")

                    if is_video:
                        self.video_frame_ready.emit(image)
                    else:
                        # 尝试解码为文本
                        try:
                            text_message = data.decode('utf-8', errors='ignore').strip()
                            if text_message:
                                self.log_received.emit(f"[UDP 消息 {addr}]: {text_message}")
                            else:
                                self.log_received.emit(
                                    f"[UDP 警告] 收到来自 {addr} 的非JPEG/非文本数据包, 大小: {len(data)} 字节")
                        except Exception as e:
                            self.log_received.emit(f"[UDP 警告] 解析来自 {addr} 的数据包时出错: {e}")

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
        (此方法保持不变)
        """
        self._running = False
        try:
            if self.sock:
                self.sock.close()
        except Exception:
            pass
        self.log_received.emit("停止请求已发送 -> 正在等待接收线程退出...")

    def _send_udp_payload(self, payload):
        """
        (内部辅助函数) 使用临时 socket 发送单个 UDP 包
        """
        addr = self.fpga_addr
        if not addr:
            self.error_occurred.emit("发送失败: 目标地址未设置")
            return False

        try:
            # 使用一个临时的 socket 来发送
            # 这允许我们在未“监听”时也能发送
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as tmp_sock:
                tmp_sock.sendto(payload, addr)
            return True
        except Exception as e:
            self.error_occurred.emit(f"UDP 发送失败: {e}")
            return False

    def send_command(self, cmd_str):
        """
        使用 sendto() 发送UDP命令 (文本)。
        (此方法保持不变)
        """
        with self._lock:
            # 文本使用 b'\x00' 前缀
            payload = b'\x00' + cmd_str.encode('utf-8') + b'\n'
            if self._send_udp_payload(payload):
                self.log_received.emit(f"-> [UDP发送 文本]: {cmd_str} 至 {self.fpga_addr}")

    # --- 修改: 发送文件 ---
    def send_file_udp(self, file_path):
        """
        通过 UDP 将文件分块发送
        """
        with self._lock:
            if not self.fpga_addr:
                self.error_occurred.emit("发送失败: 目标地址未设置")
                return

            self.log_received.emit(f"-> [UDP发送 文件]: {file_path} 至 {self.fpga_addr}")

            try:
                file_size = os.path.getsize(file_path)
                self.log_received.emit(f"    文件大小: {file_size} 字节")

                with open(file_path, 'rb') as f:
                    while True:
                        chunk = f.read(CHUNK_SIZE)
                        if not chunk:
                            break  # 文件读取完毕

                        # 文件块使用 b'\x02' 前缀
                        payload = b'\x02' + chunk + b'\n'
                        if not self._send_udp_payload(payload):
                            self.error_occurred.emit("文件发送中断")
                            return

                        time.sleep(0.1)  # <-- 新增延时

                self.log_received.emit(f"-> [UDP发送 文件]: 完成")

            except FileNotFoundError:
                self.error_occurred.emit(f"文件未找到: {file_path}")
            except Exception as e:
                self.error_occurred.emit(f"文件发送失败: {e}")

    # --- 修改: 发送音频 ---
    def send_audio_udp(self, audio_bytes: bytes):
        """
        通过 UDP 将音频数据分块发送
        """
        with self._lock:
            if not self.fpga_addr:
                self.error_occurred.emit("发送失败: 目标地址未设置")
                return

            self.log_received.emit(f"-> [UDP发送 音频]: {len(audio_bytes)} 字节至 {self.fpga_addr}")

            try:
                idx = 0
                while idx < len(audio_bytes):
                    chunk = audio_bytes[idx: idx + CHUNK_SIZE]
                    idx += CHUNK_SIZE

                    # 音频块使用 b'\x03' 前缀
                    payload = b'\x03' + chunk + b'\n'
                    if not self._send_udp_payload(payload):
                        self.error_occurred.emit("音频发送中断")
                        return

                    time.sleep(0.1)  # <-- 新增延时

                self.log_received.emit(f"-> [UDP发送 音频]: 完成")

            except Exception as e:
                self.error_occurred.emit(f"音频发送失败: {e}")

