; 本程序运行后，会把 BOOT_START 和 OS 程序 拷贝到 软盘中
; flow 是：开机后，系统会将软盘的 第一个扇区的程序 拷贝到 不知名地方 并且 CS:IP 指向它（自动执行）
;       --> 这个时候，这段程序就是我们的 boot(introduce)，我们要做的就是继续把软盘中的 OS 程序拷贝到一段安全的内存地址中：0:7E00H
;       --> 此时，我们需要把 CS:IP 指向我们的 OS
;       --> 我们的 os 的 restart PC 和 start system 两个功能分别是：
;           ① CS:IP = 0:0FFFFH
;           ② 拷贝c盘（驱动号是80H）的引导程序到 0:7c00H 并把 CS:IP 指向 0:7c00H （这样就会引导本身的操作系统）


assume ds:data,ss:stack,cs:code

data segment
STRING  db      128     dup     (0)
data ends

stack segment stack
        db      128     dup     (0)
stack ends

code segment

start:          mov     ax,stack
                mov     ss,ax
                mov     sp,128
                call    int_reg

                call    cpy_introduce_toDisk
                call    cpy_boot_toDisk

                mov     ax,4c00H
                int     21H

;===========================================   
;===========================================
int_reg:        mov     ax,data
                mov     ds,ax
                mov     si,0
                mov     ax,0B800H
                mov     es,ax
                ret

cpy_introduce_toDisk:
                mov     bx,cs
                mov     es,bx
                mov     bx,OFFSET introduce

                mov     dl,0
                mov     dh,0
                mov     ch,0
                mov     cl,1
                mov     al,1
                mov     ah,3
                int     13H
                ret

cpy_boot_toDisk:
                mov     bx,cs
                mov     es,bx
                mov     bx,OFFSET Boot

                mov     dl,0
                mov     dh,0
                mov     ch,0
                mov     cl,2
                mov     al,4
                mov     ah,3
                int     13H
                ret

; =================introduce==========================
; 作用：引导 OS
introduce:      mov     ax,0
                mov     ss,ax
                mov     sp,7c00H

                call    save_old_int9           ; int9是键盘中断，后面用到，所以save
                call    cpy_boot_fromDisk
                call    setIP
                ret

; ============== old_int9 =====================
save_old_int9:  push    ax
                push    es

                mov     ax,0
                mov     es,ax
                
                push    es:[9*4]
                pop     es:[200H]
                push    es:[9*4+2]
                pop     es:[202H]

                pop     es
                pop     ax
                ret

cpy_boot_fromDisk:
                mov     ax,0
                mov     es,ax
                mov     bx,7E00H

                mov     dl,0
                mov     dh,0
                mov     ch,0
                mov     cl,2
                mov     al,4
                mov     ah,2
                int     13H
                ret


; ===========================================
setIP:          mov     ax,0
                push    ax
                mov     ax,7E00H
                push    ax
                retf

                db      512 dup (0)
introduce_end:  nop

; <<<<<<<<<<<<<<<<<<<<<<<这里就相当于新的程序一样>>>>>>>>>>>>>>>>>>>>>>
; ==================Boot=====================
Boot:           jmp     BOOT_START

OPTION_1        db      '1) restart PC',0
OPTION_2        db      '2) start system',0
OPTION_3        db      '3) show clock',0
OPTION_4        db      '4) set clock',0

ADDRESS_OPTION  dw      OFFSET  OPTION_1 - OFFSET Boot + 7E00H
                dw      OFFSET  OPTION_2 - OFFSET Boot + 7E00H
                dw      OFFSET  OPTION_3 - OFFSET Boot + 7E00H
                dw      OFFSET  OPTION_4 - OFFSET Boot + 7E00H

CLOCK_STYLE     db      'YY-MM-DD HH:MM:SS',0
CLOCK_ADDR      db      9,8,7,4,2,0
STRING_STACK    db      12      dup     ('0'),0,0,0                     ; set clock 用的

BOOT_START:     call    Boot_init_reg
                call    clear_screen
                call    show_options

                jmp     choose_option

                mov     ax,4c00H
                int     21H

; >>==============Boot_init_reg==========================
Boot_init_reg:  mov     ax,0
                mov     ds,ax
                
                mov     ax,0B800H
                mov     es,ax
                ret
; >>===============clear_screen=========================
clear_screen:   push    ax
                push    cx
                push    di

                mov     ax,0
                mov     cx,2000
                mov     di,0
clearScreen:    mov     es:[di],ax
                add     di,2
                loop    clearScreen

                pop     di
                pop     cx
                pop     ax
                ret
; >>===============show_string=========================
; 把字符串的首地址放到 ds:[si], ah 是颜色
; 显示到 es:[di]
show_string:    push    ax
                push    bx
                push    si
                push    di
                push    es
                mov     bx,0B800H
                mov     es,bx
