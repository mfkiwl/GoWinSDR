# GoWinSDR

## 工程简介

**本项目基于高云 GW5AT-LV60 FPGA与ADI AD9363/AD9361射频收发器，构建了一套灵活可重构的软件无线电（SDR）系统。通过软硬件协同设计，将高速基带处理部署于FPGA，将交互业务部署于Python上位机，通过千兆以太网交互，实现了QPSK等多种实时通信与动态参数配置**

系统可通过千兆以太网或 USB2.0 (开发中)接口连接 PC 端，配套开发的图形用户界面（GUI上位机）能够直观展示通信参数、数据传输状态等信息，支持用户实时配置系统参数、监控传输过程，大幅提升了人机交互体验。经实际测试，该 SDR 无线通信系统可实现两台设备间的真实无线通信，数据传输速率高达 4Mbps

本工程所使用的FPGA只有PL端，因此将AD936X射频芯片的初始化部分代码移植至STM32平台，经测试运行稳定，使用较为方便。除初始化外的所有逻辑均在FPGA上用Verilog实现

相比Xilinx ZYNQ平台上众多的软件无线电开源项目，本项目没有使用异构FPGA，核心逻辑均使用Verilog实现，数据传输路径更加清晰，操作逻辑更加直观和接近底层，便于无线电爱好者/通信工程师/学生等人群更深入的了解软件无线电基本原理，或作为基本平台进行编码等内容的二次开发

![](./Image/front.jpg)



## 工程结构

GoWinSDR/
├── FPGA/
│   ├── SDR_Final_CMOS/ # 完整版FPGA项目，基于SDR Base底板，实现所有功能
│   ├── SDR_TANG_CMOS/ # AD9363测试项目，基于AD9363_Debug测试板和Sipeed Tang Mega开发板，只能收发单音信号
│   └── Submodule/ # 用于存放测试时使用的子模块，非开发人员请勿使用
├── Firmware/
│   └── GoWinSDR_STM32/ # 初始化AD9363的STM32代码，移植自Xilinx，使用HAL库开发
├── Hardware/
│   ├── Gerber/ # PCB制版文件
│   ├── ProPrj_AD9363_Debug/ # 嘉立创EDA工程，AD9363功能测试板
│   └── ProPrj_GoWinSDR_SMT/ # 嘉立创EDA工程，项目完整PCB
├── Image/  # 存放文档图片
├── Matlab/  # 用于生成滤波器系数
├── Software/ # 基于PyQt的上位机
└── README.MD



## 系统框图

![](./Image/github.png)



## 快速使用

1. **打样工程ProPrj_GoWinSDR_SMT并焊接，测试各部分电源正常**
2. **打开工程GoWinSDR_STM32，通过板载SWD烧录STM32程序**
3. **打开工程SDR_Final_CMOS，将程序下载/固化到FPGA**
4. **使用Pycharm或其他软件运行上位机，检测参数能否配置，能否收发信号**
5. **若发现某一部分工作异常，可以通过串口和高云FPGA内置逻辑分析仪分析错误**



## 核心代码功能介绍

**核心代码位于目录\FPGA\SDR_Final_CMOS\src下**

### 顶层模块

#### `top.v`

> 顶层模块，负责连接各子模块

---

### AD936X 接口

#### `ad9363_dev_cmos.v`

> 

---

### 以太网

#### `eth_transceiver.v`

> 

#### `eth_frame_gene.v`

> 

#### `eth_pack.v`

> 

#### `arp_responder.v`

> 

---

### 调制解调

#### `qpsk_demod.v`

> 

#### `costas.v`

> 

#### `costas_flt_new.v`

> 

#### `costas_loop_filter.v`

> 

#### `phase_detector.v`

> 

#### `gardner_sync.v`

> 

#### `gardner_ted.v`

> 

---

### 射频收发

#### `rf_rxt.v`

> 

#### `rf_diff_encode.v`

> 

#### `rf_diff_decode.v`

> 

---

### 信号处理

#### `nco.v`

> 

#### `interpolate_filter.v`

> 

#### `calibration.v`

> 

---

### 其他

#### `com_fpga.v`

> 

#### `crc.v`

> 

#### `led_control.v`

> 

---

### 约束文件

#### `SDR_Test.cst`

> 管脚约束文件

#### `timeconstrain.sdc`

> 时序约束文件

#### `SDR_Test.rao`

> 布局布线结果文件



## 上位机功能介绍



## 测试结果



## 成品展示



## 注意事项

