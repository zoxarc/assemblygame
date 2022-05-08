IDEAL
MODEL compact
STACK 100h
DATASEG
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
currentlvl db ?
seed dw ?
wall dw ?
pcor dw  ?  ; coordinates for player
pcorbackup dw ? ; Backup of pcor
upcor db ?,?
maxhealth dw 20  ;the max amount of health the player can have
health dw 20     ;how much health the player has now
pdir dw 2       ; 0 is left, 1 is up, 2 is right, 3 is down
mainmsg db 'choose a level: ','$'
mainin db ?
lasert dw 0
laser db 50 dup(0)
uenemy db ?,?
enemy db 100 dup(0)
enemyt db 100 dup(0)
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

macro rcalc p1,p2
push ax
push bx
push offset p1
push p2
call revcoordinatecalc
pop bx
pop ax
endm rcalc

macro player p1
push ax
push cx
push di
push bx
push p1
push [pdir]
call cplayer
pop bx
pop di
pop cx
pop ax
endm player

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

macro horline p1,p2,p3
push ax
push bx
push cx
push p1
push p2
push p3
call drawhorline
pop cx
pop bx
pop ax
endm horline

macro verline p1,p2,p3
push ax
push bx
push cx
push p1
push p2
push p3
call drawverline
pop cx
pop bx
pop ax
endm verline

macro hashp p1
push ax
push bx
push p1
call hash
pop bx
pop ax
endm hashp

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~

CODESEG
;            procedures

proc mainmenu
mov al,03h
mov ah,0
int 10h
lea dx,[mainmsg]
mov ah,9h
int 21h
mov ah,01h
int 21h
sub al,'0'
mov [currentlvl],al
ret
endp mainmenu

proc endprogram
mov al,03h
mov ah,0
int 10h
mov ax, 4c00h
int 21h
ret
endp endprogram


;Copy everything in the buffer to display memory
proc buffertoscreen    
mov ax,bufferseg      
mov ds,ax              ;ds = segment for buffer
xor si,si              ;si = address for buffer copy
xor di,di
mov ax,0A000h          
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

proc clearscreen
xor di,di
mov cx,32000
mov ax,1212h
cld
rep stosw
ret
endp clearscreen

proc reset
call clearscreen
call buffertoscreen
ret
endp reset

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

proc revcoordinatecalc
mov bp,sp
mov bl,[bp+2]
mov ax,320
div bl
mov bx,[bp+4]
mov [bx],ah
mov [bx+2],al
ret 4
endp revcoordinatecalc

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
mov ax,[health]
mov bx,[maxhealth]
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
ret 
endp lives


proc hitdetected
pixel [pcor] 28h
ret
endp hitdetected

proc mlaser
xor si,si
mov si,1
mov ah,[byte ptr laser]
cmp ah,0
je @lend1
@laserload:
mov di,[word ptr laser+si]
mov al,[byte ptr laser+si+2]
cmp al,1
je @laserup
jz @laserside
@laserside:
dec di
mov [byte ptr es:di],12h
add di,2
cmp [byte ptr es:di],12h
je @sidecontinue
push di
dec di
jne @laserhit
@sidecontinue:
mov [byte ptr es:di],36h
mov [word ptr laser+si],di
mov di,[word ptr laser+si+3]
mov [byte ptr es:di-1],15
mov [byte ptr es:di],15
jmp @laserend

@laserup:
sub di,320
mov [byte ptr es:di],12h
add di,640
cmp [byte ptr es:di],12h
je @upcontinue
push di
sub di,320
jne @laserhit
@upcontinue:
mov [byte ptr es:di],36h
mov [word ptr laser+si],di
mov di,[word ptr laser+si+3]
mov [byte ptr es:di-320],15
mov [byte ptr es:di],15
jmp @laserend

@laserhit:
mov [byte ptr es:di],12h
mov bx,[word ptr laser+si+3]
mov [word ptr laser+si],bx
call laserck

@laserend:
add si,5
dec ah
@lend1:
jnz @laserload
ret 
endp mlaser

