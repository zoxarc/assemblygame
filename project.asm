IDEAL
MODEL compact
STACK 100h
DATASEG
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
wall dw ?
pcor dw  ?  ; coordinates for player
pcorbackup dw ? ; Backup of pcor
laser dw ?
maxhealth dw 3
health dw 3
pcolor dw 4
pdir dw ?
dtimer dw 0
FARDATA bufferseg ;the buffer
buffer db 64000 dup(12h)

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~
;           macros

macro callpixel p1,p2
push ax
push di
push p1
push p2
call pixeltobuffer
pop di
pop ax
endm callpixel

macro callrect p1,p2
push ax
push p1
push p2
call drawrect
pop ax
endm callrect

macro pixel p1,p2
push ax
push bx
push p1
push p2
call rect2x2
pop bx
pop ax
endm pixel

macro calc p1,p2,p3
push ax
push bx
push offset p1
push p2
push p3
call coordinatecalc
pop bx
pop ax
endm calc

macro callplayer p1,p2,p3
push ax
push bx
push p1
push p2
push p3
call drawplayer
pop bx
pop ax
endm callplayer

macro life
push ax
push bx
push [maxhealth]
push [health]
call lives
pop bx
pop ax
endm life

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~

CODESEG
;            procedures
proc pixeltobuffer   ;First push y second x third color
mov bp,sp            ;Freeze the stack pointer
xor ax,ax            ;Reset ax and di
xor di,di
mov di,[bp+4]        ;di = calculated coordinates 
mov al,[bp+2]        ;al = colour
mov [es:di],al       ;Store colour in buffer at (x,y)
ret 4
endp pixeltobuffer

;Copy everything in the buffer to display memory
proc buffertoscreen    
mov ax,bufferseg      
mov ds,ax              ;ds = segment for buffer
xor si,si              ;si = address for buffer copy
mov ax,0A000h          
mov di,ax              ;di = address for display memory
xor di,di
mov es,ax              ;es = segment for display memory
mov cx,32000       ;cx = number of words to copy
cld                    ;Make sure direction flag is clear
rep movsw              ;Copy 320*200/2 words from ds:si to es:di
mov ax, @data          
mov ds, ax             ;ds = segment for data
mov ax, bufferseg
mov es,ax              ;es = segment for buffer
ret
endp buffertoscreen

;draw a rectangle using the coordinate as the top left pixel
proc drawrect 
mov bp,sp ;Freeze the stack pointer
xor ax,ax ;Set ax,bx,si,di to 0
xor bx,bx
xor si,si
xor di,di
mov ax,[bp+4] ;ax = coordinate
mov bx,[bp+2] ;bx = color
sub ax,320    ;Subtract from ax 317 to neutrlize the first add and inc
add ax,3
mov di,4
@outerrectloop:
add ax,320
sub ax,4
mov si,4
@innerrectloop:
inc ax
callpixel ax bx 
dec si
jnz @innerrectloop
dec di
jnz @outerrectloop
ret 4
endp drawrect

proc rect2x2
mov bp,sp ;Freeze the stack pointer
xor ax,ax ;Set ax,bx,si,di to 0
xor bx,bx
xor si,si
xor di,di
mov ax,[bp+4] ;ax = coordinate
mov bx,[bp+2] ;bx = color
sub ax,320    ;Subtract from ax 317 to neutrlize the first add and inc
add ax,1
mov di,2
@outerrectloop1:
add ax,320
sub ax,2
mov si,2
@innerrectloop1:
inc ax
callpixel ax bx 
dec si
jnz @innerrectloop1
dec di
jnz @outerrectloop1
ret 4
endp rect2x2

proc lives
mov bp,sp
mov ax,[bp+2]
mov bx,[bp+4]
calc wall 10 10
cmp bx,ax
je @redlives
mov cx,[wall]
@emptylives:
pixel cx 15
add cx,5
dec bx
jnz @emptylives
@redlives:
pixel [wall] 4
add [wall],5
dec ax
jnz @redlives
@livesend:
ret 4
endp lives

proc coordinatecalc
mov bp,sp
mov bx,[bp+6]        ;bx = address for return
mov ax,[bp+4]        ;ax = y coordinate
mov dx,320           
mul dx               ;dx:ax = y * 320
mov di,[bp+2]        ;di = x coordinate
add di,ax            ;di = y * 320 + x
mov [bx],di          ;Set the variable at [bx] to di
ret 6
endp coordinatecalc

proc hitdetected
pixel [pcor] 28h
ret
endp hitdetected

