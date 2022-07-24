#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "tty.h"
#include "console.h"
#include "global.h"
#include "proto.h"


PUBLIC void ctoh(char* str ,char num)
{
    u8* p = str;
    u8 hexHight = (num >> 4) & 0xF;
    u8 hexLow   = num & 0xF;
    
    hexHight += '0';
    hexLow   += '0';
    if(hexHight > '9'){
        // is letter
        hexHight += 7;
    }

    if(hexLow > '9'){
        // is letter
        hexLow += 7;
    }

    *p++ = hexHight;
    *p++ = hexLow;
    *p   = 0;
}

PUBLIC void itoh(char* str ,int num)
{
    u8 i = 0;
    u8 size_num = sizeof(num);
    char* p;

    for (i = 0, p = str;i < size_num;i++)
    {
        ctoh(p, num >> ((size_num-i-1)*8 & 0xFF));
        p += 2;
    }
}


PUBLIC void disp_hex_oneByte(u8 hex)
{
    u8 szHex[3] = {0};
    ctoh(szHex, hex);

    disp_str(szHex);
}

PUBLIC void disp_hex_fourByte(u32 hex)
{
    u8 szHex[9] = {0};
    itoh(szHex, hex);

    disp_str(szHex);
}

PUBLIC void delay(u16 time)
{
    int i, j, k;
    for (k = 0; k < time; k++) {
        for (i = 0; i < 10; i++) {
            for (j = 0; j < 10000; j++) {}
        }
    }
}

PUBLIC void ClearScreen()
{
    int i;
    for (i = 0, disp_pos = 0; i < 2000; i++) {
        disp_str(" ");
    }
    disp_pos = 0;
}