proc laserck
mov bp,sp
mov di,[bp+2]
cmp [byte ptr es:di],15
je @lackend

dec [health]
jz @lad
push ax
call lives
pop ax
jmp @lackend

@lad:
jmp exit

@lackend:
ret 2
endp laserck

; enemy ai
; [num of enemies , e1 location , e1 dir ,e1 dtimer, e1 dis, e1 state , e1 health  ...]
;       0               1            3        4        5        6          7       
proc enemyai
xor si,si
xor di,di
xor cx,cx
sub si,2
sub di,8
mov ch,[enemy]
@enemytimer:
cmp ch,0
je @aiend
dec ch
add si,2
add di,8
inc [word ptr enemyt+si]
cmp [word ptr enemyt+si],100h
jne @enemytimer
mov [word ptr enemyt+si],0

call epatrol
mov ax,di
mov di,[word ptr enemy+di+1]
mov [byte ptr es:di],4h
mov di,ax

@aisemiend:
jmp @enemytimer
@aiend:
ret
endp enemyai

proc epatrol
cmp [byte ptr enemy+di+4],0
je @changeedir
jmp @ewalk

@changeedir:
mov al,3
sub al,[byte ptr enemy+di+3]
mov [byte ptr enemy+di+3],al
mov cl,[byte ptr enemy+di+5]
mov [byte ptr enemy+di+4],cl

@ewalk:
dec [byte ptr enemy+di+4]
push cx
xor cx,cx
mov cl,[byte ptr enemy+di+3]
cmp cx,2
jcxz @eleft
jb @eup
ja @eright
je @edown

@eleft:
sub [word ptr enemy+di+1],2
jmp @endpatrol

@eup:
sub [word ptr enemy+di+1],640
jmp @endpatrol

@eright:
add [word ptr enemy+di+1],2
jmp @endpatrol

@edown:
add [word ptr enemy+di+1],640
jmp @endpatrol


@endpatrol:
pop cx
ret 
endp epatrol

proc searchforplayer
rcalc upcor [pcor]
rcalc uenemy word ptr enemy+di+1
mov ax,[word ptr uenemy]
cmp [word ptr upcor],ax
je @xspotted
mov ax,[word ptr uenemy+2]
cmp [word ptr upcor+2],ax
je @yspotted
jmp @endpatrol

@xspotted:
mov ax,[word ptr uenemy+2]
cmp ax,[word ptr upcor+2]
jg @ygreater
@ygreater:
sub ax,[word ptr upcor+2]
cmp ax,10
jg @endsearch
mov [byte ptr enemy+di+3],3



@endsearch:
ret
endp searchforplayer

; draw the player character, each proc draws the player from a different side
proc drawfrontplayer
mov bp,sp
mov di,[bp+2]
add di,2
mov [byte ptr es:di],4
add di,318
mov cx,3
@fronthat:
inc di
mov [byte ptr es:di],28h
dec cx
jnz @fronthat
add di,317
mov cx,4
@fronthair:
inc di
mov [byte ptr es:di],52h
dec cx
jnz @fronthair
add di,317
mov [byte ptr es:di],5h
inc di
mov [byte ptr es:di],0Fh
inc di
mov [byte ptr es:di],5h
mov [byte ptr es:di+2],52h
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
add di,2
mov [byte ptr es:di],4
add di,318
mov ch,3
mov al,28h
mov ah,52h
mov cl,3
mov [byte ptr es:di+324],52h
mov [byte ptr es:di+645],52h
@backhair:
inc di
mov [byte ptr es:di],al
dec cl
jnz @backhair
add di,317
mov al,ah
mov ah,6h
mov cl,3
dec ch
jnz @backhair
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
add di,3
mov [byte ptr es:di],4h
add di,318
mov cl,3
mov ch,2
mov ah,52h
mov al,28h

@righthair:
inc di
mov [byte ptr es:di],al
dec cl
jnz @righthair
add di,317
mov al,52h
mov cl,3
dec ch
jnz @righthair

