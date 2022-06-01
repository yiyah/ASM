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

Bootmessage:        db      'H', 0
FoundLoaderMsg:     db      'Fo l!', 0
NoLoaderMsg:        db      'NO l', 0
IndexOfRootDir:     db      19
LoaderName:         db      'A.TXT',0   ; length <= 8 (not include ".bin")
LENOFLOADERNAME     equ     ($ - LoaderName - 1)
BASEOFSTACK         equ     0x7C00
BASEOFLOADER        equ     0x9000
OFFSETLOADER        equ     0x0

LABEL_BOOT:
    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    mov     ss, ax

    mov     sp, BASEOFSTACK
    mov     si,Bootmessage
    xor     di,di
    ;call    ClearScreen
    call    DispStr

    mov     ax, 0
    push    ax
    call    ResetDisk
    add     sp, 2

    call    FindLoader
    jmp     $               ; stop here when display is finish

; ===================================
; @Function: ResetDisk(dw driveLetter)
; @Brief: reset disk
; @param: [IN] driveLetter: only use low 8 bit
; @stack: bp, ip, driveLetter
; ===================================
ResetDisk:
    push    bp
    mov     bp, sp
    push    ax
    push    dx

    mov     ah, 0
    mov     dl, [bp+4]
    int     13H

    pop     dx
    pop     ax
    mov     sp, bp
    pop     bp
    ret

; ===================================
; @Function: FindLoader()
; @Brief: Find loader in floppy A
; ===================================
FindLoader:
    push    bp
    mov     bp, sp
    sub     sp, 1       ; [bp+1] local variable: save number of root directory sector
    sub     sp, 1       ; [bp+2] local variable: save next index of sector which to read
    push    es
    push    ax
    push    bx
    push    cx
    push    si
    push    di

    mov     al, [IndexOfRootDir]
    mov     [bp+2], al
    ; step1: calculate the sector number of root directory
    mov     ax, [BPB_RootEntCnt]
    mov     bl, 16      ; One Dir Entry is 32 Bytes
    div     bl          ; 32/512=1/16
    mov     [bp+1], al
    mov     cx, [bp+1]

_NEXTSECTOR:
    push    cx                  ; for   "loop    _NEXTSECTOR"
    ; step2: read sector
    mov     ax, BASEOFLOADER
    mov     es, ax
    mov     bx, OFFSETLOADER    ; es:bx: data go where
    mov     ax, 1
    push    ax
    mov     al, [bp+2]
    push    ax
    call    ReadSector
    add     sp, 4               ; clean formal parameter
    inc     byte [bp+2]

    ; step3: match loaderName
    mov     cx, 16              ; one sector have 512/32=16 files
_CHECKDIRENTRY:
    push    cx                  ;for    "loop    _CHECKDIRENTRY"
    mov     cx, LENOFLOADERNAME - 4     ; only use name's length
    xor     di, di
_CHECKFILENAME:
    mov     al, [es:bx+di]
    cmp     al, [cs:LoaderName+di]      ;0x0:0x7cf3
    jne     _NOTMATCH
    inc     di
    loop    _CHECKFILENAME
    ; run here if all match "LoaderName"
    ; But it may just match the previous letter, and there are letters after, so we need further processing
    mov     al, LENOFLOADERNAME - 4
    cmp     al, 8
    je      _CHECKEXTENSION     ; =8
    cmp     byte [es:bx+di], 0x20   ; <8
    je      _CHECKEXTENSION     ; if not equal 0x20, it indicate that not matched
_NOTMATCH:
    ; check next file if no matched
    add     bx, 32
    pop     cx                  ; file number
    loop    _CHECKDIRENTRY
    ; run here if all directory entry of one sector had checked but no matched
    pop     cx
    loop    _NEXTSECTOR
    ; run here if all root directory had checked but no matched
    jmp     _NOLOADER
_CHECKEXTENSION:
    mov     cx, 3
    mov     si, LENOFLOADERNAME - 3
    mov     di, 8               ; start index of extension name in FAT12
__CHECK_EXTENSION:
    mov     al, [cs:LoaderName + si]
    cmp     al, [es:bx+di]
    jne     _NOTMATCH
    inc     si
    inc     di
    loop    __CHECK_EXTENSION
    ; run here if all file name matched
_MATCHFILE:
    mov     ax, cs
    mov     ds, ax
    mov     si, FoundLoaderMsg
    mov     di, 10*80*2
    call    DispStr
    mov     ax, [es:bx+0x1A]            ; 0x1A is start cluster of file
    push    ax
    call    GetFATEntry
    add     sp, 2
    jmp     $
_NOLOADER:
    mov     ax, cs
    mov     ds, ax
    mov     si, NoLoaderMsg
    mov     di, 11*80*2
    call    DispStr
    jmp     $

    push    di
    push    si
    pop     cx
    pop     bx
    pop     ax
    pop     es
    mov     sp, bp
    pop     bp
    ret


