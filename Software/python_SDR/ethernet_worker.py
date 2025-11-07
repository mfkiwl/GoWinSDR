# 文件名: py代码/ethernet_worker.py
# (已修改：添加"隐形"P2P模式)
# (已修改：实现 Selective Repeat 滑动窗口以提高可靠传输效率)
# (已修改：為 SR 添加最大重傳次數限制)
# (已修改：添加 0.005s 發包最小時間間隔 - Pacer)

import socket
import threading
import os
import time
import struct
import zlib
import random
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot
from PyQt6.QtGui import QImage

# --- [!! 核心修改：在这里设置你的P2P IP !!] ---
# LAN_TARGET_IP = "192.168.43.192"
# LAN_LISTEN_IP = "192.168.43.217"
LAN_TARGET_IP = "127.0.0.1"
LAN_LISTEN_IP = "127.0.0.1"
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
HEADER_FORMAT = '!BI'
HEADER_SIZE = struct.calcsize(HEADER_FORMAT)
CRC_SIZE = struct.calcsize('!I')

# --- [!! 停等协议 (Stop-and-Wait) 常量 !!] ---
RETRY_COUNT = 15
ACK_TIMEOUT = 0.01

# --- [!! SR 滑动窗口 (Selective Repeat) 新增常量 !!] ---
WINDOW_SIZE = 10
RELIABLE_TIMEOUT = 0.05
SR_MAX_RETRIES = 15

# --- [!! 發送速率 (Pacer) 新增常量 !!] ---
MIN_SEND_INTERVAL = 0.002  # 每個數據包的最小發送間隔 (秒)


# --- [!! 結束新增 !!] ---


