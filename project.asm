﻿IDEAL
MODEL compact
STACK 100h
DATASEG
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
currentlvl db 2
seed dw ?
oseed dw ?
sseed db ?
filename db 'save.txt',0
filebuffer db 6 dup(?)
score dw 0
wall dw ?
pcor dw  ?  ; coordinates for player
pcorbackup dw ? ; Backup of pcor
upcor db ?,?
maxhealth dw 20  ;the max amount of health the player can have
health dw 20     ;how much health the player has now
pdir dw 2       ; 0 is left, 1 is up, 2 is right, 3 is down
mainmsg db 'load existing save? (y or n):','$'
scoremsg db 'your score is:','$'
endmsg db 'press any key to continue','$'
mainin db ?
inttostr db 6 dup(?)
rinttostr db 6 dup(?)
lasert dw 0
laser db 500 dup(0)
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
push di
push p1
push p2
call rect2x2
pop di
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
push di
push p1
push p2
push p3
call drawhorline
pop di
pop cx
pop bx
pop ax
endm horline

macro verline p1,p2,p3
push ax
push bx
push cx
push di
push p1
push p2
push p3
call drawverline
pop di
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

macro setlaser p1,p2
push si
push ax
push p1
push p2
call setlaserproc
pop ax
pop si
endm setlaser

macro strint p1
push offset strtoint
push p1
call stringtointeger
endm strint

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
cmp al,'y'
je @lfile
jne @nofile
@lfile:
call fileload
cmp [oseed],0
je @nofile
call selectlvl
jmp @mainend
@nofile:
call entropy
call selectlvl
@mainend:
mov ax,13h    
int 10h              ;switch to mode 13h
ret
endp mainmenu

proc endprogram
mov al,03h
mov ah,0
int 10h
call displayscore
mov ax, 4c00h
int 21h
ret
endp endprogram

proc integertostring
mov bp,sp
push ax
push bx
push cx
push di
push si
mov ax,[bp+2]
xor si,si
xor di,di
inc si
mov bl,10
@divide:
div bl
add ah,'0'
mov [inttostr+si],ah
xor ah,ah
inc si
test al,al
jnz @divide
@reverse:
mov ah,[inttostr+si]
mov [rinttostr+di],ah
inc di
dec si
jnz @reverse
mov [rinttostr+di],'$'
pop si
pop di
pop cx
pop bx
pop ax
ret 2
endp integertostring

proc displayscore
lea dx,[scoremsg]
mov ah,9h
int 21h
push [score]
call integertostring
lea dx,[rinttostr]
mov ah,09h
int 21h
ret
endp displayscore


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


proc filesave
@filestart:
lea dx,[filename]
mov al,1
mov ah,3Dh
int 21h
jc @nofilexits
jmp @saveinfo

@nofilexits:
xor cx,cx
mov cx,7
mov ah,3Ch
int 21h
jmp @filestart

@saveinfo:
xor dx,dx
mov bx,ax
mov cx,4
mov dx,[oseed]
mov [word ptr filebuffer],dx
xor dx,dx
mov dl,[currentlvl]
mov [word ptr filebuffer+2],dx
lea dx,[filebuffer]
mov ah,40h
int 21h
mov ah,3Eh
int 21h
ret
endp filesave

proc fileload
xor dx,dx
xor ax,ax
mov al,0
lea dx,[filename]
mov ah,3Dh
int 21h
jc @failload
mov bx,ax
lea dx,[filebuffer]
mov cx,4
mov ah,3Fh
int 21h
mov ax,[word ptr filebuffer]
mov [oseed],ax
xor ax,ax
mov ax,[word ptr filebuffer+2]
mov [currentlvl],al
mov ah,3Eh
int 21h
jmp @endfileload
@failload:
mov [oseed],0
@endfileload:
ret
endp fileload

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


proc mlaser
push si
push cx
xor si,si
xor cx,cx
mov si,1
mov ah,[byte ptr laser]
cmp ah,0
je @_lend
@laserload:
mov di,[word ptr laser+si]
mov cl,[byte ptr laser+si+2]
cmp cx,2
jcxz @lcxz
je @laserup
jb @laserright
ja @laserleft
@laserright:
dec di
mov [byte ptr es:di],12h
add di,2
cmp [byte ptr es:di],12h
je @rightcontinue
push di
dec di
jne @laserhitjump
@rightcontinue:
mov [byte ptr es:di],36h
mov [word ptr laser+si],di
mov di,[word ptr laser+si+3]
mov [byte ptr es:di-1],15
mov [byte ptr es:di],15
jmp @laserend

