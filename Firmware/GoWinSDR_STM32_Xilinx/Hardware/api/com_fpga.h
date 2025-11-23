#ifndef __COM_FPGA_H_
#define __COM_FPGA_H_

#include "stm32f4xx_hal.h"
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "usart.h"

// Òý½Å¶¨Òå
#define DATA_PORT GPIOA
#define REQUEST_PORT GPIOA
#define REQUEST_PIN GPIO_PIN_11
#define VALID_PORT GPIOA
#define VALID_PIN GPIO_PIN_12
#define DATA_CLK_PORT GPIOA
#define DATA_CLK_PIN GPIO_PIN_10

// extern UART_HandleTypeDef huart1;

void DataRecv_Init(void);
uint32_t QueryDataFromFPGA_Polling(void);

#endif