mov [byte ptr es:di-320],52h
mov [byte ptr es:di-1],52h
inc di
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
add di,2
mov [byte ptr es:di],4
add di,318
mov al,28h
mov cl,3
mov ch,2
@lefthair:
inc di
mov [byte ptr es:di],al
dec cl
jnz @lefthair
add di,317
mov al,52h
mov cl,3
dec ch
jnz @lefthair
inc di
mov [byte ptr es:di-317],52h
mov [byte ptr es:di+4],52h
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

proc cplayer
mov bp,sp
mov si,[bp+4]
push [bp+4]
mov cx,[bp+2] ;cx is the direction of the player
cmp cx,2  
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
mov [byte ptr es:si],4
ret 4
endp cplayer

;player is 9x6
proc clearplayer
mov bp,sp
mov di,[bp+4]
mov al,[bp+2]
mov ch,9
@clearloop1:
mov cl,6
@clearloop2:
mov [byte ptr es:di],al
inc di
dec cl
jnz @clearloop2
add di,314
dec ch
jnz @clearloop1

ret 4
endp clearplayer


proc hash
mov bp,sp
xor ax,ax
mov bx,[bp+2]
mov al,bl
not al
mul bl
xor ax,bx
div bx
mov bx,35h
mul bl
mov [seed],ax

ret 2
endp hash

proc drawhorline
mov bp,sp
mov ax,[bp+6]
xor bx,bx
mov bl,[bp+4]
mov cl,[bp+2]
@horloop:
pixel ax bx
add ax,2
dec cl
jnz @horloop

ret 6
endp drawhorline

proc drawverline
mov bp,sp
mov ax,[bp+6]
xor bx,bx
mov bl,[bp+4]
mov cl,[bp+2]
@verloop:
pixel ax bx
add ax,640
dec cl
jnz @verloop

ret 6
endp drawverline

;180 20 , 20 20
proc drawlvlframe
call lives
player [pcor]
calc wall 20 20
mov cx,280
frameloop1:
pixel [wall] 15
inc [wall]
dec cx
jnz frameloop1 
mov cx,160
frameloop2:
pixel [wall] 15
add [wall],320
dec cx
jnz frameloop2
mov cx,280
frameloop3:
pixel [wall] 15
dec [wall]
dec cx
jnz frameloop3
mov cx,160
frameloop4:
pixel [wall] 15
sub [wall],320
dec cx
jnz frameloop4

ret
endp drawlvlframe

proc selectlvl
call clearscreen
cmp [currentlvl],2
je @selectlvl2
jb @selectlvl1
cmp [currentlvl],235
jne @lvlsend
call endprogram
@selectlvl1:
call lvl1
jmp @lvlsend
@selectlvl2:
call lvl2
jmp @lvlsend

@lvlsend:
ret
endp selectlvl

proc lvl1
calc pcor 25 25
call drawlvlframe
calc wall 40 20
mov cx,30
@lvl1wall1:
pixel [wall] 15
add [wall],2
dec cx
jnz @lvl1wall1

calc wall 20 120 
pixel [wall] 4
mov cx,60
@lvl1wall2:
pixel [wall] 15
add [wall],640
dec cx
jnz @lvl1wall2

calc wall 42 78 
mov cx,69
@lvl1wall3:
pixel [wall] 9
add [wall],640
dec cx
jnz @lvl1wall3


calc wall 42 130 
mov cx,30
@lvl1wall4:
pixel [wall] 9
add [wall],2
dec cx
jnz @lvl1wall4
pixel [wall] 15
sub [wall],62
mov cl,4
@lvl1wall5:
pixel [wall] 15
sub [wall],2
dec cl
jnz @lvl1wall5
calc wall 42 190
pixel [wall] 15

calc wall 42 298 
mov cl,4
@lvl1wall6:
pixel [wall] 15
sub [wall],2
dec cl
jnz @lvl1wall6
mov cx,30
@lvl1wall7:
pixel [wall] 9
sub [wall],2
dec cx
jnz @lvl1wall7
pixel [wall] 15
calc wall 28 260
pixel [wall] 30h

