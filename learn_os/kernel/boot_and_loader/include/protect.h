#ifndef __PROTECT_H_
#define __PROTECT_H_

typedef struct s_descriptor
{
    u16 limit_low;
    u16 base_low;
    u8  base_mid;
    u8  attr1;              /* TYPE(4) S(1) DPL(2) P(1) */
    u8  limit_high_attr2;   /* LIMIT(4) AVL(1) 0(1) D/B(1) G(1) */
    u8  base_high;
}DESCRIPTOR;

/* interrupt vector */
#define INT_VECTOR_IRQ0 0x20
#define INT_VECTOR_IRQ8 0x28

#endif /* __PROTECT_H_ */
