import socket
import time
import os
import threading

# --- 配置 ---
# 1. 服务器 (FPGA) 在这里接收命令
SERVER_HOST = '127.0.0.1'
SERVER_PORT = 8080  # 必须与你上位机 "FPGA 端口" 一致

# 2. 服务器向这个地址发送视频
CLIENT_HOST = '127.0.0.1'
CLIENT_PORT = 8081  # 必须与你上位机 "本地端口" 一致

IMAGE_FILE = 'test_video.jpg'
FPS = 30  # 模拟的视频帧率
# -------------

# 全局标志，用于停止发送线程
running = True


def load_image_data(image_path):
    """
    加载JPEG图片数据
    """
    if not os.path.exists(image_path):
        print(f"错误: 测试图片 '{image_path}' 未找到。")
        return None

    with open(image_path, 'rb') as f:
        data = f.read()

    # 假设一个JPEG帧可以放入一个UDP包
    if len(data) > 65500:
        print(f"警告: 图片太大 ({len(data)} 字节), 超过UDP包大小限制。")
        return None

    print(f"测试图片加载成功, 大小: {len(data)} 字节")
    return data


def video_stream_sender(sock, jpeg_data, target_addr):
    """
    这个函数在一个单独的线程中运行，循环发送视频包
    """
    print(f"[视频线程] 开始向 {target_addr} 发送模拟视频流...")
    while running:
        try:
            sock.sendto(jpeg_data, target_addr)
            time.sleep(1.0 / FPS)
        except Exception as e:
            # 当客户端关闭时, sendto 可能会失败, 导致这里也出错
            if running:
                print(f"[视频线程] 发送错误: {e}")
            break  # 客户端关闭，线程停止发送
    print("[视频线程] 停止。")


def main():
    global running
    jpeg_data = load_image_data(IMAGE_FILE)
    if not jpeg_data:
        return

    # 1. 创建Socket
    # 这个 socket 既用于接收命令，也用于发送视频
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    try:
        # 2. 绑定服务器地址以接收命令
        server_socket.bind((SERVER_HOST, SERVER_PORT))
        print(f"--- 模拟FPGA UDP服务器已启动 ---")
        print(f"正在 {SERVER_HOST}:{SERVER_PORT} 上等待命令...")

        # 3. 准备视频发送
        target_addr = (CLIENT_HOST, CLIENT_PORT)

        # 4. 启动视频发送线程
        sender_thread = threading.Thread(
            target=video_stream_sender,
            args=(server_socket, jpeg_data, target_addr)
        )
        sender_thread.start()

        # 5. 主线程循环，用于接收命令
        while True:
            try:
                # 阻塞式等待命令
                data, addr = server_socket.recvfrom(1024)
                print(f"[收到命令] 来自 {addr}: {data.decode('utf-8').strip()}")

            # --- 这是关键的修复 ---
            except ConnectionResetError:
                # [WinError 10054] - 远程主机强迫关闭了一个现有的连接。
                # 这通常发生在客户端 (GUI) 关闭了它的监听端口。
                # 这是一个无害的错误，我们不希望服务器因此崩溃。
                print(f"[!] 收到客户端 (GUI) 端口不可达消息。继续监听...")
                continue  # 继续循环，等待下一个命令
            # --- 修复结束 ---

            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"服务器接收出错: {e}")
                break

    except Exception as e:
        print(f"服务器启动失败: {e}")
    finally:
        print("--- 正在关闭模拟服务器 ---")
        running = False  # 通知视频线程停止
        if sender_thread.is_alive():
            sender_thread.join()  # 等待视频线程退出
        server_socket.close()
        print("--- 模拟服务器已关闭 ---")


if __name__ == "__main__":
    main()

