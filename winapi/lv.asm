
;
;Created on: 2009-05-28
;Author: M
;
;Function for accessing ListView-controls.
;TODO: all functions that send a message to a ListView-control, should be named
;after "lvm" to indicate this.
;
; ***
;
;LAST MODIFICATION:
;
;YYYY-MM-DD: Author
;	Description
;2010-04-15: M
;	Div. optimizations.
;2010-04-13: M
;	Fixed spelling mistakes.
;2009-07-15: M
;	Added lvsel.
;2009-07-10: M
;	Added new functions: lvcolw, lvmgeti
;


; lvdeli löscht ein Item aus einer ListView.
;	eax ... Handle zur ListView-Control
;	edx ... Index des zu löschenden Items
lvdeli: push	0
	push	edx
	push	0x1008			; LVM_DELETEITEM
	push	eax
	call	[SendMessage]
	ret


; lvdela löscht alle Items aus einer ListView:
;	eax ... Handle zur ListView-Control
;	ebx ... Sollen auch die Spalten gelöscht werden? 0|1
lvdela:	push	0
	push	0
	push	0x1009			; LVM_DELETEALLITEMS
	push	eax
	call	[SendMessage]
	ret

;Deletes all items in a listview.
;	ebx ... Handle to ListView-Control
lvdela_ex:
	push	0
	push	0
	push	0x1009			; LVM_DELETEALLITEMS
	push	ebx
	call	[SendMessage]
	ret


; getsel_ex liefert den Index des selektierten ListView Items zurück, genauso
; wie getfsel; jedoch mit dem Unterschied, dass der Handle zur ListView Control
; in edx übergeben wird.
; Ist kein Item in der ListView gewählt, gibt LVM_GETNEXTITEM -1 zurück.
getsel_ex:

	push	2			; LVNI_SELECTED
	push	-1			; find first item
	push	0x100C			; LVM_GETNEXTITEM
	push	edx
	call	[SendMessage]
	ret


;Returns the index of the first selected item. Parameters like with getsel2.
getfsel:mov	edx,0xFFFF'FFFF
;Returns the index of the next selected item. Parameters:
;	ebx ... Handle to ListView control
;	edx ... Index of start item, from where to start search.
;		If function should return the very first matching item, edx
;		should be set to -1.
;Returns the index of the next item if successful or -1 otherwise.
getsel2:push	2			; LVNI_SELECTED
	push	edx
	push	0x100C			; LVM_GETNEXTITEM
	push	ebx
	call	[SendMessage]
	ret


; Zählt die Anzahl der Items in einer ListView. Parameter:
;	ebx ... Handle zur ListView
lvc:	push	0
	push	0
	push	0x1004			; LVM_GETITEMCOUNT
	push	ebx
	call	[SendMessage]
	ret


;Returns the width of a column. Parameters:
;	eax ... Index of wanted column
;	ebx ... ListView-handle
lvcolw:	push	0
	push	eax
	push	0x101D			; LVM_GETCOLUMNWIDTH
	push	ebx
	call	[SendMessage]
	ret


;Gets only the text-element of an ListView Subitem. This function expects the
;following LV_ITEM members to be set: iItem, iSubItem, pszText, cchTextMax.
;
;PARAMETERS:
;	ebx ... Handle of ListView control
;	edx ... Pointer to LV_ITEM structure
lvmgetstr:
	mov	dword[edx],1		; LVIF_TEXT
;Sends the LVM_GETITEM message to the ListView-control specified by ebx.
;The pointer to the LV_ITEM structure should be stored in edx.
lvmgeti:push	edx
	push	0
	push	0x1005			; LVM_GETITEM
	push	ebx
	call	[SendMessage]
	ret


;Sets an item selection. Expects two parameters:
;	edx ... Pointer to LV_ITEM structure
;	ebx ... ListView-Handle
lvsel:

  .modify_structure:

	mov	dword[edx],8		; LVIF_STATE
	mov	dword[edx+0xC],2	; LVIS_SELECTED
	mov	dword[edx+0x10],2

  .set_selection:

	push	edx
	push	0
	push	0x1006			; LVM_SETITEM
	push	ebx
	call	[SendMessage]
	ret


;Sets an item selection and focus to this item. Parameters like with lvsel.
lvfocs:

  .modify_structure:

	mov	dword[edx],8		; LVIF_STATE
	mov	dword[edx+0xC],3	; LVIS_SELECTED+LVIS_FOCUS
	mov	dword[edx+0x10],3

  .select_and_focus_item:

	jmp	lvsel.set_selection
