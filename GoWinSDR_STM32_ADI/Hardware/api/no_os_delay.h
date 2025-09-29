#ifndef NO_OS_DELAY_H_
#define NO_OS_DELAY_H_

#include <stdint.h>
#include "main.h"

#define no_os_mdelay(msec)    HAL_Delay(msec)
#endif /* NO_OS_DELAY_H_ */