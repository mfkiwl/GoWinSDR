import struct
import numpy as np

# ================= 配置 =================
INPUT_FILE = "beacon_chips.bin"
# 802.11b Barker Code (11 chips)
BARKER_SEQ = np.array([1, 0, 1, 1, 0, 1, 1, 1, 0, 0, 0], dtype=int)


def correlate_and_despread(chips):
    if len(chips) % 11 != 0:
        print(f"[Warning] Chip count {len(chips)} is not a multiple of 11. Truncating.")
        chips = chips[:-(len(chips) % 11)]
    n_bits = len(chips) // 11
    decoded_bits = []
    for i in range(n_bits):
        chunk = chips[i * 11: (i + 1) * 11]
        xor_sum = np.sum(chunk ^ BARKER_SEQ)
        if xor_sum < 2:
            decoded_bits.append(0)
        elif xor_sum > 9:
            decoded_bits.append(1)
        else:
            decoded_bits.append(0)
    return decoded_bits


def diff_decode(bits):
    decoded = []
    prev = 0
    for curr in bits:
        val = curr ^ prev
        decoded.append(val)
        prev = curr
    return decoded


def descrambler(bits):
    state = [1, 0, 1, 1, 1, 0, 1]
    out_bits = []
    for b in bits:
        feedback = state[6] ^ state[3]
        state = [feedback] + state[:-1]
        out_bits.append(b ^ feedback)
    return out_bits


def bits_to_bytes(bits):
    bytes_data = bytearray()
    for i in range(0, len(bits), 8):
        byte_chunk = bits[i:i + 8]
        if len(byte_chunk) < 8:
            break
        val = 0
        for idx, bit in enumerate(byte_chunk):
            val |= (bit << idx)
        bytes_data.append(val)
    return bytes_data


def verify():
    print(f"[*] Reading {INPUT_FILE}...")
    try:
        with open(INPUT_FILE, 'rb') as f:
            chips = np.frombuffer(f.read(), dtype=np.uint8)
    except FileNotFoundError:
        print(f"[Error] File not found.")
        return

    print(f"[*] Total Chips: {len(chips)}")

    # 1. 解扩频
    raw_bits = correlate_and_despread(chips)
    # 2. 解差分
    diff_decoded = diff_decode(raw_bits)
    # 3. 解扰码
    descrambled = descrambler(diff_decoded)

    # 4. 寻找 SFD
    sfd_pattern = [1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 1]
    start_idx = -1
    for i in range(len(descrambled) - 16):
        if descrambled[i: i + 16] == sfd_pattern:
            start_idx = i + 16
            print(f"[+] Found SFD at bit index: {i}")
            break

    if start_idx == -1:
        print("[-] SFD not found!")
        return

    # 5. 提取 Payload
    payload_bits = descrambled[start_idx:]
    payload_bytes = bits_to_bytes(payload_bits)

    plcp_header = payload_bytes[:6]
    psdu = payload_bytes[6:]  # 这里是完整的 MAC Frame (Header + Body + FCS)

    print(f"[+] PLCP Header: {plcp_header.hex()} (Signal: {plcp_header[0]:02x})")
    print(f"[+] PSDU (MAC Frame): {psdu.hex()}")

    # ================= 解析 SSID =================
    print("\n--- Parsing Beacon Info ---")

    # Beacon Frame 结构:
    # 24 bytes: MAC Header
    # 12 bytes: Fixed Parameters (Timestamp, Interval, Cap)
    # Variable: Tags

    offset_to_tags = 24 + 12

    if len(psdu) < offset_to_tags:
        print("[!] MAC Frame too short.")
        return

    # 跳过 MAC Header 和 Fixed Parameters，直接定位到 Tags
    tagged_params = psdu[offset_to_tags:]

    current_idx = 0
    found_ssid = False

    while current_idx < len(tagged_params):
        if current_idx + 2 > len(tagged_params):
            break

        tag_id = tagged_params[current_idx]
        tag_len = tagged_params[current_idx + 1]

        if current_idx + 2 + tag_len > len(tagged_params):
            print("[!] Malformed Tag length.")
            break

        tag_data = tagged_params[current_idx + 2: current_idx + 2 + tag_len]

        if tag_id == 0:  # SSID Tag
            ssid_str = tag_data.decode('utf-8', errors='replace')
            print(f"\n[SUCCESS] PARSED SSID: '{ssid_str}'")
            print(f"          (Tag Length: {tag_len})")
            found_ssid = True
            break

        current_idx += 2 + tag_len

    if not found_ssid:
        print("\n[FAIL] SSID Tag not found.")


if __name__ == "__main__":
    verify()