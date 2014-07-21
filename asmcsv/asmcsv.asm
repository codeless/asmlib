
;
;Created on: 2009-11-02
;Author: M
;
;PURPOSE:
;Implements functions for handling (Microsoft-Excel-)CSV files.
;A Microsoft-Excel-CSV file consists of fields seperated by a semicolon.
;A record can only be ONE line!
;
;REMARKS:
;These functions make use of the LibC.
;
;TODO:
;Find a replacement for the fgets function, which stops when encountering
;a NULL byte.
;
;***
;
;LAST MODIFICATION:
;
;YYYY-MM-DD: Author
;	Description
;2010-04-13: M
;	Added the csv_parse_str function.
;2010-04-07: M
;	Added the csv_skip function.
;

;Possible return values of ASMCSV functions:
FOPEN_FAILED	= -1
MALLOC_FAILED	= -2


;Macros used:
macro ENTERFUN	;ENTERFUN creates space for 10 local buffers inside a function
{
	sub	esp,0x28
	push	ebp esi edi ebx
	mov	ebp,esp
}
virtual at ebp+0x10		;Variables on the stack
	mode	dd ?
	fp	dd ?
end virtual
macro EXITFUN	;Should be used before a function returns to free local buffers
{
	pop	ebx edi esi ebp
	add	esp,0x28
}


;Initializes a CSV file for sequential reading.
;
;PARAMETERS:
;	esi ... Filename ended by \0 (C-String)
;	ecx ... Maximal length per CSV record; if a record occurs to be longer,
;		then everything after the maximal length gets stripped.
;		Default is 1.000 (when ecx is passed with value 0)
;		Maximum is 10.000
;	ebx ... Column delimiter string, ended by \0 (C-String)
;		Default is ";" (when ebx is passed with value 0)
;		The maxlength of the delimiter is four bytes (including the
;		0-byte) NOT YET IMPLEMENTED!
;
;RETURN VALUES:
;	FILE_NOT_FOUND
;	MALLOC_FAILED
;	Any positive value returned points to the allocated memory where the
;	initialization data for the CSV file got stored. This pointer is
;	called the "Resource ID" and can be passed to other CSV functions
;	(csv_fetch_row, csv_fin, ...).
;
csv_init:

	ENTERFUN

  .try_to_open_file:

	mov	[mode],0x0000'0072	;"r"
	lea	edi,[mode]
	push	ecx			;store maxlength on stack
	push	edi			;"r"-mode
	push	esi
	call	[fopen]
	add	esp,8
	pop	ecx			;load maxlength from stack
	test	eax,eax
	jz	csvi_set_errorcode.fopen_failed
	mov	[fp],eax

  .check_maxlength_param:

	test	ecx,ecx
	jnz	csvi_control.maxlength
	mov	ecx,0x3E8		;1.000

;  .check_delimiter_param:
;
;	test	ebx,ebx
;	jnz	@f
;	mov	ebx,0x0000'002C		;","
;
;  @@:

  .allocate_memory_for_saving_the_resource_id:
	;The Resource ID is a pointer to allocated memory where the pointer to
	;the CSV file stream, the passed maxlength and the passed delimiter is
	;stored. Also, beginning at byte 13, is a buffer for the data read from
	;the CSV file. The length of this buffer is five times as large as
	;the value given in the maxlenght parameter.
	;While the first bytes (as long as the value in maxlength) is used
	;for the read in data and columns, the rest is used as sort of stack 
	;for the pointers to the columns.

	push	ecx			;store maxlength on stack
	mov	eax,ecx			;multiply with 5 to get the space
	mov	ecx,5			;for the data to read in and
	mul	ecx			;additional space to save pointers
					;to the csv columns.
	mov	ecx,eax
	add	ecx,0xC			;12 bytes for: fp, maxlength, delimiter
	push	ecx
	call	[malloc]
	add	esp,4
	pop	ecx			;load maxlength from stack
	test	eax,eax
	jz	csvi_set_errorcode.malloc_failed

  .save_initialization_data:

	mov	edi,eax
	mov	eax,[fp]
	stosd
	mov	eax,ecx
	stosd
	mov	eax,ebx			;Delimiter; not yet implemented
	stosd
	sub	edi,0xC
	mov	eax,edi

  .return:

	EXITFUN
	ret

  csvi_set_errorcode:
  .fopen_failed:

	mov	eax,FOPEN_FAILED
	jmp	csv_init.return

  .malloc_failed:

	mov	eax,MALLOC_FAILED
	jmp	csv_init.return

  csvi_control:
  .maxlength:

	cmp	ecx,0x2710		;10.000
	jle	csv_init.allocate_memory_for_saving_the_resource_id
	mov	ecx,0x2710
	jmp	csv_init.allocate_memory_for_saving_the_resource_id