showString:     mov     al,ds:[si]
                cmp     al,0
                je      showStringRet
                mov     es:[di],ax
                add     si,1
                add     di,2
                jmp     showString
showStringRet:  pop     es
                pop     di
                pop     si
                pop     bx
                pop     ax
                ret

; >>===============show_options=========================
show_options:   push    bx
                push    cx
                push    si
                push    di

                mov     cx,4
                mov     di,160*10+25*2                                          ; 显示到第几行第几列
                mov     bx,OFFSET ADDRESS_OPTION - OFFSET Boot + 7E00H          ; 字符串的地址 的地址
                
showOptions:    mov     si,ds:[bx]                                              ; 得到字符串的地址
                mov     ah,02H                                                  ; 设置颜色
                call    show_string
                add     bx,2                                                    ; 指向下一个字符串的地址
                add     di,160                                                  ; 显示到下一行
                loop    showOptions

                pop     di
                pop     si
                pop     cx
                pop     bx
                ret
; >>===============clear_buff=========================
; 这个函数现在不知道是啥作用
clear_buff:     mov     ah,1
                int     16H
                jz      clearBuffRet
                mov     ah,0
                int     16H
                jmp     clear_buff
clearBuffRet:   ret

; >>===============show choice=========================
isChooseOne:    mov     di,160*3
                mov     byte ptr es:[di],'1'
                mov     byte ptr es:[di+1],02H
                call    restart_PC
                jmp     choose_option
isChooseTwo:    mov     di,160*3
                mov     byte ptr es:[di],'2'
                mov     byte ptr es:[di+1],02H
                call    start_os
                jmp     choose_option

isChooseThree:  mov     di,160*3
                mov     byte ptr es:[di],'3'
                mov     byte ptr es:[di+1],02H
                call    show_clock
                jmp     BOOT_START

isChooseFour:   mov     di,160*3 
                mov     byte ptr es:[di],'4'
                mov     byte ptr es:[di+1],02H
                call    set_clock
                jmp     choose_option

; >>===============choose_option=========================
choose_option:  call    clear_buff
                mov     ah,0
                int     16H

                cmp     al,'1'
                je      isChooseOne
                cmp     al,'2'
                je      isChooseTwo
                cmp     al,'3'
                je      isChooseThree
                cmp     al,'4'
                je      isChooseFour

                jmp     choose_option
; >>===============sub function=========================
; >>===============sub function=========================

; >>=============== new int 9 ==========================
set_new_int9:   push    ax
                push    es

                mov     ax,0
                mov     es,ax

                cli
                mov     word ptr es:[9*4],OFFSET new_int9 - OFFSET Boot + 7E00H
                mov     word ptr es:[9*4+2],0
                sti
                
                pop     es
                pop     ax
                ret
set_old_int9:   push    ax
                push    es

                mov     ax,0
                mov     es,ax
                cli
                push    es:[200H]
                pop     es:[9*4]
                push    es:[202H]
                pop     es:[9*4+2]
                sti
                pop     es
                pop     ax
                ret
new_int9:       push    ax
                call    clear_buff
                in      al,60H
                pushf
                call    dword ptr cs:[200H]

                cmp     al,01H                  ; ESC
                je      isESC
                cmp     al,3BH                  ; F1
                jne     new_int9Ret
                call    change_time_color
new_int9Ret:    pop     ax
                iret

; >>=============== isESC ====================       
isESC:          pop     ax
                add     sp,4
                popf
                jmp     show_clockRet
; >>=============== change_time_color ====================       
change_time_color:
                push    ax
                push    cx
                push    di
                push    es

                mov     ax,0B800H
                mov     es,ax
                mov     di,160*20+1
                mov     cx,17
chaneTimeColor: inc     byte ptr es:[di]
                add     di,2
                loop    chaneTimeColor
                pop     es
                pop     di
                pop     cx
                pop     ax
                ret
; >>=============== FUN1: restart PC====================
restart_PC:     mov     bx,0FFFFH
                push    bx
                mov     bx,0
                push    bx
                retf
; >>=============== FUN2: start_os====================
start_os:       mov     bx,0
                mov     es,bx
                mov     bx,7c00H

                mov     dl,80H
                mov     dh,0
                mov     ch,0
                mov     cl,1
                mov     al,1
                mov     ah,2
                int     13H

                mov     bx,0
                push    bx
                mov     bx,7c00H
                push    bx
                retf
                ret
; >>=============== FUN3: show clock====================
show_style:     mov     si,OFFSET CLOCK_STYLE - OFFSET Boot + 7E00H
                mov     di,160*20
                call    show_string
                ret

