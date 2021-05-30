; start --> init_reg
;       --> clear_screen
;       --> show_string
;       --> get_file_path
;                           -->> _getInput
;                                       -->>> _char_push
;                                       -->>> _notChar
;                                                   -->>>> _isBackSpace
;                                                   -->>>> _isEnter
;       --> open_file
;                           -->> openFileFailed
;                           -->> clear_File_PATH_STACK
;
;       --> get_file_size
;       --> read_file
;       --> show_file_buff
;                           -->> _show_offset
;                                       -->>> show_hex
;                           -->> _show_byte
;                                       -->>> show_hex
;                           -->> _show_char

.386
assume ds:data,ss:stack,cs:code

data segment use16

STRING_SHOW         db  'please input path: ',0
STRING_SHOWFAILED   db  'open file failed!',0
FILE_BUFF           db  '0123456789ABCDEF',240 dup ('!')        ; 用于存放文件内容
FILE_PATH_STACK     db  128 dup (0),0                           ; 用于存放 键盘输入的内容
HANDLE              dw  0                                       ; 存放文件句柄
FILE_SIZE           dd  0
FILE_OFFSET         dd  0                                       ; 这个主要用在键盘调整文件位置

KEY_PAGEUP          db  49H
KEY_PAGEDOWM        db  51H
KEY_HOME            db  47H
KEY_END             db  4FH
KEY_ESC             db  01H

data ends

stack segment stack use16
            db      128 dup (0)
stack ends

code segment use16

start:      mov     ax,stack
            mov     ss,ax
            mov     sp,128
nextOpen:   call    init_reg
            call    clear_screen
            
            ; show input
            mov     ax,data
            mov     ds,ax
            mov     si,OFFSET STRING_SHOW
            mov     di,160*5+3*2
            call    show_string

            ; open file
            call    get_file_path
            call    open_file
            call    clear_screen

            ; get file info            
            call    get_file_size
            ; call    show_file_size    ; 好像差两个字节

nextRead:   call    clear_FileBuff      ; 如果不清除 buff 的内容，最后一页显示 会缓存 上一页的内容
            call    read_file           ; 所以先清缓存在 read file

            ; show file info
            call    show_file_buff

            call    choose_option
            jmp     nextRead
            
closeFile:  call    close_file

            mov     ax,4c00H
            int     21H

; ===========================================================
init_reg:   mov     ax,data
            mov     ds,ax
            ret
; ===========================================================
clear_screen:
            push    ax
            push    cx
            push    dx
            push    es
            push    di

            mov     ax,0B800H
            mov     es,ax
            mov     di,0
            mov     dx,0700H
            mov     cx,2000
clearScreen:
            mov     es:[di],dx
            add     di,2
            loop    clearScreen
            
            pop     di
            pop     es
            pop     dx
            pop     cx
            pop     ax
            ret
; ===========================================================
; * -------------------------------------
; param     si      get the FILE_BUFF's address
; * -------------------------------------
show_file_buff:
            push    ax
            push    bx
            push    cx
            push    es
            push    di

            mov     ax,0B800H
            mov     es,ax
            mov     di,160*3+3*2
            mov     si,0
            mov     bx,0        ; set the address's head address
            mov     cx,16
            
showFileBuff:
            call    _show_offset
            call    _show_byte
            call    _show_char
            add     si,16
            add     bx,16
            add     di,160
            loop    showFileBuff

            pop     di
            pop     es
            pop     cx
            pop     bx
            pop     ax
            ret
; * -------------------------------------
; param     bx  the head address
; param     di  
; * -------------------------------------
_show_offset:
            push    ax
            push    di

            ; show the hight address
            mov     al,bh
            call    show_hex
            ; show the low address
            mov     al,bl
            add     di,2*2
            call    show_hex

            pop     di
            pop     ax
            ret
; * -------------------------------------
; param     al 要显示的 hex
; param     di
; * -------------------------------------
show_hex:   jmp     _showHEX
TABLE_HEX   db      '0123456789ABCDEF'
_showHEX:   
            push    bx

            mov     ah,al
            shr     ah,1            
            shr     ah,1            
            shr     ah,1            
            shr     ah,1
            and     al,00001111B
            
            ; show the hight
            mov     bx,0
            mov     bl,ah
            mov     ah,cs:TABLE_HEX[bx]
            mov     es:[di],ah
            ; show the low
            mov     bx,0
            mov     bl,al
            mov     al,cs:TABLE_HEX[bx]
            mov     es:[di+2],al

            pop     bx
            ret
; * -------------------------------------
; param     si 要显示的 hex 的地址
; param     di
; * -------------------------------------
_show_byte:
            push    ax
            push    cx
            push    si
            push    di

            mov     cx,16
            add     di,8*2

