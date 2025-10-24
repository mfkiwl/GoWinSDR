#include "api.h"

char *strsep(char **stringp, const char *delim) {
    char *start = *stringp;
    char *p;
    
    if (start == NULL)
        return NULL;
        
    p = strpbrk(start, delim);
    if (p) {
        *p = '\0';
        *stringp = p + 1;
    } else {
        *stringp = NULL;
    }
    
    return start;
}