show_clock:     call    show_style
                call    set_new_int9            ; 目的是自己管理键盘中断
showTime:       mov     si,OFFSET CLOCK_ADDR - OFFSET Boot + 7E00H
                mov     di,160*20
                mov     cx,6                    ; 循环 6 次从 CMOS 里取时间
showClock:      mov     al,ds:[si]
                out     70H,al
                in      al,71H
                mov     ah,al                   ; 这里是为了把 十位 和 个位 分别放在 ah al 中
                shr     ah,1
                shr     ah,1
                shr     ah,1
                shr     ah,1
                and     al,00001111B

                add     ah,30H                  ; 得到 ASCII
                add     al,30H                  ; 得到 ASCII

                mov     es:[di],ah
                mov     es:[di+2],al
                inc     si                      ; 为下一次取时间做准备
                add     di,6                    ; 显示的位置 +6
                loop    showClock
                jmp     showTime
show_clockRet:  call    set_old_int9            ; 程序退出，设回原来的中断
                ret

; >>=============== FUN4: set clock ====================
set_clock:      call    clear_string_stack
                call    show_string_stack
                call    get_string
                call    set_cmos_time

                ret
; 作用是将 dx 复制到 ds:[si]
clear_string_stack:
                push    ax
                push    dx
                push    cx
                push    ds
                push    si
                mov     ax,0
                mov     ds,ax
                mov     si,OFFSET STRING_STACK - OFFSET Boot + 7E00H
                mov     dx,3030H
                mov     cx,6
clearStringStack:
                mov     ds:[si],dx
                add     si,2
                loop    clearStringStack

                pop     si
                pop     ds
                pop     cx
                pop     dx
                pop     ax
                ret
show_string_stack:
                push    ax
                push    si
                push    di
                push    ds
                push    es

                mov     ax,0
                mov     ds,ax
                mov     si,OFFSET STRING_STACK - OFFSET Boot + 7E00H
                mov     ax,0B800H
                mov     es,ax
                mov     di,160*4                ; 第四行显示
                mov     ah,02H
                call    show_string
                pop     es
                pop     ds
                pop     di
                pop     si
                pop     ax
                ret
; >>=============== get_string ====================
get_string:     push    ax
                push    bx
                push    es
                push    di

                mov     ax,0
                mov     es,ax
                mov     di,OFFSET STRING_STACK - OFFSET Boot + 7E00H
                mov     bx,0
                call    clear_buff              ; 不调用也行
getString:      mov     ah,0
                int     16H

                cmp     al,'0'
                jb      notNumber
                cmp     al,'9'
                ja      notNumber
                call    char_push
                call    show_string_stack
                jmp     getString
; 注意这里 cmp 变成了 ah
notNumber:      cmp     ah,1CH                  ; Enter
                je      getStringRet
                cmp     ah,0EH                  ; Backspace
                je      isBackspace
                jmp     getString

; 传进来 al, es, di,bx
char_push:      cmp     bx,11                   ; 注意这里要比实际小1
                ja      charPushRet
                mov     es:[di+bx],al
                inc     bx
charPushRet:    ret
char_pop:       cmp     bx,0
                je      charPopRet
                dec     bx                      ; 注意先自减
                mov     byte ptr es:[di+bx],'0'          
charPopRet:     ret
isBackspace:    call    char_pop
                call    clear_buff
                call    show_string_stack
                jmp     getString
isEnter:        
getStringRet:   pop     di
                pop     es
                pop     bx
                pop     ax
                ret
; >>=============== set_cmos_time ====================
set_cmos_time:  push    ax
                push    bx
                push    cx
                push    si
                push    ds
                ;call    clear_screen
                mov     ax,0
                mov     ds,ax
                mov     si,OFFSET STRING_STACK - OFFSET Boot + 7E00H
                mov     bx,OFFSET CLOCK_ADDR - OFFSET Boot + 7E00H
                mov     cx,6
setCmosTime:    mov     dx,ds:[si]              ; if dx = '12'
                sub     dh,30H                  ; dh = '2'
                sub     dl,30H                  ; dl = '1'
                and     dh,00001111B
                shl     dl,1                    ; 要组成 12，就把 dl 左移
                shl     dl,1
                shl     dl,1
                shl     dl,1
                or      dl,dh
                
                mov     al,ds:[bx]              ; 访问 CMOS 哪个地址
                out     70H,al
                mov     al,dl                   ; 赋值
                out     71H,al
                
                add     si,2
                inc     bx
                loop    setCmosTime

                pop     ds
                pop     si
                pop     cx
                pop     bx
                pop     ax
                ret
Boot_END:       nop
; <<<<<<<<<<<<<<<<<<<<<<<---END--->>>>>>>>>>>>>>>>>>>>>>


code ends
end start