_showByte:  mov     al,ds:FILE_BUFF[si]
            call    show_hex
            add     si,1
            add     di,3*2
            loop    _showByte

            pop     di
            pop     si
            pop     cx
            pop     ax
            ret
; * -------------------------------------
; param     si 要显示的 char 的地址
; param     di
; * -------------------------------------
_show_char: push    ax
            push    dx
            push    cx
            push    si
            push    di
            add     di,60*2
            mov     cx,16                   ; 可实现同样功能 ↓↓↓
_showChar:  mov     dx,'.'                  ; _showChar:  mov     byte ptr es:[di],'.'                                         
            mov     al,ds:FILE_BUFF[si]     ;             mov     al,ds:FILE_BUFF[si]                
            cmp     al,32                   ;             cmp     al,32    
            jb      show_dot                ;             jb      _show_next_char        
            cmp     al,128                  ;             cmp     al,128    
            jnb     show_dot                ;             jnb     _show_next_char        
            mov     dl,al                   ;             mov     es:[di],al    
show_dot:   mov     es:[di],dl              ; _show_next_char:        
            add     di,2                    ;             add     di,2    
            inc     si                      ;             inc     si
            loop    _showChar               ;             loop    _showChar           

            pop     di
            pop     si
            pop     cx
            pop     dx
            pop     ax
            ret
; ===========================================================
; * -------------------------------------
; param     si 要显示的 string 的地址
; param     ds 要显示的 string 的地址
; param     di 要显示的位置
; * -------------------------------------
show_string:
            push    ax
            push    es
            push    si
            push    di

            mov     ax,0B800H
            mov     es,ax
            
showString: mov     al,ds:[si]
            cmp     al,0
            je      show_stringRet
            mov     es:[di],al
            add     di,2
            inc     si
            jmp     showString
show_stringRet:
            mov     byte ptr es:[di],0
            pop     di
            pop     si
            pop     es
            pop     ax
            ret        
; =========================================================== 
get_file_path:
            push    ax
            push    bx
            push    si
            push    di

            mov     si,OFFSET   FILE_PATH_STACK
            mov     di,160*5+23*2
            mov     bx,0            ; 记录 FILE_PATH_STACK 的栈顶标记
_getInput:  mov     ah,0
            int     16H
            cmp     al,20H
            jb      _notCHar
            call    _char_push
            call    show_string
            jmp     _getInput       ; 直到输入 ENTER
            ret

_notChar:   cmp     ah,1cH
            je      _isEnter
            cmp     ah,0eH
            je      _isBackSpace
            jmp     _getInput

_isEnter:   pop     di
            pop     si
            pop     bx
            pop     ax
            ret
_isBackSpace:
            call    _char_pop
            call    show_string
            jmp     _getInput

_char_push: cmp     bx,128
            jnb     _char_pushRet
            mov     ds:FILE_PATH_STACK[bx],al
            inc     bx
_char_pushRet:
            ret
_char_pop:  cmp     bx,0
            je      _char_popRet
            dec     bx
            mov     byte ptr ds:FILE_PATH_STACK[bx],0
_char_popRet:
            ret
; =========================================================== 
open_file:  mov     ah,3DH
            mov     al,0            ; 对应 open() 的第2个参数，表示只读
            mov     dx,OFFSET FILE_PATH_STACK   ; 文件名的地址
            int     21H             ; success: CF=0, AX=HANDLE; fail: CF=1, AX=erro code;
            jc      openFileFailed
            mov     HANDLE,ax
            ret
openFileFailed:
            add     sp,2        ; 因为是通过 call open_file 进来的，但是返回直接 jmp，所以需要移动 sp
            mov     si,OFFSET STRING_SHOWFAILED
            mov     di,160*3+30*2
            call    show_string
            mov     ah,0
            int     16H
            call    clear_File_PATH_STACK
            jmp     nextOpen

get_file_size:
            push    ax
            push    cx
            push    dx

            mov     ah,42H
            mov     al,2        ; 对应 lseek() 的第 3 个参数，表示以 EOF 为参照点进行移动
            mov     bx,HANDLE
            mov     cx,0        ; cx 是高位，dx 是低位
            mov     dx,0        ; cx:dx 对应 lseek() 的第 2 个参数，表示偏移量
            int     21H
            ; 返回最终的偏移量（从头开始数），因为从结尾打开文件，所以返回的是文件的大小
            mov     word ptr ds:FILE_SIZE[0],ax ; size 的 l 8位
            mov     word ptr ds:FILE_SIZE[2],dx ; size 的 h 8位

            pop     dx
            pop     cx
            pop     ax
            ret
