# 文件名: py代码/ethernet_worker.py
# (已修改：添加“隐形”P2P模式)

import socket
import threading
import os
import time
import struct
import zlib
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot  # <-- 导入 pyqtSlot
from PyQt6.QtGui import QImage

# --- [!! 核心修改：在这里设置你的P2P IP !!] ---
#
# 这是“隐形”局域网模式的设置。
# 当你点击"LAN"按钮时，程序将使用这些值，
# 无论UI上显示什么。
#
# LAN_TARGET_IP: 
#   你 *另一* 台电脑的IP地址 (例如: "192.168.3.20")
# LAN_LISTEN_IP: 
#   "0.0.0.0" (这表示"监听本机所有网卡"，不要改)
# LAN_PORT: 
#   两台电脑必须使用的 *相同* 端口 (例如: 32768)
#
LAN_TARGET_IP = "192.168.43.192"  # <--- 在这里填入你另一台PC的IP
LAN_LISTEN_IP = "192.168.43.217"
LAN_PORT = 32768
# --- [!! 结束核心修改 !!] ---


CHUNK_SIZE = 1024
PREFIX_TEXT = b'\x00'
PREFIX_VIDEO = b'\x01'
PREFIX_FILE_DATA = b'\x02'
PREFIX_AUDIO_DATA = b'\x03'
PREFIX_FILE_INFO = b'\x0F'
PREFIX_AUDIO_STREAM = b'\x04'
PREFIX_ACK = b'\xAA'
RETRY_COUNT = 15
ACK_TIMEOUT = 0.01
HEADER_FORMAT = '!BI'
HEADER_SIZE = struct.calcsize(HEADER_FORMAT)
CRC_SIZE = struct.calcsize('!I')


