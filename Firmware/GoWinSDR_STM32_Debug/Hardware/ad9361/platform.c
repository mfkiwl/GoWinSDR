/***************************************************************************//**
 *   @file   Platform.c
 *   @brief  Implementation of Platform Driver.
 *   @author DBogdan (dragos.bogdan@analog.com)
********************************************************************************
 * Copyright 2013(c) Analog Devices, Inc.
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *  - Neither the name of Analog Devices, Inc. nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *  - The use of this software may or may not infringe the patent rights
 *    of one or more patent holders.  This license does not release you
 *    from the requirement that you obtain separate licenses from these
 *    patent holders to use this software.
 *  - Use of the software either in source or binary form, must be run
 *    on or directly connected to an Analog Devices Inc. component.
 *
 * THIS SOFTWARE IS PROVIDED BY ANALOG DEVICES "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, NON-INFRINGEMENT,
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL ANALOG DEVICES BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, INTELLECTUAL PROPERTY RIGHTS, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************/

/******************************************************************************/
/***************************** Include Files **********************************/
/******************************************************************************/
#include <stdint.h>

#include "util.h"
#include "adc_core.h"
#include "dac_core.h"
#include "platform.h"

static inline void usleep(unsigned long usleep)
{
	unsigned long delay = 0;

	for(delay = 0; delay < usleep * 10; delay++);
}



/***************************************************************************//**
 * @brief spi_init
*******************************************************************************/
int32_t spi_init(uint32_t device_id,
				 uint8_t  clk_pha,
				 uint8_t  clk_pol)
{

	UNUSED(device_id);
	UNUSED(clk_pha);
	UNUSED(clk_pol);
	return SUCCESS;
}

/***************************************************************************//**
 * @brief spi_read
*******************************************************************************/
int32_t spi_read(SPI_HandleTypeDef *spi,
				 uint8_t *data,
				 uint8_t bytes_number)
{
	HAL_GPIO_WritePin(SPI2_EN_GPIO_Port, SPI2_EN_Pin, GPIO_PIN_RESET); // CS low
	
	if (HAL_SPI_Receive(spi, data, bytes_number, HAL_MAX_DELAY) != HAL_OK)
	{
		return -1;
	}
	
	// Soft_SPI_ReadBuffer(data, bytes_number); // Use software SPI to read data

	HAL_GPIO_WritePin(SPI2_EN_GPIO_Port, SPI2_EN_Pin, GPIO_PIN_SET); // CS high
	return SUCCESS;
}

/***************************************************************************//**
 * @brief spi_write_then_read
*******************************************************************************/
int spi_write_then_read(SPI_HandleTypeDef *spi,
		const unsigned char *txbuf, unsigned n_tx,
		unsigned char *rxbuf, unsigned n_rx)
{
	HAL_GPIO_WritePin(SPI2_EN_GPIO_Port, SPI2_EN_Pin, GPIO_PIN_RESET); // CS low

	// Send tx data first

	if (n_tx > 0) {
		HAL_StatusTypeDef status = HAL_SPI_Transmit(spi, (uint8_t*)txbuf, n_tx, HAL_MAX_DELAY);
		// Soft_SPI_TransferBuffer((uint8_t*)txbuf, NULL, n_tx); // Use software SPI to send data
		if (status != HAL_OK)
		{
			printf("Error: SPI transmit failed: %d\n", status);
			return -1;
		}
	}

	if (n_rx > 0) {
		// Soft_SPI_ReadBuffer(rxbuf, n_rx); // Use software SPI to read data
		if (HAL_SPI_Receive(spi, rxbuf, n_rx, HAL_MAX_DELAY) != HAL_OK)
		{
			printf("Error: SPI receive failed\n");
			return -1;
		}
	}
	HAL_GPIO_WritePin(SPI2_EN_GPIO_Port, SPI2_EN_Pin, GPIO_PIN_SET); // CS high

	return SUCCESS;
}

// int spi_write_then_read(SPI_HandleTypeDef *spi,
//                                    const unsigned char *txbuf, unsigned n_tx,
//                                    unsigned char *rxbuf, unsigned n_rx)
// {

// 	HAL_StatusTypeDef status;
    
//     // 参数检查
//     if (spi == NULL || (n_tx > 0 && txbuf == NULL) || (n_rx > 0 && rxbuf == NULL)) {
//         return -1;
//     }
    
//     unsigned total_len = n_tx + n_rx;
    
//     // 如果总长度较小，使用栈缓冲区；否则需要动态分配或使用静态缓冲区
//     if (total_len <= 256) {
//         uint8_t tx_buffer[256];
//         uint8_t rx_buffer[256];
        
//         // 准备发送缓冲区
//         if (n_tx > 0) {
//             memcpy(tx_buffer, txbuf, n_tx);
//         }
//         // 填充dummy bytes用于接收阶段
//         if (n_rx > 0) {
//             memset(tx_buffer + n_tx, 0xFF, n_rx);
//         }
        
//         HAL_GPIO_WritePin(SPI2_EN_GPIO_Port, SPI2_EN_Pin, GPIO_PIN_RESET); // CS low
        
//         // 全双工传输
//         status = HAL_SPI_TransmitReceive(spi, tx_buffer, rx_buffer, total_len, HAL_MAX_DELAY);
        
//         HAL_GPIO_WritePin(SPI2_EN_GPIO_Port, SPI2_EN_Pin, GPIO_PIN_SET); // CS high
        
//         if (status != HAL_OK) {
//             return -1;
//         }
        
