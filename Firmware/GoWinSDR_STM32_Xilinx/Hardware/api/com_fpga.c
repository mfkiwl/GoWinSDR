#include "com_fpga.h"

//int myprintf(const char *format, ...)
//{
//    char buffer[128]; 
//    va_list args;
//    va_start(args, format);
//    vsnprintf(buffer, sizeof(buffer), format, args);
//    va_end(args);

//    return HAL_UART_Transmit(&huart1, (uint8_t*)buffer, strlen(buffer), HAL_MAX_DELAY);
//}


typedef struct {
    uint32_t data_24bit;
    uint8_t byte_cnt;
    uint8_t is_ready;
    uint8_t error_flag;
} RecvData_t;

RecvData_t recv_data = {0, 0, 0, 0};
uint8_t clk_last = 0;

/**
 * 读取PA0-PA7的8位数据
 */
uint8_t ReadDataBus(void)
{
    return (uint8_t)(DATA_PORT->IDR & 0xFF);
}

/**
 * 初始化接收模块
 */
void DataRecv_Init(void)
{
    recv_data.data_24bit = 0;
    recv_data.byte_cnt = 0;
    recv_data.is_ready = 0;
    recv_data.error_flag = 0;
    clk_last = 0;
    
    // PB0（请求信号）初始为低电平
    HAL_GPIO_WritePin(REQUEST_PORT, REQUEST_PIN, GPIO_PIN_RESET);
}

/**
 * 请求FPGA发送数据
 */
void DataRecv_Request(void)
{
    // 拉高请求信号
    HAL_GPIO_WritePin(REQUEST_PORT, REQUEST_PIN, GPIO_PIN_SET);
}

/**
 * 接收数据处理函数（定时器中断中调用，建议1ms间隔）
 * 通过检测data_clk的上升沿来同步读取数据
 */
void DataRecv_Process(void)
{
    uint8_t clk_current = HAL_GPIO_ReadPin(DATA_CLK_PORT, DATA_CLK_PIN);
    
    // 检测data_clk的上升沿
    if (clk_current == GPIO_PIN_SET && clk_last == GPIO_PIN_RESET) {
        // 时钟上升沿：读取一个字节
        uint8_t byte_data = ReadDataBus();
        
        if (recv_data.byte_cnt < 3) {
            // 将字节按顺序存储（低字节在前）
            recv_data.data_24bit |= ((uint32_t)byte_data << (recv_data.byte_cnt * 8));
            recv_data.byte_cnt++;
            
            // 接收完成3个字节
            if (recv_data.byte_cnt == 3) {
                recv_data.is_ready = 1;
            }
        } else {
            recv_data.error_flag = 1;  // 超出预期
        }
    }
    
    clk_last = clk_current;
}

/**
 * 获取接收到的24位数据
 */
uint32_t GetRecvData24Bit(void)
{
    return recv_data.data_24bit;
}

/**
 * 检查数据是否已准备好
 */
uint8_t IsDataReady(void)
{
    return recv_data.is_ready;
}

/**
 * 清除接收标志，释放请求信号，准备接收下一组数据
 */
void ClearRecvFlag(void)
{
    recv_data.data_24bit = 0;
    recv_data.byte_cnt = 0;
    recv_data.is_ready = 0;
    
    // 释放请求信号
    HAL_GPIO_WritePin(REQUEST_PORT, REQUEST_PIN, GPIO_PIN_RESET);
}



/**
 * 轻量级查询函数（无定时器中断情况下使用）
 * 主动轮询方式，由data_clk驱动采样
 * 
 * @return 查询到的24位数据
 */
uint32_t QueryDataFromFPGA_Polling(void)
{
    // myprintf("Query\n");
	uint32_t data = 0;
    uint8_t byte_cnt = 0;
    uint8_t clk_last_local = 0;
    
    // 1. 发送请求信号
    HAL_GPIO_WritePin(REQUEST_PORT, REQUEST_PIN, GPIO_PIN_SET);
    
    // 2. 等待FPGA响应并接收数据
    uint32_t timeout = 100000;  // 防止死循环
    
    while (byte_cnt < 3 && timeout--) {
        uint8_t clk_current = HAL_GPIO_ReadPin(DATA_CLK_PORT, DATA_CLK_PIN);
	    uint8_t valid = HAL_GPIO_ReadPin(VALID_PORT, VALID_PIN);
        
        // 检测data_clk的上升沿
        if (clk_current == GPIO_PIN_SET && clk_last_local == GPIO_PIN_RESET && valid) {
            // 在时钟上升沿读取数据
            uint8_t byte_data = ReadDataBus();
            data |= ((uint32_t)byte_data << (byte_cnt * 8));
            byte_cnt++;
        }
        
        clk_last_local = clk_current;
    }
    
    // 3. 释放请求信号
    HAL_GPIO_WritePin(REQUEST_PORT, REQUEST_PIN, GPIO_PIN_RESET);
    
    // 4. 返回结果
    if (byte_cnt == 3) {
        return data;
    } else {
        // printf("FPGA query failed: received %d bytes\r\n", byte_cnt);
        return 0xFFFFFF;  // 错误值
    }
}

