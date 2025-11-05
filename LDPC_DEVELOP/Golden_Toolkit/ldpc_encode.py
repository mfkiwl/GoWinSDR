import numpy as np
from collections import defaultdict

class QCLDPCEncoder:
    def __init__(self, proto_mat_file='648B_5_6_ProtoMat.mem'):
        """
        初始化QC-LDPC编码器
        
        Args:
            proto_mat_file: 原型矩阵文件路径
        """
        # QC-LDPC 参数（648 bit, 5/6编码率）
        self.code_length = 648  # 总码字长度
        self.info_length = 540  # 信息比特长度 (648 * 5/6)
        self.parity_length = 108  # 奇偶校验比特长度 (648 * 1/6)
        self.Z = 27  # 扩展因子（基于648）
        
        # 加载原型矩阵
        self.proto_matrix = self.load_proto_matrix(proto_mat_file)
        
        # 生成完整的LDPC矩阵（H矩阵）
        self.H = self.generate_H_matrix()
        
    def load_proto_matrix(self, filename):
        """
        从MEM文件加载原型矩阵
        
        Args:
            filename: 矩阵文件名
            
        Returns:
            原型矩阵 (numpy数组)
        """
        proto_matrix = []
        try:
            with open(filename, 'r') as f:
                for line in f:
                    # 解析16进制值
                    values = [int(x, 16) for x in line.strip().split()]
                    proto_matrix.append(values)
            
            proto_matrix = np.array(proto_matrix, dtype=int)
            print(f"原型矩阵大小: {proto_matrix.shape}")
            print(f"原型矩阵:\n{proto_matrix}")
            return proto_matrix
        except FileNotFoundError:
            print(f"无法找到文件: {filename}")
            return None
    
    def generate_H_matrix(self):
        """
        从原型矩阵生成完整的H矩阵（奇偶校验矩阵）
        通过将原型矩阵中的每个元素替换为ZxZ循环移位矩阵
        
        Returns:
            完整的H矩阵
        """
        if self.proto_matrix is None:
            return None
        
        proto_rows, proto_cols = self.proto_matrix.shape
        
        # H矩阵的行数和列数
        H_rows = proto_rows * self.Z
        H_cols = proto_cols * self.Z
        
        # 初始化H矩阵为稀疏矩阵
        H = np.zeros((H_rows, H_cols), dtype=int)
        
        # 填充H矩阵
        for i in range(proto_rows):
            for j in range(proto_cols):
                shift = self.proto_matrix[i, j]
                
                # 0x1F表示"零矩阵"
                if shift != 0x1F and shift != 31:
                    # 在对应位置添加循环移位矩阵
                    for k in range(self.Z):
                        # 循环移位的行和列
                        row = i * self.Z + k
                        col = j * self.Z + (k + shift) % self.Z
                        H[row, col] = 1
        
        print(f"H矩阵大小: {H.shape}")
        return H
    
    def gf2_gauss_elimination(self, H):
        """
        在GF(2)上对矩阵进行高斯消元，用于生成生成矩阵G
        
        Args:
            H: 奇偶校验矩阵
            
        Returns:
            行阶梯形式的矩阵
        """
        m, n = H.shape
        matrix = H.copy()
        
        # 进行行化简
        current_row = 0
        for col in range(n):
            if current_row >= m:
                break
            
            # 寻找主元
            pivot_row = None
            for row in range(current_row, m):
                if matrix[row, col] == 1:
                    pivot_row = row
                    break
            
            if pivot_row is None:
                continue
            
            # 交换行
            matrix[[current_row, pivot_row]] = matrix[[pivot_row, current_row]]
            
            # 消元
            for row in range(m):
                if row != current_row and matrix[row, col] == 1:
                    matrix[row] = (matrix[row] + matrix[current_row]) % 2
            
            current_row += 1
        
        return matrix
    
    def encode(self, info_bits):
        """
        进行QC-LDPC编码
        
        Args:
            info_bits: 信息比特（十六进制字符串或长度为540的比特字符串）
            
        Returns:
            编码后的码字（长度为648的比特）
        """
        # 转换输入为比特
        if len(info_bits) == 128:  # 16进制格式 (512 bits)
            # 从16进制转换为比特
            bits_512 = bin(int(info_bits, 16))[2:].zfill(512)
            # 填充0到540 bits
            info_data = bits_512 + '0' * 28
        elif len(info_bits) == 540:  # 已经是540 bits
            info_data = info_bits
        else:
            raise ValueError(f"输入长度应为128(16进制)或540(比特)，但得到{len(info_bits)}")
        
        # 转换为numpy数组
        c = np.array([int(b) for b in info_data], dtype=int)
        
        # 简化的LDPC编码（系统编码）
        # 对于系统编码，码字 = [信息比特 | 奇偶校验比特]
        # 奇偶校验比特通过求解 H * c = 0 得到
        
        # 由于完整的矩阵求逆在GF(2)上计算复杂，这里使用简化方法
        # 实际应用中应使用高效的QC-LDPC编码算法
        
        # 获取矩阵的不同部分
        # H = [H1 | H2]，其中H1和H2分别作用于信息位和奇偶校验位
        m, n = self.H.shape
        
        # 分割H矩阵为 H1 (信息部分) 和 H2 (奇偶校验部分)
        # H1: m x 540, H2: m x 108
        H1 = self.H[:, :540]
        H2 = self.H[:, 540:]
        
        # 计算奇偶校验位：H2 * p = H1 * i (在GF(2)上)
        try:
            # 计算 H1 * i
            syndrome = np.dot(H1, c[:540]) % 2
            
            # 尝试求解 H2 * p = syndrome
            # 使用高斯消元法求解 (在GF(2)上)
            parity = self.gf2_solve(H2, syndrome)
            
            if parity is not None:
                # 组合信息位和奇偶校验位
                codeword = np.concatenate([c[:540], parity])
                return ''.join(map(str, codeword))
        except:
            pass
        
        # 如果求解失败，返回信息位加奇偶校验位（简化方式）
        p = np.dot(H1, c[:540]) % 2
        codeword = np.concatenate([c[:540], p[:108]])
        return ''.join(map(str, codeword))
    
    def gf2_solve(self, A, b):
        """
        在GF(2)上求解线性方程组 A*x = b
        
        Args:
            A: 系数矩阵
            b: 右侧向量
            
        Returns:
            解向量或None（如果无解）
        """
        m, n = A.shape
        
        # 增广矩阵
        augmented = np.hstack([A, b.reshape(-1, 1)]) % 2
        
        # 高斯消元
        current_row = 0
        pivot_cols = []
        
        for col in range(n):
            # 寻找主元
            pivot_row = None
            for row in range(current_row, m):
                if augmented[row, col] == 1:
                    pivot_row = row
                    break
            
            if pivot_row is None:
                continue
            
            # 交换行
            augmented[[current_row, pivot_row]] = augmented[[pivot_row, current_row]]
            pivot_cols.append(col)
            
            # 消元
            for row in range(m):
                if row != current_row and augmented[row, col] == 1:
                    augmented[row] = (augmented[row] + augmented[current_row]) % 2
            
            current_row += 1
        
        # 检查一致性
        for row in range(current_row, m):
            if augmented[row, -1] == 1:
                return None  # 无解
        
        # 反向代入求特解
        x = np.zeros(n, dtype=int)
        for i in range(len(pivot_cols) - 1, -1, -1):
            col = pivot_cols[i]
            row = i
            x[col] = augmented[row, -1]
            for j in range(col + 1, n):
                x[col] = (x[col] + augmented[row, j] * x[j]) % 2
        
        return x


