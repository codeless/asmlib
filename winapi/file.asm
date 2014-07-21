
;
;Created on: 2009-07-27
;Author: M
;
;Functions for file dialogs.
;
;***
;
;LAST MODIFICATION:
;
;YYYY-MM-DD: Author
;	Description
;2010-11-19: M
;	Added the write_to_file_unlimited and the
;	write_to_file_fixedlen function.
;


;Initializes and runs the GetOpenFileName winapi function.
;
;PARAMETERS:
open_file_dlg:

	mov	eax,[GetOpenFileName]
	jmp	saveas.save_functionname_on_stack

;Initializes and runs the GetSaveFileName winapi function.
;
;PARAMETERS:
;	ecx	...	String Identifier for the lpstrFilter member
;	edx	...	Pointer to an empty buffer which can hold the
;			to be loaeded filterstring
;	ebx	...	Handle to owner window
;	esi	...	Pointer to a buffer that contains a filename used to 
;			initialize the File Name edit control.
;			This buffer must at least be 256 characters long!
;			(set using nMaxFile)
;	edi	...	Points to a buffer that contains the default extension
;
;REMARKS:
;
saveas:

	mov	eax,[GetSaveFileName]

  .save_functionname_on_stack:

	push	eax

  .init:

	xor	eax,eax
	mov     [opfnam.lStructSize],0x4C
	push	ebx
	pop	[opfnam.hwndOwner]
	push	[hinst]
	pop	[opfnam.hInstance]
	mov	[opfnam.lpstrCustomFilter],eax
	mov	[opfnam.nFilterIndex],eax
	mov	[opfnam.nMaxFile],0x12C
	mov	[opfnam.lpstrFileTitle],eax
	mov	[opfnam.lpstrInitialDir],eax
	mov	[opfnam.lpstrTitle],eax
	mov	[opfnam.Flags],0x2000	; OFN_CREATEPROMPT
	mov	[opfnam.lpstrFile],esi
	mov	[opfnam.nFileOffset],0
	mov	[opfnam.lpstrDefExt],edi

  .load_filter_string:

	mov	edi,edx
	call	loads
	mov	[opfnam.lpstrFilter],edi

  .format_filterstring:
  .terminate_pair:

	xor	ecx,ecx
	mov	ecx,0x64
	mov	al,0x7C		;"|"
	repne	scasb
	dec	edi
	mov	byte[edi],0

  .terminate_buffer:

	inc	edi
	mov	ecx,0x64
	mov	al,0
	repne	scasb
	mov	byte[edi],0

  .get_file_extension_start:

	mov	edi,[opfnam.lpstrFile]
	mov	al,0x2E
	mov	ecx,0xFF
	repne	scasb
	mov	eax,0xFF
	sub	eax,ecx
	inc	eax
	mov	[opfnam.nFileExtension],ax

  .show_get_save_filename_dlg:

	pop	eax
	push	opfnam
	call	eax
	;call	[GetSaveFileName]
	test	eax,eax
	jz	.comdlg_error

  .end:

	ret

  .comdlg_error:

	call	[CommDlgExtendedError]
	test	eax,eax
	jz	.end
	push	eax

  .load_errorstring:

	mov	edi,tbuf1
	mov	ecx,IDS_COMDLGFAILURE
	call	loads

  .format_errorstring:

	;eax is on the stack
	push	edi
	push	tbuf3
	call	[wsprintf]
	add	esp,0xC

  .output_errorbox:

	push	0x10
	push	0
	push	tbuf3
	push	0
	call	[MessageBox]
	jmp	exit


;Calls the CreateFile winapi function.
;
;PARAMETERS:
;	eax	...	dwDesiredAccess
;			GENERIC_READ = 0x80000000
;			GENERIC_WRITE = 0x40000000
;	ecx	...	dwCreationDistribution; Specifies which action 
;			to take on files that exist, and which action 
;			to take when files do not exist.
;			OPEN_ALWAYS = 4
;	esi	...	pointer to the name of the file to open
create_file:

	push	0
	push	0x80	;FILE_ATTRIBUTE_NORMAL
	push	ecx
	push	0
	push	0
	push	eax
	push	esi
	call	[CreateFile]
	ret


;Calls the WriteFile function.
;
;PARAMETERS:
;	ecx ... Handle to buffer where the number of written bytes gets stored
;	edx ... Handle to file to write to (hFile)
;	esi ... Pointer to data to write to file (lpBuffer)
;
;RETURNS:
;Returns true if successful or in case of failure, zero.
;
;REMARKS:
;This write function is limited to 1.000 bytes only.
;The data in esi should be terminated by a NULL byte. This terminating
;NULL byte does not get written to file!
write_to_file:

  wtf_init:

	push	ebp esi edi ebx
	mov	ebp,esp
  .get_strlen:
	push	ecx
	mov	edi,esi
	mov	ecx,0x3E8	;1.000
	call	strlen
	pop	ecx
	dec	eax

  wtf_write:

	push	0		;Structure for overlapped I/O
	push	ecx		;Number of bytes written
	push	eax		;Number of bytes to write
	push	esi		;Data to write
	push	edx		;hFile
	call	[WriteFile]

  wtf_end:

	pop	ebx edi esi ebp
	ret


;Like write_to_file, but allows an unlimited number of bytes to be written
;to file:
write_to_file_unlimited:
	push	ebp esi edi ebx
	mov	ebp,esp
.get_strlen:
	push	ecx
	mov	edi,esi
	mov	ecx,0x0FFF'FFFF
	call	strlen
	pop	ecx
	dec	eax
	jmp	wtf_write


;Writes data to a file where the length is already known.
;This function can also be used to write data with 0-bytes inside.
;When calling this function, besides the three parameters as used
;in write_to_file, a fourth parameter has to get passed:
;	eax ... Length of data, in bytes
write_to_file_fixedlen:
	push	ebp esi edi ebx
	mov	ebp,esp
	jmp	wtf_write
