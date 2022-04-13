IDEAL
MODEL compact
STACK 100h
DATASEG
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
wall dw ?
pcor dw  ?  ; coordinates for player
pcorbackup dw ? ; Backup of pcor
laser dw ?
maxhealth dw 3  ;the max amount of health the player can have
health dw 3     ;how much health the player has now
pcolor dw 4
pdir dw 3       ;the direction of the player
dtimer dw 0
FARDATA bufferseg ;the buffer
buffer db 64000 dup(12h)


;r	project.asm	/^$/;"	l 

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~
;           macros

macro callrect p1,p2
push ax
push di
push p1
push p2
call drawrect
pop di
pop ax
endm callrect

macro pixel p1,p2
push ax
push cx
push bx
push p1
push p2
call rect2x2
pop bx
pop cx
pop ax
endm pixel

macro calc p1,p2,p3
push ax
push cx
push bx
push offset p1
push p2
push p3
call coordinatecalc
pop bx
pop cx
pop ax
endm calc

macro callplayer p1
push ax
push cx
push di
push bx
push p1
push [pdir]
call player
pop bx
pop di
pop cx
pop ax
endm callplayer

macro pclear p1,p2
push ax
push di
push bx
push p1
push p2
call clearplayer
pop bx
pop di
pop ax
endm pclear

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

;draw a rectangle using the coordinate as the top left pixel - currently broken
proc drawrect
mov bp,sp ;Freeze the stack pointer
xor ax,ax ;Set ax,bx,si,di to 0
xor cx,cx
xor di,di
mov di,[bp+4] ;di = coordinate
mov al,[bp+2] ;al = color
sub di,317    ;Subtract from ax 317 to neutrlize the first add and inc
mov cl,4
@outerrectloop:
add di,320
sub di,4
mov ch,4
@innerrectloop:
inc di
mov [byte ptr es:di],al ;move al into the buffer
dec ch
jnz @innerrectloop
dec cl
jnz @outerrectloop
ret 4
endp drawrect

proc rect2x2
mov bp,sp ;Freeze the stack pointer
xor ax,ax ;Set di,ax,cx to 0
xor cx,cx
xor di,di
mov di,[bp+4] ;di = coordinate
mov al,[bp+2] ;al = color
sub di,319    ;Subtract from di 319 to neutrlize the first add and inc
mov cl,2
@outerrectloop1:
add di,318
mov ch,2
@innerrectloop1:
inc di
mov [es:di],al
dec ch
jnz @innerrectloop1
dec cl
jnz @outerrectloop1
ret 4
endp rect2x2

;procedure to draw the player lives on screen
proc lives
mov bp,sp
mov ax,[bp+2]
mov bx,[bp+4]
calc wall 10 10  ;calc the coordinates of the hearts
cmp bx,ax   ;check if player has max health
je @redlives
mov cx,[wall]
@emptylives:
pixel cx 15 ; draw max health of empty hearts
add cx,5
dec bx
jnz @emptylives
@redlives:
pixel [wall] 4 ; draw health amount of red hearts
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



; draw the player character, each proc draws the player from a different side
proc drawfrontplayer
mov bp,sp
mov di,[bp+2]
mov cx,3
@fronthair:
inc di
mov [byte ptr es:di],6h
dec cx
jnz @fronthair
add di,318
mov [byte ptr es:di],28h
inc di
mov [byte ptr es:di],0Fh
inc di
mov [byte ptr es:di],28h
add di,317
mov cx,3
@frontface:
inc di
mov [byte ptr es:di],42h
dec cx
jnz @frontface
add di,317
mov [byte ptr es:di],77h
mov [byte ptr es:di+4],77h
mov ch,2
mov [byte ptr es:di+324],43h
mov [byte ptr es:di+320],43h

@frontshirt1:
mov cl,3
@frontshirt2:
inc di
mov [byte ptr es:di],02h
dec cl
jnz @frontshirt2
add di,317
dec ch
jnz @frontshirt1
inc di
mov [byte ptr es:di],20h
mov [byte ptr es:di+1],20h
mov [byte ptr es:di+2],01h
add di,320
mov [byte ptr es:di],00h
mov [byte ptr es:di+2],00h

ret 2
endp drawfrontplayer

