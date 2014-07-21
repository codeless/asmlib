
;
;Created on: 2009-06-08
;Author: M
;
;Diverse functions for dialog-applications.
;
; ***
;
;LAST MODIFICATION:
;
;YYYY-MM-DD: Author
;	Description
;2010-12-27: M
;	Added the remove_wndstyle procedure.
;2010-05-18: M
;	Added the SWITCH_TEXT macro.
;2010-04-27: M
;	Added the DISSET macro.
;2010-04-15: M
;	Added the INLIM macro.
;2010-04-13: M
;	Added the switch_text_al jump-mark.
;2010-04-08: M
;	Added the switch_text function.
;2009-07-27: M
;	Added the getchrb function.
;


;disset deactivates a row of controls.
;
;PARAMETERS:
;	eax	... ID of the first control
;	ecx	... Number of controls to deactivate
;	ebx	... Handle of window
;
;REMARKS:
;The controls which should get deactivated must have continous ID's!
disset:

	xor	edx,edx

  .zwischenspeichern:

	push	eax ecx edx

  .hole_ctrl_handle:

	push	eax
	push	ebx
	call	[GetDlgItem]
	test	eax,eax
	jz	errout

  .flag_zwischenspeichern:

	pop	edx
	push	edx

  .disable_ctrl:

	push	edx
	push	eax
	call	[EnableWindow]

  .naechste_ctrl:

	pop	edx ecx eax
	inc	eax
	loop	.zwischenspeichern
	ret

macro DISSET id_of_first_control,number_of_controls,hwnd {
	mov	eax,id_of_first_control
	mov	ecx,number_of_controls
	mov	ebx,hwnd
	call	disset
}


;Activates a row of controls. For parameters, see disset.
actset: mov	edx,1
	jmp	disset.zwischenspeichern


;Limits input fields.
;
;PARAMETERS:
;	ecx	... Input limit
;	edx	... ID of control
;	ebx	... Handle of window
inlim:

  .get_control_handle:

	push	ecx
	push	edx
	push	ebx
	call	[GetDlgItem]
	pop	ecx
	test	eax,eax
	jz	errout

  .limit_input:

	push	0
	push	ecx
	push	0xC5			; EM_SETLIMITTEXT
	push	eax
	call	[SendMessage]
	ret

;Limit input field length:
macro INLIM window,ctrl_id,limit {
	mov	ecx,limit
	mov	edx,ctrl_id
	mov	ebx,window
	call	inlim
}


;Returns the control identifier of a selected radio button in a group of radio
;buttons.
;
;PARAMETERS:
;	ecx	... Number of Radio Buttons
;	edx	... Control identifier of the first Radio Button in a group
;	ebx	... Handle to Window
;
;RETURNS:
;	-1	... No control is checked
;	>0	... Control identifier of checked control
getchrb:

  .save:

	push	ecx
	push	edx

  .get_control_status:

	push	edx
	push	ebx
	call	[IsDlgButtonChecked]

  .restore:

	pop	edx
	pop	ecx

  .check_if_control_is_checked:

	cmp	eax,1
	jz	.checked_control_found

  .control_is_not_checked:

	inc	edx
	dec	ecx
	jnz	.save

  .no_checked_control_found:

	mov	eax,0xFFFF'FFFF
	jmp	.end

  .checked_control_found:

	mov	eax,edx

  .end:

	ret


;Switches the text of a window.
;
;PARAMETERS:
;	ecx ... String identifier used in String Table resource
;	ebx ... Handle of window where control resides
;	eax ... ID of control to switch text of
;	edi ... Pointer to a buffer where the string can be loaded into
switch_text:
	push	eax
	call	loads	;Load new textstring from resource
	pop	eax
	mov	esi,edi
	;Set loaded textstring by sending a Message:
switch_text_al:			;_al=already loaded
	push	esi
	push	0
	push	0xC		;WM_SETTEXT
	push	eax		;ID of control
	push	ebx		;HWND
	call	[SendDlgItemMessage]
	ret

macro SWITCH_TEXT string_id,hwnd,control_id,buffer {
	mov	ecx,string_id
	mov	ebx,hwnd
	mov	eax,control_id
	mov	edi,buffer
	call	switch_text
}


;Removes a style from a window using the GetWindowLong and SetWindowLong
;functions from the Windows API.
;
;PARAMETERS:
;	ecx ... Window-Style to be removed
;	ebx ... Handle of window
remove_wndstyle:
	push	ecx	;Save ecx
	;Get current window style:
	push	GWL_STYLE
	push	ebx
	call	[GetWindowLong]
	pop	ecx	;Get ecx
	test	eax,eax	;if eax==0
	jz	.return	; then return
	sub	eax,ecx	;remove style
	;Set new style:
	push	eax
	push	GWL_STYLE
	push	ebx
	call	[SetWindowLong]
.return:ret
