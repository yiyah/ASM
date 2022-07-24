#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "tty.h"
#include "console.h"
#include "global.h"
#include "proto.h"

int printf(const char* fmt, ...)
{
    u32 len;
    char buf[256];

    va_list arg = (va_list) ((char*) (&fmt) + 4);
    len = vsprintf(buf, fmt, arg);
    write(buf, len);

    return len;
}