class EthernetWorker(QObject):
    """
    (文档已更新)
    - 增加了对“隐形”P2P LAN模式的支持。
    """

    # (信号保持不变)
    started = pyqtSignal()
    stopped = pyqtSignal()
    log_received = pyqtSignal(str)
    video_frame_ready = pyqtSignal(QImage)
    error_occurred = pyqtSignal(str)
    finished = pyqtSignal()
    file_received = pyqtSignal(str, bytes)
    audio_chunk_received = pyqtSignal(bytes)

    def __init__(self):
        super().__init__()
        self.sock = None
        self._running = False
        self.fpga_addr = None
        self._recv_thread = None
        self._lock = threading.Lock()
        self.is_receiving_file = False
        self.current_file_info = {}
        self.file_buffer = bytearray()
        self.enable_file_reception = False
        self.ack_event = threading.Event()
        self.last_received_ack_seq = -1
        self.expected_recv_seq = 0

        # --- [!! 新增 !!] ---
        self.is_lan_mode = False
        # --- [!! 结束新增 !!] ---

    # --- [!! 新增: 公共槽 !!] ---
    @pyqtSlot(bool)
    def set_lan_mode(self, enabled):
        """
        [公共槽] 由 MainWindow 连接，用于切换“隐形”P2P模式
        """
        self.is_lan_mode = enabled
        if enabled:
            self.log_received.emit(f"--- [!] 局域网P2P模式已激活 (目标: {LAN_TARGET_IP}:{LAN_PORT}) ---")
        else:
            self.log_received.emit("--- [!] 局域网P2P模式已停用 (返回FPGA模式) ---")

    # --- [!! 结束新增 !!] ---

    def start_listening(self, listen_ip, listen_port, fpga_ip, fpga_port):
        """
        [!! 重大修改 !!]
        此方法会检查 self.is_lan_mode。
        如果为 True，它会 *忽略* 传入的参数，并使用硬编码的 LAN_SETTINGS。
        """
        with self._lock:
            if self._recv_thread and self._recv_thread.is_alive():
                self.log_received.emit("[警告] 监听已在运行,请先停止。")
                return

            # --- [!! 新增: 隐形切换逻辑 !!] ---
            local_listen_ip = listen_ip
            local_listen_port = listen_port

            if self.is_lan_mode:
                # 模式激活！忽略UI传来的值
                self.fpga_addr = (LAN_TARGET_IP, LAN_PORT)
                local_listen_ip = LAN_LISTEN_IP
                local_listen_port = LAN_PORT
                self.log_received.emit(f"P2P模式: 目标地址已覆盖为 {self.fpga_addr}")
            else:
                # 正常 FPGA 模式
                self.fpga_addr = (fpga_ip, fpga_port)
            # --- [!! 结束新增 !!] ---

            self.expected_recv_seq = 0
            self._running = True

            # --- [!! 修改 !!] ---
            # 使用我们刚刚选择的 local_listen_ip 和 local_listen_port
            self._recv_thread = threading.Thread(
                target=self._recv_loop, args=(local_listen_ip, local_listen_port), daemon=True
            )
            # --- [!! 结束修改 !!] ---

            self._recv_thread.start()

        self.started.emit()
        # --- [!! 修改 !!] ---
        self.log_received.emit(f"UDP 正在监听 {local_listen_ip}:{local_listen_port}...")
        # --- [!! 结束修改 !!] ---

    def _recv_loop(self, listen_ip, listen_port):
        # (此方法保持不变)
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

            # --- [!! 新增: 启用广播和地址重用 !!] ---
            # (这对于P2P和广播模式都是很好的做法)
            self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            # 允许接收广播包 (如果将来需要)
            # self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
            # --- [!! 结束新增 !!] ---

            self.sock.settimeout(0.5)

            try:
                self.sock.bind((listen_ip, listen_port))
            except Exception as e:
                self.error_occurred.emit(f"UDP 绑定失败: {e} (地址: {listen_ip}:{listen_port})")
                return

            while self._running:
                try:
                    data, addr = self.sock.recvfrom(65536)

                    # (所有后续的接收逻辑保持不变...)
                    if not data or len(data) < (HEADER_SIZE + CRC_SIZE):
                        # self.log_received.emit(f"[UDP 警告] 收到过短的包 (len={len(data)}),已丢弃")
                        continue

                    received_crc = struct.unpack('!I', data[-CRC_SIZE:])[0]
                    data_without_crc = data[:-CRC_SIZE]
                    calculated_crc = zlib.crc32(data_without_crc)

                    if received_crc != calculated_crc:
                        self.log_received.emit(f"[UDP 错误] 收到 CRC 校验失败的包,已丢弃")
                        continue

                    prefix_byte, seq_num = struct.unpack(HEADER_FORMAT, data_without_crc[:HEADER_SIZE])
                    prefix = bytes([prefix_byte])
                    payload = data_without_crc[HEADER_SIZE:]

                    if prefix == PREFIX_ACK:
                        self.last_received_ack_seq = seq_num
                        self.ack_event.set()
                        continue

                    if prefix == PREFIX_VIDEO:
                        image = QImage()
                        if image.loadFromData(payload, "JPEG"):
                            self.video_frame_ready.emit(image)
                        else:
                            self.log_received.emit(f"[UDP 警告] 收到损坏的视频包 (JPEG?)")
                        continue

                    if prefix == PREFIX_AUDIO_STREAM:
                        self.audio_chunk_received.emit(payload)
                        continue

                    if seq_num < self.expected_recv_seq:
                        self.log_received.emit(
                            f"[UDP 调试] 收到重复包 {seq_num} (期望 {self.expected_recv_seq}),重发 ACK")
                        self._send_ack(seq_num, addr)
                        continue

                    if seq_num > self.expected_recv_seq:
                        self.log_received.emit(
                            f"[UDP 警告] 收到乱序包 {seq_num} (期望 {self.expected_recv_seq}),已丢弃")
                        continue

                    self._send_ack(seq_num, addr)

                    if prefix == PREFIX_TEXT:
                        try:
                            text_message = payload.decode('utf-8').strip()
                            if text_message:
                                self.log_received.emit(f"[UDP 消息 {addr}]: {text_message}")
                        except Exception:
                            self.log_received.emit(f"[UDP 警告] 收到无法解码的文本包")
                        self.expected_recv_seq = 0
                        self.log_received.emit(f"[UDP 调试] 文本命令接收完成,序列号已重置")

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
                            self.expected_recv_seq += 1
                        except Exception as e:
                            self.log_received.emit(f"[UDP 错误] 收到损坏的文件头: {e}")
                            self.is_receiving_file = False
                            self.expected_recv_seq = 0

                    elif prefix == PREFIX_FILE_DATA:
                        if self.is_receiving_file:
                            self.file_buffer.extend(payload)
                            if len(self.file_buffer) >= self.current_file_info.get("size", -1):
                                file_data_bytes = self.file_buffer[:self.current_file_info["size"]]
                                filename = self.current_file_info.get("name", "unknown_file")
                                self.log_received.emit(f"[UDP 文件] 接收完毕: {filename}")
                                self.file_received.emit(filename, bytes(file_data_bytes))
                                self.is_receiving_file = False
                                self.file_buffer.clear()
                                self.current_file_info.clear()
                                self.expected_recv_seq = 0
                                self.log_received.emit(f"[UDP 调试] 文件接收完成,序列号已重置")
                            else:
                                self.log_received.emit(
                                    f"[UDP 文件] (SEQ={seq_num}) 接收中... 已接收 {len(self.file_buffer)}/{self.current_file_info.get('size', -1)} 字节")
                                self.expected_recv_seq += 1
                        else:
                            self.log_received.emit(f"[UDP 警告] 收到文件数据 (SEQ={seq_num}),但未在接收文件状态")

                    elif prefix == PREFIX_AUDIO_DATA:
                        self.log_received.emit(f"[UDP 消息] 收到一个音频包 (SEQ={seq_num}) (暂不处理)")
                        # --- 修改: 如果音频是多包传输,需要根据实际协议处理 ---
                        # 这里假设音频可能是多包传输,推进序列号
                        # 如果需要检测音频传输结束,需要添加额外的协议标记
                        self.expected_recv_seq += 1
                        # (注意：你现有的逻辑在这里没有结束标记, 序列号不会重置为0,
                        #  除非对方停止发送并且你也重启监听。
                        #  我们保持这个逻辑不变。)

                    else:
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
        # (保持上次的修复：只设置标志位，防止卡退)
        self._running = False
        # try:
        #     if self.sock:
        #         self.sock.close()
        # except Exception:
        #     pass
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

    def _pack_data(self, prefix: bytes, seq_num: int, payload: bytes) -> bytes:
        # (此方法保持不变)
        header = struct.pack(HEADER_FORMAT, prefix[0], seq_num)
        data_without_crc = header + payload
        crc = zlib.crc32(data_without_crc)
        return data_without_crc + struct.pack('!I', crc)

    def _send_udp_payload(self, raw_bytes: bytes) -> bool:
        # (此方法保持不变)
        addr = self.fpga_addr
        if not addr:
            self.error_occurred.emit("发送失败: 目标地址未设置")
            return False
        try:
            if self.sock:
                self.sock.sendto(raw_bytes, addr)
                return True
            else:
                with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as tmp_sock:
                    tmp_sock.sendto(raw_bytes, addr)
                    return True
        except Exception as e:
            self.error_occurred.emit(f"UDP 发送失败: {e}")
            return False

    def _send_ack(self, seq_num_to_ack: int, target_addr: tuple):
        # (此方法保持不变)
        ack_packet = self._pack_data(PREFIX_ACK, seq_num_to_ack, b'')
        try:
            if self.sock:
                self.sock.sendto(ack_packet, target_addr)
        except Exception as e:
            self.log_received.emit(f"发送 ACK {seq_num_to_ack} 失败: {e}")

    def _send_reliable_payload(self, prefix: bytes, seq_num: int, payload: bytes) -> bool:
        # (此方法保持不变)
        packet = self._pack_data(prefix, seq_num, payload)
        for i in range(RETRY_COUNT):
            self.ack_event.clear()
            self.last_received_ack_seq = -1
            if not self._send_udp_payload(packet):
                self.error_occurred.emit("UDP 套接字发送失败,中止重试")
                return False
            if self.ack_event.wait(ACK_TIMEOUT):
                if self.last_received_ack_seq == seq_num:
                    return True
                else:
                    self.log_received.emit(
                        f"[UDP 警告] 收到错误 ACK (Seq={self.last_received_ack_seq}, 期望={seq_num})")
            self.log_received.emit(
                f"[UDP 重试] 包 {seq_num} (Prefix 0x{prefix.hex()}) 未收到 ACK ({i + 1}/{RETRY_COUNT})")
        self.error_occurred.emit(f"包 {seq_num} (Prefix 0x{prefix.hex()}) 发送失败 {RETRY_COUNT} 次,已放弃")
        return False

    def _send_unreliable_payload(self, prefix: bytes, payload: bytes) -> bool:
        # (此方法保持不变)
        packet = self._pack_data(prefix, 0, payload)
        return self._send_udp_payload(packet)

    def send_command(self, cmd_str: str):
        # (此方法保持不变)
        with self._lock:
            seq_num = 0
            payload = cmd_str.encode('utf-8')
            self.log_received.emit(f"-> [UDP发送 文本]: {cmd_str} (SEQ={seq_num})")
            success = self._send_reliable_payload(PREFIX_TEXT, seq_num, payload)
            if success:
                self.log_received.emit(f"-> [UDP发送 文本]: {cmd_str} 完成,序列号已重置")
            else:
                self.log_received.emit(f"-> [UDP发送 文本]: {cmd_str} 失败")

    def send_file_udp(self, file_path: str):
        # (此方法保持不变)
        with self._lock:
            if not self.fpga_addr:
                self.error_occurred.emit("发送失败: 目标地址未设置")
                return
            try:
                file_size = os.path.getsize(file_path)
                filename = os.path.basename(file_path)
                self.log_received.emit(f"-> [UDP发送 文件]: {filename} ({file_size} 字节)")
                seq_num = 0
                info_str = f"{filename}:{file_size}"
                info_payload = info_str.encode('utf-8')
                self.log_received.emit(f"-> [UDP发送 文件头] (SEQ={seq_num})")
                if not self._send_reliable_payload(PREFIX_FILE_INFO, seq_num, info_payload):
                    self.error_occurred.emit("文件头发送失败,未收到 ACK")
                    return
                self.log_received.emit(f"-> [UDP发送 文件头] 完成")
                with open(file_path, 'rb') as f:
                    while True:
                        chunk = f.read(CHUNK_SIZE)
                        if not chunk:
                            break
                        seq_num += 1
                        if not self._send_reliable_payload(PREFIX_FILE_DATA, seq_num, chunk):
                            self.error_occurred.emit(f"文件块 {seq_num} 发送失败,已中止")
                            return
                        self.log_received.emit(f"-> [UDP发送 文件块] SEQ={seq_num}, 大小={len(chunk)} 字节")
                self.log_received.emit(f"-> [UDP发送 文件]: {filename} 完成,序列号已重置")
            except FileNotFoundError:
                self.error_occurred.emit(f"文件未找到: {file_path}")
            except Exception as e:
                self.error_occurred.emit(f"文件发送失败: {e}")

    def send_audio_udp(self, audio_bytes: bytes):
        # (此方法保持不变 - 可靠的录音发送)
        with self._lock:
            if not self.fpga_addr:
                self.error_occurred.emit("发送失败: 目标地址未设置")
                return
            self.log_received.emit(f"-> [UDP发送 音频]: {len(audio_bytes)} 字节至 {self.fpga_addr}")
            try:
                seq_num = 0
                idx = 0
                while idx < len(audio_bytes):
                    chunk = audio_bytes[idx: idx + CHUNK_SIZE]
                    idx += CHUNK_SIZE
                    if not self._send_reliable_payload(PREFIX_AUDIO_DATA, seq_num, chunk):
                        self.error_occurred.emit("音频发送中断")
                        return
                    seq_num += 1
                self.log_received.emit(f"-> [UDP发送 音频]: 完成,序列号已重置")
            except Exception as e:
                self.error_occurred.emit(f"音频发送失败: {e}")

    @pyqtSlot(bytes)
    def send_audio_chunk(self, audio_data: bytes):
        # (此方法保持不变 - 不可靠的实时流发送)
        if not self.fpga_addr:
            return
        if not self._send_unreliable_payload(PREFIX_AUDIO_STREAM, audio_data):
            pass