import numpy as np
import sys

class QCLDPCDecoder:
    def __init__(self, proto_mat_file='648B_5_6_ProtoMat.mem'):
        """
        初始化QC-LDPC解码器
        
        Args:
            proto_mat_file: 原型矩阵文件路径
        """
        # QC-LDPC 参数（648 bit, 5/6编码率）
        self.code_length = 648  # 总码字长度
        self.info_length = 540  # 信息比特长度 (648 * 5/6)
        self.parity_length = 108  # 奇偶校验比特长度 (648 * 1/6)
        self.Z = 27  # 扩展因子（基于648）
        self.max_iterations = 6  # 最大迭代次数
        
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
    
    def bp_decode(self, received_bits, max_iterations=None):
        """
        基于信念传播(BP)的LDPC解码算法
        
        Args:
            received_bits: 接收的比特（长度为648的比特字符串或numpy数组）
            max_iterations: 最大迭代次数
            
        Returns:
            解码后的比特（长度为648）和迭代次数
        """
        if max_iterations is None:
            max_iterations = self.max_iterations
        
        # 转换输入为numpy数组
        if isinstance(received_bits, str):
            received = np.array([int(b) for b in received_bits], dtype=float)
        else:
            received = np.array(received_bits, dtype=float)
        
        m, n = self.H.shape  # m: 校验方程数, n: 码字长度
        
        # 初始化消息
        # LLR (Log Likelihood Ratio) 初值：根据接收比特初始化
        # 假设接收到的是硬判决：0->+inf, 1->-inf
        llr = np.zeros(n)
        for i in range(n):
            if received[i] == 0:
                llr[i] = 10.0  # 强烈倾向于0
            else:
                llr[i] = -10.0  # 强烈倾向于1
        
        # 变量节点到校验节点的消息 (初始化为LLR值)
        v2c = llr.copy()  # Variable to Check
        
        # 迭代解码
        for iteration in range(max_iterations):
            # ============ 校验节点更新 ============
            # 计算校验节点到变量节点的消息
            c2v = np.zeros((m, n))  # Check to Variable
            
            for i in range(m):
                for j in range(n):
                    if self.H[i, j] == 1:
                        # 对于校验方程i中的变量j，计算消息
                        # 包括所有其他变量的v2c消息
                        product = 1.0
                        sum_val = 0.0
                        
                        for k in range(n):
                            if k != j and self.H[i, k] == 1:
                                product *= np.tanh(v2c[k] / 2.0)
                                sum_val += v2c[k]
                        
                        # 使用双曲正切函数计算
                        if abs(product) < 1e-10:
                            product = 1e-10
                        
                        c2v[i, j] = 2.0 * np.arctanh(product)
            
            # ============ 变量节点更新 ============
            # 更新变量节点的后验概率
            v2c_new = llr.copy()
            
            for j in range(n):
                for i in range(m):
                    if self.H[i, j] == 1:
                        v2c_new[j] += c2v[i, j]
            
            v2c = v2c_new
            
            # ============ 硬判决 ============
            decoded_bits = (v2c < 0).astype(int)
            
            # ============ 校验解码结果 ============
            # 检查是否满足所有校验方程：H * c = 0 (mod 2)
            parity_check = np.dot(self.H, decoded_bits) % 2
            
            if np.all(parity_check == 0):
                # 成功解码
                print(f"  解码成功！在第 {iteration + 1} 次迭代后收敛")
                return decoded_bits, iteration + 1
        
        # 最大迭代次数后仍未收敛，返回最后的硬判决结果
        decoded_bits = (v2c < 0).astype(int)
        print(f"  未在{max_iterations}次迭代内收敛，返回最后结果")
        return decoded_bits, max_iterations
    
    def decode(self, received_hex, max_iterations=None):
        """
        进行QC-LDPC解码
        
        Args:
            received_hex: 接收的16进制码字（162个字符）
            max_iterations: 最大迭代次数
            
        Returns:
            解码后的540比特信息位（16进制字符串）
        """
        if max_iterations is None:
            max_iterations = self.max_iterations
        
        # 转换16进制为比特
        bit_length = len(received_hex) * 4  # 每个16进制字符对应4比特
        bits_str = bin(int(received_hex, 16))[2:].zfill(bit_length)
        
        # 进行BP解码，得到完整的648比特码字
        decoded_bits, iterations = self.bp_decode(bits_str, max_iterations)
        
        # 返回完整的648比特码字作为1D数组，不需要返回info_bits
        return decoded_bits, iterations


def main():
    """
    主函数：读取LRS_data.txt，进行解码，输出到decodeout.txt
    """
    try:
        # 初始化解码器
        decoder = QCLDPCDecoder('648B_5_6_ProtoMat.mem')
        
        # 读取接收数据
        input_file = 'LRS_data.txt'
        output_file = 'decode_out.txt'
        
        print(f"\n从 {input_file} 读取数据...")
        with open(input_file, 'r') as f:
            received_data = f.read().strip().split('\n')
        
        print(f"共读取 {len(received_data)} 行数据")
        
        # 解码每一行数据
        decoded_data = []
        success_count = 0
        
        for i, hex_data in enumerate(received_data):
            hex_data = hex_data.strip()
            if len(hex_data) == 0:
                continue
            
            print(f"\n解码第 {i+1}/{len(received_data)} 行数据...")
            
            try:
                # 进行解码，得到完整的648比特码字
                decoded_bits, iterations = decoder.decode(hex_data, max_iterations=6)
                
                # 校验解码结果
                parity_check = np.dot(decoder.H, decoded_bits) % 2
                is_valid = np.all(parity_check == 0)
                
                if is_valid:
                    success_count += 1
                    print(f"  ✓ 校验通过")
                else:
                    print(f"  ✗ 校验未通过")
                
                # 从540比特中取最高的512比特
                # 540 bits -> 取前512 bits (最高位)
                bits_540 = decoded_bits[:540]
                bits_512 = bits_540[:512]
                
                # 转换为16进制
                hex_result = hex(int(''.join(map(str, bits_512)), 2))[2:].zfill(128)
                
                decoded_data.append(hex_result)
                
                print(f"  输入码字 (16进制): {hex_data[:40]}...")
                print(f"  输出信息 (16进制): {hex_result}")
                    
            except Exception as e:
                print(f"  错误: {e}")
                import traceback
                traceback.print_exc()
        
        # 保存解码数据到文件
        print(f"\n保存解码数据到 {output_file}...")
        with open(output_file, 'w') as f:
            for hex_data in decoded_data:
                f.write(hex_data + '\n')
        
        print(f"\n完成！")
        print(f"总处理行数: {len(decoded_data)}")
        print(f"成功解码行数: {success_count}/{len(decoded_data)}")
        print(f"每行16进制数据长度: 128 字符 (512 bits)")
        print(f"解码数据已保存到 {output_file}")
        
    except Exception as e:
        print(f"错误: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