; 0 is left, 1 is up, 2 is right, 3 is down
proc direction
mov bp,sp
mov cx,[bp+2]
mov ax,[bp+4]
cmp cx,2
jcxz @leftcp
ja @dirdown
je @dirright
jb @dirup
@leftcp:
jmp @dirleft
@dirdown:
add ax,320
callpixel ax 0Ah
inc ax
callpixel ax 0Ah
jmp @dirend
@dirright:
inc ax
callpixel ax 0Ah
add ax,320
callpixel ax 0Ah
jmp @dirend
@dirup:
callpixel ax 0Ah
inc ax
callpixel ax 0Ah
jmp @dirend
@dirleft:
callpixel ax 0Ah
add ax,320
callpixel ax 0Ah

@dirend:
ret 4
endp direction

proc lvl1
calc pcor 100 160
pixel [pcor] [pcolor]
life
calc wall 20 20
mov cx,280
lvl1loop1:
pixel [wall] 15
inc [wall]
dec cx
jnz lvl1loop1 
mov cx,160
lvl1loop2:
pixel [wall] 15
add [wall],320
dec cx
jnz lvl1loop2
mov cx,280
lvl1loop3:
pixel [wall] 15
dec [wall]
dec cx
jnz lvl1loop3
mov cx,160
lvl1loop4:
pixel [wall] 15
sub [wall],320
dec cx
jnz lvl1loop4

calc wall 28 260
pixel [wall] 06h

ret 
endp lvl1


proc mlaser
mov bp,sp
ret 4
endp mlaser

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~

start:
mov ax, @data   
mov ds, ax           ;ds = segment for data
mov ax,bufferseg 
mov es,ax            ;es = segment for buffer
assume es:bufferseg  ;bind es to bufferseg
mov ax,13h    
int 10h              ;switch to mode 13h

call lvl1            ;generate level 1

calc laser 100 100
pixel [laser] 9


@waitforkey:
call buffertoscreen
mov ah,1            
int 16h             ;Check if there's input in the buffer
jz @waitforkey
mov ah,0           
int 16h             ;Get the input and clean the buffer 
pixel [pcor] 12h 
mov bx,[pcor]
mov [pcorbackup],bx ;save the current location of the player in case there's a collision
cmp ah,11h          ;find if the input matches w,a,s,d,esc
je @wpressed
cmp ah,1fh
je @spressed
cmp ah,1eh
je @apressed
cmp ah,20h
je @dpressed
cmp ah,0B9h
je @interact

cmp ah,1h           
je @exitcp
pixel [pcor] [pcolor] 
jmp @waitforkey

@wpressed:
sub [pcor],640     ;move the player 2 pixels up 
mov [pdir],1
jmp @collisioncheck

@spressed:
add [pcor],640     ;move the player 2 pixels down
mov [pdir],3
jmp @collisioncheck

@dpressed:
add [pcor],2       ;move the player 2 right
mov [pdir],2
jmp @collisioncheck

@apressed:
sub [pcor],2       ;move the player 2 left 
mov [pdir],0
jmp @collisioncheck

@exitcp:
jmp exit           ;checkpoint for exit

@interact:

@collisioncheck:
mov di,[pcor]
cmp [byte ptr es:di],12h
jne @collisionfound
inc di
cmp [byte ptr es:di],12h
jne @collisionfound
add di,320
cmp [byte ptr es:di],12h
jne @collisionfound
dec di
cmp [byte ptr es:di],12h
jne @collisionfound
sub di,320
cmp [byte ptr es:di],12h
jne @collisionfound
;@@collisioncheck:
;cmp [byte ptr es:di],0
;jne @collisionfound
;mov cl,6
;@@innercc:
;add di,320
;cmp [byte ptr es:di],0
;jne @collisionfound
;dec cl
;jnz @@innercc
;mov cl,3
;@@outercc:
;inc di
;cmp [byte ptr es:di],0
;jne @collisionfound
;dec cl
;jnz @@outercc
;sub di,1280
;mov cl,6
;@@collisioncheck1:
;add di,320
;cmp [byte ptr es:di],0
;jne @collisionfound
;dec cl
;jnz @@collisioncheck1



@moveplayer:
pixel [pcor] [pcolor] 
push [pcor]
push [pdir]
call direction
jmp @waitforkey

@collisionfound:
cmp [byte ptr es:di],9
jne @stopmovement
dec [health]
jz exit
life
mov [pcolor],02h
@stopmovement:
mov ax,[pcorbackup]
mov [pcor],ax
jmp @moveplayer




; --------------------------

        
exit:
mov al,03h
mov ah,0
int 10h
mov ax, 4c00h
int 21h
END start
