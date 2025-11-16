# 文件名: py代码/camera_worker.py
# (已修复: 1. 添加了缺失的 'finished' 信号。 2. 确保在循环结束时发出信号。 3. 添加了 @pyqtSlot 装饰器。)

import cv2
import numpy as np
import time
import threading  # <-- 导入 threading
from PyQt6.QtCore import QObject, pyqtSignal, QThread, pyqtSlot  # <-- 导入 pyqtSlot
from PyQt6.QtGui import QImage

# --- 视频流配置 ---
FRAME_WIDTH = 640
FRAME_HEIGHT = 480
FPS_LIMIT = 20  # 限制帧率以节省带宽
JPEG_QUALITY = 70  # 图像质量 (0-100)


class CameraWorker(QObject):
    """
    从电脑摄像头抓取视频帧,
    并为本地显示和网络发送发出信号。
    """
    # 信号: (QImage) - 用于本地实时显示
    frame_ready = pyqtSignal(QImage)
    # 信号: (bytes) - 用于发送到网络
    jpeg_bytes_ready = pyqtSignal(bytes)
    # 信号: (str) - 用于错误日志
    error_occurred = pyqtSignal(str)

    # --- [!! 关键修复 1 !!] ---
    # 添加 'finished' 信号
    finished = pyqtSignal()

    # --- [!! 修复结束 1 !!] ---

    def __init__(self):
        super().__init__()
        self.cap = None
        self._running = False
        self.frame_interval = 1.0 / FPS_LIMIT
        self.capture_thread = None  # 保持对线程的引用

    @pyqtSlot()  # <-- 添加装饰器
    def start_streaming(self):
        """
        [公共槽] 启动摄像头
        """
        if self.cap and self.cap.isOpened():
            self.error_occurred.emit("摄像头已在运行中")
            return

        try:
            # 尝试打开默认摄像头 (索引 0)
            self.cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)  # 使用 DSHOW 后端提高Windows兼容性
            if not self.cap.isOpened():
                raise ConnectionError("无法打开摄像头。请检查是否已连接或被其他程序占用。")

            # 设置摄像头分辨率
            self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, FRAME_WIDTH)
            self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, FRAME_HEIGHT)

            self._running = True

            # 启动一个内部线程来循环读取 (避免阻塞)
            self.capture_thread = threading.Thread(target=self.run_capture_loop, daemon=True)
            self.capture_thread.start()


        except Exception as e:
            self._running = False
            self.cap = None
            self.error_occurred.emit(f"启动摄像头失败: {e}")

    def run_capture_loop(self):
        """
        在工作线程中运行的循环。
        """
        last_frame_time = 0
        try:
            while self._running:
                try:
                    # --- 限制帧率 ---
                    current_time = time.time()
                    if (current_time - last_frame_time) < self.frame_interval:
                        # 睡一小会，把CPU让给其他线程
                        time.sleep(0.001)
                        continue
                    last_frame_time = current_time

                    # --- 1. 读取帧 ---
                    if not self.cap:
                        break
                    ret, frame = self.cap.read()
                    if not ret:
                        self.error_occurred.emit("无法读取摄像头帧，停止。")
                        self._running = False
                        break

                    # (可选) 水平翻转图像，使其像镜子一样
                    frame = cv2.flip(frame, 1)

                    # --- 2. 为本地显示准备 (OpenCV BGR -> QImage RGB) ---
                    rgb_image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    h, w, ch = rgb_image.shape
                    bytes_per_line = ch * w
                    qt_image = QImage(rgb_image.data, w, h, bytes_per_line, QImage.Format.Format_RGB888)
                    self.frame_ready.emit(qt_image.copy())  # 发送 QImage (用 .copy() 确保线程安全)

                    # --- 3. 为网络发送准备 (编码为 JPEG) ---
                    encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), JPEG_QUALITY]
                    ret, jpeg_buffer = cv2.imencode('.jpg', frame, encode_param)
                    if ret:
                        self.jpeg_bytes_ready.emit(jpeg_buffer.tobytes())  # 发送 bytes

                except Exception as e:
                    if self._running:
                        self.error_occurred.emit(f"摄像头捕获循环出错: {e}")
                    self._running = False  # 出错时停止循环

        finally:
            # --- [!! 关键修复 2 !!] ---
            # 循环结束，释放摄像头并发出 'finished' 信号
            if self.cap:
                try:
                    self.cap.release()
                except Exception as e:
                    print(f"释放摄像头时出错: {e}")
            self.cap = None
            self.error_occurred.emit("摄像头已停止。")
            self.finished.emit()
            # --- [!! 修复结束 2 !!] ---

    @pyqtSlot()  # <-- 添加装饰器
    def stop_streaming(self):
        """
        [公共槽] 停止摄像头
        """
        self._running = False