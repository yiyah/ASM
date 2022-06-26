; only use in real mode

; ===================================
; @Function: ResetFloppyDisk(dw driveLetter)
; @Brief: reset disk
; @param: [IN] driveLetter: only use low 8 bit
; @stack: bp, ip, driveLetter
; ===================================
ResetFloppyDisk:
    push    ax
    push    dx

    mov     ah, 0
    mov     dl, 0
    int     13H

    pop     dx
    pop     ax
    ret

; ===================================
; @Function: ax = FindFile(dw IndexOfRootDir,dw NumSectorOfRootEntry, dw LenOfLoaderName)
; @Brief: Find file in floppy A
;         This function always read one sector for search file
;         so es will never change, and bx will never overflow
; @param: [IndexOfRootDir]        Fixed value in most cases: 19
; @param: [NumSectorOfRootEntry]  Fixed value in most cases: 14
; @param: [LenOfLoaderName]       "L.BIN" length is 5
; @return: [ax] 0xFFFF :mismatch
;               other  :start cluster of file
; @Usage:
;   mov     ax, BASEOFLOADER
;   mov     es, ax
;   mov     bx, OFFSETLOADER    ; es:bx: data go where (Root Directory)
;   mov     ax, cs
;   mov     ds, ax
;   mov     si, LoaderName
;   push    word LenOfLoaderName
;   push    word NumSectorOfRootEntry
;   push    word IndexOfRootDir
;   call    FindFile
;   add     sp, 6
; ===================================
FindFile:
    push    bp
    mov     bp, sp
    push    cx
    push    di

    mov     cx, [bp+6]          ; NumSectorOfRootEntry
_NEXTSECTOR:
    push    cx                  ; for   "loop    _NEXTSECTOR"
    ; step2: read sector
    ; es:bx had setted before call FindFile
    push    word 1
    push    word [bp+4]         ; IndexOfRootDir: only use low 8bits
    call    ReadSector
    add     sp, 4               ; clean formal parameter
    inc     word [bp+4]

    ; step3: match fileName
    mov     cx, 16              ; one sector have 512/32=16 files(also name Directory Entry)
_CHECKDIRENTRY:
    push    si                  ; for keep si always point to the head of FileName
    push    cx                  ; for    "loop    _CHECKDIRENTRY"
    mov     cx, [bp+8]          ; `. LenOfLoaderName
    sub     cx, 4               ; /  only use name's length
    xor     di, di
_CHECKFILENAME:
    mov     al, [es:bx+di]
    cmp     al, [ds:si]
    jne     _NOTMATCH
    inc     di
    inc     si
    loop    _CHECKFILENAME
    ; run here if all match "LoaderName"
    ; But it may just match the file name, and there are extension name, so we need further processing
    mov     al, [bp+8]          ; LenOfLoaderName
    cmp     al, 12              ; file name size max is 12 (include ".")
    je      _CHECKEXTENSION     ; =12
    cmp     byte [es:bx+di], 0x20   ; <12
    je      _CHECKEXTENSION     ; if not equal 0x20, it indicate that not matched
_NOTMATCH:
    ; check next file if no matched
    add     bx, 32              ; bx point to the next Directory Entry
    pop     cx                  ; file number, use for record how many file are left
    pop     si                  ; Restore si to point to the first letter of loadername
    loop    _CHECKDIRENTRY
    ; run here if all directory entry of one sector had checked but no matched
    pop     cx
    loop    _NEXTSECTOR
    ; run here if all root directory had checked but no matched
    jmp     _NOLOADER
_CHECKEXTENSION:
    mov     cx, 3               ; number of extension name
    inc     si                  ; start index of extension name in Reference (skip ".")
    mov     di, 8               ; start index of extension name in Root Directory
__CHECK_EXTENSION:
    mov     al, [ds:si]
    cmp     al, [es:bx+di]
    jne     _NOTMATCH
    inc     si
    inc     di
    loop    __CHECK_EXTENSION
    ; run here if all file name matched
    add     sp, 4               ; clear push si; push cx
_MATCHFILE:
    mov     ax, [es:bx+0x1A]    ; return the start cluster
    jmp     _EXIT_FINDFILE
_NOLOADER:
    mov     ax, 0xFFFF          ; mismatch code
_EXIT_FINDFILE:
    pop     di
    pop     cx
    mov     sp, bp
    pop     bp
    ret


; ===================================
; @Function: ax = _GetFATEntry(dw startCluster)
; @Brief: get FAT1 value according to the startCluster
;         This function will calculate the offset of the startCluster in FAT1
;         and return the value in FAT1.
;         Note that it will need a 4K free space(es:bx) to temporarily save the read FAT sector.
; @param: startCluster: range[2,3072]
; @return: ax: vaule of startCluster in FAT
; @usage: 
;       mov     es, ax
;       mov     bx, 0
;       push    word startCluster
;       call    _GetFATEntry
;       add     sp, 2
; ===================================
_GetFATEntry:
    push    bp
    mov     bp, sp
    sub     sp, 2           ; `. local variable: flag of if read in odd cluster, 1: odd, 0: even
                            ; /  if odd cluster: high 4bits of middle byte is low 4 bit of FAT entry
    push    dx

    push    bx
    mov     word [bp-2], 0  ; default is 0: not odd cluster
    mov     ax, [bp+4]      ; startCluster
    mov     bx, 3           ; need x*1.5, so x*3/2
    mul     bx              ; ax max is 3072*3=9216, so never use dx
    mov     bx, 2           ; but if ax is max, div 2 will use dx
    xor     dx, dx          ; dx: high 16bit; ax: low 16bit
    div     bx              ; ax is offset in FAT
    mov     [bp-2], dx      ; save flag: dx is 0 or 1
    xor     dx, dx          ; dx: high 16bit; ax: low 16bit
    mov     bx, 512         ; [BPB_BytsPerSec]=512=0x200
    div     bx              ; ax
                            ; ax <- 商 (FATEntry 所在的扇区相对于 FAT 的扇区号)
                            ; dx <- 余数 (FATEntry 在扇区内的偏移)
    pop     bx              ; es:bx to save data when call ReadSector     
    inc     ax              ; sector of FAT Entry(+1 is for skip MBR)
    push    word 2          ; read how many sectors
    push    ax
    call    ReadSector
    add     sp, 4
    add     bx, dx          ; `. offset in current sector of FAT
    mov     ax, [es:bx]     ; /  save FAT entry
    cmp     word [bp-2], 0
    je      _ISEVENCLUSTER
    shr     ax, 4
_ISEVENCLUSTER:
    and     ax, 0x0FFF

    pop     dx
    mov     sp, bp
    pop     bp
    ret

; ===================================
; @Function: LoadFile(dw startCluster, dw IndexOfDataBlock)
; @Brief: load file to es:bx and start with it's first cluster.
;         And it's principle is read (IndexOfDataBlock+startCluster-2) sector.
;         startCluster will change in this function for save memory, and because we only use it once so that is ok.
; @Attention: This will temply use [es-0x100]:bx to save FAT12 table for _GetFATEntry.
; @param: startCluster: range[2,3072]
; @param: IndexOfDataBlock: Fixed value in most cases: 33 (IndexOfRootDir + NumSectorOfRootEntry)
; @usage:
;         mov   es, ax
;         mov   bx, OFFSETLOADER    ; save data to es:bx
;         push  word IndexOfDataBlock
;         push  word startCluster
;         call  LoadFile
;         add   sp, 4
; ===================================
LoadFile:
    push    bp
    mov     bp, sp
    sub     sp, 2           ; local variabel: save bx for _GetFATEntry
    push    bx              ; make bx never change after this function called

    mov     [bp-2], bx      ; local variabel: save bx for _GetFATEntry
    mov     ax, [bp+4]      ; startCluster
    add     ax, [bp+6]      ; `. IndexOfDataBlock
    sub     ax, 2           ; /  (-2) due to first cluster is 2 in data block, for ReadSector
    ; now ax is the number which sector want to read
