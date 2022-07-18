#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "global.h"
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

PRIVATE u8 get_byte_from_kbuf();
PRIVATE void resetCursor();


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

    resetCursor();
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
    int b_make;         /* TURE: makeCode;  FALSE: breakCode */
    u32 key = 0;        /* for save the key value: Hight 8B is flag */
    u32* keyrow;

    if (kb_in.count > 0) {
        bE0 = FALSE;

        scan_code = get_byte_from_kbuf();

        /* parse scan code */
        if (0xE1 == scan_code) {
            /* deal PAUSE key */
            u8 i;
            u8 pausebrk_scode[] = {0xE1, 0x1D, 0x45,
                                   0xE1, 0x9D, 0xC5};
            int bPausebreak = TRUE;
            for(i = 1;i < 6;i++){
                if (get_byte_from_kbuf() != pausebrk_scode[i]) {
                    bPausebreak = FALSE;
                    break;
                }
            }
            if (bPausebreak) {
                key = PAUSEBREAK;
            }
        }
        else if (0xE0 == scan_code) {
            /* deal PrintScreen key */
            scan_code = get_byte_from_kbuf();

            /* press PrintScreen */
            if (0x2A == scan_code) {
                if (0xE0 == get_byte_from_kbuf()) {
                    if (0x37 == get_byte_from_kbuf()) {
                        key = PRINTSCREEN;
                        b_make = TRUE;
                    }
                }
            }
            /* release PrintScreen */
            if (0xB7 == scan_code) {
                if (0xE0 == get_byte_from_kbuf()) {
                    if (0xAA == get_byte_from_kbuf()) {
                        key = PRINTSCREEN;
                        b_make = FALSE;
                    }
                }
            }
            /* 不是PrintScreen, 此时 scan_code 为 0xE0 紧跟的那个值. */
            if (0 == key) {
                bE0 = TRUE;
            }
        }
        if ((key != PAUSEBREAK) && (key != PRINTSCREEN)) {
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
                break;
            case SHIFT_R:
                bShift_r = b_make;
                break;
            case CTRL_L:
                bCtrl_l = b_make;
                break;
            case CTRL_R:
                bCtrl_r = b_make;
                break;            
            case ALT_L:
                bAlt_l = b_make;
                break;
            case ALT_R:
                bAlt_r = b_make;
                break;
            default:
                break;
            }

            if (b_make)
            {
                /* only deal when press */
                /* reset key if press SHIFT, CTRL and ALT */
                key |= bShift_l  ? FLAG_SHIFT_L  : 0;
                key |= bShift_r  ? FLAG_SHIFT_R  : 0;
                key |= bCtrl_l   ? FLAG_CTRL_L   : 0;
                key |= bCtrl_r   ? FLAG_CTRL_R   : 0;
                key |= bAlt_l    ? FLAG_ALT_L    : 0;
                key |= bAlt_r    ? FLAG_ALT_R    : 0;

                in_process(key);
            }
        }
    }
}


/**
  * @brief  read next byte from kb_in.buf
  * @retval scan_code
  */
PRIVATE u8 get_byte_from_kbuf()
{
    u8 scan_code;

    while (kb_in.count <= 0) {}   /* 等待下一个字节到来 */

    disable_int();
    scan_code = *(kb_in.p_tail);
    kb_in.p_tail++;
    if (kb_in.p_tail == kb_in.buf + KB_IN_BYTES) {
            kb_in.p_tail = kb_in.buf;
    }
    kb_in.count--;
    enable_int();

    return scan_code;
}

PRIVATE void resetCursor()
{
    out_byte(CRTC_ADDR_REG, CURSOR_H);
    out_byte(CRTC_DATA_REG, ((disp_pos/2)>>8)&0xFF);
    out_byte(CRTC_ADDR_REG, CURSOR_L);
    out_byte(CRTC_DATA_REG, (disp_pos/2)&0xFF);
}
