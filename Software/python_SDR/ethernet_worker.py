import socket
import threading
import os
import time
import struct  # --- 新增: 用于打包和解包头部
import zlib  # --- 新增: 用于 CRC32 校验
from PyQt6.QtCore import QObject, pyqtSignal
from PyQt6.QtGui import QImage

# --- 修改: 增加 CHUNK_SIZE 以提高效率 ---
CHUNK_SIZE = 256

# --- 协议前缀 (保持不变) ---
PREFIX_TEXT = b'\x00'
PREFIX_VIDEO = b'\x01'
PREFIX_FILE_DATA = b'\x02'
PREFIX_AUDIO_DATA = b'\x03'
PREFIX_FILE_INFO = b'\x0F'

# --- 新增: 可靠传输所需的新前缀和常量 ---
PREFIX_ACK = b'\xAA'  # 确认包 (ACK)

RETRY_COUNT = 5  # 最大重试次数
ACK_TIMEOUT = 1.0  # ACK 超时时间 (秒) - 你可以根据链路质量调整

# 定义包头结构: 1B Prefix + 4B SequenceNumber
# '!' = 网络字节序 (big-endian)
# 'B' = unsigned char (1 byte)
# 'I' = unsigned int (4 bytes)
HEADER_FORMAT = '!BI'
HEADER_SIZE = struct.calcsize(HEADER_FORMAT)  # 5 字节
CRC_SIZE = struct.calcsize('!I')  # 4 字节


