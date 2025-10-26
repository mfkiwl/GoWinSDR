#include "no_os_api.h"

uint16_t no_os_do_div(uint32_t *n, uint32_t d){
    uint16_t r = *n % d;
    *n = *n / d;
    return r;
}