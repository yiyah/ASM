org     0x7C00

jmp short LABEL_BOOT
nop
	; head of FAT12
	BS_OEMName	    DB 'HZHLotd.'	; OEM String, 必须 8 个字节
	BPB_BytsPerSec	DW 512		    ; 每扇区字节数
	BPB_SecPerClus	DB 1		    ; 每簇多少扇区
	BPB_RsvdSecCnt	DW 1		    ; Boot 记录占用多少扇区
	BPB_NumFATs	    DB 2		    ; 共有多少 FAT 表
	BPB_RootEntCnt	DW 224		    ; 根目录文件数最大值
	BPB_TotSec16	DW 2880		    ; 逻辑扇区总数
	BPB_Media	    DB 0xF0		    ; 媒体描述符
	BPB_FATSz16	    DW 9		    ; 每FAT扇区数
	BPB_SecPerTrk	DW 18		    ; 每磁道扇区数
	BPB_NumHeads	DW 2		    ; 磁头数(面数)
	BPB_HiddSec	    DD 0		    ; 隐藏扇区数
	BPB_TotSec32	DD 0		    ; wTotalSectorCount为0时这个值记录扇区数
	BS_DrvNum	    DB 0		    ; 中断 13 的驱动器号
	BS_Reserved1	DB 0		    ; 未使用
	BS_BootSig	    DB 29h		    ; 扩展引导标记 (29h)
	BS_VolID	    DD 0		    ; 卷序列号
	BS_VolLab	    DB 'OrangeS0_02'; 卷标, 必须 11 个字节
	BS_FileSysType	DB 'FAT12   '	; 文件系统类型, 必须 8个字节  

Bootmessage:    db 'Hello world!',0

LABEL_BOOT:
    mov     ax,cs
    mov     ds,ax
    mov     si,Bootmessage
    xor     di,di
    call    Disp_Str
    jmp     $               ; stop here when display is finish

; Call this function when di, ds:[si] is ready
; The string must end of 0x00
Disp_Str:
    push    es
    push    ax
    push    cx
    mov     ax,0xB800
    mov     es,ax           ; set the data destination
    xor     cx,cx           ; reset cx for loop
DispStr:
    xor     cx,cx
    mov     cl,[ds:si]
    jcxz    Disp_ret        ; finish display when the data is 0x00
    mov     ch,0x02         ; set color
    mov     [es:di],cx
    inc     si              ; the next index of what to show
    add     di,2            ; the next index of where to show
    jmp     DispStr
Disp_ret:
    pop     cx
    pop     ax
    pop     es
    ret

times   510-($-$$) db 0
dw      0xAA55
