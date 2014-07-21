
;
;Created on: 2010-02-04
;Author: M
;
;Several functions for handling EDIT controls.
;
;***
;
;LAST MODIFICATION:
;
;YYYY-MM-DD: Author
;	Description


;Selects all the content in a EDIT control.
;
;PARAMETERS:
;	edx ... Handle of EDIT control
;
;RETURNS:
;	Doesn't return a value.
ec_select_all:

	push	0xFFFF'FFFF	;-1
	push	0
	push	0xB1		;EM_SETSEL
	push	edx
	call	[SendMessage]
	ret


;Sets the text in a EDIT control.
;
;PARAMETERS:
;	edx ... Handle of EDIT control
;	esi ... Pointer to text
;	ebx ... Flag to specifiy wether the replacement operation can
;		be undone.
;
;RETURNS:
;	Doesn't return a value.
ec_set_text:

  .select_all_text:

	push	edx
	call	ec_select_all
	pop	edx

  .replace_all_text:

	push	esi
	push	ebx
	push	0xC2		;EM_REPLACESEL
	push	edx
	call	[SendMessage]
	ret
