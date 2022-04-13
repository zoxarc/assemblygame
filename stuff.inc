
; draw the player character
proc drawfrontplayer
mov bp,sp
mov di,[bp+2]
mov cx,3
@fronthair:
inc di
mov [es:di],6h
dec cx
jnz @fronthair
add di,318
mov [es:di],28h
inc di
mov [es:di],0Fh
inc di
mov [es:di],60h
add di,317
mov cx,3
@frontface:
inc di
mov [es:di],42h
dec cx
jnz @frontface
add di,317
mov [es:di],77h




ret 2
endp drawfrontplayer
