DA_32       EQU     4000H   ; 32 bit seg
DA_C        EQU       98H   ; code seg which can run
DA_CR       EQU       9AH   ; code seg which can run and read
DA_DRW      EQU       92H   ; R/W data seg
DA_DRWA     EQU       93H
DA_LDT      EQU       82H   ; LDT
DA_LIMIT_4K EQU     8000H

DA_DPL0     EQU       00H
DA_DPL1     EQU       20H
DA_DPL2     EQU       40H
DA_DPL3     EQU       60H

DA_CGATE    EQU       8CH
DA_TSS      EQU       89H

SA_TIL      EQU         4   ; selector of LDT
SA_RPL0     EQU         0
SA_RPL1     EQU         1
SA_RPL2     EQU         2
SA_RPL3     EQU         3

PG_P        EQU         1
PG_USU      EQU         4
PG_RWW      EQU         2

; usage: Descriptor Base, Limit, Attr
;        Base:  dd
;        Limit: dd (low 20 bits available)
;        Attr:  dw (low 4 bits of high bytes are always 0)
%macro Descriptor 3
dw      %2 & 0xFFFF
dw      %1 & 0xFFFF
db      (%1 >> 16) & 0xFF
dw      ((%2 >> 8) & 0xF00) | (%3 & 0xF0FF)
db      (%1 >> 24) & 0xFF
%endmacro   ; total 8 bytes

; usage: Gate Selector, Offset, Paramcount, Attr
;       Selector:   dw
;       Offset:     dd
;       Paramcount: db
;       Attr:       db
%macro Gate 4
dw      (%2 & 0xFFFF)
dw      %1 & 0xFFFF
dw      (%3 & 0x1F) | ((%4 << 8) & 0xFF00)
dw      ((%2 >> 16) & 0xFFFF)
%endmacro   ; total 8 bytes
