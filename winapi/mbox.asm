
;
;Created on 2009-05-27
;Author: M
;
;MessageBoxes.
;
;***
;
;LAST MODIFICATION:
;
;YYYY-MM-DD: Author
;	Description
;2010-11-19: M
;	Added the mbox_gle function.
;


;mbox displays a MessageBox.
;
;PARAMETERS:
;	eax	... Handle of the owner window
;	ecx	... ID of the message string
;	edx	... ID of the title string
;	ebx	... Style of the MessageBox
;
;RETURN VALUES:
;	The return value is zero if there is not enough memory to create the
;	message box. If the function succeeds, the return value is one of the
;	following menu-item values returned by the dialog box: 
;		IDABORT		Abort button was selected.
;		IDCANCEL	Cancel button was selected.
;		IDIGNORE	Ignore button was selected.
;		IDNO		No button was selected.
;		IDOK		OK button was selected.
;		IDRETRY		Retry button was selected.
;		IDYES		Yes button was selected.
;
;REMARKS:
;The style of the MessageBox could be a bitmask of:
;	0x4	... MB_YESNO
;	0x10	... MB_ICONERROR
;	0x20	... MB_ICONQUESTION
;	0x40	... MB_ICONINFORMATION
mbox:

	push	eax edx

  .lade_nachricht:

	mov	edi,tbuf1
	call	loads

  .soll_ein_titel_geladen_werden:

	xor	eax,eax
	pop	edx
	test	edx,edx
	cmovz	edx,eax
	jz	.standardtitel_verwenden

  .lade_titel:

	mov	edi,tbuf1+0x100
	xchg	ecx,edx
	call	loads
	jmp	.msgbox_darstellen

  .standardtitel_verwenden:

	xor	edi,edi

  .msgbox_darstellen:

	pop	eax
	push	ebx
	push	edi
	push	tbuf1
	push	eax
	call	[MessageBox]

  .beenden:

	ret


;Displays an MessageBox with the "Error"-Title and an Error-icon:
errorbox:
mboxe:	xor	edx,edx
	mov	ebx,0x10
	jmp	mbox


;Displays an MessageBox with the IDS_INFORMATION String as title 
;and an info-icon.
infobox:
	mov	edx,IDS_INFO
	mov	ebx,0x40
	jmp	mbox


;Displays an question-box:
qbox:	mov	edx,IDS_QUESTION
	mov	ebx,0x20+4	;MB_ICONQUESTION+MB_YESNO
	jmp	mbox


;Calls GetLastError and outputs the returned message as
;Error-MessageBox.
;errout:
mbox_gle:
	call	[GetLastError]	;Get last error code value
	;Format message:
	push	0		;Parameters
	push	0		;Number of bytes available for message string
	push	buffer
	push	0x0C07		;German (Austrian), Language Identifier
	push	eax		;Message ID
	push	0
	push	0x1000		;FORMAT_MESSAGE_FROM_SYSTEM
	call	[FormatMessage]
	;Display MessageBox:
	push	0x10		;Error-Icon
	push	0
	push	buffer
	push	0
	call	[MessageBox]
	;Free memory used for message:
	push	[buffer]
	call	[LocalFree]
	ret
