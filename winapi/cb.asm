
;
; Created on: 2009-07-07
; Author: M
;
; Functions for handling COMBOBOX-Controls.
;
; ***
;
; LAST MODIFICATION:
;
; YYYY-MM-DD: Author
;	Description
; 2009-07-14: M
;	Bugfixed the cbgetsel function.
;

; Selects an item with the given index:
;	ecx ... index of item to select
;	ebx ... HWND of COMBOBOX
cbsetsel:
	push	0
	push	ecx
	push	0x14E		; CB_SETCURSEL
	push	ebx
	call	[SendMessage]
	CHKERR	0xFFFFFFFF
	ret

; Returns the index of the selected item in the list.
;	ebx ... HWND of COMBOBOX
cbgetsel:
	push	0
	push	0
	push	0x147		; CB_GETCURSEL
	push	ebx
	call	[SendMessage]
	CHKERR	0xFFFFFFFF
	ret

; Returns the selected string from the list. Same parameters like cbsetsel.
; Additional parameter:
;	esi ... Adress to the buffer than can hold 
;		the text of the selected item.
cbgetstr:

  .get_selected_index:

	call	cbgetsel

  .retrieve_text_of_selected_item:

	push	esi
	push	eax
	push	0x148		; CB_GETLBTEXT
	push	ebx
	call	[SendMessage]
	ret

; Returns the number of items in the list box of a COMBOBOX. Parameters:
;	ebx ... HWND of COMBOBOX
cbgetc:	push	0
	push	0
	push	0x146		; CB_GETCOUNT
	push	ebx
	call	[SendMessage]
	ret


; Like cbgetid, but before trying to retrieve the item data of an item, the
; index of the currently selected item gets retrieved:
cbgetid_ex:

	call	cbgetsel
	mov	ecx,eax

; Returns the item data of the wanted item. Parameters:
;	ecx ... index of the item, where the itemdata is wanted
;	ebx ... HWND of COMBOBOX
cbgetid:

	push	0
	push	ecx
	push	0x150		; CB_GETITEMDATA
	push	ebx
	call	[SendMessage]
	ret