//         // 复制接收到的数据（跳过发送阶段的数据）
//         if (n_rx > 0) {
//             memcpy(rxbuf, rx_buffer + n_tx, n_rx);
//         }
        
//         return 0;
//     } else {
//         // 数据量大时，使用分步传输方式
        
//     }
	
// }

/***************************************************************************//**
 * @brief gpio_init
*******************************************************************************/
void gpio_init(uint32_t device_id)
{
	UNUSED(device_id);
}

/***************************************************************************//**
 * @brief gpio_direction
*******************************************************************************/
void gpio_direction(uint8_t pin, uint8_t direction)
{
	UNUSED(pin);
	UNUSED(direction);
}

/***************************************************************************//**
 * @brief gpio_is_valid
*******************************************************************************/
bool gpio_is_valid(int number)
{
	if(number >= 0)
		return 1;
	else
		return 0;
}

/***************************************************************************//**
 * @brief gpio_data
*******************************************************************************/
void gpio_data(uint8_t pin, uint8_t data)
{
	GPIO_TypeDef* gpio_port;
	uint16_t gpio_pin;
	
	// Map pin number to GPIO port and pin
	// Assuming pin numbering: 0-15 = GPIOA, 16-31 = GPIOB, etc.
	if (pin < 16) {
		gpio_port = GPIOA;
		gpio_pin = 1 << pin;
	} else if (pin < 32) {
		gpio_port = GPIOB;
		gpio_pin = 1 << (pin - 16);
	} else if (pin < 48) {
		gpio_port = GPIOC;
		gpio_pin = 1 << (pin - 32);
	} else if (pin < 64) {
		gpio_port = GPIOD;
		gpio_pin = 1 << (pin - 48);
	} else {
		return; // Invalid pin
	}
	
	if (data) {
		HAL_GPIO_WritePin(gpio_port, gpio_pin, GPIO_PIN_SET);
	} else {
		HAL_GPIO_WritePin(gpio_port, gpio_pin, GPIO_PIN_RESET);
	}
}

/***************************************************************************//**
 * @brief gpio_set_value
*******************************************************************************/
void gpio_set_value(unsigned gpio, int value)
{
	gpio_data(gpio, value);
}

/***************************************************************************//**
 * @brief udelay
*******************************************************************************/
void udelay(unsigned long usecs)
{
	usleep(usecs);
}

/***************************************************************************//**
 * @brief mdelay
*******************************************************************************/
void mdelay(unsigned long msecs)
{
	HAL_Delay(msecs);
}

/***************************************************************************//**
 * @brief msleep_interruptible
*******************************************************************************/
unsigned long msleep_interruptible(unsigned int msecs)
{
	HAL_Delay(msecs);

	return 0;
}

/***************************************************************************//**
 * @brief axiadc_init
*******************************************************************************/
void axiadc_init(struct ad9361_rf_phy *phy)
{
	adc_init(phy);
	dac_init(phy, DATA_SEL_DDS, 0);
}

/***************************************************************************//**
 * @brief axiadc_post_setup
*******************************************************************************/
int axiadc_post_setup(struct ad9361_rf_phy *phy)
{
	return ad9361_post_setup(phy);
}

/***************************************************************************//**
 * @brief axiadc_read
*******************************************************************************/
unsigned int axiadc_read(struct axiadc_state *st, unsigned long reg)
{
	uint32_t val;

	adc_read(st->phy, reg, &val);

	return val;
}

/***************************************************************************//**
 * @brief axiadc_write
*******************************************************************************/
void axiadc_write(struct axiadc_state *st, unsigned reg, unsigned val)
{
	adc_write(st->phy, reg, val);
}

/***************************************************************************//**
 * @brief axiadc_set_pnsel
*******************************************************************************/
int axiadc_set_pnsel(struct axiadc_state *st, int channel, enum adc_pn_sel sel)
{
	unsigned reg;

	uint32_t version = axiadc_read(st, 0x4000);

	if (PCORE_VERSION_MAJOR(version) > 7) {
		reg = axiadc_read(st, ADI_REG_CHAN_CNTRL_3(channel));
		reg &= ~ADI_ADC_PN_SEL(~0);
		reg |= ADI_ADC_PN_SEL(sel);
		axiadc_write(st, ADI_REG_CHAN_CNTRL_3(channel), reg);
	} else {
		reg = axiadc_read(st, ADI_REG_CHAN_CNTRL(channel));

		if (sel == ADC_PN_CUSTOM) {
			reg |= ADI_PN_SEL;
		} else if (sel == ADC_PN9) {
			reg &= ~ADI_PN23_TYPE;
			reg &= ~ADI_PN_SEL;
		} else {
			reg |= ADI_PN23_TYPE;
			reg &= ~ADI_PN_SEL;
		}

		axiadc_write(st, ADI_REG_CHAN_CNTRL(channel), reg);
	}

	return 0;
}

/***************************************************************************//**
 * @brief axiadc_idelay_set
*******************************************************************************/
void axiadc_idelay_set(struct axiadc_state *st,
				unsigned lane, unsigned val)
{
	if (PCORE_VERSION_MAJOR(st->pcore_version) > 8) {
		axiadc_write(st, ADI_REG_DELAY(lane), val);
	} else {
		axiadc_write(st, ADI_REG_DELAY_CNTRL, 0);
		axiadc_write(st, ADI_REG_DELAY_CNTRL,
				ADI_DELAY_ADDRESS(lane)
				| ADI_DELAY_WDATA(val)
				| ADI_DELAY_SEL);
	}
}
