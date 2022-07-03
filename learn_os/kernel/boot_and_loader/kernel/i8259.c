#include "const.h"
#include "type.h"
#include "protect.h"
#include "proto.h"

PUBLIC void init_8259A()
{
    out_byte(I8259A_MASTER_PORT, 0x11);  /* ICW1 */
    out_byte(I8259A_SLAVE_PORT, 0x11);   /* ICW1 */

    out_byte(I8259A_MASTER_PORTMASK, INT_VECTOR_IRQ0);  /* ICW2 */
    out_byte(I8259A_SLAVE_PORTMASK, INT_VECTOR_IRQ8);   /* ICW2 */

    out_byte(I8259A_MASTER_PORTMASK, 0x4);  /* ICW3 */
    out_byte(I8259A_SLAVE_PORTMASK, 0x2);   /* ICW3 */

    out_byte(I8259A_MASTER_PORTMASK, 0x1);  /* ICW4 */
    out_byte(I8259A_SLAVE_PORTMASK, 0x1);   /* ICW4 */

    // 0xFF: mask all interrupt
    // 0xFD: open keyboard interrupt
    // 0xFE: open clock interrupt
    out_byte(I8259A_MASTER_PORTMASK, 0xFE);  /* OCW1 */
    out_byte(I8259A_SLAVE_PORTMASK, 0xFF);   /* OCW1 */

}

/* external interrupt */
PUBLIC void spurious_irq(u32 irq)
{
    disp_str("spurious_irq: ");
    disp_hex_fourByte(irq);
    disp_str("\n");
}
