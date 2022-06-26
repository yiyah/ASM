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

    out_byte(I8259A_MASTER_PORT, 0xFF);  /* OCW1 */
    out_byte(I8259A_SLAVE_PORT, 0xFF);   /* OCW1 */

}
