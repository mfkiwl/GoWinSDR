import socket
import threading
from PyQt6.QtCore import QObject, pyqtSignal
from PyQt6.QtGui import QImage


class EthernetWorker(QObject):
    """
    网络工作线程 (UDP)

    - 接收循环运行在独立的 Python 线程 self._recv_thread 中，start_listening 非阻塞。
    - 支持 stop_listening 安全关闭 socket 以中断 recvfrom。
    - 新增 send_command 方法，可在监听时或未监听时发送 UDP 命令（若未监听则使用短期临时 socket 发送）。
    """

    # 定义信号
    started = pyqtSignal()
    stopped = pyqtSignal()
    log_received = pyqtSignal(str)  # 用于发送日志
    video_frame_ready = pyqtSignal(QImage)  # 用于发送视频帧
    error_occurred = pyqtSignal(str)
    finished = pyqtSignal()

    def __init__(self):
        super().__init__()
        self.sock = None
        self._running = False
        self.fpga_addr = None  # (ip, port)
        self._recv_thread = None
        self._lock = threading.Lock()

    def start_listening(self, listen_ip, listen_port, fpga_ip, fpga_port):
        """
        启动接收线程（非阻塞，立即返回）。
        实际接收循环在独立线程 self._recv_thread 中运行。
        """
        with self._lock:
            if self._recv_thread and self._recv_thread.is_alive():
                self.log_received.emit("[警告] 监听已在运行，请先停止。")
                return

            # 存储目标地址
            self.fpga_addr = (fpga_ip, fpga_port)
            self._running = True

            # 启动后台接收线程
            self._recv_thread = threading.Thread(
                target=self._recv_loop, args=(listen_ip, listen_port), daemon=True
            )
            self._recv_thread.start()

        # 发信号通知已经开始（UI可立即响应）
        self.started.emit()
        self.log_received.emit(f"UDP 正在监听 {listen_ip}:{listen_port}...")

    def _recv_loop(self, listen_ip, listen_port):
        """
        在独立的 Python 线程中执行接收循环。
        关闭 socket 会使 recvfrom 抛出异常，从而结束循环。
        """
        try:
            # 1. 创建 UDP socket
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.sock.settimeout(0.5)

            # 2. 绑定本地地址
            try:
                self.sock.bind((listen_ip, listen_port))
            except Exception as e:
                # 绑定失败，向 UI 报错并返回
                self.error_occurred.emit(f"UDP 绑定失败: {e}")
                return

            # 3. 接收循环
            while self._running:
                try:
                    data, addr = self.sock.recvfrom(65536)
                    image = QImage()
                    image.loadFromData(data, "JPEG")

                    if not image.isNull():
                        self.video_frame_ready.emit(image)
                    else:
                        self.log_received.emit("[警告] 收到损坏的UDP数据包 (非JPEG?)")

                except socket.timeout:
                    # 正常超时，继续检查 self._running
                    continue
                except Exception as e:
                    # 当另一个线程调用 close() 时会抛异常
                    if self._running:
                        self.error_occurred.emit(f"UDP 接收错误: {e}")
                    # 不论是否主动停止，都退出循环
                    break

        finally:
            # 清理 socket
            try:
                if self.sock:
                    self.sock.close()
            except Exception:
                pass
            self.sock = None

            # 确保状态一致
            self._running = False

            # 发停止/完成信号（这些信号会回到主线程，更新 UI）
            self.stopped.emit()
            self.finished.emit()
            self.log_received.emit("UDP 监听已停止")

    def stop_listening(self):
        """
        停止接收循环并关闭 socket。
        这个函数可以从主线程被调用（直接或 queued 连接都可以），
        关闭 socket 会导致 recvfrom 抛出异常，从而让后台线程退出循环。
        """
        self._running = False

        # 强制关闭 socket（可能在接收线程中被使用）
        try:
            if self.sock:
                self.sock.close()
        except Exception:
            pass

        # 不在这里 join 线程以避免阻塞 GUI；后台线程退出后会发 stopped/finished
        self.log_received.emit("停止请求已发送 -> 正在等待接收线程退出...")

    def send_command(self, cmd_str):
        """
        使用 sendto() 发送UDP命令。
        - 若当前已有用于接收的 socket（self.sock），优先通过该 socket 发送。
        - 若未监听，也允许通过临时 socket 发送命令（不会改变监听状态）。
        - 线程安全：使用 self._lock 保护对 self.sock / self.fpga_addr 的访问。
        """
        with self._lock:
            addr = self.fpga_addr

            if not addr:
                self.error_occurred.emit("发送失败: 目标地址未设置")
                return

            try:
                payload = cmd_str.encode('utf-8') + b'\n'
                if self.sock:
                    # 如果监听 socket 存在，直接使用它发送
                    try:
                        self.sock.sendto(payload, addr)
                    except Exception as e:
                        # 如果通过监听 socket 发送失败，再尝试临时 socket 发送一次
                        self.log_received.emit(f"通过监听 socket 发送失败，尝试临时 socket：{e}")
                        tmp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                        tmp.sendto(payload, addr)
                        tmp.close()
                else:
                    # 未监听时使用短期 socket 发送
                    tmp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                    tmp.sendto(payload, addr)
                    tmp.close()

                self.log_received.emit(f"-> [UDP发送]: {cmd_str} 至 {addr}")
            except Exception as e:
                self.error_occurred.emit(f"UDP 发送失败: {e}")