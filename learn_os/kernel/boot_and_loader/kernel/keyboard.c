#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "proto.h"
#include "keyboard.h"
#include "keymap.h"

PRIVATE KB_INPUT kb_in;

PRIVATE int bE0 = FALSE;
PRIVATE int bShift_l;       /* left  shift state */
PRIVATE int bShift_r;       /* right shift state */
PRIVATE int bAlt_l;         /* left  alt   state */
PRIVATE int bAlt_r;         /* right left  state */
PRIVATE int bCtrl_l;        /* left ctrl state   */
PRIVATE int bCtrl_r;        /* left ctrl state   */
PRIVATE int bCaps_lock;     /* Caps Lock         */
PRIVATE int bNum_lock;      /* Num Lock          */
PRIVATE int bScroll_lock;   /* Scroll Lock       */
PRIVATE int column;


/**
  * @brief  called by hwint_master
  * @param  irq: it must 1
  * @retval None
  */
PUBLIC void keyboard_handler(u32 irq)
{
    u8 scan_code = in_byte(0x60);

    if (kb_in.count < KB_IN_BYTES) {
        *(kb_in.p_head) = scan_code;
        kb_in.p_head++;

        if (kb_in.p_head == kb_in.buf + KB_IN_BYTES)
        {
            /* discard received byte if buffer is full */
            kb_in.p_head = kb_in.buf;
        }
        kb_in.count++;
    }
}

PUBLIC void init_keyboard()
{
    kb_in.count = 0;
    kb_in.p_tail = kb_in.p_head = kb_in.buf;

    put_irq_handler(KEYBOARD_IRQ, keyboard_handler);
    enable_irq(KEYBOARD_IRQ);
}

/**
  * @brief  called by task_tty()
  *         This function will parse the input of keyboard
  *         and show the input
  * @param  irq: it must 1
  * @retval None
  */
PUBLIC void keyboard_read()
{
    u8 scan_code;
    char output[2] = {0};
    int b_make;         /* TURE: makeCode;  FALSE: breakCode*/
    u32 key = 0;        /* for save the key value */
    u32* keyrow;

    if (kb_in.count > 0) {
        disable_int();
        scan_code = *(kb_in.p_tail);
        kb_in.p_tail++;             /* point to the next byte to read */
        if (kb_in.p_tail == kb_in.buf + KB_IN_BYTES) {
            /* point to head if exceed the buffer size */
            kb_in.p_tail = kb_in.buf;
        }
        kb_in.count--;
        enable_int();

        /* parse scan code */
        if (0xE1 == scan_code) {
            // do nothing now
        }
        else if (0xE0 == scan_code) {
            bE0 = TRUE;
        }
        else {
            /* Determine whether to press or release the keyboard */
            b_make = (scan_code & FLAG_BREAK ? FALSE : TRUE);

            /* first navigate to the row in the keymap */
            keyrow = &keymap[(scan_code&0x7F) * MAP_COLS];
            
            column = 0;                 /* default is the first column */
            if (bShift_l || bShift_r)
            {
                column = 1;             /* press the SHIFT */
            }
            if (bE0)
            {
                column = 2;
                bE0 = FALSE;
            }

            key = keyrow[column];
            switch (key)
            {
                /* note that the b_make had 2 state: press or release.
                   and reset key if not the printable character
                 */
            case SHIFT_L:
                bShift_l = b_make;
                key = 0;
                break;
            case SHIFT_R:
                bShift_r = b_make;
                key = 0;                
                break;
            case CTRL_L:
                bCtrl_l = b_make;
                key = 0;
                break;
            case CTRL_R:
                bCtrl_r = b_make;
                key = 0;
                break;            
            case ALT_L:
                bAlt_l = b_make;
                key = 0;
                break;
            case ALT_R:
                bAlt_r = b_make;
                key = 0;
                break;
            default:
                if (!b_make) {
                    /* reset key if realease the key */
                    key = 0;
                }
                break;
            }

            if (key)
            {
                /* It is a printable character if key != 0 */
                output[0] = key;
                disp_str(output);
            }
        }
    }
}