@laserleft:
inc di
mov [byte ptr es:di],12h
sub di,2
cmp [byte ptr es:di],12h
je @leftcontinue
push di
inc di
jne @laserhitjump
@leftcontinue:
mov [byte ptr es:di],36h
mov [word ptr laser+si],di
mov di,[word ptr laser+si+3]
mov [byte ptr es:di+1],15
mov [byte ptr es:di],15
jmp @laserend

@laserhitjump:
jmp @laserhit

@_lend:
jmp @lend1

@_laserload:
jmp @laserload

@lcxz:
jmp @laserdown

@laserup:
add di,320
mov [byte ptr es:di],12h
sub di,640
cmp [byte ptr es:di],12h
je @upcontinue
push di
add di,320
jne @laserhitjump
@upcontinue:
mov [byte ptr es:di],36h
mov [word ptr laser+si],di
mov di,[word ptr laser+si+3]
mov [byte ptr es:di+320],15
mov [byte ptr es:di],15
jmp @laserend

@laserdown:
sub di,320
mov [byte ptr es:di],12h
add di,640
cmp [byte ptr es:di],12h
je @downcontinue
push di
sub di,320
jne @laserhit
@downcontinue:
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
jnz @_laserload
pop cx
pop si
ret 
endp mlaser

proc laserck
mov bp,sp
push si
push ax
push cx
push di
mov di,[bp+2]
cmp [byte ptr es:di],15
je @lackend
cmp [byte ptr es:di],9
je @lackend
cmp [byte ptr es:di],36h
je @lackend
cmp [byte ptr es:di],4
je @lackend
cmp [byte ptr es:di],30h
je @lackend
cmp [byte ptr es:di],31h
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
pop di
pop cx
pop ax
pop si
ret 2
endp laserck

proc setlaserproc
mov bp,sp
xor ax,ax
mov ax,5
mul [byte ptr laser]
mov si,ax
mov ax,[bp+4]
mov [word ptr laser+1+si],ax
mov [word ptr laser+4+si],ax
mov al,[bp+2]
mov [byte ptr laser+si+3],al
inc [byte ptr laser]
ret 4
endp setlaserproc

proc claser0
mov bp,sp
push di
mov di,[bp+2]
@lgen0:
pixel di 9
add di,2
cmp [byte ptr es:di+1],12h
je @lgen0
cmp [byte ptr es:di],12h
jne @clasere0
dec di
pixel di 9
@clasere0:
pop di
ret 2
endp claser0

proc claser1
mov bp,sp
push di
mov di,[bp+2]
@lgen1:
pixel di 9
sub di,640
cmp [byte ptr es:di],12h
je @lgen1
cmp [byte ptr es:di+320],12h
jne @clasere1
add di,320
pixel di 9
@clasere1:
pop di
ret 2
endp claser1

proc claser2
mov bp,sp
push di
mov di,[bp+2]
@lgen2:
pixel di 9
add di,640
cmp [byte ptr es:di],12h
je @lgen2
cmp [byte ptr es:di-320],12h
jne @clasere2
sub di,320
pixel di 9
@clasere2:
pop di
ret 2
endp claser2

proc claser3
mov bp,sp
push di
mov di,[bp+2]
@lgen3:
pixel di 9
sub di,2
cmp [byte ptr es:di],12h
je @lgen3
cmp [byte ptr es:di+1],12h
jne @clasere3
inc di
pixel di 9
@clasere3:
pop di
ret 2
endp claser3

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
push ax
push bx
push dx
xor ax,ax
xor dx,dx
mov bx,[bp+2]
mov al,bl
mov ah,bh
add ah,al
inc ax
mov bl,7
mul bl
inc ax
mov [seed],ax
pop dx
pop bx
pop ax

ret 2
endp hash

proc drawhorline
mov bp,sp
xor ax,ax
xor bx,bx
xor cx,cx
mov ax,[bp+6] ;ax coordinate
xor bx,bx
mov bl,[bp+4] ;bl color
mov cx,[bp+2] ;cl length
@horloop:
pixel ax bx
add ax,2
dec cx
jnz @horloop

ret 6
endp drawhorline

proc entropy
push ax
push bx
push cx
push dx
mov ah,2ch
int 21h
mov [byte ptr oseed],dl
mov [byte ptr seed],dl
pop dx
pop cx
pop bx
pop ax
ret
endp entropy