_GOONLOADING:
    ; es had been setted before call LoadFile
    push    word 1
    push    ax
    call    ReadSector
    add     sp, 4

    push    es              ; `.
    push    bx              ;  |  
    mov     ax, es          ;  | 
    sub     ax, 0x100       ;  | use 4K space befor es:bx to save 2 sectors of FAT (becase this is segment address)
    mov     es, ax          ;  | make bx never change
    mov     bx, [bp-2]      ; /  because _GetFATEntry can reuse memory

    push    word [bp+4]     ; startCluster
    call    _GetFATEntry    ; will change ax
    add     sp, 2
    pop     bx
    pop     es

    and     ax, 0x0FFF
    cmp     ax, 0x0FFF
    je      _ENDOFFILE
    mov     [bp+4], ax      ; startCluster had changed, for _GetFATEntry
    add     bx, 512         ; next address to save file
    add     ax, [bp+6]      ; `. IndexOfDataBlock
    sub     ax, 2           ; /  (-2) due to first cluster is 2 in data block, for ReadSector
    ; now ax is the number which sector want to read
    jmp     _GOONLOADING
_ENDOFFILE:
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
; @Usage:
;         mov     es, ax
;         mov     bx, 0
;         push    word 1
;         push    word [bp+4]         ; IndexOfRootDir: only use low 8bits
;         call    ReadSector
;         add     sp, 4
; ===================================
ReadSector:
    push    bp
    mov     bp, sp
    push    ax
    push    cx
    push    dx

    mov     dl, 18              ; dl: 除数, BPB_SecPerTrk=18
    mov     ax, [bp+4]
    div     dl                  ; y 在 al 中, z 在 ah 中
    inc     ah                  ; z++
    mov     cl, ah              ; cl <- 起始扇区号
    mov     dh, al              ; dh <- y
    shr     al, 1               ; y >> 1 (y/BPB_NumHeads)
    mov     ch, al              ; ch <- 柱面号
    and     dh, 1               ; dh & 1 = 磁头号

    ; 至此, "柱面号, 起始扇区, 磁头号" 全部得到
    mov     dl, 0               ; [BS_DrvNum]=0, 驱动器号 (0 表示 A 盘)
_GoOnReading:
    mov     ah, 2               ; 读
    mov     al, byte [bp+6]     ; 读 al 个扇区
    ; es:bx had been setted when call ReadSector
    int     13h
    jc      _GoOnReading        ; 如果读取错误 CF 会被置为 1, 
                                ; 这时就不停地读, 直到正确为止
    pop     dx
    pop     cx
    pop     ax
    pop     bp

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
_Disp_Str:
    xor     cx,cx           ; reset cx for jcxz
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
ClearScreen:
    push    ax
    push    cx
    push    di
    push    es

    mov     ax, 0xB800
    mov     es, ax
    mov     cx, 25*80   ; total 4000 Bytes
    mov     ax, 0       ; but I use ax so it will div 2
    xor     di, di
_Clear_Screen:
    mov     [es:di],ax
    add     di,2
    loop    _Clear_Screen

    pop     es
    pop     di
    pop     cx
    pop     ax
    ret