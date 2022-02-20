DA_32       EQU     4000H   ; 32 bit seg
DA_C        EQU       98H   ; code seg which can run
DA_DRW      EQU       92H   ; R/W data seg
DA_DRWA     EQU       93H
DA_LDT      EQU       82H   ; LDT
SA_TIL      EQU         4   ; selector of LDT

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
