# 文件名: py代码/audio_stream_worker.py
# (已修改：start_streaming 支持指定设备ID)

import sounddevice as sd
import numpy as np
from PyQt6.QtCore import QObject, pyqtSignal, QThread, pyqtSlot
import queue

# --- 音频流配置 ---
SAMPLE_RATE = 44100
CHANNELS = 1
DTYPE = np.float32
BLOCK_SIZE = 256


# ------------------


class AudioInputWorker(QObject):
    """
    从麦克风或指定设备连续捕获音频并通过信号发出。
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
            # 忽略 Input overflow 警告，避免刷屏
            if "Input overflow" not in str(status):
                print(f"[AudioInput] 状态: {status}")

        if self._running:
            # 1. 发送 NumPy 数组给本地波形图
            self.chunk_ready_array.emit(indata.copy())
            # 2. 发送原始字节给网络
            self.chunk_ready_bytes.emit(indata.tobytes())

    @pyqtSlot(int)
    def start_streaming(self, device_index=None):
        """
        开始采集
        :param device_index: sounddevice 的设备ID (int)。如果为 None 或 -1，使用系统默认。
        """
        if self.stream and self.stream.active:
            self.error_occurred.emit("已在录制中")
            return

        # 处理无效索引
        dev_id = device_index
        if dev_id is not None and dev_id < 0:
            dev_id = None  # 使用默认

        try:
            self._running = True

            # 打印调试信息
            # dev_info = sd.query_devices(dev_id, 'input') if dev_id is not None else "Default"
            # print(f"正在打开音频设备 ID: {dev_id}, Info: {dev_info}")

            self.stream = sd.InputStream(
                samplerate=SAMPLE_RATE,
                blocksize=BLOCK_SIZE,
                channels=CHANNELS,
                dtype=DTYPE,
                device=dev_id,  # [!! 关键修改 !!] 传入设备ID
                callback=self._audio_callback
            )
            self.stream.start()
        except Exception as e:
            self._running = False
            self.error_occurred.emit(f"启动音频采集失败 (设备ID {dev_id}): {e}")

    def stop_streaming(self):
        self._running = False
        if self.stream:
            try:
                self.stream.stop()
                self.stream.close()
            except Exception:
                pass
            self.stream = None


class AudioOutputWorker(QObject):
    """
    从队列中获取音频块并播放它们。
    """
    error_occurred = pyqtSignal(str)
    # 专门用于更新波形图的信号
    waveform_ready = pyqtSignal(object)

    def __init__(self):
        super().__init__()
        self.stream = None
        self._running = False
        self.audio_queue = queue.Queue(maxsize=10)  # 稍微增大缓冲
        self.last_good_chunk = np.zeros((BLOCK_SIZE, CHANNELS), dtype=DTYPE)

    def _audio_callback(self, outdata, frames, time, status):
        if status:
            if "Output underflow" not in str(status):
                print(f"[AudioOutput] 状态: {status}")

        try:
            chunk = self.audio_queue.get_nowait()
            outdata[:] = chunk.reshape(outdata.shape)
            self.last_good_chunk = chunk

        except queue.Empty:
            # 缓冲不足时，静音或重复上一帧(这里选择静音以减少噪音)
            outdata.fill(0)
            # outdata[:] = self.last_good_chunk.reshape(outdata.shape)

    def play_chunk(self, chunk_bytes: bytes):
        """
        [内部方法] 将数据放入队列
        """
        if not self._running:
            return

        try:
            chunk_array = np.frombuffer(chunk_bytes, dtype=DTYPE)
            if chunk_array.size != (BLOCK_SIZE * CHANNELS):
                # print(f"[AudioOutput] 收到大小不匹配的音频包, 丢弃.")
                return

            self.audio_queue.put_nowait(chunk_array)

        except queue.Full:
            pass  # 丢弃最新包以追赶实时性
        except Exception as e:
            print(f"[AudioOutput] play_chunk 错误: {e}")

    @pyqtSlot(bytes)
    def receive_and_play_chunk(self, chunk_bytes: bytes):
        """
        [公共槽] 网络线程调用此方法
        """
        # 1. 播放逻辑
        self.play_chunk(chunk_bytes)

        # 2. UI波形逻辑
        try:
            arr = np.frombuffer(chunk_bytes, dtype=DTYPE)
            if arr.size > 0:
                self.waveform_ready.emit(arr)
        except Exception:
            pass

    def start_playback(self):
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
        self._running = False
        if self.stream:
            try:
                self.stream.stop()
                self.stream.close()
            except Exception:
                pass
            self.stream = None