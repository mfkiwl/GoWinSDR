import socket
import time
import os
import threading
import cv2  # <-- 新导入 OpenCV

# --- 配置 ---
# 1. 服务器 (FPGA) 在这里接收命令
SERVER_HOST = '127.0.0.1'
SERVER_PORT = 8080  # 必须与你上位机 "FPGA 端口" 一致

# 2. 服务器向这个地址发送视频
CLIENT_HOST = '127.0.0.1'
CLIENT_PORT = 8081  # 必须与你上位机 "本地端口" 一致

VIDEO_FILE = 'test_video.mp4'  # <-- 修改为视频文件
FPS = 30  # 默认帧率 (如果视频文件无法读取)
# -------------

# 全局标志，用于停止发送线程
running = True


def video_stream_sender(sock, target_addr):
    """
    这个函数在一个单独的线程中运行，
    读取视频文件, 编码为JPEG, 并循环发送视频包
    """
    print(f"[视频线程] 尝试打开视频文件: {VIDEO_FILE}...")

    cap = cv2.VideoCapture(VIDEO_FILE)
    if not cap.isOpened():
        print(f"[视频线程] 错误: 无法打开视频文件 '{VIDEO_FILE}'。")
        print("[视频线程] 请确保文件存在并且 OpenCV (FFmpeg) 可以读取它。")
        return  # 线程退出

    # 尝试获取视频的真实FPS，如果失败则使用默认值
    try:
        video_fps = cap.get(cv2.CAP_PROP_FPS)
        if video_fps <= 0:
            video_fps = FPS
    except:
        video_fps = FPS

    print(f"[视频线程] 视频文件打开成功。将以 ~{int(video_fps)} FPS 发送。")
    print(f"[视频线程] 开始向 {target_addr} 发送模拟视频流...")

    while running:
        try:
            ret, frame = cap.read()

            if not ret:
                # 视频播放完毕, 循环播放
                # print("[视频线程] 视频播放完毕, 循环。")
                cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
                continue

            # 1. 调整帧大小以确保UDP包不会太大
            # 640x480 是一个比较安全的分辨率
            frame_resized = cv2.resize(frame, (640, 480))

            # 2. 将帧编码为JPEG
            # 设置JPEG质量 (90%)
            encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 90]
            ret, jpeg_data_encoded = cv2.imencode('.jpg', frame_resized, encode_param)

            if not ret:
                print("[视频线程] 帧编码为JPEG失败，跳过。")
                continue

            jpeg_data = jpeg_data_encoded.tobytes()

            # 3. 检查大小
            if len(jpeg_data) > 65500:
                print(f"[视频线程] 警告: 编码后的帧太大 ({len(jpeg_data)} 字节), 降低质量。")
                # 尝试用更低的质量再次编码
                encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 50]
                ret, jpeg_data_encoded = cv2.imencode('.jpg', frame_resized, encode_param)
                if not ret:
                    print("[视频线程] 降低质量后编码失败，跳过此帧。")
                    continue

                jpeg_data = jpeg_data_encoded.tobytes()

                if len(jpeg_data) > 65500:
                    print("[视频线程] 降低质量后仍然太大，跳过此帧。")
                    continue

            # 4. 发送数据
            sock.sendto(jpeg_data, target_addr)

            # 5. 等待 (根据视频的真实帧率)
            time.sleep(1.0 / video_fps)

        except Exception as e:
            if running:
                print(f"[视频线程] 发送错误: {e}")
            break  # 客户端关闭，线程停止发送

    cap.release()
    print("[视频线程] 视频流停止。")


def main():
    global running
    # 1. 创建Socket
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
            args=(server_socket, target_addr)  # 参数已更改
        )
        sender_thread.daemon = True  # 设置为守护线程
        sender_thread.start()

        # 5. 主线程循环，用于接收命令
        while True:
            try:
                # 阻塞式等待命令
                data, addr = server_socket.recvfrom(1024)
                print(f"[收到命令] 来自 {addr}: {data.decode('utf-8').strip()}")

            except ConnectionResetError:
                # [WinError 10054]
                print(f"[!] 收到客户端 (GUI) 端口不可达消息。继续监听...")
                continue  # 继续循环

            except KeyboardInterrupt:
                print("\n[!] 收到 Ctrl+C...")
                break  # 退出循环
            except Exception as e:
                print(f"服务器接收出错: {e}")
                break

    except Exception as e:
        print(f"服务器启动失败: {e}")
    finally:
        print("--- 正在关闭模拟服务器 ---")
        running = False  # 通知视频线程停止
        if sender_thread.is_alive():
            print("等待视频线程退出...")
            sender_thread.join(timeout=2.0)  # 等待线程2秒钟
        server_socket.close()
        print("--- 模拟服务器已关闭 ---")


if __name__ == "__main__":
    main()

