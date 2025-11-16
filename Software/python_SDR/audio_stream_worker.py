# 文件名: audio_stream_worker.py
# (已修复：1. 添加新槽和新信号, 解耦UI)

import sounddevice as sd
import numpy as np
# --- [!! 新增导入 !!] ---
from PyQt6.QtCore import QObject, pyqtSignal, QThread, pyqtSlot
# --- [!! 结束新增 !!] ---
import queue

# --- 音频流配置 (保持不变) ---
SAMPLE_RATE = 44100
CHANNELS = 1
DTYPE = np.float32
BLOCK_SIZE = 256


# ---------------------------------------------


class AudioInputWorker(QObject):
    # ... (此
    # 类保持不变) ...
    """
    从麦克风连续捕获音频并通过信号发出。
    (此部分无需修改)
    """
    # 信号: (原始字节)
    chunk_ready_bytes = pyqtSignal(bytes)
    # 信号: (Numpy 数组, 用于本地波形图)
    chunk_ready_array = pyqtSignal(object)
    error_occurred = pyqtSignal(str)

    def __init__(self):
        super().__init__()
        self.stream = None
        self._running = False

    def _audio_callback(self, indata, frames, time, status):
        """
        这是在 sounddevice 的独立线程中调用的。
        """
        if status:
            print(f"[AudioInput] 状态: {status}")

        if self._running:
            # 1. 发送 NumPy 数组给本地波形图
            self.chunk_ready_array.emit(indata.copy())
            # 2. 发送原始字节给网络
            self.chunk_ready_bytes.emit(indata.tobytes())

    def start_streaming(self):
        if self.stream and self.stream.active:
            self.error_occurred.emit("已在录制中")
            return

        try:
            self._running = True
            self.stream = sd.InputStream(
                samplerate=SAMPLE_RATE,
                blocksize=BLOCK_SIZE,
                channels=CHANNELS,
                dtype=DTYPE,
                callback=self._audio_callback
            )
            self.stream.start()
        except Exception as e:
            self._running = False
            self.error_occurred.emit(f"启动麦克风失败: {e}")

    def stop_streaming(self):
        self._running = False
        if self.stream:
            self.stream.stop()
            self.stream.close()
            self.stream = None


class AudioOutputWorker(QObject):
    """
    从队列中获取音频块并播放它们。
    (此部分已修复)
    """
    error_occurred = pyqtSignal(str)

    # --- [!! 关键修复 1: 新信号 !!] ---
    # 专门用于更新波形图的信号
    waveform_ready = pyqtSignal(object)

    # --- [!! 修复结束 1 !!] ---

    def __init__(self):
        super().__init__()
        self.stream = None
        self._running = False
        self.audio_queue = queue.Queue(maxsize=5)
        self.last_good_chunk = np.zeros((BLOCK_SIZE, CHANNELS), dtype=DTYPE)

    def _audio_callback(self, outdata, frames, time, status):
        # ... (此
        # 方法保持不变) ...
        if status:
            print(f"[AudioOutput] 状态: {status}")

        try:
            chunk = self.audio_queue.get_nowait()
            outdata[:] = chunk.reshape(outdata.shape)
            self.last_good_chunk = chunk

        except queue.Empty:
            outdata[:] = self.last_good_chunk.reshape(outdata.shape)

    def play_chunk(self, chunk_bytes: bytes):
        """
        [公共槽 -> 内部方法]
        (此方法现在只负责将数据放入队列)
        """
        if not self._running:
            return

        try:
            chunk_array = np.frombuffer(chunk_bytes, dtype=DTYPE)
            if chunk_array.size != (BLOCK_SIZE * CHANNELS):
                print(f"[AudioOutput] 收到大小不匹配的音频包, 丢弃.")
                return

            self.audio_queue.put_nowait(chunk_array)

        except queue.Full:
            pass  # 丢弃最新包 (修复高音调)
        except Exception as e:
            print(f"[AudioOutput] play_chunk 错误: {e}")

    # --- [!! 关键修复 2: 新槽 !!] ---
    @pyqtSlot(bytes)
    def receive_and_play_chunk(self, chunk_bytes: bytes):
        """
        [新的公共槽]
        这是从 EthernetWorker 调用的新入口点。
        它在 AudioOutputWorker 自己的线程中执行。
        """
        # 1. 立即将音频放入队列 (关键路径)
        self.play_chunk(chunk_bytes)

        # 2. 为UI发出波形信号 (非关键路径)
        try:
            arr = np.frombuffer(chunk_bytes, dtype=DTYPE)
            if arr.size > 0:
                self.waveform_ready.emit(arr)
        except Exception as e:
            pass  # 忽略损坏的包

    # --- [!! 修复结束 2 !!] ---

    def start_playback(self):
        # ... (此
        # 方法保持不变) ...
        if self.stream and self.stream.active:
            self.error_occurred.emit("已在播放中")
            return

        try:
            self._running = True

            while not self.audio_queue.empty():
                self.audio_queue.get()
            self.last_good_chunk.fill(0)

            self.stream = sd.OutputStream(
                samplerate=SAMPLE_RATE,
                blocksize=BLOCK_SIZE,
                channels=CHANNELS,
                dtype=DTYPE,
                callback=self._audio_callback
            )
            self.stream.start()
        except Exception as e:
            self._running = False
            self.error_occurred.emit(f"启动扬声器失败: {e}")

    def stop_playback(self):
        # ... (此
        # 方法保持不变) ...
        self._running = False
        if self.stream:
            self.stream.stop()
            self.stream.close()
            self.stream = None