# DDR FIFO 读写测试程序说明

## 文件结构

```
DDR_FIFO/
├── src/
│   ├── fifo_ddr.v          # DDR FIFO主模块
│   ├── ddr_fifo_test.v     # FIFO测试模块
│   ├── top_test.v          # 测试顶层文件(用于上板)
│   └── top.v               # 原始顶层文件
├── sim/
│   └── tb_ddr_fifo_test.v  # 仿真测试台
└── README_TEST.md          # 本说明文档
```

## 模块功能

### 1. ddr_fifo_test.v - 测试模块

**功能特性:**
- 自动生成可预测的测试数据
- 支持独立的读写时钟域
- 支持不同的读写数据位宽
- 自动验证读出数据的正确性
- 提供详细的测试状态和错误信息

**测试数据模式:**
- 32位: `addr[31:0]`
- 64位: `{addr[31:0], ~addr[31:0]}`
- 128位: `{addr[31:0], ~addr[31:0], addr+1, ~(addr+1)}`

**参数配置:**
```verilog
parameter WR_DATA_WIDTH = 64,      // 写数据位宽
parameter RD_DATA_WIDTH = 64,      // 读数据位宽
parameter TEST_DATA_COUNT = 1024   // 测试数据量
```

**端口说明:**

| 端口名 | 方向 | 说明 |
|--------|------|------|
| test_start | input | 测试启动信号(高电平启动) |
| test_running | output | 测试运行中标志 |
| test_done | output | 测试完成标志 |
| test_pass | output | 测试通过标志 |
| test_fail | output | 测试失败标志 |
| write_count | output[31:0] | 已写入数据计数 |
| read_count | output[31:0] | 已读出数据计数 |
| error_count | output[31:0] | 错误数据计数 |
| first_error_addr | output[31:0] | 第一个错误地址 |
| first_error_expected | output | 第一个错误的期望值 |
| first_error_actual | output | 第一个错误的实际值 |

**工作流程:**
1. 等待 `ddr_init_done` 信号为高
2. 在 `test_start` 为高时开始测试
3. 写阶段: 向FIFO写入指定数量的测试数据
4. 读阶段: 从FIFO读出数据并验证
5. 测试完成后设置相应的状态标志

### 2. top_test.v - 测试顶层

**功能:**
- 集成DDR3_LARGE_FIFO和测试模块
- 生成读写时钟(可根据需要调整)
- 提供LED指示状态

**LED状态指示:**
- `led_init_done`: DDR初始化完成
- `led_test_running`: 测试运行中
- `led_test_pass`: 测试通过(绿灯)
- `led_test_fail`: 测试失败(红灯)

### 3. tb_ddr_fifo_test.v - 仿真测试台

**功能:**
- 提供仿真环境
- 包含简化的FIFO行为模型
- 自动检查测试结果
- 打印测试日志

## 使用方法

### 方法1: FPGA上板测试

1. **配置参数**

编辑 `top_test.v` 中的参数:
```verilog
localparam WR_DATA_WIDTH = 64;
localparam RD_DATA_WIDTH = 64;
localparam TEST_DATA_COUNT = 2048;  // 根据需要调整
```

2. **时钟配置**

根据实际需求调整读写时钟频率:
```verilog
// 写时钟分频设置
if (clk_div_wr >= 1) begin  // 修改这里的值
    ...
end

// 读时钟分频设置
if (clk_div_rd >= 2) begin  // 修改这里的值
    ...
end
```

3. **综合下载**
- 使用 `top_test.v` 作为顶层文件
- 添加约束文件(时钟、引脚等)
- 综合、布局布线、生成比特流
- 下载到FPGA

4. **运行测试**
- 按下复位按钮
- 按下 `test_start` 按钮启动测试
- 观察LED指示:
  - DDR初始化完成后开始测试
  - 测试运行中 LED闪烁
  - 测试通过 绿灯常亮
  - 测试失败 红灯常亮

### 方法2: 仿真测试

1. **准备仿真环境**

