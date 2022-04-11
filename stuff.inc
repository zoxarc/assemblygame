
; draw the player character
proc drawplayer
mov bp,sp
mov cx,[bp+6]
mov dx,[bp+4]
mov bx,[bp+2]
pixel cx bx
add cx,640
pixel cx dx
add cx,2
pixel cx bx
sub cx,4
pixel cx bx
add cx,642
pixel cx bx
add cx,640
pixel cx bx
add cx,640
pixel cx bx
add cx,642
pixel cx bx
sub cx,4
pixel cx bx
ret 6
endp drawplayer
