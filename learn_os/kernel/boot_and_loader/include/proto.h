#ifndef __PROTO_H_
#define __PROTO_H_

/* string.asm */
PUBLIC void* memcpy(void* pDst, void* pSrc, int iSize);

/* kliba.asm */
PUBLIC void disp_str(char* pszInfo);
PUBLIC void out_byte(u16 port, u8 value);
PUBLIC u8   in_byte(u16 port);

PUBLIC void init_8259A();

#endif
