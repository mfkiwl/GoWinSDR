# 文件名: audio_stream_worker.py

import sounddevice as sd
import numpy as np
from PyQt6.QtCore import QObject, pyqtSignal, QThread
import queue

# --- 音频流配置 (必须在收发两端匹配!) ---
SAMPLE_RATE = 44100
CHANNELS = 1  # 保持单声道以降低数据量
DTYPE = np.float32  # Float32 是 sounddevice 的默认值
BLOCK_SIZE = 1024  # 每次回调处理的样本数


# ---------------------------------------------


class AudioInputWorker(QObject):
    """
    从麦克风连续捕获音频并通过信号发出。
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
    """
    error_occurred = pyqtSignal(str)

    def __init__(self):
        super().__init__()
        self.stream = None
        self._running = False
        # 使用队列来缓冲网络抖动
        self.audio_queue = queue.Queue(maxsize=100)  # 缓冲约100个块

    def _audio_callback(self, outdata, frames, time, status):
        """
        这是在 sounddevice 的独立线程中调用的。
        """
        if status:
            print(f"[AudioOutput] 状态: {status}")

        try:
            # 从队列中获取数据
            chunk = self.audio_queue.get_nowait()
            outdata[:] = chunk.reshape(outdata.shape)
        except queue.Empty:
            # 没有数据了 (网络延迟), 播放静音
            outdata.fill(0)

    def play_chunk(self, chunk_bytes: bytes):
        """
        [公共槽] 从网络接收字节
        """
        if not self._running:
            return  # 未在播放

        try:
            # 将字节转换回 NumPy 数组
            chunk_array = np.frombuffer(chunk_bytes, dtype=DTYPE)
            self.audio_queue.put_nowait(chunk_array)
        except queue.Full:
            print("[AudioOutput] 播放队列已满，丢弃一个音频包")
        except ValueError:
            print("[AudioOutput] 收到损坏的音频包 (大小不匹配?)")

    def start_playback(self):
        if self.stream and self.stream.active:
            self.error_occurred.emit("已在播放中")
            return

        try:
            self._running = True
            # 清空旧的缓冲
            while not self.audio_queue.empty():
                self.audio_queue.get()

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
        self._running = False
        if self.stream:
            self.stream.stop()
            self.stream.close()
            self.stream = None