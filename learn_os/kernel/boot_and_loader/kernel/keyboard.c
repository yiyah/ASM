#include "type.h"
#include "const.h"
#include "proto.h"
#include "keyboard.h"

PRIVATE KB_INPUT kb_in;

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
