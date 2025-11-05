import random
import sys

def add_random_bit_flips(hex_data, max_flips=6):
    """
    在16进制数据中随机翻转不超过指定数量的比特
    
    Args:
        hex_data: 16进制字符串
        max_flips: 最多翻转的比特数（默认6）
        
    Returns:
        翻转后的16进制字符串
    """
    # 转换16进制为比特字符串
    bit_length = len(hex_data) * 4  # 每个16进制字符对应4比特
    bit_string = bin(int(hex_data, 16))[2:].zfill(bit_length)
    
    # 转换为列表方便修改
    bits = list(bit_string)
    
    # 随机确定翻转的比特数（0到max_flips之间）
    num_flips = random.randint(0, max_flips)
    
    # 随机选择要翻转的比特位置
    if num_flips > 0:
        flip_positions = random.sample(range(bit_length), num_flips)
        
        # 翻转选定位置的比特
        for pos in flip_positions:
            bits[pos] = '0' if bits[pos] == '1' else '1'
    
    # 转换回16进制
    bit_result = ''.join(bits)
    hex_result = hex(int(bit_result, 2))[2:].zfill(len(hex_data))
    
    return hex_result, num_flips


def process_encoded_data(input_file='encodedata.txt', output_file='LRS_data.txt', max_flips=6):
    """
    读取编码数据，添加随机比特翻转，保存到输出文件
    
    Args:
        input_file: 输入编码数据文件
        output_file: 输出文件名
        max_flips: 每行最多翻转的比特数
    """
    try:
        # 读取编码数据
        print(f"从 {input_file} 读取数据...")
        with open(input_file, 'r') as f:
            encoded_lines = f.read().strip().split('\n')
        
        print(f"共读取 {len(encoded_lines)} 行数据")
        
        # 处理每一行数据
        noisy_data = []
        flip_stats = []
        
        for i, hex_data in enumerate(encoded_lines):
            # 去除可能的空格和换行
            hex_data = hex_data.strip()
            
            if len(hex_data) == 0:
                continue
            
            # 添加随机比特翻转
            noisy_hex, num_flips = add_random_bit_flips(hex_data, max_flips)
            
            noisy_data.append(noisy_hex)
            flip_stats.append(num_flips)
            
            print(f"第 {i+1}/{len(encoded_lines)} 行: 翻转了 {num_flips} 个比特")
            if num_flips > 0:
                print(f"  原: {hex_data}")
                print(f"  噪: {noisy_hex}")
        
        # 保存带噪声的数据到文件
        print(f"\n保存带噪声数据到 {output_file}...")
        with open(output_file, 'w') as f:
            for hex_data in noisy_data:
                f.write(hex_data + '\n')
        
        # 统计信息
        print(f"\n完成！数据已保存到 {output_file}")
        print(f"总行数: {len(noisy_data)}")
        print(f"平均翻转比特数: {sum(flip_stats) / len(flip_stats):.2f}")
        print(f"最大翻转比特数: {max(flip_stats)}")
        print(f"最小翻转比特数: {min(flip_stats)}")
        print(f"翻转比特总数: {sum(flip_stats)}")
        
        # 统计有无比特翻转的行数
        no_flip_count = flip_stats.count(0)
        with_flip_count = len(flip_stats) - no_flip_count
        print(f"无比特翻转的行数: {no_flip_count}")
        print(f"有比特翻转的行数: {with_flip_count}")
        
    except FileNotFoundError:
        print(f"错误: 无法找到输入文件 {input_file}")
        sys.exit(1)
    except Exception as e:
        print(f"错误: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    # 设置随机种子（可选，用于可复现性）
    # random.seed(42)
    
    # 处理编码数据，添加随机噪声
    process_encoded_data(
        input_file='encodedata.txt',
        output_file='LRS_data.txt',
        max_flips=6
    )