使用 Modelsim/Vivado/Icarus Verilog 等仿真工具

2. **编译文件**
```bash
# Icarus Verilog 示例
iverilog -o sim.out \
    src/ddr_fifo_test.v \
    sim/tb_ddr_fifo_test.v

# 运行仿真
vvp sim.out

# 查看波形
gtkwave tb_ddr_fifo_test.vcd
```

3. **查看结果**

仿真结束后会打印测试结果:
```
========================================
TEST PASSED!
========================================
Write count: 100
Read count:  100
Error count: 0
========================================
```

### 方法3: 集成到现有设计

1. **添加测试模块**

在您的设计中例化测试模块:
```verilog
ddr_fifo_test #(
    .WR_DATA_WIDTH(64),
    .RD_DATA_WIDTH(64),
    .TEST_DATA_COUNT(1024)
) u_test (
    .wr_clk(your_wr_clk),
    .rd_clk(your_rd_clk),
    .rst_n(rst_n),
    .test_start(test_start_signal),
    
    // 连接到FIFO接口
    .wr_en(fifo_wr_en),
    .wr_data(fifo_wr_data),
    // ... 其他信号
    
    // 测试状态
    .test_pass(test_pass_led),
    .test_fail(test_fail_led)
);
```

2. **添加控制逻辑**
- 上电后自动启动测试，或
- 通过按钮手动启动测试，或
- 通过串口/SPI等接口控制测试

## 测试场景

### 场景1: 相同时钟、相同位宽
```verilog
WR_DATA_WIDTH = 64
RD_DATA_WIDTH = 64
wr_clk = rd_clk = 50MHz
```
验证基本的读写功能。

### 场景2: 不同时钟、相同位宽
```verilog
WR_DATA_WIDTH = 64
RD_DATA_WIDTH = 64
wr_clk = 125MHz
rd_clk = 100MHz
```
验证跨时钟域功能。

### 场景3: 相同时钟、不同位宽
```verilog
WR_DATA_WIDTH = 64
RD_DATA_WIDTH = 32
wr_clk = rd_clk = 50MHz
```
验证位宽转换功能。

### 场景4: 不同时钟、不同位宽
```verilog
WR_DATA_WIDTH = 128
RD_DATA_WIDTH = 64
wr_clk = 200MHz
rd_clk = 100MHz
```
验证完整的跨时钟域和位宽转换功能。

## 调试技巧

### 1. 查看错误信息
当测试失败时，检查以下信号:
- `error_count`: 总错误数
- `first_error_addr`: 第一个错误发生的地址
- `first_error_expected`: 期望值
- `first_error_actual`: 实际读出的值

### 2. 使用ChipScope/ILA
在FPGA中插入逻辑分析仪，监控:
- FIFO的读写操作
- 数据计数器
- 错误发生时刻的数据

### 3. 减少测试数据量
如果测试失败，可以先用少量数据测试:
```verilog
localparam TEST_DATA_COUNT = 16;  // 先测试16个数据
```

### 4. 检查时钟关系
确保读写时钟稳定且满足时序要求。

## 常见问题

**Q: 测试一直卡在运行中?**
A: 检查DDR初始化是否完成，FIFO是否正常工作。

**Q: 错误计数很大?**
A: 可能是数据位宽配置不匹配，或时钟不稳定。

**Q: 第一个数据就错误?**
A: 检查复位时序和初始化流程。

**Q: 写操作很快完成但读操作很慢?**
A: 正常现象，读时钟频率较低时会出现这种情况。

## 性能参考

### 测试数据传输速率估算

以64位数据宽度为例:
- 写时钟25MHz: 25M × 64bit = 1.6Gbps = 200MB/s
- 读时钟16.7MHz: 16.7M × 64bit = 1.07Gbps = 133MB/s

实际速率会因FIFO满空控制而略低。

## 版本历史

- v1.0 (2025-11-10): 初始版本
  - 支持独立读写时钟域
  - 支持不同读写数据位宽
  - 自动数据生成和验证
  - 详细的错误报告

## 许可证

与主项目相同。
