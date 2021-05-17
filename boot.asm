; flow: start: copy Boot to 0:7E00H --> set CS:IP=0:7E00H
; 也就是说所有的字符串，子程序 都定义在 Boot 程序中，免得被清理掉（注意此时的Boot的地址是 0:7E00H）
; Boot程序相当于正常写一个新的程序，上面是定义一些data，下面有个start的标号 标示 程序开始。


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

                
                call    cpy_boot
                call    save_old_int9
                call    setIP

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
                push    si
                push    di

showString:     mov     al,ds:[si]
                cmp     al,0
                je      showStringRet
                mov     es:[di],ax
                add     si,1
                add     di,2
                jmp     showString
showStringRet:  pop     di
                pop     si
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
                jmp     choose_option
isChooseTwo:    mov     di,160*3
                mov     byte ptr es:[di],'2'
                mov     byte ptr es:[di+1],02H
                jmp     choose_option

isChooseThree:  mov     di,160*3
                mov     byte ptr es:[di],'3'
                mov     byte ptr es:[di+1],02H
                call    show_clock
                jmp     BOOT_START

isChooseFour:   mov     di,160*3 
                mov     byte ptr es:[di],'4'
                mov     byte ptr es:[di+1],02H
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
; >>=============== FUN1: restart pc====================

; >>=============== FUN3: show clock====================
show_style:     mov     si,OFFSET CLOCK_STYLE - OFFSET Boot + 7E00H
                mov     di,160*20
                call    show_string
                ret

show_clock:     call    show_style
                call    set_new_int9
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
show_clockRet:  call    set_old_int9
                ret
Boot_END:       nop

; <<<<<<<<<<<<<<<<<<<<<<<---END--->>>>>>>>>>>>>>>>>>>>>>
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


; ==============cpy_boot=====================
cpy_boot:       mov     ax,cs
                mov     ds,ax
                mov     si,OFFSET Boot

                mov     ax,0
                mov     es,ax
                mov     di,7E00H

                mov     cx, OFFSET Boot_END - OFFSET Boot
                cld
                rep     movsb
                ret
; ===========================================
setIP:          mov     ax,0
                push    ax
                mov     ax,7E00H
                push    ax
                retf



code ends
end start