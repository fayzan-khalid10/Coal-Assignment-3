org 100h
        jmp main


; Layout constants

WIN_TOP     equ 3               
WIN_BOTTOM  equ 21
WIN_LEFT    equ 8
WIN_RIGHT   equ 72
TEXT_ROW    equ 5              
TEXT_COL    equ 10              
LINE_W      equ 61              
WRAP_SKIP   equ 160 - 2*LINE_W  


; Data

bannerText  db "Text Viewer Windowww", 0
BANNER_LEN  equ $ - bannerText - 1

bodyText    db "Once there was a boy named Peter. He had high hopes from himself. He thought he was destined for greatness. But as life went on, he realised that there was nothing guaranteed. Life owed him nothing. That's when he realised the importance and the need of hardwork.", 0
BODY_LEN    equ $ - bodyText - 1

scrollLines dw 0                

needle    db "he"

NEEDLE_LEN  equ $ - needle


statLabel   db "Total Matches Found: "
STAT1_LEN   equ $ - statLabel
statTail    db " | Viewport Status: ACTIVE"
STAT2_LEN   equ $ - statTail

hitCount    dw 0


clear_screen:
        push es
        push ax
        push cx
        push di

        mov ax, 0xb800
        mov es, ax
        xor di, di
        mov ax, 0x0720
        mov cx, 80*25
        cld
        rep stosw

        pop di
        pop cx
        pop ax
        pop es
        ret


corners:
        push bp
        mov bp, sp
        push ax
        push bx

        mov bx, 160
        mov ax, [bp+10]
        mul bx
        mov si, ax              ; top * 160
        mov ax, [bp+8]
        mul bx
        mov cx, ax              ; bottom * 160
        mov ax, [bp+6]
        shl ax, 1
        mov bx, ax              ; left * 2
        mov ax, [bp+4]
        shl ax, 1               ; right * 2

        mov di, si
        mov dx, cx
        add si, bx              ; top-left
        add cx, bx              ; bottom-left
        add di, ax              ; top-right
        add dx, ax              ; bottom-right

        pop bx
        pop ax
        pop bp
        ret 8


draw_frame:
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push di
        push es

        mov ax, 0xb800
        mov es, ax
        cld

        ; four corners
        mov di, [bp+10]
        mov word [es:di], 0x0FC9
        mov di, [bp+8]
        mov word [es:di], 0x0FBB
        mov di, [bp+6]
        mov word [es:di], 0x0FC8
        mov di, [bp+4]
        mov word [es:di], 0x0FBC

        
        mov ax, 0x0FBA
        mov di, [bp+10]         ; left wall pointer
        mov bx, [bp+8]          ; right wall pointer
.walls:
        add di, 160
        add bx, 160
        cmp di, [bp+6]         
        jae .wallsDone
        mov [es:di], ax
        mov [es:bx], ax
        jmp .walls
.wallsDone:

        ; top and bottom edges
        mov ax, 0x0FCD
        mov cx, [bp+8]
        sub cx, [bp+10]
        shr cx, 1
        dec cx                  
        mov bx, cx
        mov di, [bp+10]
        add di, 2
        rep stosw
        mov cx, bx
        mov di, [bp+6]
        add di, 2
        rep stosw

        pop es
        pop di
        pop cx
        pop bx
        pop ax
        pop bp
        ret 8


draw_title:
        push bp
        mov bp, sp
        push ax
        push cx
        push si
        push di
        push es

        mov ax, 0xb800
        mov es, ax
        cld

        mov cx, [bp+4]
        mov ax, 65              
        sub ax, cx
        shr ax, 1
        add ax, WIN_LEFT        
        shl ax, 1
        add ax, 2*160           
        mov di, ax
        mov si, [bp+6]
        mov ah, 0x1E            
.put:
        lodsb
        stosw
        loop .put

        pop es
        pop di
        pop si
        pop cx
        pop ax
        pop bp
        ret 4


stream_text:
        push bp
        mov bp, sp
        sub sp, 2
        push ax
        push cx
        push si
        push di
        push es

        mov ax, 0xb800
        mov es, ax
        cld
        mov di, TEXT_ROW*160 + TEXT_COL*2
        mov si, [bp+6]
        mov cx, [bp+4]
        mov word [bp-2], 0
        mov ah, 0x0F           
.emit:
        lodsb
        stosw
        inc word [bp-2]
        cmp word [bp-2], LINE_W
        jb .more
        mov word [bp-2], 0
        add di, WRAP_SKIP       
.more:
        loop .emit

        pop es
        pop di
        pop si
        pop cx
        pop ax
        mov sp, bp
        pop bp
        ret 4


scroll_window_up:
        push bp
        mov bp, sp
        sub sp, 6
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        push es
        push ds

        mov ax, 0xb800
        mov es, ax
        mov ds, ax
        cld

        mov ax, [bp+10]
        sub ax, [bp+6]
        dec ax
        shl ax, 1
        mov [bp-2], ax          
        mov ax, [bp+6]
        inc ax
        shl ax, 1
        mov [bp-4], ax          
        mov ax, [bp+12]
        mov [bp-6], ax          

