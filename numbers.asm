
;
;Created on: 2010-05-04
;Author: M
;
;Functions for processing numbers.
;
;***
;
;LAST MODIFICATION:
;
;YYYY-MM-DD: Author
;	Description
;


;itoa converts an integer to a string.
;Copyright © Tommy Lillehagen, 2003.
;eax = number, ebx = base, edi = buffer
itoa:	push	ecx edx
	xor	ecx,ecx
.new:	xor	edx,edx
	div	ebx
	push	edx
	inc	ecx
	test	eax,eax
	jnz	.new
.loop:	pop	eax
	add	al,30h
	cmp	al,'9'
	jng	.ok
	add	al,7
.ok:	stosb
	loop	.loop
	mov	al,0
	stosb
	pop	edx ecx
	ret
