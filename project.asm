IDEAL
MODEL compact
STACK 100h

DATASEG
; --------------------------
x dw 160
y dw 100
c db 4
FARDATA bufferseg
buffer db 64000 dup(0)
; --------------------------
CODESEG
proc drawpixel
mov bp,sp ;store the stack pointer

xor ax,ax
xor bx,bx
xor cx,cx
xor dx,dx
mov ax,13h ;switch to video mode
int 10h

mov bh,0h ;set page num to 0
mov al,[bp+6] ;set color to red
mov cx,[bp+4] ;set x cor to xpos 
mov dx,[bp+2] ;set y cor to ypos
mov ah,0ch ;write pixel

dec cx ;to stop the first inc in the loops
dec dx
xor di,di ;si and di will be the counters
xor si,si
mov si,3
mov di,3

@pixely:
inc dx
@pixelx:
inc cx
int 10h
dec si
jnz @pixelx ;draw a row

sub cx,3
mov si,3
dec di
jnz @pixely ;draw the row 3 times


ret 6 
endp drawpixel

proc drawplayer
mov bp,sp
xor ax,ax
mov ax,[bp+4] ;the y cordinate
mov bx,[bp+2] ;the x cordinate
mov dx,4
add bx,1     ;setting the cordinate of the corner of the head 
sub ax,8
push dx
push bx
push ax
call drawpixel

ret 4
endp drawplayer




start:
        mov ax, @data
        mov ds, ax
; --------------------------
xor ax,ax
mov ax,100
push ax
mov ax,160
push ax
call drawplayer
xor ax,ax
mov ax,bufferseg
mov es,ax
assume es:bufferseg
mov ax,13h ;switch to video mode
int 10h
mov ax,[y]
mov dx,320
mul dx               ;dx:ax = y * 320
mov di,[x]           ;di = x
add di,ax            ;di = y * 320 + x
;lea bx,[buffer]   ;bx = segment of video buffer
;mov es,bx            ;es:di = address of pixel
mov al,[c]           ;al = colour
mov [es:di],al       ;Store colour in buffer at (x,y)

mov ax,bufferseg
mov ds,ax              ;ds = segment for buffer
;lea si,[buffer]              ;si:si = address for buffer
xor si,si
mov ax,0A000h          ;ax = segment for display memory
mov di,ax              ;di = segment for display memory
mov es,ax              ;es:di = address for display memory
mov cx,320*200/2       ;cx = number of words to copy
cld                    ;Make sure direction flag is clear
rep movsw              ;Copy 320*200/2 words from buffer to display memory
; --------------------------

        
exit:
        mov ax, 4c00h
        int 21h
END start
