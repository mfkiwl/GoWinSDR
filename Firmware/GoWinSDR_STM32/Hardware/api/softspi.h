
/* soft_spi.h */
#ifndef __SOFT_SPI_H
#define __SOFT_SPI_H

#include "stm32f4xx_hal.h" 

/* 软件SPI引脚定义 */
#define SOFT_SPI_SCK_PIN       GPIO_PIN_10
#define SOFT_SPI_SCK_PORT      GPIOB
#define SOFT_SPI_SCK_CLK()     __HAL_RCC_GPIOB_CLK_ENABLE()

#define SOFT_SPI_MISO_PIN      GPIO_PIN_14
#define SOFT_SPI_MISO_PORT     GPIOB
#define SOFT_SPI_MISO_CLK()    __HAL_RCC_GPIOB_CLK_ENABLE()

#define SOFT_SPI_MOSI_PIN      GPIO_PIN_15
#define SOFT_SPI_MOSI_PORT     GPIOB
#define SOFT_SPI_MOSI_CLK()    __HAL_RCC_GPIOB_CLK_ENABLE()

#define SOFT_SPI_CS_PIN        GPIO_PIN_13
#define SOFT_SPI_CS_PORT       GPIOB
#define SOFT_SPI_CS_CLK()      __HAL_RCC_GPIOB_CLK_ENABLE()

/* GPIO操作宏定义 */
#define SOFT_SPI_SCK_HIGH()    HAL_GPIO_WritePin(SOFT_SPI_SCK_PORT, SOFT_SPI_SCK_PIN, GPIO_PIN_SET)
#define SOFT_SPI_SCK_LOW()     HAL_GPIO_WritePin(SOFT_SPI_SCK_PORT, SOFT_SPI_SCK_PIN, GPIO_PIN_RESET)

#define SOFT_SPI_MOSI_HIGH()   HAL_GPIO_WritePin(SOFT_SPI_MOSI_PORT, SOFT_SPI_MOSI_PIN, GPIO_PIN_SET)
#define SOFT_SPI_MOSI_LOW()    HAL_GPIO_WritePin(SOFT_SPI_MOSI_PORT, SOFT_SPI_MOSI_PIN, GPIO_PIN_RESET)

#define SOFT_SPI_MISO_READ()   HAL_GPIO_ReadPin(SOFT_SPI_MISO_PORT, SOFT_SPI_MISO_PIN)

#define SOFT_SPI_CS_HIGH()     HAL_GPIO_WritePin(SOFT_SPI_CS_PORT, SOFT_SPI_CS_PIN, GPIO_PIN_SET)
#define SOFT_SPI_CS_LOW()      HAL_GPIO_WritePin(SOFT_SPI_CS_PORT, SOFT_SPI_CS_PIN, GPIO_PIN_RESET)

/* SPI模式定义 */
typedef enum {
    SOFT_SPI_MODE0 = 0,  // CPOL=0, CPHA=0
    SOFT_SPI_MODE1,      // CPOL=0, CPHA=1
    SOFT_SPI_MODE2,      // CPOL=1, CPHA=0
    SOFT_SPI_MODE3       // CPOL=1, CPHA=1
} SoftSPI_Mode_t;

/* 函数声明 */
void Soft_SPI_Init(SoftSPI_Mode_t mode);
uint8_t Soft_SPI_TransferByte(uint8_t data);
void Soft_SPI_TransferBuffer(uint8_t *txBuf, uint8_t *rxBuf, uint16_t len);
void Soft_SPI_WriteByte(uint8_t data);
uint8_t Soft_SPI_ReadByte(void);
void Soft_SPI_ReadBuffer(uint8_t *data, uint16_t len);

#endif /* __SOFT_SPI_H */