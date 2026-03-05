/* soft_spi.c */
#include "softspi.h"

static SoftSPI_Mode_t spi_mode = SOFT_SPI_MODE1;

/* 延时函数（根据需要的SPI速度调整） */
static void Soft_SPI_Delay(void)
{
    // 简单延时，可根据需要调整
    // 对于高速MCU可能需要更精确的延时
    volatile uint16_t i = 2;
    while(i--);
}

/**
 * @brief  软件SPI初始化
 * @param  mode: SPI工作模式
 * @retval None
 */
void Soft_SPI_Init(SoftSPI_Mode_t mode)
{
    GPIO_InitTypeDef GPIO_InitStruct = {0};
    
    spi_mode = mode;
    
    /* 使能GPIO时钟 */
    SOFT_SPI_SCK_CLK();
    SOFT_SPI_MISO_CLK();
    SOFT_SPI_MOSI_CLK();
    SOFT_SPI_CS_CLK();
    
    /* 配置SCK引脚 - 推挽输出 */
    GPIO_InitStruct.Pin = SOFT_SPI_SCK_PIN;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(SOFT_SPI_SCK_PORT, &GPIO_InitStruct);
    
    /* 配置MOSI引脚 - 推挽输出 */
    GPIO_InitStruct.Pin = SOFT_SPI_MOSI_PIN;
    HAL_GPIO_Init(SOFT_SPI_MOSI_PORT, &GPIO_InitStruct);
    
    /* 配置MISO引脚 - 输入 */
    GPIO_InitStruct.Pin = SOFT_SPI_MISO_PIN;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(SOFT_SPI_MISO_PORT, &GPIO_InitStruct);
    
    /* 配置CS引脚 - 推挽输出 */
    GPIO_InitStruct.Pin = SOFT_SPI_CS_PIN;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(SOFT_SPI_CS_PORT, &GPIO_InitStruct);
    
    /* 设置初始状态 */
    SOFT_SPI_CS_HIGH();
    
    if(mode == SOFT_SPI_MODE0 || mode == SOFT_SPI_MODE1) {
        SOFT_SPI_SCK_LOW();   // CPOL=0
    } else {
        SOFT_SPI_SCK_HIGH();  // CPOL=1
    }
}

/**
 * @brief  软件SPI传输一个字节（同时发送和接收）
 * @param  data: 要发送的数据
 * @retval 接收到的数据
 */
uint8_t Soft_SPI_TransferByte(uint8_t data)
{
    uint8_t rxData = 0;
    uint8_t i;
    
    for(i = 0; i < 8; i++) {
        /* MODE0和MODE2: 第一个边沿采样 */
        /* MODE1和MODE3: 第二个边沿采样 */
        
        if(spi_mode == SOFT_SPI_MODE0 || spi_mode == SOFT_SPI_MODE2) {
            /* CPHA=0: 第一个时钟边沿采样 */
            
            /* 发送数据位（MSBFirst） */
            if(data & 0x80) {
                SOFT_SPI_MOSI_HIGH();
            } else {
                SOFT_SPI_MOSI_LOW();
            }
            data <<= 1;
            
            Soft_SPI_Delay();
            
            /* 时钟上升沿或下降沿 */
            if(spi_mode == SOFT_SPI_MODE0) {
                SOFT_SPI_SCK_HIGH();  // 上升沿采样
            } else {
                SOFT_SPI_SCK_LOW();   // 下降沿采样
            }
            
            Soft_SPI_Delay();
            
            /* 读取数据位 */
            rxData <<= 1;
            if(SOFT_SPI_MISO_READ()) {
                rxData |= 0x01;
            }
            
            /* 时钟恢复 */
            if(spi_mode == SOFT_SPI_MODE0) {
                SOFT_SPI_SCK_LOW();
            } else {
                SOFT_SPI_SCK_HIGH();
            }
        } else {
            /* CPHA=1: 第二个时钟边沿采样 */
            
            /* 时钟第一个边沿 */
            if(spi_mode == SOFT_SPI_MODE1) {
                SOFT_SPI_SCK_HIGH();
            } else {
                SOFT_SPI_SCK_LOW();
            }
            
            /* 发送数据位 */
            if(data & 0x80) {
                SOFT_SPI_MOSI_HIGH();
            } else {
                SOFT_SPI_MOSI_LOW();
            }
            data <<= 1;
            
            Soft_SPI_Delay();
            
            /* 时钟第二个边沿（采样边沿） */
            if(spi_mode == SOFT_SPI_MODE1) {
                SOFT_SPI_SCK_LOW();
            } else {
                SOFT_SPI_SCK_HIGH();
            }
            
            Soft_SPI_Delay();
            
            /* 读取数据位 */
            rxData <<= 1;
            if(SOFT_SPI_MISO_READ()) {
                rxData |= 0x01;
            }
        }
    }
    
    return rxData;
}

/**
 * @brief  软件SPI传输缓冲区
 * @param  txBuf: 发送缓冲区指针
 * @param  rxBuf: 接收缓冲区指针（可为NULL）
 * @param  len: 传输长度
 * @retval None
 */
void Soft_SPI_TransferBuffer(uint8_t *txBuf, uint8_t *rxBuf, uint16_t len)
{
    uint16_t i;
    uint8_t rxData;
    
    SOFT_SPI_CS_LOW();  // 片选拉低
    
    for(i = 0; i < len; i++) {
        rxData = Soft_SPI_TransferByte(txBuf[i]);
        if(rxBuf != NULL) {
            rxBuf[i] = rxData;
        }
    }
    
    SOFT_SPI_CS_HIGH();  // 片选拉高
}

/**
 * @brief  软件SPI写一个字节
 * @param  data: 要写入的数据
 * @retval None
 */
void Soft_SPI_WriteByte(uint8_t data)
{
    SOFT_SPI_CS_LOW();
    Soft_SPI_TransferByte(data);
    SOFT_SPI_CS_HIGH();
}

/**
 * @brief  软件SPI读一个字节
 * @param  None
 * @retval 读取的数据
 */
uint8_t Soft_SPI_ReadByte(void)
{
    uint8_t data;
    
    SOFT_SPI_CS_LOW();
    data = Soft_SPI_TransferByte(0xFF);  // 发送dummy数据
    SOFT_SPI_CS_HIGH();
    
    return data;
}

void Soft_SPI_ReadBuffer(uint8_t *data, uint16_t len)
{
    uint16_t i;
    
    SOFT_SPI_CS_LOW();  // 片选拉低
    
    for(i = 0; i < len; i++) {
        data[i] = Soft_SPI_TransferByte(0xFF);  // 发送dummy数据并接收
    }
    
    SOFT_SPI_CS_HIGH();  // 片选拉高
}