; ===================================
; @Function: ax = GetFATEntry(dw startCluster)
; @Brief: get value according to the startCluster
;         This function will calculate the offset of the startCluster
;         and return the value in FAT.
; @param: startCluster: range[2,3072]
; @return: ax: vaule of startCluster in FAT
; ===================================
GetFATEntry:
    push    bp
    mov     bp, sp
    sub     sp, 2           ; local variable: flag of if read in odd cluster, 1: odd, 0: even
                            ; if odd cluster: high 4bits of middle byte is low 4 bit of FAT entry
    push    bx
    push    dx
    push    es
    push    si

    mov     ax, BASEOFLOADER
    sub     ax, 0x40        ; left 1K space to save 2 sectors of FAT
    mov     es, ax          ; becase this is segment address
    mov     word [bp-2], 0  ; default is 0: not odd cluster
    mov     ax, [bp+4]      ; startCluster
    mov     bx, 3           ; need x*1.5, so x*3/2
    mul     bx              ; ax max is 3072*3=9216, so never use dx
    mov     bx, 2           ; but if ax is max, div 2 will use dx
    xor     dx, dx          ; dx: high 16bit; ax: low 16bit
    div     bx              ; ax is offset in FAT
    mov     [bp-2], dx      ; save flag: dx is 0 or 1
    xor     dx, dx          ; dx: high 16bit; ax: low 16bit
    mov     bx, [BPB_BytsPerSec]
    div     bx              ; ax
                            ; ax <- 商 (FATEntry 所在的扇区相对于 FAT 的扇区号)
                            ; dx <- 余数 (FATEntry 在扇区内的偏移)
    add     ax, 1           ; sector of FAT Entry
    mov     bx, 2           ; read how many sectors
    push    bx
    push    ax
    mov     bx, 0
    call    ReadSector
    add     sp, 4
    mov     si, dx          ; offset in current sector of FAT
    mov     ax, [es:bx+si]  ; save FAT entry
    cmp     word [bp-2], 0
    je      _ISEVENCLUSTER
    shr     ax, 4
_ISEVENCLUSTER:
    and     ax, 0x0FFF

    pop     si
    pop     es
    pop     dx
    pop     bx
    mov     sp, bp
    pop     bp
    ret

; ===================================
; @Function: ReadSector(dw startSector,dw num)
; @Brief: Read num sectors starting from the startSector sector to es:bx
;         -------------------------------------------------------------
;         扇区号求扇区在磁盘中的位置 (扇区号 -> 柱面号, 起始扇区, 磁头号) (LBA -> CHS)
;         -------------------------------------------------------------
;         设start扇区号为 x
;                                  ┌ 柱面号 = y >> 1
;               x           ┌ 商 y ┤
;         -------------- => ┤      └ 磁头号 = y & 1
;          每磁道扇区数       │
;                           └ 余 z => 起始扇区号 = z + 1
; @param: [IN] startSector
; @param: [IN] num: only use low 8 bit
; @stack: bp, ip, startSector, num
; ===================================
ReadSector:
    push	bp
    mov	    bp, sp
    push    ax    
    push    cx
    push    dx

    mov	    dl, [BPB_SecPerTrk] ; dl: 除数
    mov     ax, [bp+4]
    div	    dl                  ; y 在 al 中, z 在 ah 中
    inc	    ah                  ; z++
    mov	    cl, ah              ; cl <- 起始扇区号
    mov	    dh, al              ; dh <- y
    shr	    al, 1               ; y >> 1 (y/BPB_NumHeads)
    mov	    ch, al              ; ch <- 柱面号
    and	    dh, 1               ; dh & 1 = 磁头号

    ; 至此, "柱面号, 起始扇区, 磁头号" 全部得到
    mov	    dl, [BS_DrvNum]		; 驱动器号 (0 表示 A 盘)
_GoOnReading:
    mov	    ah, 2			    ; 读
    mov	    al, byte [bp+6]		; 读 al 个扇区
    int	    13h
    jc	    _GoOnReading		; 如果读取错误 CF 会被置为 1, 
    				            ; 这时就不停地读, 直到正确为止
    pop     dx
    pop     cx
    pop     ax
    mov     sp, bp
    pop	    bp

    ret

; ===================================
; @Function: DispStr(ds:si, di)
; @Brief: Display string which end with 0
; @param: [IN] ds:si data from where
; @param: [IN] di data go where
; @usage:   mov   ax, cs
;           mov   ds, ax
;           mov   si, STRING
;           mov   di, 10*80*2
;           call  DispStr
; ===================================
DispStr:
    push    es
    push    ax
    push    cx
    mov     ax,0xB800
    mov     es,ax           ; set the data destination
    xor     cx,cx           ; reset cx for loop
_Disp_Str:
    xor     cx,cx
    mov     cl,[ds:si]
    jcxz    _Disp_ret       ; finish display when the data is 0x00
    mov     ch,0x02         ; set color
    mov     [es:di],cx
    inc     si              ; the next index of what to show
    add     di,2            ; the next index of where to show
    jmp     _Disp_Str
_Disp_ret:
    pop     cx
    pop     ax
    pop     es
    ret

; ===================================
; Function: clear screen
; ===================================
;ClearScreen:
;    push    ax
;    push    cx
;    push    di
;    push    es
;
;    mov     ax, 0xB800
;    mov     es, ax
;    mov     cx,25*80        ; total 4000 Bytes
;    mov     ax,0            ; but I use ax so it will div 2
;    xor     di,di
;Clear_Screen:
;    mov     [es:di],ax
;    add     di,2
;    loop    Clear_Screen
;
;    pop     es
;    pop     di
;    pop     cx
;    pop     ax
;    ret

times   510-($-$$) db 0
dw      0xAA55
