import sounddevice as sd
import wave
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
            sd.InputStream(callback=self.audio_callback,
                           samplerate=self.sample_rate,
                           channels=self.channels).start()
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

        # 将录制的音频数据转换为字节
        try:
            with wave.open("temp_audio.wav", "wb") as wf:
                wf.setnchannels(self.channels)
                wf.setsampwidth(2)  # 16位音频
                wf.setframerate(self.sample_rate)
                wf.writeframes(b"".join(self.frames))

            with open("temp_audio.wav", "rb") as f:
                audio_data = f.read()
                self.audio_recorded.emit(audio_data)
        except Exception as e:
            self.error_occurred.emit(f"音频处理失败: {e}")

    def audio_callback(self, indata, frames, time, status):
        """
        音频录制回调
        """
        if self.is_recording:
            self.frames.append(indata.copy())