proc drawverline
mov bp,sp
mov ax,[bp+6] ;ax coor
xor bx,bx
mov bl,[bp+4] ;bl color
mov cx,[bp+2] ;cl length
@verloop:
pixel ax bx
add ax,640
dec cx
jnz @verloop

ret 6
endp drawverline

;180 20 , 20 20
proc drawlvlframe
call lives
calc wall 20 20
horline [wall] 15 141
verline [wall] 15 82
calc wall 20 302
verline [wall] 15 82
calc wall 182 20
horline [wall] 15 142

ret
endp drawlvlframe

proc selectlvl
call clearscreen
call drawlvlframe
mov cl,[byte ptr oseed]
mov [byte ptr seed],cl
mov cl,[currentlvl]
@hashloop:
push [seed]
call hash
dec cl
jnz @hashloop
mov [byte ptr laser],0
mov ch,[byte ptr seed]
mov [sseed],ch
mov [health],20
call lives
call filesave
call proceaduralgen

ret
endp selectlvl


proc drawshape
mov bp,sp
mov di,[bp+2]
horline di 15 35
sub di,12160
horline di 15 35
verline di 15 20

add di,68

verline di 15 20
ret 2
endp drawshape

proc drawshape1

ret 2
endp drawshape1


proc drawshape2
mov bp,sp
mov di,[bp+2]
sub di,9590
verline di 15 8
setlaser di 3
add di,1280
setlaser di 3
add di,1280
setlaser di 3
add di,1280
setlaser di 3
add di,1280
setlaser di 3

sub di,5100
verline di 15 8
push di
call claser3
mov [byte ptr es:di+320],15
mov [byte ptr es:di+321],15
inc di
setlaser di 1
add di,1280
setlaser di 1
add di,1280
setlaser di 1
add di,1280
setlaser di 1
add di,1280
setlaser di 1
add di,3822
horline di 15 8
ret 2
endp drawshape2

proc drawshape3
mov bp,sp
mov di,[bp+2]
sub di,636
pixel di 15
add di,60
pixel di 15
sub di,58

push di
sub di,8962
horline di 9 30
pixel di 15
add di,60
pixel di 15
pop di

push di
call claser0
sub di,3832
pixel di 15
sub di,640
push di
call claser1
add di,660
pixel di 15
sub di,640
push di
call claser1
add di,660
pixel di 15
sub di,640
push di
call claser1
ret 2
endp drawshape3

proc drawshape4
mov bp,sp
mov di,[bp+2]
sub di,1252
setlaser di 1
sub di,2
setlaser di 3
add di,340
pixel di 15
sub di,30
push di
call claser0
sub di,10
pixel di 15
add di,10
push di
call claser3
sub di,5108
setlaser di 1
sub di,2
setlaser di 3
sub di,620
pixel di 15
sub di,30
push di
call claser0
sub di,10
pixel di 15
add di,10
push di
call claser3
ret 2
endp drawshape4

proc drawshape5
mov bp,sp
mov di,[bp+2]
sub di,610
setlaser di 2
sub di,9595
verline di 15 10
sub di,10
verline di 15 10
sub di,10
pixel di 15
push di
add di,640
add di,8960
push di
call claser1
add di,640
pixel di 15
pop di
add di,2
push di
call claser0
add di,26
push di
call claser3
add di,2
push di
add di,9600
pixel di 15
call claser2
pixel di 15
sub di,9600
pixel di 15
ret 2
endp drawshape5

proc drawshape6
mov bp,sp
mov di,[bp+2]
sub di,1890
pixel di 15
sub di,4170
horline di 15 6
setlaser di 3
setlaser di 2
add di,320
setlaser di 0
setlaser di 3
sub di,4468
verline di 15 14
sub di,2
pixel di 15
ret 2
endp drawshape6

proc drawshape7
mov bp,sp
mov di,[bp+2]
sub di,3830
pixel di 15
add di,640
pixel di 15
sub di,620
pixel di 15
add di,640
pixel di 15
sub di,2
push di
call claser3
ret 2
endp drawshape7

proc drawshape8
mov bp,sp
mov di,[bp+2]
sub di,5100
setlaser di 3
add di,2
setlaser di 1
sub di,641
setlaser di 2
add di,1280
setlaser di 0
ret 2
endp drawshape8