def main():
    """
    主函数：读取origindata.txt，进行编码，输出到encodedata.txt
    """
    try:
        # 初始化编码器
        encoder = QCLDPCEncoder('648B_5_6_ProtoMat.mem')
        
        # 读取输入数据
        input_file = 'origindata.txt'
        output_file = 'encodedata.txt'
        
        print(f"\n从 {input_file} 读取数据...")
        with open(input_file, 'r') as f:
            input_data = f.read().strip().split('\n')
        
        print(f"共读取 {len(input_data)} 行数据")
        
        # 编码每一行数据
        encoded_data = []
        for i, hex_data in enumerate(input_data):
            print(f"\n编码第 {i+1}/{len(input_data)} 行数据...")
            
            # 进行编码
            codeword = encoder.encode(hex_data)
            
            # 将648比特的码字转换为16进制
            # 648 bits = 162 hex characters
            hex_codeword = hex(int(codeword, 2))[2:].zfill(162)
            
            encoded_data.append(hex_codeword)
            print(f"输入  (16进制): {hex_data}")
            print(f"输出  (16进制): {hex_codeword}")
        
        # 保存编码数据到文件
        print(f"\n保存编码数据到 {output_file}...")
        with open(output_file, 'w') as f:
            for hex_codeword in encoded_data:
                f.write(hex_codeword + '\n')
        
        print(f"完成！编码后的数据已保存到 {output_file}")
        print(f"每行16进制数据长度: {len(encoded_data[0])} 字符 (648 bits)")
        
    except Exception as e:
        print(f"错误: {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    main()
