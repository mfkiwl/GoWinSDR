import sys
import struct
import numpy as np
from scapy.all import Dot11, Dot11Beacon, Dot11Elt, RadioTap
from zlib import crc32

# ================= 配置参数 =================
SSID_NAME = "open123456"
SENDER_MAC = "00:11:22:33:44:55"
BROADCAST_MAC = "ff:ff:ff:ff:ff:ff"
OUTPUT_FILE = "beacon_chips.bin"

# 802.11b Barker Code (11 chips)
# 左边是先发送的 (假设 BPSK 映射: 0->-1, 1->+1)
BARKER_SEQ = np.array([1, 0, 1, 1, 0, 1, 1, 1, 0, 0, 0], dtype=int)


def get_crc16(data_bytes):
    """计算 PLCP Header 的 CRC-16 (X^16 + X^12 + X^5 + 1)"""
    crc = 0xFFFF
    poly = 0x8408  # 反转的多项式 (0x1021 的反转)

    for b in data_bytes:
        crc ^= b
        for _ in range(8):
            if (crc & 0x0001):
                crc = (crc >> 1) ^ poly
            else:
                crc >>= 1
    return (~crc) & 0xFFFF


def bytes_to_bits_lsb(data_bytes):
    """将字节转换为比特流 (LSB First: 802.11 标准)"""
    bits = []
    for b in data_bytes:
        for i in range(8):
            bits.append((b >> i) & 1)
    return bits


def scrambler(bits):
    """
    IEEE 802.11b Scrambler
    Poly: X^7 + X^4 + 1
    Seed: 必须非零，这里随机选一个，例如 0b1011101
    """
    state = [1, 0, 1, 1, 1, 0, 1]  # 初始种子 (7 bits)
    out_bits = []

    for b in bits:
        # 反馈位: x^7 + x^4
        feedback = state[6] ^ state[3]
        # 更新状态 (移位)
        state = [feedback] + state[:-1]
        # 输出位 = 输入位 XOR 反馈位
        out_bits.append(b ^ feedback)

    return out_bits


def diff_encode(bits):
    """DBPSK 差分编码: out[i] = data[i] XOR out[i-1]"""
    out_bits = []
    last_bit = 0  # 初始参考相位假设为 0
    for b in bits:
        encoded = b ^ last_bit
        out_bits.append(encoded)
        last_bit = encoded
    return out_bits


def spread_spectrum(bits):
    """DSSS 扩频: 1 bit -> 11 chips (Barker)"""
    chips = []
    for b in bits:
        # 如果 bit 为 1，Barker 码反转 (XOR 1)；如果为 0，保持原样
        # 注意：这里是逻辑上的扩频，后续物理映射 0->-1, 1->+1
        seq = [c ^ b for c in BARKER_SEQ]
        chips.extend(seq)
    return chips


def create_packet():
    print(f"[*] Generating Beacon Frame for SSID: {SSID_NAME}")

    # 1. 构建 MAC 层 (使用 Scapy)
    # 注意：不包含 RadioTap 头，因为那是给操作系统看的，我们要发纯 Raw 802.11 帧
    dot11 = Dot11(type=0, subtype=8, addr1=BROADCAST_MAC, addr2=SENDER_MAC, addr3=SENDER_MAC)
    beacon = Dot11Beacon(cap='ESS')
    essid = Dot11Elt(ID='SSID', info=SSID_NAME, len=len(SSID_NAME))
    # 支持速率: 1Mbps (0x82 = 基础速率 1Mbps)
    rates = Dot11Elt(ID='Rates', info=b'\x82')
    dsset = Dot11Elt(ID='DSset', info=b'\x01')  # Channel 1

    mac_frame = dot11 / beacon / essid / rates / dsset
    mac_bytes = bytes(mac_frame)

    # 2. 计算 FCS (CRC32) 并附加到 MAC 帧末尾
    # Scapy 有时会自动加，但为了保险我们自己算
    fcs = crc32(mac_bytes) & 0xffffffff
    mac_bytes += struct.pack('<I', fcs)  # Little endian

    # 3. 构建 PLCP Header (802.11b Long Preamble)
    # Signal: 0x0A (1Mbps)
    # Service: 0x00
    # Length: 微秒数。1Mbps下，1 byte = 8 us.
    length_us = len(mac_bytes) * 8

    plcp_header_bytes = bytearray()
    plcp_header_bytes.append(0x0A)  # Signal
    plcp_header_bytes.append(0x00)  # Service
    plcp_header_bytes.extend(struct.pack('<H', length_us))  # Length (2 bytes)

    # 计算 PLCP Header CRC
    hdr_crc = get_crc16(plcp_header_bytes)
    plcp_header_bytes.extend(struct.pack('<H', hdr_crc))

    # 4. 组装比特流 (Raw Bits)
    # 结构: [Preamble Sync 128 bit] + [SFD 16 bit] + [PLCP Header 48 bit] + [MAC Frame]

    # Sync: 128 个 1
    raw_bits = [1] * 128

    # SFD: 0xF3A0 (1111 0011 1010 0000)
    # 按照 LSB first 发送: 0xF3 -> 11001111, 0xA0 -> 00000101
    sfd_bytes = b'\xf3\xa0'
    raw_bits.extend(bytes_to_bits_lsb(sfd_bytes))

    # PLCP Header
    raw_bits.extend(bytes_to_bits_lsb(plcp_header_bytes))

    # MAC Frame Body
    raw_bits.extend(bytes_to_bits_lsb(mac_bytes))

    print(f"[*] Total Raw Bits: {len(raw_bits)}")

    # 5. 加扰 (Scrambling)
    # 802.11b 标准要求整个 PSDU (包含 Preamble) 都要加扰
    scrambled_bits = scrambler(raw_bits)

    # 6. 差分编码 (Differential Encoding)
    diff_bits = diff_encode(scrambled_bits)

    # 7. DSSS 扩频 (Barker Spreading)
    chip_stream = spread_spectrum(diff_bits)

    print(f"[*] Total Chips to send: {len(chip_stream)}")

    # 8. 保存为二进制文件 (供 FPGA 读取)
    # 这里我们将每个 chip 存为 1 个字节 (0x00 或 0x01)，方便 Verilog 读取
    # 你也可以打包成 bit 存，但处理麻烦
    with open(OUTPUT_FILE, 'wb') as f:
        f.write(bytearray(chip_stream))

    print(f"[+] Saved to {OUTPUT_FILE}")


if __name__ == "__main__":
    create_packet()