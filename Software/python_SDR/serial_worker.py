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
    log_received = pyqtSignal(str)  # 收到普通日志时发射
    error_occurred = pyqtSignal(str)  # 发生错误时发射
    finished = pyqtSignal()  # 线程结束时发射

    # --- 新增: 用于参数响应的专用信号 ---
    #      (command_name, value)
    param_response_received = pyqtSignal(str, str)

    def __init__(self):
        super().__init__()
        self.serial = None
        self._running = False

    def connect_serial(self, port, baudrate):
        """
        尝试连接串口
        """
        if self.serial:
            # 如果已连接，先断开旧的
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
        self._running = False  # 通知读取循环停止
        if self.serial:
            try:
                self.serial.close()
            except Exception as e:
                self.error_occurred.emit(f"关闭串口时出错: {e}")
            self.serial = None

        self.disconnected.emit()
        self.finished.emit()  # 确保线程可以被清理

    def start_read_loop(self):
        """
        循环读取串口数据 (已修改为可解析响应)
        """
        buffer = bytearray()
        while self._running and self.serial and self.serial.is_open:
            try:
                # 检查是否有数据在等待
                if self.serial.in_waiting > 0:
                    # 读取所有可用数据，避免阻塞
                    data = self.serial.read(self.serial.in_waiting)
                    buffer.extend(data)

                    # 处理缓冲区中的所有完整行
                    while b'\n' in buffer:
                        line_bytes, buffer = buffer.split(b'\n', 1)
                        line_str = line_bytes.decode('utf-8', errors='ignore').strip()
                        self.process_line(line_str)
                else:
                    # 没有数据时短暂休眠，避免CPU空转
                    time.sleep(0.01)

            except serial.SerialException as e:
                self.error_occurred.emit(f"读取错误: {e}")
                self._running = False  # 导致循环退出
            except Exception as e:
                if self._running:  # 避免在关闭时报告错误
                    self.error_occurred.emit(f"未知读取错误: {e}")

        # 循环结束，确保已断开连接 (如果尚未断开)
        if self.serial:
            self.disconnect_serial()

    def process_line(self, line):
        """
        辅助函数: 解析收到的行
        """
        if not line:
            return

        # --- 核心逻辑: 检查它是否是一个参数响应 ---
        # 你的设备响应格式为 "command=value"
        if '=' in line:
            parts = line.split('=', 1)
            if len(parts) == 2:
                command = parts[0].strip()
                value = parts[1].strip()

                # 这是一个参数响应！
                self.param_response_received.emit(command, value)
                return  # 处理完毕

        # --- 如果不是参数响应，则视为普通日志 ---
        self.log_received.emit(line)

    def send_data(self, data_str):
        """
        向串口发送字符串数据 (命令)
        """
        if self.serial and self.serial.is_open:
            try:
                # 你的设备需要换行符来执行命令
                full_command = data_str + '\n'
                self.serial.write(full_command.encode('utf-8'))
                self.log_received.emit(f"-> [发送]: {data_str}")
            except Exception as e:
                self.error_occurred.emit(f"发送失败: {e}")
        else:
            self.error_occurred.emit("发送失败: 串口未连接")

    def send_file(self, file_path):
        """
        向串口发送文件（原始字节）
        (此功能保持不变)
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
        (此功能保持不变)
        """
        ports = serial.tools.list_ports.comports()
        return [port.device for port in ports]

