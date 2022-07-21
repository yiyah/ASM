#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "tty.h"
#include "console.h"
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

PRIVATE int bCaps_lock;     /* Caps Lock         */
PRIVATE int bNum_lock;      /* Num Lock          */
PRIVATE int bScroll_lock;   /* Scroll Lock       */

PRIVATE u8 get_byte_from_kbuf();
PRIVATE void resetCursor();
PRIVATE void set_leds();

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

    bShift_l = bShift_r = 0;
    bAlt_l   = bAlt_r   = 0;
    bCtrl_l  = bCtrl_r  = 0;

    bCaps_lock   = 0;
    bNum_lock    = 1;
    bScroll_lock = 0;

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
PUBLIC void keyboard_read(TTY* p_tty)
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

            int bCaps = bShift_l || bShift_r;
            if (bCaps_lock) {
                if ((keyrow[0] >= 'a') && (keyrow[0] <= 'z')) {
                    bCaps = !bCaps;
                }
            }
            if (bCaps)
            {
                column = 1;             /* press the SHIFT */
            }
            if (bE0)
            {
                column = 2;
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
            case CAPS_LOCK:
                if (b_make) {
                    bCaps_lock   = !bCaps_lock;
                    set_leds();
                }
                break;
            case NUM_LOCK:
                if (b_make) {
                    bNum_lock    = !bNum_lock;
                    set_leds();
                }
                break;
            case SCROLL_LOCK:
                if (b_make) {
                    bScroll_lock = !bScroll_lock;
                    set_leds();
                }
                break;
            default:
                break;
            }

            if (b_make) /* ignore Break Code */
            {
                int pad = 0;

                /* 首先处理小键盘 */
                if ((key >= PAD_SLASH) && (key <= PAD_9)) {
                    pad = 1;
                    switch(key) {
                    case PAD_SLASH:
                        key = '/';
                        break;
                    case PAD_STAR:
                        key = '*';
                        break;
                    case PAD_MINUS:
                        key = '-';
                        break;
                    case PAD_PLUS:
                        key = '+';
                        break;
                    case PAD_ENTER:
                        key = ENTER;
                        break;
                    default:
                        if (bNum_lock &&
                            (key >= PAD_0) &&
                            (key <= PAD_9)) {
                            key = key - PAD_0 + '0';
                        }
                        else if (bNum_lock &&
                             (key == PAD_DOT)) {
                            key = '.';
                        }
                        else{
                            switch(key) {
                            case PAD_HOME:
                                key = HOME;
                                break;
                            case PAD_END:
                                key = END;
                                break;
                            case PAD_PAGEUP:
                                key = PAGEUP;
                                break;
                            case PAD_PAGEDOWN:
                                key = PAGEDOWN;
                                break;
                            case PAD_INS:
                                key = INSERT;
                                break;
                            case PAD_UP:
                                key = UP;
                                break;
                            case PAD_DOWN:
                                key = DOWN;
                                break;
                            case PAD_LEFT:
                                key = LEFT;
                                break;
                            case PAD_RIGHT:
                                key = RIGHT;
                                break;
                            case PAD_DOT:
                                key = DELETE;
                                break;
                            default:
                                break;
                            }
                        }
                        break;
                    }
                }
                /* only deal when press */
                key |= bShift_l  ? FLAG_SHIFT_L  : 0;
                key |= bShift_r  ? FLAG_SHIFT_R  : 0;
                key |= bCtrl_l   ? FLAG_CTRL_L   : 0;
                key |= bCtrl_r   ? FLAG_CTRL_R   : 0;
                key |= bAlt_l    ? FLAG_ALT_L    : 0;
                key |= bAlt_r    ? FLAG_ALT_R    : 0;
                key |= pad       ? FLAG_PAD      : 0;

                in_process(p_tty, key);
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


/**
  * @brief  等待 8042 的输入缓冲区空
  */
PRIVATE void kb_wait()
{
    u8 kb_stat;

    do {
        kb_stat = in_byte(KB_CMD);
    } while (kb_stat & 0x02);
}


PRIVATE void kb_ack()
{
    u8 kb_read;

    do {
        kb_read = in_byte(KB_DATA);
    } while (kb_read =! KB_ACK);
}


PRIVATE void set_leds()
{
    u8 leds = (bCaps_lock << 2) | (bNum_lock << 1) | bScroll_lock;

    kb_wait();
    out_byte(KB_DATA, LED_CODE);
    kb_ack();

    kb_wait();
    out_byte(KB_DATA, leds);
    kb_ack();
}
