
;
;Created on: 2009-07-21
;Author: M
;
;String manipulation functions.
;
;***
;
;LAST MODIFICATION:
;
;YYYY-MM-DD: Author
;	Description
;2010-05-10: M
;	Added the strins function.
;2010-04-15: M
;	Added the strfoc function.
;2010-04-13: M
;	Fixed several bugs in the strcopy function; added the strcopy_ai
;	jump mark.
;2010-04-06: M
;	Added the strcon function for concatenating strings.
;	Added the strcopy function for copying strings.
;


;Inserts a NULL-terminated string before the searched byte
;into a string.
;
;PARAMETERS:
;	al  ... Byte that gets searched in the source string
;	esi ... source string
;	edi ... destination string
;	ebx ... pointer to replacement string
;	ecx ... Number of bytes to search source string through
;
;RETURN VALUES:
;	eax ... Total number of bytes written into destination string
strins:	xor	edx,edx		;Initialize counter
  .compare:
	test	ecx,ecx
	jz	.done
	cmp	byte[esi],al
	jz	.replace
  .copy:movsb			;Copy byte
	inc	edx
	dec	ecx
	jmp	.compare
  .replace:
	push	esi
	mov	esi,ebx
  @@:	movsb
	inc	edx
	cmp	byte[esi],0
	jz	.replacement_done
	jmp	@b
  .replacement_done:
	pop	esi
	jmp	.copy
  .done:mov	eax,edx
	ret


;strfoc searches for the first occurence of the passed byte in the
;passed string.
;
;PARAMETERS:
;	esi ... Pointer to string
;	dl  ... Byte to search for
;	ecx ... Maximal number of bytes to search through
;
;RETURN VALUES (in eax):
;	0 ... Byte not found
;	1 ... Byte found, esi is set to location of this byte
strfoc:	xor	eax,eax
  .search:
	lodsb
	cmp	al,dl
	jz	.found
	cmp	al,0
	jz	.not_found
	loop	.search
  .not_found:
	mov	al,0
	jmp	.end
  .found:
	dec	esi		;Move back to byte occurance
	mov	al,1
  .end: ret


;strcopy copies esi into edi. The strings pointed to by esi and edi
;must be NULL-terminating ones!
;
;PARAMETERS:
;	esi ... source string
;	edi ... pointer to destination
;
;REMARKS:
;The source string is allowed to have a maximum lenght of 4.096 characters.
strcopy:mov	ecx,0x1000
strcopy_ai:			;_ai: already initialised ecx!
	cmp	byte[esi],0
	jz	.end
	movsb
	loop	strcopy_ai
  .end:	movsb			;copy terminating NULL byte
	ret


;strcon concatenates two NULL-terminated strings.
;
;PARAMETERS:
;	edi ... first string
;	esi ... second string, to be added at the end of edi
;
;RETURN VALUES:
;strcon returns the concatenated strings in edi.
;
;REMARKS:
;The strings pointed to by edi and esi can have a maximal length
;of 4.096 characters.
strcon:
  .move_to_end_of_edi:
	call	strlend
	dec	edi		;because of terminating 0 byte!
	mov	ecx,0x1000	;4.096 characters
  .copy_esi_into_edi:
	cmp	byte[esi],0
	jz	.end
	movsb
	loop	.copy_esi_into_edi
  .end:	movsb			;copy NULL-byte
	ret


;Returns the length of an string that is terminated by an 0.
;The returned length includes the terminating 0 byte.
;	edi ... Pointer to string
;	ecx ... Maximal length of string
strlend:mov	ecx,0x1000	;4.096 characters
strlen: push	ecx
	mov	al,0
	repne	scasb
	pop	eax
	sub	eax,ecx
	ret


;Compares two strings.
;	esi ... String 1
;	edi ... String 2
;	ecx ... Number of maximal characters to compare
;
;RETURN VALUES:
; 0 ... Strings are equal
; 1 ... String 1 is greater
; 2 ... String 2 is greater
strcmp:

  .get_length_of_first_string:

	push	ecx
	push	edi
	mov	edi,esi
	call	strlen
	pop	edi
	pop	ecx

  .fix_maxlen_to_fit_strlen:

	cmp	eax,ecx
	cmovb	ecx,eax

  .compare_strings:

	push	ebx
	xor	eax,eax
	mov	edx,eax
	mov	dl,1
	mov	ebx,eax
	mov	bl,2
	repz	cmpsb
	cmova	ax,dx
	cmovb	ax,bx
	pop	ebx
	ret
