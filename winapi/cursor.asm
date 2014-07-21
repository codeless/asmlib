
;
;Created on: 2010-02-05
;Author: M
;
;Cursor-Functions.
;
;***
;
;LAST MODIFICATION:
;
;YYYY-MM-DD: Author
;	Description
;


;switch_cursor simply switches the current cursor with the one identified
;by the passed ID.
;
;PARAMETERS:
;	eax ... Holds the ID of the new cursor-resource which can be
;		for instance one of: 
;		0x7F00 ... IDC_ARROW (Standard arrow)
;		0x7F8A ... IDC_APPSTARTING (Standard arrow and small hourglass)
;		0x7F03 ... IDC_CROSS (Crosshair)
;		0x7F88 ... IDC_NO (Slashed circle)
;		0x7F02 ... IDC_WAIT (Hourglass)
;	edx ... Flag which indicates if the cursor to switch to is a 
;		Win32 predefined cursor or an cursor delivered with the
;		current application. This flag has to be set to 1
;		if the cursor is delivered from within the current
;		application's resource.
;
;RETURN VALUES:
;	0  ...	In any case of failure
;	>0 ...	Any value above zero is the handle of the previous cursor.
;
;REMARKS:
;	switch_cursor expects that a variable with the name "hinst" holds the
;	handle of the application instance.
switch_cursor:

  .check_application_instance_handle:

	test	edx,edx
	jz	.try_to_load_cursor
	mov	edx,[hinst]

  .try_to_load_cursor:

	push	eax
	push	edx
	call	[LoadCursor]
	test	eax,eax
	jz	.end

  .try_to_set_the_loaded_cursor:

	push	eax
	call	[SetCursor]

  .end:

	ret


;Every time the new set cursor gets moved, the cursor is redrawn and reset to
;the cursor stored in the registered window class. To prevent this, the window
;class has to get subclassed. This can be done via switch_and_hold_cursor.
;
;PARAMETERS:
;	eax ... See documentation to switch_cursor
;	edx ... See documentation to switch_cursor
;	ebx ... Handle to window
switch_and_hold_cursor:

	call	switch_cursor	;load and switch cursor
	push	eax		;cursor
	push	0xFFFF'FFF4	;GCL_HCURSOR
	push	ebx		;hwnd
	call	[SetClassLong]
	CHKERR	0
	ret
