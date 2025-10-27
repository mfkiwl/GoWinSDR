import sounddevice as sd
import wave
import numpy as np
from PyQt6.QtCore import QObject, pyqtSignal


class AudioWorker(QObject):
    """
    音频录制工作线程
    """
    audio_recorded = pyqtSignal(bytes)  # 录制完成后发送音频数据
    error_occurred = pyqtSignal(str)  # 发生错误时发射

    def __init__(self):
        super().__init__()
        self.is_recording = False
        self.frames = []
        self.sample_rate = 48000  # 采样率
        self.channels = 2  # 双声道
        self.stream = None

    def start_recording(self):
        """
        开始录制音频
        """
        if self.is_recording:
            self.error_occurred.emit("录制已在进行中")
            return

        self.is_recording = True
        self.frames = []

        try:
            # 开始录制
            self.stream = sd.InputStream(callback=self.audio_callback,
                                         samplerate=self.sample_rate,
                                         channels=self.channels)
            self.stream.start()
        except Exception as e:
            self.is_recording = False
            self.error_occurred.emit(f"录制失败: {e}")

    def stop_recording(self):
        """
        停止录制音频
        """
        if not self.is_recording:
            self.error_occurred.emit("录制未开始")
            return

        self.is_recording = False

        # 停止流
        if self.stream:
            self.stream.stop()
            self.stream.close()
            self.stream = None

        try:
            # 将录制的音频数据转换为字节
            audio_data = np.concatenate(self.frames, axis=0)

            # 归一化音频数据
            audio_data = audio_data / np.max(np.abs(audio_data), axis=0)

            # 保存为 WAV 文件
            with wave.open("temp_audio.wav", "wb") as wf:
                wf.setnchannels(self.channels)
                wf.setsampwidth(2)  # 16位音频
                wf.setframerate(self.sample_rate)
                wf.writeframes((audio_data * 32767).astype(np.int16).tobytes())

            # 读取 WAV 文件并发送数据
            with open("temp_audio.wav", "rb") as f:
                self.audio_recorded.emit(f.read())
        except Exception as e:
            self.error_occurred.emit(f"音频处理失败: {e}")

    def audio_callback(self, indata, frames, time, status):
        """
        音频录制回调
        """
        try:
            if self.is_recording:
                # 将录制的音频数据存储到 frames
                self.frames.append(indata.copy())
        except Exception as e:
            self.error_occurred.emit(f"音频回调错误: {e}")