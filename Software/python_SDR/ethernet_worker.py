import socket
import threading
import os
import time
from PyQt6.QtCore import QObject, pyqtSignal
from PyQt6.QtGui import QImage

# --- 定义安全的数据包大小 ---
CHUNK_SIZE = 256  # 保持一个安全值

# --- 新增: 协议前缀 ---
PREFIX_TEXT = b'\x00'
PREFIX_VIDEO = b'\x01'  # 我们将显式使用这个
PREFIX_FILE_DATA = b'\x02'
PREFIX_AUDIO_DATA = b'\x03'
PREFIX_FILE_INFO = b'\x0F'  # 文件头 (文件名和大小)


# --- 结束新增 ---

class EthernetWorker(QObject):
    """
    网络工作线程 (UDP)
    - [修改] 实现了文件接收状态机。
    - [修改] 实现了文件发送协议 (文件头 + 数据块)。
    - [修改] 实现了基于前缀的健壮的数据包路由。
    """

    # 定义信号
    started = pyqtSignal()
    stopped = pyqtSignal()
    log_received = pyqtSignal(str)
    video_frame_ready = pyqtSignal(QImage)
    error_occurred = pyqtSignal(str)
    finished = pyqtSignal()

    # --- 新增: 文件接收信号 ---
    #      (filename, file_data_bytes)
    file_received = pyqtSignal(str, bytes)

    # --- 结束新增 ---

    def __init__(self):
        super().__init__()
        self.sock = None
        self._running = False
        self.fpga_addr = None
        self._recv_thread = None
        self._lock = threading.Lock()

        # --- 新增: 文件接收状态 ---
        self.is_receiving_file = False
        self.current_file_info = {}  # "name": str, "size": int
        self.file_buffer = bytearray()
        self.enable_file_reception = False  # 由 MainWindow 控制
        # --- 结束新增 ---

    def start_listening(self, listen_ip, listen_port, fpga_ip, fpga_port):
        # (此方法保持不变)
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
        [重大修改]
        在独立的 Python 线程中执行接收循环。
        实现了基于包前缀的状态机。
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

                    if not data:
                        continue

                    # --- 协议路由 ---
                    prefix = data[0:1]  # 取第一个字节作为前缀
                    payload = data[1:]  # 剩余的是数据

                    if prefix == PREFIX_VIDEO:
                        # 1. 视频帧
                        image = QImage()
                        if image.loadFromData(payload, "JPEG"):
                            self.video_frame_ready.emit(image)
                        else:
                            self.log_received.emit(f"[UDP 警告] 收到损坏的视频包 (JPEG?)")

                    elif prefix == PREFIX_TEXT:
                        # 2. 文本消息
                        try:
                            text_message = payload.decode('utf-8').strip()
                            if text_message:
                                self.log_received.emit(f"[UDP 消息 {addr}]: {text_message}")
                        except Exception:
                            self.log_received.emit(f"[UDP 警告] 收到无法解码的文本包")

                    elif prefix == PREFIX_FILE_INFO:
                        # 3. 文件头 (开始接收)
                        if not self.enable_file_reception:
                            continue  # 未启用文件接收，忽略
                        try:
                            info_str = payload.decode('utf-8')
                            filename, filesize_str = info_str.split(':', 1)
                            filesize = int(filesize_str)

                            self.current_file_info = {"name": filename, "size": filesize}
                            self.file_buffer.clear()
                            self.is_receiving_file = True
                            self.log_received.emit(f"[UDP 文件] 开始接收: {filename} ({filesize} 字节)")

                        except Exception as e:
                            self.log_received.emit(f"[UDP 错误] 收到损坏的文件头: {e}")
                            self.is_receiving_file = False

                    elif prefix == PREFIX_FILE_DATA:
                        # 4. 文件数据块
                        if self.is_receiving_file:
                            self.file_buffer.extend(payload)

                            # 检查是否接收完毕
                            if len(self.file_buffer) >= self.current_file_info.get("size", -1):
                                # 截取正确长度的数据
                                file_data_bytes = self.file_buffer[:self.current_file_info["size"]]
                                filename = self.current_file_info.get("name", "unknown_file")
                                self.log_received.emit(f"[UDP 文件] 接收完毕: {filename}")
                                self.file_received.emit(filename, bytes(file_data_bytes))

                                # 重置状态机
                                self.is_receiving_file = False
                                self.file_buffer.clear()
                                self.current_file_info.clear()

                    elif prefix == PREFIX_AUDIO_DATA:
                        # 5. 音频数据 (我们目前只发送，不接收)
                        self.log_received.emit(f"[UDP 消息] 收到一个音频包 (暂不处理)")

                    else:
                        # 6. 未知包
                        self.log_received.emit(f"[UDP 警告] 收到未知前缀的包: 0x{prefix.hex()}")

                except socket.timeout:
                    continue
                except Exception as e:
                    if self._running:
                        self.error_occurred.emit(f"UDP 接收错误: {e}")
                    break

        finally:
            # (清理逻辑保持不变)
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
        # (此方法保持不变)
        self._running = False
        try:
            if self.sock:
                self.sock.close()
        except Exception:
            pass
        self.log_received.emit("停止请求已发送 -> 正在等待接收线程退出...")

    # --- 新增: 控制文件接收的槽 ---
    def set_file_reception_enabled(self, enabled: bool):
        """
        [公共槽] 由 MainWindow 连接到 FileReceiveWidget 的信号
        """
        self.enable_file_reception = enabled
        if enabled:
            self.log_received.emit("文件接收已启用")
        else:
            self.log_received.emit("文件接收已禁用")
            # 如果在禁用时正在接收文件，则中止
            if self.is_receiving_file:
                self.is_receiving_file = False
                self.file_buffer.clear()
                self.current_file_info.clear()
                self.log_received.emit("[警告] 文件接收已中止")

    # --- 结束新增 ---

    def _send_udp_payload(self, payload):
        # (此方法保持不变)
        addr = self.fpga_addr
        if not addr:
            self.error_occurred.emit("发送失败: 目标地址未设置")
            return False
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as tmp_sock:
                tmp_sock.sendto(payload, addr)
            return True
        except Exception as e:
            self.error_occurred.emit(f"UDP 发送失败: {e}")
            return False

    def send_command(self, cmd_str):
        # [修改] 确保添加了正确的前缀
        with self._lock:
            payload = b'\x00' + PREFIX_TEXT + cmd_str.encode('utf-8') + b'\n'  # 你的旧代码已包含 \n
            if self._send_udp_payload(payload):
                self.log_received.emit(f"-> [UDP发送 文本]: {cmd_str} 至 {self.fpga_addr}")

    def send_file_udp(self, file_path):
        """
        [重大修改]
        通过 UDP 将文件分块发送 (文件头 + 数据块)
        """
        with self._lock:
            if not self.fpga_addr:
                self.error_occurred.emit("发送失败: 目标地址未设置")
                return

            try:
                file_size = os.path.getsize(file_path)
                filename = os.path.basename(file_path)  # 只发送文件名，不带路径
                self.log_received.emit(f"-> [UDP发送 文件]: {filename} ({file_size} 字节)")

                # --- 1. 发送文件头 ---
                info_str = f"{filename}:{file_size}"
                info_payload = b'\x00' + PREFIX_FILE_INFO + info_str.encode('utf-8') + b'\x00'
                if not self._send_udp_payload(info_payload):
                    self.error_occurred.emit("文件头发送失败")
                    return
                time.sleep(1)  # 等待 FPGA 处理文件头

                # --- 2. 发送文件数据块 ---
                with open(file_path, 'rb') as f:
                    while True:
                        chunk = f.read(CHUNK_SIZE)
                        if not chunk:
                            break  # 文件读取完毕

                        payload = b'\x00' + PREFIX_FILE_DATA + chunk + b'\x00'
                        if not self._send_udp_payload(payload):
                            self.error_occurred.emit("文件发送中断")
                            return

                        time.sleep(1)  # 块之间用较小的延时 (0.1s 太慢了)

                self.log_received.emit(f"-> [UDP发送 文件]: 完成")

            except FileNotFoundError:
                self.error_occurred.emit(f"文件未找到: {file_path}")
            except Exception as e:
                self.error_occurred.emit(f"文件发送失败: {e}")

    def send_audio_udp(self, audio_bytes: bytes):
        """
        [修改] 确保添加了正确的前缀
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

                    payload = b'\x00' + PREFIX_AUDIO_DATA + chunk + b'\x00'
                    if not self._send_udp_payload(payload):
                        self.error_occurred.emit("音频发送中断")
                        return

                    time.sleep(1)  # 块之间用较小的延时 (0.1s 太慢了)

                self.log_received.emit(f"-> [UDP发送 音频]: 完成")

            except Exception as e:
                self.error_occurred.emit(f"音频发送失败: {e}")

