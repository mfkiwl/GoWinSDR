import os
import secrets

def generate_random_hex_data(num_lines=20, bit_length=512):
    """
    生成指定数量的随机16进制数据
    
    Args:
        num_lines: 生成的行数（默认20行）
        bit_length: 每条数据的比特数（默认512bit）
    
    Returns:
        生成的16进制数据列表
    """
    hex_data = []
    
    # 512 bit = 128 hex characters (512 / 4 = 128)
    hex_length = bit_length // 4
    
    for _ in range(num_lines):
        # 生成指定比特数的随机数据
        random_bytes = secrets.token_bytes(bit_length // 8)
        # 转换为16进制字符串
        hex_string = random_bytes.hex()
        hex_data.append(hex_string)
    
    return hex_data

def save_to_file(hex_data, output_file='origindata.txt'):
    """
    将16进制数据保存到文件
    
    Args:
        hex_data: 16进制数据列表
        output_file: 输出文件名
    """
    with open(output_file, 'w') as f:
        for data in hex_data:
            f.write(data + '\n')
    
    print(f"已生成 {len(hex_data)} 条512bit的16进制数据")
    print(f"数据已保存到 {output_file}")

if __name__ == '__main__':
    # 生成20条512bit的16进制数据
    hex_data = generate_random_hex_data(num_lines=20, bit_length=512)
    
    # 保存到文件
    save_to_file(hex_data, 'origindata.txt')
