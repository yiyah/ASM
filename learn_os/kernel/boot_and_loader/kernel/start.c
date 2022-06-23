#include "const.h"
#include "type.h"
#include "protect.h"

PUBLIC void* memcpy(void* pDst, void* pSrc, int iSize);
PUBLIC void disp_str(char* pszInfo);

PUBLIC u8 gdt_ptr[6];
PUBLIC DESCRIPTOR gdt[DESC_NUM];

PUBLIC void cstart()
{
    disp_str("kernel start\nhello world\nyiya");
    memcpy(gdt,                             /* new GDT */
        (void*)(*((u32*)(&gdt_ptr[2]))),    /* base of old GDT */
        *((u16*)(&gdt_ptr[0])) + 1          /* limit of old GDT */
    );

    *((u16*)(&gdt_ptr[0])) = DESC_NUM * sizeof(DESCRIPTOR) - 1;
    *((u32*)(&gdt_ptr[2])) = (u32)gdt;
}
