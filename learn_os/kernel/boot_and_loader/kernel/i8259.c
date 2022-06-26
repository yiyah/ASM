#include "const.h"
#include "type.h"
#include "protect.h"
#include "proto.h"

PUBLIC void init_8259A()
{
    out_byte(I8259A_MASTER_PORT, 0x11);  /* ICW1 */
    out_byte(I8259A_SLAVE_PORT, 0x11);   /* ICW1 */

    out_byte(I8259A_MASTER_PORT, INT_VECTOR_IRQ0);  /* ICW2 */
    out_byte(I8259A_SLAVE_PORT, INT_VECTOR_IRQ8);   /* ICW2 */

    out_byte(I8259A_MASTER_PORT, 0x4);  /* ICW3 */
    out_byte(I8259A_SLAVE_PORT, 0x2);   /* ICW3 */

    out_byte(I8259A_MASTER_PORT, 0x1);  /* ICW4 */
    out_byte(I8259A_SLAVE_PORT, 0x1);   /* ICW4 */

    // 0xFF: mask all interrupt
    // 0xFD: open keyboard interrupt
    out_byte(I8259A_MASTER_PORT, 0xFD);  /* OCW1 */
    out_byte(I8259A_SLAVE_PORT, 0xFF);   /* OCW1 */

}

/* external interrupt */
PUBLIC void spurious_irq(u32 irq)
{
    disp_str("spurious_irq: ");
    disp_hex_fourByte(irq);
    disp_str("\n");
}
