#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "tty.h"
#include "console.h"
#include "global.h"
#include "proto.h"


PUBLIC void disp_hex_oneByte(u8 hex)
{
    u8 szHex[3] = {0};
    u8 hexHight = (hex >> 4) & 0xF;
    u8 hexLow   = hex & 0xF;
    
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
    szHex[0] = hexHight;
    szHex[1] = hexLow;
    disp_str(szHex);
}

PUBLIC void disp_hex_fourByte(u32 hex)
{
    u8 szHex[4] = {0};
    szHex[0] = (hex >> 24) & 0xFF;
    szHex[1] = (hex >> 16) & 0xFF;
    szHex[2] = (hex >>  8) & 0xFF;
    szHex[3] = (hex >>  0) & 0xFF;
    disp_hex_oneByte(szHex[0]);
    disp_hex_oneByte(szHex[1]);
    disp_hex_oneByte(szHex[2]);
    disp_hex_oneByte(szHex[3]);
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
