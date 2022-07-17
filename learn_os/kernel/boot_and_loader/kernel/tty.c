#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "proto.h"
#include "keyboard.h"

PUBLIC void task_tty()
{
    while (1) {
        keyboard_read();
    }
}

PUBLIC void in_process(u32 key)
{
    char output[2] = {0};

    if (!(key & FLAG_EXT)) {
        /* FLAG_EXT  used to distinguish whether a character is printable */
        output[0] = key & 0xFF;
        disp_str(output);
    }
}
