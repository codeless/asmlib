
;
;Created on: 2009-06-22
;Author: M
;
;String operations.
;
; ***
;
;LAST MODIFICATION:
;
;YYYY-MM-DD: Author
;	Description
;

;loads_ex is a wrapper for loads, but takes an additional parameter for the
;maximal string length.
;
;PARAMETERS:
;	edx	...	Maximal string length
loads_ex:
	push	edx
	jmp	loads.push_the_rest
;Loads a string from the String table of the ressource section.
;
;PARAMETERS:
;	ecx	...	String Identifier
;	edi	...	Pointer to buffer the string can be loaded into
;
;RETURN VALUES:
;If the function succeeds, the return value is the number of bytes (ANSI
;version) or characters (Unicode version) copied into the buffer,
loads:

  .push_default_maximal_string_length:

	push	0x100		;256 Bytes

  .push_the_rest:

	push	edi
	push	ecx
	push	[hinst]
	call	[LoadString]
	test	eax,eax
	jz	errout
	ret