proc drawshape9
mov bp,sp
mov di,[bp+2]
sub di,6390
horline di 9 6
verline di 9 6 
add di,3200
horline di 9 6
sub di,3190
verline di 9 6
ret 2
endp drawshape9

proc drawshape10
mov bp,sp
mov di,[bp+2]
sub di,2550
pixel di 15
setlaser di 2
inc di
setlaser di 2
inc di
horline di 15 6
sub di,5110
verline di 15 8
sub di,12
horline di 15 7
add di,1290
mov [byte ptr es:di],31h
ret 2 
endp drawshape10

proc drawshape11
mov bp,sp
mov di,[bp+2]
sub di,2229
setlaser di 1
sub di,299
setlaser di 2
sub di,4801
setlaser di 3
add di,299
setlaser di 0
add di,2570
mov [byte ptr es:di],31h
ret 2
endp drawshape11

proc drawshape12

ret 2
endp drawshape12

proc proceaduralgen
mov bp,sp
mov ax,[seed]
calc wall 180 22
mov di,[wall]
xor cx,cx
call pspawn
add di,70
mov ch,3
@gprogen:
add cl,3
@progen:
push di
call rgen
pop di
add di,70
dec cl
jnz @progen
sub di,13080
inc cl
dec ch
jnz @gprogen
mov ch,3
@progen2:
push di
call rgen
pop di
add di,70
dec ch
jnz @progen2
push di
call goalspawn

ret 
endp proceaduralgen

proc shash
mov al,10
div [sseed]
mov [sseed],al
ret
endp shash

proc pspawn
mov bp,sp
push di
sub di,2530
mov [pcor],di
player di
pop di
ret
endp pspawn

proc goalspawn
mov bp,sp
mov di,[bp+2]
sub di,2540
pixel di 30h
ret 2
endp goalspawn

proc rgen
xor ax,ax
mov ah,3h
add [sseed],ah
xor ax,ax
mov al,[sseed]
mov bl,10
div bl
sub [sseed],al
inc ah
add [sseed],ah
push di
cmp ah,1
je @shape1
cmp ah,2
je @shape2
cmp ah,3
je @shape3
cmp ah,4
je @shape4
cmp ah,5
je @shape5
cmp ah,6
je @shape6
cmp ah,7
je @shape7
cmp ah,8
je @shape8
cmp ah,9
je @shape9
cmp ah,10
je @shape10
cmp ah,11
je @shape11
cmp ah,12
je @shape12
cmp ah,13
je @shape13
cmp ah,14
je @shape14
cmp ah,15
je @shape15
cmp ah,16
je @shape16


@shape1:
call drawshape11
jmp @rgenend
@shape2:
call drawshape2
jmp @rgenend
@shape3:
call drawshape3
jmp @rgenend
@shape4:
call drawshape4
jmp @rgenend
@shape5:
call drawshape5
jmp @rgenend
@shape6:
call drawshape6
jmp @rgenend
@shape7:
call drawshape7
jmp @rgenend
@shape8:
call drawshape8
jmp @rgenend
@shape9:
call drawshape9
jmp @rgenend
@shape10:
call drawshape10
jmp @rgenend
@shape11:
call drawshape11
jmp @rgenend
@shape12:
call drawshape12
jmp @rgenend
@shape13:
call drawshape1
jmp @rgenend
@shape14:
call drawshape2
jmp @rgenend
@shape15:
call drawshape3
jmp @rgenend
@shape16:
call drawshape5
jmp @rgenend


@rgenend:
ret
endp rgen

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~

start:
mov ax, @data   
mov ds, ax           ;ds = segment for data
mov ax,bufferseg 
mov es,ax            ;es = segment for buffer
assume es:bufferseg  ;bind es to bufferseg

;call mainmenu
mov ax,13h    
int 10h              ;switch to mode 13h



;call mainmenu            ;generate level 1

;call selectlvl
call drawlvlframe
calc wall 180 22
push [wall]
call drawshape7


@waitforkey:
call buffertoscreen
inc [lasert]
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
call endprogram

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
cmp [byte ptr es:di],0Eh
je @incscore
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

@incscore:
inc [score]
jmp @moveplayer

@goalreached:
mov [byte ptr laser],0
inc [currentlvl]
call selectlvl
jmp @waitforkey




; --------------------------

        
exit:
call filesave
mov al,03h
mov ah,0
int 10h
call displayscore
mov ax, 4c00h
int 21h
END start