class EthernetWorker(QObject):
    """
    (文档已更新)
    - 增加了对"隐形"P2P LAN模式的支持。
    - 为文件/音频传输实现了 SR (Selective Repeat) 滑动窗口协议。
    - 為 SR 增加了最大重傳次數限制。
    - 為所有數據包添加了最小發送間隔 (Pacer)。
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
        self.is_lan_mode = False

        # --- 停等协议 (Stop-and-Wait) 状态 ---
        self.ack_event = threading.Event()
        self.last_received_ack_seq = -1

        # --- 接收方状态 (SR 修改) ---
        self.recv_base = 0  # 接收窗口基址
        self.recv_buffer = {}  # {seq_num: payload} 存储乱序到达的包
        self.recv_acked = set()  # 已确认的序列号集合

        # --- SR (Selective Repeat) 发送方状态 ---
        self.send_base = 0
        self.next_seq_num = 0
        self.send_buffer = {}  # {seq_num: packet_bytes}
        self.send_timers = {}  # {seq_num: Timer对象}
        self.send_retry_count = {}  # {seq_num: 重传次数}
        self.sr_lock = threading.Lock()
        self.window_space_cv = threading.Condition(self.sr_lock)
        self.sr_transfer_active = False

        # --- [!! 新增: Pacer 狀態 !!] ---
        self.pacer_lock = threading.Lock()
        self.last_send_time = 0
        # --- [!! 結束新增 !!] ---

    # --- [!! 新增: 公共槽 !!] ---
    @pyqtSlot(bool)
    def set_lan_mode(self, enabled):
        # (此方法保持不变)
        self.is_lan_mode = enabled
        # if enabled:
        #     self.log_received.emit(f"--- [!] 局域网P2P模式已激活 (目标: {LAN_TARGET_IP}:{LAN_PORT}) ---")
        # else:
        #     self.log_received.emit("--- [!] 局域网P2P模式已停用 (返回FPGA模式) ---")

    def start_listening(self, listen_ip, listen_port, fpga_ip, fpga_port):
        # (此方法保持不变)
        with self._lock:
            if self._recv_thread and self._recv_thread.is_alive():
                self.log_received.emit("[警告] 监听已在运行,请先停止。")
                return

            local_listen_ip = listen_ip
            local_listen_port = listen_port

            if self.is_lan_mode:
                self.fpga_addr = (LAN_TARGET_IP, LAN_PORT)
                local_listen_ip = LAN_LISTEN_IP
                local_listen_port = LAN_PORT
                # self.log_received.emit(f"P2P模式: 目标地址已覆盖为 {self.fpga_addr}")
            else:
                self.fpga_addr = (fpga_ip, fpga_port)

            self.recv_base = 0
            self.recv_buffer.clear()
            self.recv_acked.clear()
            self._running = True

            self._recv_thread = threading.Thread(
                target = self._recv_loop, args = (local_listen_ip, local_listen_port), daemon = True
            )
            self._recv_thread.start()

        self.started.emit()
        self.log_received.emit(f"UDP 正在监听 {local_listen_ip}:{local_listen_port}...")

    def _recv_loop(self, listen_ip, listen_port):
        # SR 接收逻辑
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.sock.settimeout(0.5)

            try:
                self.sock.bind((listen_ip, listen_port))
            except Exception as e:
                self.error_occurred.emit(f"UDP 绑定失败: {e} (地址: {listen_ip}:{listen_port})")
                return

            while self._running:
                try:
                    data, addr = self.sock.recvfrom(65536)

                    if not data or len(data) < (HEADER_SIZE + CRC_SIZE):
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
                        # SR: 处理单个包的 ACK
                        self.last_received_ack_seq = seq_num
                        self.ack_event.set()

                        # SR 发送方逻辑
                        with self.sr_lock:
                            if seq_num in self.send_buffer:
                                # 停止该包的计时器
                                self._sr_stop_timer(seq_num)

                                # 从发送缓冲区移除
                                self.send_buffer.pop(seq_num, None)
                                self.send_retry_count.pop(seq_num, None)

                                # 如果是窗口基址的包被确认，滑动窗口
                                if seq_num == self.send_base:
                                    # 向前滑动到第一个未确认的包
                                    while self.send_base < self.next_seq_num and self.send_base not in self.send_buffer:
                                        self.send_base += 1

                                self.window_space_cv.notify_all()
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

                    # --- SR 接收方逻辑 ---
                    # 检查包是否在接收窗口内
                    if seq_num < self.recv_base:
                        # 旧包，重新发送 ACK
                        self.log_received.emit(
                            f"[UDP SR] 收到旧包 {seq_num} (窗口基址 {self.recv_base}), 重发 ACK")
                        self._send_ack(seq_num, addr)
                        continue

                    if seq_num >= self.recv_base + WINDOW_SIZE:
                        # 超出接收窗口，丢弃
                        self.log_received.emit(
                            f"[UDP SR] 收到超出窗口的包 {seq_num} (窗口 [{self.recv_base}, {self.recv_base + WINDOW_SIZE - 1}]), 已丢弃")
                        continue

                    # 包在窗口内，发送 ACK
                    self._send_ack(seq_num, addr)

                    # 如果已经确认过，跳过
                    if seq_num in self.recv_acked:
                        continue

                    # 存储到接收缓冲区
                    self.recv_buffer[seq_num] = (prefix, payload)
                    self.recv_acked.add(seq_num)

                    # 尝试交付连续的包
                    while self.recv_base in self.recv_acked:
                        recv_prefix, recv_payload = self.recv_buffer.pop(self.recv_base)
                        self.recv_acked.remove(self.recv_base)

                        # 处理不同类型的包
                        self._process_received_packet(recv_prefix, self.recv_base, recv_payload, addr)

                        self.recv_base += 1

                except socket.timeout:
                    continue
                except Exception as e:
                    if self._running:
                        self.error_occurred.emit(f"UDP 接收错误: {e}")
                    break

        finally:
            # 清理逻辑
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

    def _process_received_packet(self, prefix, seq_num, payload, addr):
        """处理接收到的数据包"""
        if prefix == PREFIX_TEXT:
            try:
                text_message = payload.decode('utf-8').strip()
                if text_message:
                    self.log_received.emit(f"[UDP 消息 {addr}]: {text_message}")
            except Exception:
                self.log_received.emit(f"[UDP 警告] 收到无法解码的文本包")
            self.recv_base = 0
            self.recv_buffer.clear()
            self.recv_acked.clear()
            self.log_received.emit(f"[UDP 调试] 文本命令接收完成,序列号已重置")

        elif prefix == PREFIX_FILE_INFO:
            if not self.enable_file_reception:
                return
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
                self.recv_base = 0
                self.recv_buffer.clear()
                self.recv_acked.clear()

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
                    self.recv_base = 0
                    self.recv_buffer.clear()
                    self.recv_acked.clear()
                    self.log_received.emit(f"[UDP 调试] 文件接收完成,序列号已重置")
                else:
                    self.log_received.emit(
                        f"[UDP 文件] (SEQ={seq_num}) 接收中... 已接收 {len(self.file_buffer)}/{self.current_file_info.get('size', -1)} 字节")
            else:
                self.log_received.emit(f"[UDP 警告] 收到文件数据 (SEQ={seq_num}),但未在接收文件状态")

        elif prefix == PREFIX_AUDIO_DATA:
            self.log_received.emit(f"[UDP 消息] 收到一个音频包 (SEQ={seq_num}) (暂不处理)")

        else:
            self.log_received.emit(f"[UDP 警告] 收到未知前缀的包: 0x{prefix.hex()}")

    def stop_listening(self):
        # (保持不变)
        self._running = False
        self.log_received.emit("停止请求已发送 -> 正在等待接收线程退出...")

    def set_file_reception_enabled(self, enabled: bool):
        # (保持不变)
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
        # (保持不变)
        header = struct.pack(HEADER_FORMAT, prefix[0], seq_num)
        data_without_crc = header + payload
        crc = zlib.crc32(data_without_crc)
        return data_without_crc + struct.pack('!I', crc)

    def _send_udp_payload(self, raw_bytes: bytes) -> bool:
        """
        [!! 重大修改: 添加 Pacer (速率控制器) !!]
        這是所有數據包的底層發送函數。
        ACK 包 (send_ack) 不會調用此函數。
        """
        addr = self.fpga_addr
        if not addr:
            self.error_occurred.emit("发送失败: 目标地址未设置")
            return False

        # --- [!! 新增: 發送速率控制器 (Pacer) !!] ---
        with self.pacer_lock:
            now = time.time()
            elapsed = now - self.last_send_time
            if elapsed < MIN_SEND_INTERVAL:
                time.sleep(MIN_SEND_INTERVAL - elapsed)
            self.last_send_time = time.time()
        # --- [!! 結束新增 !!] ---

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
        """
        (此方法保持不变)
        ACK 包 *不* 經過 Pacer, 以便盡快響應
        """
        ack_packet = self._pack_data(PREFIX_ACK, seq_num_to_ack, b'')
        if self.is_lan_mode:
            if random.random() < 0.05:  # 5% 概率
                # self.log_received.emit("人为误码产生")
                return
        try:
            if self.sock:
                self.sock.sendto(ack_packet, target_addr)
        except Exception as e:
            self.log_received.emit(f"发送 ACK {seq_num_to_ack} 失败: {e}")

    # --- [!! SR (Selective Repeat) 輔助函數 !!] ---

    def _sr_start_timer(self, seq_num):
        """为特定序列号启动计时器"""
        self._sr_stop_timer(seq_num)
        timer = threading.Timer(RELIABLE_TIMEOUT, self._sr_handle_timeout, args = (seq_num,))
        timer.daemon = True
        self.send_timers[seq_num] = timer
        timer.start()

    def _sr_stop_timer(self, seq_num):
        """停止特定序列号的计时器"""
        if seq_num in self.send_timers:
            self.send_timers[seq_num].cancel()
            self.send_timers.pop(seq_num, None)

    def _sr_handle_timeout(self, seq_num):
        """处理特定包的超时"""
        with self.sr_lock:
            if not self.sr_transfer_active:
                return

            if seq_num not in self.send_buffer:
                # 已经被确认了
                return

            # 增加重传计数
            retry_count = self.send_retry_count.get(seq_num, 0) + 1
            self.send_retry_count[seq_num] = retry_count

            if retry_count >= SR_MAX_RETRIES:
                self.error_occurred.emit(
                    f"[UDP SR 错误] 包 {seq_num} 达到最大重传次数 ({SR_MAX_RETRIES})。中止传输。")
                self.sr_transfer_active = False

                # 停止所有计时器
                for sn in list(self.send_timers.keys()):
                    self._sr_stop_timer(sn)

                self.window_space_cv.notify_all()
                return

            self.log_received.emit(
                f"[UDP SR 重传] 包 {seq_num} 超时! ({retry_count}/{SR_MAX_RETRIES}) 重传")

            # 重传该包
            packet = self.send_buffer.get(seq_num)
            if packet:
                self._send_udp_payload(packet)
                # 重新启动计时器
                self._sr_start_timer(seq_num)

    def _send_sr_stream(self, prefix: bytes, start_seq: int, chunk_iterator) -> bool:
        """SR 流式发送"""
        with self.sr_lock:
            self.send_base = start_seq
            self.next_seq_num = start_seq
            self.send_buffer.clear()
            self.send_retry_count.clear()

            # 停止所有旧的计时器
            for seq_num in list(self.send_timers.keys()):
                self._sr_stop_timer(seq_num)

            self.sr_transfer_active = True

        try:
            chunk_cache = {}
            chunk_gen = iter(chunk_iterator)
            current_packet_index = 0
            all_chunks_loaded = False

            while not all_chunks_loaded or self.send_base < self.next_seq_num:

                # --- 1. 填充发送窗口 ---
                with self.sr_lock:
                    if not self._running:
                        self.error_occurred.emit("SR 发送中止 (1)")
                        return False
                    if not self.sr_transfer_active:
                        self.error_occurred.emit("SR 发送中止 (因最大重传)")
                        return False

                    while (self.next_seq_num - self.send_base) < WINDOW_SIZE and not all_chunks_loaded:
                        try:
                            chunk = next(chunk_gen)
                        except StopIteration:
                            all_chunks_loaded = True
                            break

                        current_seq = start_seq + current_packet_index
                        chunk_cache[current_seq] = chunk
                        packet = self._pack_data(prefix, current_seq, chunk)
                        self.send_buffer[current_seq] = packet
                        self.send_retry_count[current_seq] = 0

                        # 发送包并启动计时器
                        self._send_udp_payload(packet)
                        self._sr_start_timer(current_seq)

                        self.next_seq_num += 1
                        current_packet_index += 1

                # --- 2. 等待 ACK (流控) ---
                with self.sr_lock:
                    if not self._running:
                        self.error_occurred.emit("SR 发送中止 (2)")
                        return False
                    if not self.sr_transfer_active:
                        self.error_occurred.emit("SR 发送中止 (因最大重传)")
                        return False

                    # 如果窗口满了，等待
                    if (self.next_seq_num - self.send_base) >= WINDOW_SIZE and not all_chunks_loaded:
                        self.window_space_cv.wait(RELIABLE_TIMEOUT * 2)

                    # 所有包都发送完了，等待确认
                    elif all_chunks_loaded and self.send_base < self.next_seq_num:
                        self.window_space_cv.wait(RELIABLE_TIMEOUT * 2)

                    # 清理已确认的缓存
                    acked_keys = [k for k in chunk_cache if k < self.send_base]
                    for k in acked_keys:
                        chunk_cache.pop(k, None)

            self.log_received.emit(f"-> [UDP SR 流] (Prefix 0x{prefix.hex()}) 发送完成。")
            return True

        except Exception as e:
            self.error_occurred.emit(f"SR 流发送失败: {e}")
            return False
        finally:
            with self.sr_lock:
                # 停止所有计时器
                for seq_num in list(self.send_timers.keys()):
                    self._sr_stop_timer(seq_num)

                self.send_buffer.clear()
                self.send_retry_count.clear()
                self.sr_transfer_active = False

    # --- [!! 結束 SR !!] ---

    def _send_reliable_payload(self, prefix: bytes, seq_num: int, payload: bytes) -> bool:
        """
        [停等协议 (Stop-and-Wait) 发送函数]
        (此方法保持不变, Pacer 將在 _send_udp_payload 中自動應用)
        """
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
        """
        (此方法保持不变, Pacer 將在 _send_udp_payload 中自動應用)
        """
        packet = self._pack_data(prefix, 0, payload)
        return self._send_udp_payload(packet)

    def send_command(self, cmd_str: str):
        # (保持不变 - 停等协议)
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
        """
        [!! SR !!]
        1. 使用 "停等" (_send_reliable_payload) 发送文件头 (SEQ=0)
        2. 使用 "SR" (_send_sr_stream) 发送文件数据 (SEQ=1...N)
        """
        with self._lock:
            if not self.fpga_addr:
                self.error_occurred.emit("发送失败: 目标地址未设置")
                return
            try:
                file_size = os.path.getsize(file_path)
                filename = os.path.basename(file_path)
                self.log_received.emit(f"-> [UDP发送 文件]: {filename} ({file_size} 字节)")

                start_time = time.time()

                # --- 1. 发送文件头 (SEQ=0, 停等) ---
                seq_num = 0
                info_str = f"{filename}:{file_size}"
                info_payload = info_str.encode('utf-8')
                self.log_received.emit(f"-> [UDP发送 文件头] (SEQ={seq_num})")
                if not self._send_reliable_payload(PREFIX_FILE_INFO, seq_num, info_payload):
                    self.error_occurred.emit("文件头发送失败,未收到 ACK")
                    return
                self.log_received.emit(f"-> [UDP发送 文件头] 完成")

                # --- 2. 发送文件数据 (SEQ=1...N, SR) ---

                def file_chunk_generator(f):
                    while True:
                        chunk = f.read(CHUNK_SIZE)
                        if not chunk:
                            break
                        yield chunk

                with open(file_path, 'rb') as f:
                    start_seq_num = 1
                    self.log_received.emit(f"-> [UDP SR 发送] 文件数据 (从 SEQ={start_seq_num} 开始)...")
                    if not self._send_sr_stream(PREFIX_FILE_DATA, start_seq_num, file_chunk_generator(f)):
                        self.error_occurred.emit(f"文件数据块发送失败 (SR)")
                        return

                end_time = time.time()
                elapsed = end_time - start_time
                speed_mbps = (file_size * 8) / (elapsed * 1024 * 1024) if elapsed > 0 else 0

                self.log_received.emit(
                    f"-> [UDP发送 文件]: {filename} 完成, "
                    f"耗时: {elapsed:.2f} 秒, "
                    f"速度: {speed_mbps:.2f} Mbps ({file_size} 字节)"
                )

            except FileNotFoundError:
                self.error_occurred.emit(f"文件未找到: {file_path}")
            except Exception as e:
                self.error_occurred.emit(f"文件发送失败: {e}")

    def send_audio_udp(self, audio_bytes: bytes):
        """
        [!! SR !!]
        1. 使用 "SR" (_send_sr_stream) 发送所有音频数据块 (SEQ=0...N)
        """
        with self._lock:
            if not self.fpga_addr:
                self.error_occurred.emit("发送失败: 目标地址未设置")
                return

            data_size = len(audio_bytes)
            self.log_received.emit(f"-> [UDP SR 发送 音频]: {data_size} 字节至 {self.fpga_addr}")

            try:
                def audio_chunk_generator(data, size):
                    idx = 0
                    while idx < len(data):
                        yield data[idx: idx + size]
                        idx += size

                start_seq_num = 0
                start_time = time.time()

                success = self._send_sr_stream(PREFIX_AUDIO_DATA, start_seq_num,
                                               audio_chunk_generator(audio_bytes, CHUNK_SIZE))

                end_time = time.time()

                if not success:
                    self.error_occurred.emit("音频发送中断 (SR)")
                    return

                elapsed = end_time - start_time
                speed_mbps = (data_size * 8) / (elapsed * 1024 * 1024) if elapsed > 0 else 0

                self.log_received.emit(
                    f"-> [UDP SR 发送 音频]: 完成, "
                    f"耗时: {elapsed:.2f} 秒, "
                    f"速度: {speed_mbps:.2f} Mbps ({data_size} 字节)"
                )

            except Exception as e:
                self.error_occurred.emit(f"音频发送失败: {e}")

    @pyqtSlot(bytes)
    def send_audio_chunk(self, audio_data: bytes):
        """
        (不可靠的实时流发送)
        """
        with self._lock:
            if not self.fpga_addr:
                return

            if not self._send_unreliable_payload(PREFIX_AUDIO_STREAM, audio_data):
                pass