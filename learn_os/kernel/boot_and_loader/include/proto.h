#ifndef __PROTO_H_
#define __PROTO_H_

/* string.asm */
PUBLIC void* memcpy(void* pDst, void* pSrc, int iSize);

/* kliba.asm */
PUBLIC void disp_str(char* pszInfo);
PUBLIC void disp_color_str(char* pszInfo, u8 color);
PUBLIC void out_byte(u16 port, u8 value);
PUBLIC u8   in_byte(u16 port);

PUBLIC void init_prot();
PUBLIC void init_8259A();
PUBLIC void disp_hex_oneByte(u8 hex);
PUBLIC void disp_hex_fourByte(u32 hex);

#endif
