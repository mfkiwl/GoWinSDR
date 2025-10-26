import serial
import serial.tools.list_ports
import time
from PyQt6.QtCore import QObject, pyqtSignal


class SerialWorker(QObject):
    """
    串口工作线程
    处理所有串口的读写操作，避免GUI卡顿
    """
    # 定义信号
    connected = pyqtSignal(str)  # 连接成功时发射
    disconnected = pyqtSignal()  # 断开连接时发射
    log_received = pyqtSignal(str)  # 收到日志数据时发射
    error_occurred = pyqtSignal(str)  # 发生错误时发射

    # --- 新增 ---
    finished = pyqtSignal()  # 线程结束时发射

    def __init__(self):
        super().__init__()
        self.serial = None
        self._running = False

    def connect_serial(self, port, baudrate):
        """
        尝试连接串口
        """
        if self.serial:
            self.disconnect_serial()

        try:
            self.serial = serial.Serial(port, int(baudrate), timeout=1)
            if self.serial.is_open:
                self._running = True
                self.connected.emit(f"成功连接到 {port} @ {baudrate}bps")
                # 启动读取循环 (在当前工作线程中)
                self.start_read_loop()
        except serial.SerialException as e:
            self.error_occurred.emit(f"连接失败: {e}")

    def disconnect_serial(self):
        """
        断开串口连接
        """
        self._running = False
        if self.serial:
            try:
                self.serial.close()
            except Exception as e:
                self.error_occurred.emit(f"关闭串口时出错: {e}")
            self.serial = None
        self.disconnected.emit()

        # --- 新增 ---
        # 当断开连接(工作完成)时，发射finished信号
        self.finished.emit()

    def start_read_loop(self):
        """
        循环读取串口数据
        这个函数会阻塞，直到 _running 为 False
        """
        while self._running and self.serial and self.serial.is_open:
            try:
                # readline() 会阻塞直到收到一个换行符或超时
                if self.serial.in_waiting > 0:
                    line = self.serial.readline()
                    if line:
                        # 假设设备发送的是UTF-8编码的文本
                        self.log_received.emit(line.decode('utf-8', errors='ignore').strip())
            except serial.SerialException as e:
                # 串口拔出等异常
                self.error_occurred.emit(f"读取错误: {e}")
                self._running = False  # 导致循环退出
            except Exception as e:
                # 其他未知错误
                self.error_occurred.emit(f"未知读取错误: {e}")
            time.sleep(0.01)  # 避免CPU空转

        # 循环结束，确保已断开连接 (如果尚未断开)
        if self.serial:
            self.disconnect_serial()  # 这将触发 finished 信号

    def send_data(self, data_str):
        """
        向串口发送字符串数据
        """
        if self.serial and self.serial.is_open:
            try:
                # 确保发送的是字节，并添加换行符（假设设备需要）
                self.serial.write(data_str.encode('utf-8') + b'\n')
                self.log_received.emit(f"-> [发送命令]: {data_str}")
            except Exception as e:
                self.error_occurred.emit(f"发送失败: {e}")
        else:
            self.error_occurred.emit("发送失败: 串口未连接")

    def send_file(self, file_path):
        """
        向串口发送文件（原始字节）
        """
        if not (self.serial and self.serial.is_open):
            self.error_occurred.emit("发送失败: 串口未连接")
            return

        try:
            with open(file_path, 'rb') as f:
                self.log_received.emit(f"-> [开始发送文件]: {file_path}")
                while True:
                    chunk = f.read(1024)  # 每次读取 1KB
                    if not chunk:
                        break  # 文件发送完毕
                    self.serial.write(chunk)
                    # 可以在这里添加握手协议或延时，以防止FPGA缓冲区溢出
                    # time.sleep(0.01)
                self.log_received.emit(f"-> [文件发送完毕]")
        except FileNotFoundError:
            self.error_occurred.emit(f"文件未找到: {file_path}")
        except Exception as e:
            self.error_occurred.emit(f"文件发送失败: {e}")

    @staticmethod
    def get_available_ports():
        """
        静态方法，获取当前可用的串口列表
        """
        ports = serial.tools.list_ports.comports()
        return [port.device for port in ports]

