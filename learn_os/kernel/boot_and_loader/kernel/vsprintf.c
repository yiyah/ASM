#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "tty.h"
#include "console.h"
#include "global.h"
#include "proto.h"


/**
  * @brief  integer to array
  * @param  value which integer need to change
  *               do not pass negative value
  * @param  str   save to where
  * @param  radix Which base to convert to
  *               10: decimal
  *               16: hex
  * @retval pointer to str
  */
PUBLIC char* itoa(int value, char **p_str, int radix)
{
    int m = value % radix; // modulo operation
    int q = value / radix; // quotient

    if (q) {
        itoa(q, p_str, radix);
    }
    *(*p_str)++ = (m < 10) ? (m + '0') : (m - 10 + 'A');

    return *p_str;
}


/**
  * @brief  Replace the format controller in fmt with the corresponding parameter args 
  *         save to buf
  * @param  buf  a pointer to the final array
  * @param  fmt  The formatted string
  * @param  args list of parameters
  * @retval 
  */
PUBLIC int vsprintf(char *buf, const char *fmt, va_list args)
{
    char*   p;
    char    tmp[256] = {0};
    int     m;
    va_list p_next_arg = args;

    for (p=buf;*fmt;fmt++) {
        if (*fmt != '%') {
            *p++ = *fmt;
            continue;
        }

        fmt++;

        switch (*fmt) {
        case 'x':
            itoh(tmp, *((int*)p_next_arg));
            strcpy(p, tmp);
            p_next_arg += 4;
            p += strlen(tmp);
            break;
        case 's':
            strcpy(p, *((char**)p_next_arg));
            p += strlen(*((char**)p_next_arg));
            p_next_arg += 4;
            break;
        case 'c':
            *p++ = *((char*)p_next_arg);
            p_next_arg += 4;
            break;
        case 'd':
            m = *((int*)p_next_arg);
            if (m < 0) {
                *p++ = '-';
                m = m * (-1);
            }
            itoa(m, &p, 10);
            p_next_arg += 4;
            break;
        default:
            break;
        }
    }
    return (p - buf);
}


PUBLIC int sprintf(char *buf, const char *fmt, ...)
{
    va_list arg = (va_list)((char*)(&fmt) + 4); /* 4 是参数 fmt 所占堆栈中的大小 */
    return vsprintf(buf, fmt, arg);
}
