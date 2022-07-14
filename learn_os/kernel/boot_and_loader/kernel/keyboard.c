#include "type.h"
#include "const.h"
#include "proto.h"

PUBLIC void keyboard_handler(u32 irq)
{
    disp_str("*");
    in_byte(0x60);
}

PUBLIC void init_keyboard()
{
    put_irq_handler(KEYBOARD_IRQ, keyboard_handler);
    enable_irq(KEYBOARD_IRQ);
}