.again:
        cmp word [bp-6], 0
        jle .finished
        mov bx, [bp+4]
        add bx, 2               
.shift:
        mov ax, [bp+8]
        dec ax                  
        cmp bx, ax
        ja .clearLast
        mov ax, bx
        mov dx, 160
        mul dx
        add ax, [bp-4]
        mov si, ax              
        sub ax, 160
        mov di, ax              
        mov cx, [bp-2]
        shr cx, 1
        rep movsw
        inc bx
        jmp .shift
.clearLast:
        mov ax, [bp+8]
        dec ax
        mov dx, 160
        mul dx
        add ax, [bp-4]
        mov di, ax
        mov cx, [bp-2]
        shr cx, 1
        mov ax, 0x0720
        rep stosw
        dec word [bp-6]
        jmp .again

.finished:
        pop ds
        pop es
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        mov sp, bp
        pop bp
        ret 10


find_and_highlight:
        push bp
        mov bp, sp
        sub sp, 2
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        push ds
        push es

        mov ax, ds
        mov es, ax
        cld
        mov si, bodyText

.scan:
        cmp byte [si], 0
        jne .check
        jmp .done
.check:
        cmp si, bodyText
        je .compare
        mov al, [si-1]          
        or al, 0x20
        cmp al, 'a'
        jb .compare
        cmp al, 'z'
        jbe .advance            
.compare:
        mov di, [bp+8]
        mov cx, [bp+6]
        push si
        repe cmpsb
        pop si
        jne .advance
        mov bx, si
        add bx, [bp+6]
        mov al, [bx]            
        or al, 0x20
        cmp al, 'a'
        jb .hit
        cmp al, 'z'
        ja .hit
.advance:
        inc si
        jmp .scan

.hit:
        mov ax, si
        sub ax, bodyText       
        xor dx, dx
        mov cx, LINE_W
        div cx                  
        mov [bp-2], dx
        add ax, TEXT_ROW
        sub ax, [scrollLines]   
        cmp ax, WIN_TOP+1       
        jl .advance
        cmp ax, WIN_BOTTOM-1   
        jg .advance
        mov cx, 160
        mul cx                 
        mov di, ax
        add di, TEXT_COL*2
        mov ax, [bp-2]
        shl ax, 1
        add di, ax             

        mov ax, 0xb800
        mov es, ax
        mov cx, [bp+6]
        mov al, [bp+4]
.paint:
        mov [es:di+1], al       
        add di, 2
        inc word [bp-2]
        cmp word [bp-2], LINE_W
        jne .sameLine
        mov word [bp-2], 0
        add di, WRAP_SKIP
.sameLine:
        loop .paint
        inc word [hitCount]
        mov ax, ds
        mov es, ax
        jmp .advance

.done:
        pop es
        pop ds
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        mov sp, bp
        pop bp
        ret 6


printNum:
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        push es

        mov ax, 0xb800
        mov es, ax
        cld
        mov di, (23*80 + WIN_LEFT)*2

        mov si, [bp+12]
        mov cx, [bp+10]
        mov ah, 0x07
.label:
        lodsb
        stosw
        loop .label

        mov ax, [bp+4]         
        mov bx, 10
        xor cx, cx
.split:
        xor dx, dx
        div bx
        push dx
        inc cx
        or ax, ax
        jnz .split
.show:
        pop ax
        add al, '0'
        mov ah, 0x07
        stosw
        loop .show

        mov si, [bp+8]
        mov cx, [bp+6]
        mov ah, 0x07
.tail:
        lodsb
        stosw
        loop .tail

        pop es
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        pop bp
        ret 10


main:
        call clear_screen

        ; border
        mov ax, WIN_TOP
        push ax
        mov ax, WIN_BOTTOM
        push ax
        mov ax, WIN_LEFT
        push ax
        mov ax, WIN_RIGHT
        push ax
        call corners
        push si
        push di
        push cx
        push dx
        call draw_frame

        ; paragraph
        mov ax, bodyText
        push ax
        mov ax, BODY_LEN
        push ax
        call stream_text

        ; scroll the window contents
        mov ax, [scrollLines]
        push ax
        mov ax, WIN_RIGHT
        push ax
        mov ax, WIN_BOTTOM
        push ax
        mov ax, WIN_LEFT
        push ax
        mov ax, WIN_TOP
        push ax
        call scroll_window_up

        ; highlight every whole-word match (blinking yellow on red)
        mov ax, needle
        push ax
        mov ax, NEEDLE_LEN
        push ax
        mov ax, 0xCE
        push ax
        call find_and_highlight

        ; title banner
        mov ax, bannerText
        push ax
        mov ax, BANNER_LEN
        push ax
        call draw_title

        ; status bar
        mov ax, statLabel
        push ax
        mov ax, STAT1_LEN
        push ax
        mov ax, statTail
        push ax
        mov ax, STAT2_LEN
        push ax
        mov ax, [hitCount]
        push ax
        call printNum

        mov ah, 0               ; wait for a key so the screen stays visible
        int 16h

        mov ax, 0x4c00
        int 21h