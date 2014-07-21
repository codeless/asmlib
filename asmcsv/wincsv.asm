
;
;Created on: 2009-11-02
;Author: M
;
;Main file for Win32 to compile a ASMCSV DLL file.
;
;***
;
;LAST MODIFICATION:
;
;YYYY-MM-DD: Author
;	Description
;

define DEBUG 1

format PE GUI 4.0 DLL
match =1,DEBUG
{
	entry test_csv
}


section ".text" code readable executable

match =1,DEBUG
{
	include "c:/manuel/pro/asmlib/winapi/dbg.asm"
}
include "asmcsv.asm"

match =1,DEBUG
{
	test_csv:

		mov	esi,filnam
		xor	ecx,ecx
		;xor	ebx,ebx	delimiter not yet supported!
		call	csv_init
		test	eax,eax
		jz	end_test_csv

	get_csv_record:

		push	eax
		mov	esi,eax
		call	csv_fetch_row
		test	eax,eax
		jz	end_test_csv
		mov	esi,eax

	output_column_to_debug_monitor:

		lodsd
		test	eax,eax
		jz	no_more_columns
		DBG	eax
		jmp	output_column_to_debug_monitor

	no_more_columns:

		pop	eax
		jmp	get_csv_record

	end_test_csv:

		pop	eax
		mov	esi,eax
		call	csv_fin
}


match =1,DEBUG
{
	section ".data" data readable writeable
	filnam	db "test.csv",0
	sep	db 13,10,"***",13,10,0
}


section ".idata" import data readable writeable

dd	0,0,0,rva msvcrt_name,	rva msvcrt_table
match =1,DEBUG
{
	dd	0,0,0,rva kernel32_name, rva kernel32_table
}
dd	0,0,0,0,0

msvcrt_table:
	fclose	dd rva _fclose
	fgets	dd rva _fgets
	fopen	dd rva _fopen
	free	dd rva _free
	malloc	dd rva _malloc
	dd 0

match =1,DEBUG
{
	kernel32_table:
		OutputDebugString	dd rva _OutputDebugStringA
		dd 0
}

msvcrt_name	db "MSVCRT.DLL",0
match =1,DEBUG
{
	kernel32_name	db "KERNEL32.DLL",0
	_OutputDebugStringA dw 0
		db 'OutputDebugStringA',0
}

_fclose dw 0
	db "fclose",0
_fgets	dw 0
	db "fgets",0
_fopen	dw 0
	db "fopen",0
_free	dw 0
	db "free",0
_malloc	dw 0
	db "malloc",0


section '.reloc' fixups data discardable
