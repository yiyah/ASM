#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "global.h"
#include "proto.h"
#include "keyboard.h"

PRIVATE u8 nextRow = 0;

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

        disable_int();
        out_byte(CRTC_ADDR_REG, CURSOR_H);
        out_byte(CRTC_DATA_REG, ((disp_pos/2) >> 8) & 0xFF);
        out_byte(CRTC_ADDR_REG, CURSOR_L);
        out_byte(CRTC_DATA_REG, (disp_pos/2) & 0xFF);
        enable_int();
    }
    else {
        int raw_code = key & MASK_RAW;
        switch (raw_code)
        {
        case UP:
            if (nextRow++ > 62) {
                nextRow = 63;   /* the bottom row */
            }
            if ((key & FLAG_SHIFT_L) || (key & FLAG_SHIFT_R)) {
                disable_int();
                out_byte(CRTC_ADDR_REG, START_ADDR_H);
                out_byte(CRTC_DATA_REG, ((80*nextRow) >> 8) & 0xFF);
                out_byte(CRTC_ADDR_REG, START_ADDR_L);
                out_byte(CRTC_DATA_REG, (80*nextRow) & 0xFF);
                enable_int();
            }
            break;
        case DOWN:
            if (nextRow-- == 0) {
                nextRow = 0;    /* the top row */
            }
            if ((key & FLAG_SHIFT_L) || (key & FLAG_SHIFT_R)) {
	        /* Shift+Down, do nothing */
                disable_int();
                out_byte(CRTC_ADDR_REG, START_ADDR_H);
                out_byte(CRTC_DATA_REG, ((80*nextRow) >> 8) & 0xFF);
                out_byte(CRTC_ADDR_REG, START_ADDR_L);
                out_byte(CRTC_DATA_REG, (80*nextRow) & 0xFF);
                enable_int();
            }
            break;
        default:
            break;
        }
    }
}