show_file_size:
            push    ax
            push    bx
            push    es
            push    di
            
            mov     ax,0B800H
            mov     es,ax

            mov     di,160*1+3*2
            mov     al,byte ptr ds:FILE_SIZE[3]
            call    show_hex

            add     di,2*2
            mov     al,byte ptr ds:FILE_SIZE[2]
            call    show_hex

            add     di,2*2
            mov     al,byte ptr ds:FILE_SIZE[1]
            call    show_hex

            add     di,2*2
            mov     al,byte ptr ds:FILE_SIZE[0]
            call    show_hex
            
            pop     di
            pop     es
            pop     bx
            pop     ax
            ret
read_file:  push    ax
            push    bx
            push    cx
            push    dx

            ; 移动文件指针
            mov     ah,42H
            mov     al,0        ; 对应 lseek() 的第 3 个参数，表示以 偏移0 为参照点进行移动
            mov     bx,HANDLE
            mov     cx,word ptr ds:FILE_OFFSET[2]   ; cx 是高位，dx 是低位
            mov     dx,word ptr ds:FILE_OFFSET[0]   ; 修改这里的 cx:dx 就可以改变读取的位置
            int     21H
            
            ; 读取文件中的 个字节到 FILE_BUFF 中
            ; 应该是读取到 ds:[dx] 中
            mov     ah,3FH
            mov     bx,HANDLE
            mov     cx,256
            mov     dx,data
            mov     ds,dx
            mov     dx,OFFSET FILE_BUFF     
            int     21H

            pop     dx
            pop     cx
            pop     bx
            pop     ax
            ret
; =========================================================== 
close_file: push    ax
            push    bx

            mov     ah,3EH
            mov     bx,HANDLE
            int     21H
            
            pop     bx
            pop     ax
            ret
; =========================================================== 
clear_File_PATH_STACK:
            push    cx
            push    di
            mov     cx,128
            mov     di,0
clearFilePathStack:
            mov     byte ptr ds:FILE_PATH_STACK[di],0
            inc     di
            loop    clearFilePathStack
            pop     di
            pop     cx
            ret
; =========================================================== 
clear_FileBuff:
            push    cx
            push    di
            mov     cx,256
            mov     di,0
clearFileBuff:
            mov     byte ptr ds:FILE_BUFF[di],0
            inc     di
            loop    clearFileBuff
            pop     di
            pop     cx
            ret
; =========================================================== 
choose_option:
            push    ax
            push    di
            push    es
            mov     ax,0B800H
            mov     es,ax

            mov     ah,0
            int     16H
            cmp     ah,KEY_PAGEDOWM
            je      _isDown
            cmp     ah,KEY_PAGEUP
            je      _isUP
            cmp     ah,KEY_HOME
            je      _isHOME
            cmp     ah,KEY_END
            je      _isEND
            cmp     ah,KEY_ESC
            je      _isESC

chooseRet:  pop     es
            pop     di
            pop     ax
            ret
_isESC:     add     sp,2
            jmp     closeFile

_isDown:    mov     di,160*22
            mov     byte ptr es:[di],'D'
            mov     eax,FILE_OFFSET             ; 用 eax 临时保存并做判断
            add     eax,256
            cmp     eax,FILE_SIZE               ; +256 后判断是否 超出文件大小
            jnb     chooseRet
            add     FILE_OFFSET,256
            jmp     chooseRet
_isUP:      mov     di,160*22
            mov     byte ptr es:[di],'U'
            cmp     FILE_OFFSET,0               ; 因为每次都是 256bytes 移动，减法到顶最终也会变 0
            je      chooseRet
            sub     FILE_OFFSET,256             ; 还不是 0 ，还可以往上翻页
            jmp     chooseRet
_isHOME:    mov     di,160*22
            mov     byte ptr es:[di],'H'
            mov     FILE_OFFSET,0               ; 直接读 0
            jmp     chooseRet
_isEND:     mov     di,160*22
            mov     byte ptr es:[di],'E'
            mov     eax,FILE_SIZE
            mov     edx,0
            mov     ebx,256
            div     ebx
            mov     eax,FILE_SIZE
            sub     eax,edx                     ; 减去 余数
            mov     FILE_OFFSET,eax             ; 上面的运算是: FILE_OFFSET = FILE_SIZE - FILE_SIZE % 256
            cmp     eax,FILE_SIZE               ; 下面的运算是为了防止 FILE_SIZE 是 256 的倍数
            jne     chooseRet                   ; 导致上面的运算结果 FILE_OFFSET = FILE_SIZE
            sub     FILE_OFFSET,256             ; 而 FILE_SIZE 是 256 的倍数的话可以 直接减掉 256 获得最后的 OFFSET
            jmp     chooseRet

code ends
end start