mov [byte ptr laser],2
calc lasert 139 120
mov di,[lasert]
mov [word ptr laser+1],di
mov [word ptr laser+4],di
mov [byte ptr laser+3],1
inc di
mov [word ptr laser+6],di
mov [word ptr laser+9],di
mov [byte ptr laser+8],1
mov [lasert],0
mov [byte ptr enemy],1
mov [word ptr enemy+1],di
mov [byte ptr enemy+17],1
mov [byte ptr enemy+25],8
mov [byte ptr enemy+33],8
ret 
endp lvl1

proc lvl2
calc pcor 170 22
call drawlvlframe
mov [byte ptr laser],0
mov [lasert],0
calc wall 168 22
;horline [wall] 9 10
calc wall 100 100
mov di,[wall]
mov [byte ptr enemy],1
mov [word ptr enemy+1],di
mov [byte ptr enemy+4],1
mov [byte ptr enemy+3],3
mov [byte ptr enemy+5],8
mov [byte ptr enemy+6],8

ret
endp lvl2


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~

start:
mov ax, @data   
mov ds, ax           ;ds = segment for data
mov ax,bufferseg 
mov es,ax            ;es = segment for buffer
assume es:bufferseg  ;bind es to bufferseg

call mainmenu
mov ax,13h    
int 10h              ;switch to mode 13h

call selectlvl            ;generate level 1

@waitforkey:
call buffertoscreen
inc [lasert]
call enemyai
cmp [lasert],100h
jne @waitforkey2
call mlaser
mov [lasert],0
@waitforkey2:
mov ah,1            
int 16h             ;Check if there's input in the buffer
jz @waitforkey
mov ah,0           
int 16h             ;Get the input and clean the buffer 
pclear [pcor] 12h 
mov bx,[pcor]
mov [pcorbackup],bx ;save the current location of the player in case there's a collision
xor bx,bx
cmp ah,11h          ;find if the input matches w,a,s,d,esc
je @wpressed
cmp ah,1fh
je @spressed
cmp ah,1eh
je @apressed
cmp ah,20h
je @dpressed
cmp ah,39h
je @interact

cmp ah,1h           
je @exitcp
player [pcor]
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
call mainmenu

@interact:
call selectlvl
jmp @waitforkey



@collisioncheck:
mov di,[pcor]
mov cl,6
mov ch,2

@topck:
cmp [byte ptr es:di],12h
jne @collision2ck
inc di
dec cl
jnz @topck
mov cl,6
add di,2554
dec ch
jnz @topck
mov di,[pcor]
mov cl,9
mov ch,2
@sideck:
cmp [byte ptr es:di],12h
jne @collision2ck
add di,320
dec cl
jnz @sideck
mov cl,9
sub di,2875
dec ch
jnz @sideck
jmp @moveplayer

@moveplayer:
player [pcor]
jmp @waitforkey

@collision2ck:
cmp bl,0
jg @collisionfound
mov di,[pcor]
mov cx,[pdir]
cmp cx,2
je @ckright
jcxz @ckleft
jb @ckup
js @ckdown
@ckright:
dec di
jmp @ck2e
@ckleft:
inc di
jmp @ck2e
@ckup:
add di,320
jmp @ck2e
@ckdown:
sub di,320
jmp @ck2e

@ck2e:
inc bl
mov [pcor],di
jmp @collisioncheck


@collisionfound:
cmp [byte ptr es:di],30h
je @goalreached
cmp [byte ptr es:di],31h
je @heal
cmp [byte ptr es:di],9
jne @stopmovement
dec [health]
jz exit
call lives
@stopmovement:
mov ax,[pcorbackup]
mov [pcor],ax
jmp @moveplayer

@heal:
mov ax,[maxhealth]
cmp [health],ax
jge @stopmovement
inc [health]
mov [byte ptr es:di],12h
call lives
jmp @stopmovement

@goalreached:
mov [byte ptr laser],0
call clearscreen
inc [currentlvl]
call selectlvl
jmp @waitforkey




; --------------------------

        
exit:
mov al,03h
mov ah,0
int 10h
mov ax, 4c00h
int 21h
END start