;csv_fetch_row tries to read the current line of the csv file and separates the
;line into columns.
;
;PARAMETERS:
;	esi ... Pointer to the Resource ID
;
;RETURN VALUES:
;	eax ... 0 if reading of file failed or EOF
;		Any other positive value points to a buffer with pointers to 
;		extracted columns (in DWORDS); those pointers can be loaded 
;		with the "lodsd" mnemonic (when using esi).
;		The last DWORD/pointer is zero.
;
csv_fetch_row:

	ENTERFUN

  csvf_read_file:

	lodsd			;load file-pointer
	mov	[fp],eax	;save fp
	push	eax		;push fp to stack for upcoming function call
	lodsd			;load maxlen parameter
	push	eax		;push maxlen on the stack
	add	esi,4		;move forward to free space
	push	esi		;push address of free space on stack
	call	[fgets]		;better than fgets: getline
	add	esp,0xC
	test	eax,eax
	jz	csvf_set_errorcode

  csvf_process_string:
	;The CSV-string which has been read above now gets split into columns.
	;The startaddress to the columns are stored in edi, which points to the
	;end of the CSV-string. The last entry of edi is 0, which indicates that
	;there are no more columns.
  .set_up_edi:

	sub	esi,8		;load maximal CSV record length.
	lodsd
	add	esi,4		;point esi to start of CSV record
	mov	edi,esi		;point edi -"-
	add	edi,eax		;point edi to the end of the CSV record
	mov	ecx,1		;Set flag to indicate that the CSV
				;string has been read via fgets

  .save_address_of_first_column:

	push	edi		;save starting position on stack
	mov	eax,esi
	stosd

  .find_semicolon:

	cmp	byte[esi],0x3B	;0x3B = ";"
	jz	.extract_column
	cmp	byte[esi],0	;end of record?
	jz	.end_processing
	inc	esi
	jmp	.find_semicolon

  .extract_column:

	mov	byte[esi],0
	inc	esi
	mov	eax,esi
	stosd
	jmp	.find_semicolon

  .end_processing:

  .remove_eol:
	;fgets adds an end-of-line character to each line read
	;which gets removed now if ecx is set:
	cmp	ecx,1
	jnz	@f
	dec	esi
  @@:	mov	byte[esi],0

  .add_endpoint:

	xor	eax,eax		;add empty pointer to edi...
	stosd			;...to indicate "no more columns"
	pop	eax		;get starting position from stack

  csvf_end:

	EXITFUN
	ret

  csvf_set_errorcode:
  .fgets_failed:

	xor	eax,eax
	jmp	csvf_end


;csv_skip can be called to skip a number of records.
;
;PARAMETERS:
;	esi ... Pointer to the Resource ID
;	ecx ... Holds the number of records that should get skipped
csv_skip:
	;Simply call csv_fetch_row while the counter is above zero.
	push	ecx
	call	csv_fetch_row
	pop	ecx
	loop	csv_skip
	ret


;csv_fin closes the opened file handle to a CSV file and frees the allocated
;memory for the passed resource id.
;
;PARAMETERS:
;	esi ... Pointer to the Resource ID
;
;RETURN VALUES:
;	eax ... 1 if file closed
;		0 if file couldn't get closed
;
csv_fin:

	ENTERFUN

  .try_to_close_file:

	lodsd				;Load file stream
	push	eax
	call	[fclose]		;Returns 0 on success, otherwise EOF/-1
	add	esp,4
	xor	al,1			;Switch 0 to 1
	push	eax			;Save return value

  .try_to_free_allocated_memory:

	sub	esi,4
	push	esi
	call	[free]			;Returns no value?
	add	esp,4

  .return:

	pop	eax
	EXITFUN
	ret


;csv_parse_str allows to pass a CSV string which is seperated into
;its columns.
;
;PARAMETERS:
;	esi ... Pointer to CSV string
;	edi ... Pointer to empty buffer, where location of columns
;		can get stored.
;
;REMARKS:
;The processing is done by calling the csv_fetch_row function.
csv_parse_str:
	ENTERFUN
	xor	ecx,ecx
	jmp	csvf_process_string.save_address_of_first_column