proc drawbackplayer
mov bp,sp
mov di,[bp+2]
mov ch,2
@backhair1:
mov cl,3
@backhair2:
inc di
mov [byte ptr es:di],6h
dec cl
jnz @backhair2
add di,317
dec ch
jnz @backhair1
mov cl,3
@scalp:
inc di
mov [byte ptr es:di],43h
dec cl
jnz @scalp
add di,317
mov [byte ptr es:di],77h
mov [byte ptr es:di+4],02h
mov [byte ptr es:di+320],43h
mov [byte ptr es:di+324],43h
mov ch,2
@backshirt1:
mov cl,3
@backshirt2:
inc di
mov [byte ptr es:di],02h
dec cl
jnz @backshirt2
add di,317
dec ch
jnz @backshirt1
inc di
mov [byte ptr es:di],20h
mov [byte ptr es:di+1],20h
mov [byte ptr es:di+2],01h
add di,320
mov [byte ptr es:di],00h
mov [byte ptr es:di+2],00h

ret 2
endp drawbackplayer

proc drawrightplayer
mov bp,sp
mov di,[bp+2]
mov cl,3
@righthair:
inc di
mov [byte ptr es:di],6h
dec cl
jnz @righthair
add di,318
mov [byte ptr es:di],6h
inc di
mov [byte ptr es:di],60h
inc di
mov [byte ptr es:di],4h
add di,317
mov cl,3
@rightface:
inc di
mov [byte ptr es:di],42h
dec cl
jnz @rightface
mov cl,3
add di,317
@rightshirt:
inc di
mov [byte ptr es:di],02h
dec cl
jnz @rightshirt
add di,318
mov [byte ptr es:di],02h
inc di
mov [byte ptr es:di],77h
inc di
mov [byte ptr es:di],77h
inc di
mov [byte ptr es:di],42h
add di,317
mov [byte ptr es:di],01h
inc di
mov [byte ptr es:di],20h
inc di
mov [byte ptr es:di],20h
add di,318
mov [byte ptr es:di],00h
mov [byte ptr es:di+2],00h

ret 2
endp drawrightplayer

proc drawleftplayer
mov bp,sp
mov di,[bp+2]
mov cl,3
@lefthair:
inc di
mov [byte ptr es:di],6h
dec cl
jnz @lefthair
add di,318
mov [byte ptr es:di],4h
inc di
mov [byte ptr es:di],60h
inc di
mov [byte ptr es:di],6h
add di,317
mov cl,3
@leftface:
inc di
mov [byte ptr es:di],42h
dec cl
jnz @leftface
mov cl,3
add di,317
@leftshirt:
inc di
mov [byte ptr es:di],02h
dec cl
jnz @leftshirt
add di,317
mov [byte ptr es:di],42h
inc di
mov [byte ptr es:di],77h
inc di
mov [byte ptr es:di],77h
inc di
mov [byte ptr es:di],02h
add di,318
mov [byte ptr es:di],20h
inc di
mov [byte ptr es:di],20h
inc di
mov [byte ptr es:di],01h
add di,318
mov [byte ptr es:di],00h
mov [byte ptr es:di+2],00h

ret 2
endp drawleftplayer

proc player
mov bp,sp
push [bp+4]
mov cx,[bp+2] ;cx is the direction of the player
cmp cx,2  ; 0 is left, 1 is up, 2 is right, 3 is down
jcxz @pdirleft
jg @pdirdown
je @pdirright
jb @pdirup
@pdirleft:
call drawleftplayer
jmp @pdend
@pdirdown:
call drawfrontplayer
jmp @pdend
@pdirright:
call drawrightplayer
jmp @pdend
@pdirup:
call drawbackplayer
jmp @pdend

@pdend:
ret 4
endp player

;player is 7x5
proc clearplayer
mov bp,sp
mov di,[bp+4]
mov al,[bp+2]
mov ch,8
@clearloop1:
mov cl,8
@clearloop2:
mov [byte ptr es:di],al
inc di
dec cl
jnz @clearloop2
add di,312
dec ch
jnz @clearloop1

ret 4
endp clearplayer

proc lvl1
life
calc pcor 100 160
callplayer [pcor]
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
;push [laser]
;call drawleftplayer


@waitforkey:
call buffertoscreen
mov ah,1            
int 16h             ;Check if there's input in the buffer
jz @waitforkey
mov ah,0           
int 16h             ;Get the input and clean the buffer 
pclear [pcor] 12h 
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
callplayer [pcor]
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
mov di,[pcor]
inc di
cmp [byte ptr es:di],06h
je @lever
@lever:



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
callplayer [pcor]
jmp @waitforkey

@collisionfound:
cmp [byte ptr es:di],9
jne @stopmovement
dec [health]
jz exit
life
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