class EthernetWorker(QObject):
    """
    网络工作线程 (UDP) - [已升级为可靠传输]
    - 实现了 CRC32 完整性校验。
    - 实现了 Stop-and-Wait ARQ (序列号 + ACK) 来处理丢包问题。
    - 修复了协议前缀的 Bug。
    """

    # 信号 (保持不变)
    started = pyqtSignal()
    stopped = pyqtSignal()
    log_received = pyqtSignal(str)
    video_frame_ready = pyqtSignal(QImage)
    error_occurred = pyqtSignal(str)
    finished = pyqtSignal()
    file_received = pyqtSignal(str, bytes)

    def __init__(self):
        super().__init__()
        self.sock = None
        self._running = False
        self.fpga_addr = None
        self._recv_thread = None
        self._lock = threading.Lock()

        # --- 文件接收状态 (保持不变) ---
        self.is_receiving_file = False
        self.current_file_info = {}
        self.file_buffer = bytearray()
        self.enable_file_reception = False

        # --- 新增: 可靠传输状态 ---
        self.ack_event = threading.Event()
        self.last_received_ack_seq = -1

        # 发送序列号 (由发送线程管理)
        self.current_send_seq = 0
        # 期望接收的序列号 (由接收线程管理)
        self.expected_recv_seq = 0
        # --- 结束新增 ---

    def start_listening(self, listen_ip, listen_port, fpga_ip, fpga_port):
        with self._lock:
            if self._recv_thread and self._recv_thread.is_alive():
                self.log_received.emit("[警告] 监听已在运行，请先停止。")
                return
            self.fpga_addr = (fpga_ip, fpga_port)

            # --- 新增: 重置序列号 ---
            self.current_send_seq = 0
            self.expected_recv_seq = 0
            # --- 结束新增 ---

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
        实现了 CRC 校验、ACK 发送和序列号检查。
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

                    if not data or len(data) < (HEADER_SIZE + CRC_SIZE):
                        self.log_received.emit(f"[UDP 警告] 收到过短的包 (len={len(data)})，已丢弃")
                        continue

                    # --- 1. 校验 CRC ---
                    received_crc = struct.unpack('!I', data[-CRC_SIZE:])[0]
                    data_without_crc = data[:-CRC_SIZE]
                    calculated_crc = zlib.crc32(data_without_crc)

                    if received_crc != calculated_crc:
                        self.log_received.emit(f"[UDP 错误] 收到 CRC 校验失败的包，已丢弃")
                        continue

                    # --- 2. 解包头 ---
                    # (我们信任 struct.unpack, 因为已检查过长度)
                    prefix_byte, seq_num = struct.unpack(HEADER_FORMAT, data_without_crc[:HEADER_SIZE])
                    prefix = bytes([prefix_byte])
                    payload = data_without_crc[HEADER_SIZE:]

                    # --- 3. 处理 ACK 包 (它确认了 *我们* 发送的包) ---
                    if prefix == PREFIX_ACK:
                        self.last_received_ack_seq = seq_num
                        self.ack_event.set()
                        continue

                    # --- 4. 处理视频包 (不可靠) ---
                    # 视频不检查序列号，也不发送 ACK，直接显示
                    if prefix == PREFIX_VIDEO:
                        image = QImage()
                        if image.loadFromData(payload, "JPEG"):
                            self.video_frame_ready.emit(image)
                        else:
                            self.log_received.emit(f"[UDP 警告] 收到损坏的视频包 (JPEG?)")
                        continue

                    # --- 5. 处理可靠包 (所有其他类型) ---

                    # 检查是否是重复的旧包
                    if seq_num < self.expected_recv_seq:
                        self.log_received.emit(
                            f"[UDP 调试] 收到重复包 {seq_num} (期望 {self.expected_recv_seq})，重发 ACK")
                        # 重发 ACK，以便发送方知道我们收到了
                        self._send_ack(seq_num, addr)
                        continue

                    # 检查是否是乱序的未来包
                    if seq_num > self.expected_recv_seq:
                        self.log_received.emit(
                            f"[UDP 警告] 收到乱序包 {seq_num} (期望 {self.expected_recv_seq})，已丢弃")
                        # 我们不 ACK，发送方将超时并重传正确的包
                        continue

                    # --- 此时，seq_num == self.expected_recv_seq ---
                    # 这是我们期望的包，处理它

                    # A. 首先，立刻发送 ACK
                    self._send_ack(seq_num, addr)

                    # B. 路由包内容
                    if prefix == PREFIX_TEXT:
                        try:
                            text_message = payload.decode('utf-8').strip()
                            if text_message:
                                self.log_received.emit(f"[UDP 消息 {addr}]: {text_message}")
                        except Exception:
                            self.log_received.emit(f"[UDP 警告] 收到无法解码的文本包")

                    elif prefix == PREFIX_FILE_INFO:
                        if not self.enable_file_reception:
                            continue
                        try:
                            info_str = payload.decode('utf-8')
                            filename, filesize_str = info_str.split(':', 1)
                            filesize = int(filesize_str)

                            self.current_file_info = {"name": filename, "size": filesize}
                            self.file_buffer.clear()
                            self.is_receiving_file = True
                            self.log_received.emit(f"[UDP 文件] (SEQ={seq_num}) 开始接收: {filename} ({filesize} 字节)")
                        except Exception as e:
                            self.log_received.emit(f"[UDP 错误] 收到损坏的文件头: {e}")
                            self.is_receiving_file = False

                    elif prefix == PREFIX_FILE_DATA:
                        if self.is_receiving_file:
                            self.file_buffer.extend(payload)

                            # 检查是否接收完毕
                            if len(self.file_buffer) >= self.current_file_info.get("size", -1):
                                file_data_bytes = self.file_buffer[:self.current_file_info["size"]]
                                filename = self.current_file_info.get("name", "unknown_file")
                                self.log_received.emit(f"[UDP 文件] 接收完毕: {filename}")
                                self.file_received.emit(filename, bytes(file_data_bytes))

                                # 重置状态机
                                self.is_receiving_file = False
                                self.file_buffer.clear()
                                self.current_file_info.clear()
                        else:
                            self.log_received.emit(f"[UDP 警告] 收到文件数据 (SEQ={seq_num})，但未在接收文件状态")

                    elif prefix == PREFIX_AUDIO_DATA:
                        self.log_received.emit(f"[UDP 消息] 收到一个音频包 (SEQ={seq_num}) (暂不处理)")

                    else:
                        self.log_received.emit(f"[UDP 警告] 收到未知前缀的包: 0x{prefix.hex()}")

                    # C. 推进期望的序列号
                    self.expected_recv_seq += 1

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
        self._running = False
        try:
            if self.sock:
                self.sock.close()
        except Exception:
            pass
        self.log_received.emit("停止请求已发送 -> 正在等待接收线程退出...")

    def set_file_reception_enabled(self, enabled: bool):
        # (此方法保持不变)
        self.enable_file_reception = enabled
        if enabled:
            self.log_received.emit("文件接收已启用")
        else:
            self.log_received.emit("文件接收已禁用")
            if self.is_receiving_file:
                self.is_receiving_file = False
                self.file_buffer.clear()
                self.current_file_info.clear()
                self.log_received.emit("[警告] 文件接收已中止")

    # --- 内部发送辅助方法 ---

    def _pack_data(self, prefix: bytes, seq_num: int, payload: bytes) -> bytes:
        """ [新增] 辅助函数：打包 Prefix, SeqNum, Payload, 和 CRC """
        header = struct.pack(HEADER_FORMAT, prefix[0], seq_num)
        data_without_crc = header + payload
        crc = zlib.crc32(data_without_crc)
        return data_without_crc + struct.pack('!I', crc)

    def _send_udp_payload(self, raw_bytes: bytes) -> bool:
        """ [修改] 内部发送函数，只发送原始字节 """
        addr = self.fpga_addr
        if not addr:
            self.error_occurred.emit("发送失败: 目标地址未设置")
            return False

        # --- 新增: FPGA Bug 补偿 ---
        # 在整个UDP Payload的头部和尾部添加一个 b'\x00'
        # FPGA会丢弃这两个字节，从而收到一个完整的 (raw_bytes)
        padded_packet = b'\x00' + raw_bytes + b'\x00'
        # --- 结束新增 ---

        try:
            # UDP 发送是原子的，不需要临时套接字
            if self.sock:
                # 【!! 修正 !!】使用 padded_packet 而不是 raw_bytes
                self.sock.sendto(padded_packet, addr)
                return True
            else:
                # 备用方案，如果 _recv_loop 尚未启动
                with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as tmp_sock:
                    # 【!! 修正 !!】使用 padded_packet 而不是 raw_bytes
                    tmp_sock.sendto(padded_packet, addr)
                    return True
        except Exception as e:
            self.error_occurred.emit(f"UDP 发送失败: {e}")
            return False

    def _send_ack(self, seq_num_to_ack: int, target_addr: tuple):
        """ [新增] 发送一个 ACK 包 """
        # ACK 包也需要打包和校验，以防 ACK 丢失或损坏
        # ACK 包的 Payload 为空
        ack_packet = self._pack_data(PREFIX_ACK, seq_num_to_ack, b'')  #

        # --- 新增: FPGA Bug 补偿 (同上) ---
        padded_ack_packet = b'\x00' + ack_packet + b'\x00'
        # --- 结束新增 ---

        try:
            if self.sock:
                self.sock.sendto(padded_ack_packet, target_addr)  # <--- 发送 Padded 包
        except Exception as e:
            self.log_received.emit(f"发送 ACK {seq_num_to_ack} 失败: {e}")

    def _send_reliable_payload(self, prefix: bytes, seq_num: int, payload: bytes) -> bool:
        """ [新增] 可靠发送 (停止-等待 ARQ) """

        packet = self._pack_data(prefix, seq_num, payload)

        for i in range(RETRY_COUNT):
            self.ack_event.clear()
            self.last_received_ack_seq = -1

            if not self._send_udp_payload(packet):
                self.error_occurred.emit("UDP 套接字发送失败，中止重试")
                return False

            # 等待 ACK
            if self.ack_event.wait(ACK_TIMEOUT):
                # 被唤醒，检查 ACK 序列号是否正确
                if self.last_received_ack_seq == seq_num:
                    # 成功！
                    return True
                else:
                    # 收到了错误的 ACK (可能来自上一个包的延迟 ACK)
                    self.log_received.emit(
                        f"[UDP 警告] 收到错误 ACK (Seq={self.last_received_ack_seq}, 期望={seq_num})")
                    # 继续循环 (相当于超时)

            # 超时
            self.log_received.emit(
                f"[UDP 重试] 包 {seq_num} (Prefix 0x{prefix.hex()}) 未收到 ACK ({i + 1}/{RETRY_COUNT})")

        self.error_occurred.emit(f"包 {seq_num} (Prefix 0x{prefix.hex()}) 发送失败 {RETRY_COUNT} 次，已放弃")
        return False

    # --- 公共发送槽函数 ---

    def send_command(self, cmd_str: str):
        """ [重大修改] 使用可靠发送 """
        with self._lock:
            # 推进序列号
            self.current_send_seq += 1
            payload = cmd_str.encode('utf-8')   # 修复: 不加 \n, 除非协议要求

            self.log_received.emit(f"-> [UDP发送 文本]: {cmd_str} (SEQ={self.current_send_seq})")
            if not self._send_reliable_payload(PREFIX_TEXT, self.current_send_seq, payload):
                self.log_received.emit(f"-> [UDP发送 文本]: {cmd_str} 失败")

    def send_file_udp(self, file_path: str):
        """ [重大修改] 使用可靠发送，移除 time.sleep """
        with self._lock:
            if not self.fpga_addr:
                self.error_occurred.emit("发送失败: 目标地址未设置")
                return

            try:
                file_size = os.path.getsize(file_path)
                filename = os.path.basename(file_path)
                self.log_received.emit(f"-> [UDP发送 文件]: {filename} ({file_size} 字节)")

                # --- 1. 发送文件头 ---
                self.current_send_seq += 1
                info_str = f"{filename}:{file_size}"
                info_payload = info_str.encode('utf-8')

                self.log_received.emit(f"-> [UDP发送 文件头] (SEQ={self.current_send_seq})")
                if not self._send_reliable_payload(PREFIX_FILE_INFO, self.current_send_seq, info_payload):
                    self.error_occurred.emit("文件头发送失败，未收到 ACK")
                    return

                # --- 2. 发送文件数据块 ---
                with open(file_path, 'rb') as f:
                    while True:
                        chunk = f.read(CHUNK_SIZE)
                        if not chunk:
                            break  # 文件读取完毕

                        self.current_send_seq += 1
                        if not self._send_reliable_payload(PREFIX_FILE_DATA, self.current_send_seq, chunk):
                            self.error_occurred.emit(f"文件块 {self.current_send_seq} 发送失败，已中止")
                            return

                self.log_received.emit(f"-> [UDP发送 文件]: {filename} 完成")

            except FileNotFoundError:
                self.error_occurred.emit(f"文件未找到: {file_path}")
            except Exception as e:
                self.error_occurred.emit(f"文件发送失败: {e}")

    def send_audio_udp(self, audio_bytes: bytes):
        """ [重大修改] 使用可靠发送，移除 time.sleep """
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

                    self.current_send_seq += 1
                    if not self._send_reliable_payload(PREFIX_AUDIO_DATA, self.current_send_seq, chunk):
                        self.error_occurred.emit("音频发送中断")
                        return

                self.log_received.emit(f"-> [UDP发送 音频]: 完成")

            except Exception as e:
                self.error_occurred.emit(f"音频发送失败: {e}")