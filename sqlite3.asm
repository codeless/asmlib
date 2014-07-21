
;
;Created on 2009-01-29
;Author: M
;
;Functions for accessing sqlite3 databases.
;
;***
;
;MODIFICATIONS:
;
;YYYY-MM-DD: Author
;	Description
;2010-10-21: M
;	Added several macros.
;2010-10-14: M
;	Added the sqbindstr function.
;2010-05-17: M
;	Added the sqopen and sqclose function.
;2010-05-11: M
;	Added the SQBIND macro.
;2010-04-27: M
;	Updated the sqpbs function.
;2010-04-21: M
;	Added the sqpbs function.
;2010-04-08: M
;	Added the sqexec function.
;2010-04-06: M
;	Removed the sqgetcol function.
;2009-07-14: M
;	Added the sqgetcol function.
;


;Opens a connection by calling sqlite3_open.
;
;PARAMETERS:
;	esi ... Pointer to the name of the database
sqopen: push	dbpont
	push	esi
	call	[sqlite3_open]
	add	esp,0x8
	ret


;Closes the database connection:
sqclose:push	[dbpont]
	call	[sqlite3_close]
	add	esp,0x4
	ret


; sqprep hat einen Paramenter, nämlich die Adresse einer SQL-Anweisung, für
; welche der SQLite-Bytecode erzeugt werden soll. Die Adresse zu diesem wird
; sqcomp gespeichert.
sqprep:	push	sqtail
	push	sqcomp
	push	-1		; Länge
	push	dword[esp+0x10]	; Parameter 1
	push	[dbpont]
	call	[sqlite3_prepare_v2]
	add	esp,0x14	; sqlite3 löscht die Parameter nicht vom Stack!
	SQLERR
	ret	0x4

macro SQPREP sql {
	;DBG	sql
	push	sql
	call	sqprep
}


; sqbind bindet den Parameter x einer SQL-Anweisung und erwartet somit zwei
; Parameter:
;	index	... Index des Parameters in der SQL-Anweisung
;	pText	... Pointer zu einem Text, welcher gebunden werden soll
sqbind: push	ebp
	mov	ebp,esp
	index	equ dword[ebp+0x8]
	pText	equ dword[ebp+0xC]
	DBGI	_sqbind,pText
	push	0
	push	-1
        push	pText
	push	index			; Index of SQL-Parameter
	push	[sqcomp]
	call	[sqlite3_bind_text]
	add	esp,0x14
	SQLERR
	pop	ebp
	ret	0x8

macro SQBIND pText,column_nr {
	push	pText
	push	column_nr
	call	sqbind
}


;sqbindl(ike) bindet ähnlich der Funktion sqbind einen Textparameter in eine
;SELECT-Anweisung ein; dieser Parameter wird vorher jedoch noch auf NULL
;geprüft und in diesem Fall wird der Parameter auf "%" gesetzt und kann somit
;für LIKE-Klauseln genützt werden.
sqbindl:pText	equ dword[esp+0x8]
	mov	esi,pText
	cmp	byte[esi],0
	jnz	sqbind
	mov	word[esi],0x0025	; "%"-Wildcard mit abschließender 0
	jmp	sqbind


; Bindet einen Integer:
sqbindi:push	ebp
	mov	ebp,esp
	index	equ dword[ebp+0x8]
	val	equ dword[ebp+0xC]
	DBGI	_sqbindi,val
	push	val
	push	index
	push	[sqcomp]
	call	[sqlite3_bind_int]
	add	esp,0xC
	SQLERR
	pop	ebp
	ret	0x8


; Bindet einen Double-Wert:
sqbindd:push	ebp
	mov	ebp,esp
	index	equ dword[ebp+0x8]
	val	equ dword[ebp+0xC]
sqbindd_push_qword:
	mov	ebx,val
	push	dword[ebx+4]
	push	dword[ebx]
	fld	qword[esp]
sqbindd_push_rest:
	push	index
	push	[sqcomp]
	call	[sqlite3_bind_double]
	add	esp,0x10
	SQLERR
	pop	ebp
	ret	0x8


;sqbindn bindet den Parameter x einer SQL-Anweisung mit dem NULL-Wert:
sqbindn:;DBG	_sqbindn
	push	dword[esp+0x4]
	push	[sqcomp]
	call	[sqlite3_bind_null]
	add	esp,0x8
	ret	0x4


;sqbindstr binds a string to a SQL statement. Before the binding
;takes place, the string is validated for NULL. In this case
;(string is null), the NULL-value gets binded.
;
;PARAMETERS:
;	esi ... Address of string
;	ecx ... Number of column
sqbindstr:
	cmp	byte[esi],0
	jz	.bindnull
  .bindstr:
	push	esi
	push	ecx
	call	sqbind
	jmp	.end
  .bindnull:
	push	ecx
	call	sqbindn
  .end:	ret


; Returns the bind parameter count:
sqbindc:push	[sqcomp]
	call	[sqlite3_bind_parameter_count]
	add	esp,0x4
	ret


; The sqlite3_finalize() function is called to delete a prepared statement. 
; If the statement was executed successfully or not executed at all, then 
; SQLITE_OK is returned. If execution of the statement failed then an 
; error code or extended error code is returned.
sqfin:	push	[sqcomp]
	call	[sqlite3_finalize]
	add	esp,0x4
	ret


;After a statement has been prepared, this function must be called one
;or more times to evaluate the statement:
sqstep:	push	[sqcomp]		; Ausführen der Abfrage
	call	[sqlite3_step]
	add	esp,0x4
	ret


;sqlid gibt die ROWID des zuletzt eingefügten DS zurück:
sqlid:	push	[dbpont]
	call	[sqlite3_last_insert_rowid]
	add	esp,0x4
	ret


;Erwartet die Spaltennr als Parameter.
;The column numbers start at zero!
sqcol:	push	dword[esp+0x4]
	push	[sqcomp]
	call	[sqlite3_column_text]
	add	esp,0x8	; Param. von sqlite3 nicht gepopt!
	ret	0x4

macro SQCOL colnr {
	push	colnr
	call	sqcol
}

sqcoli:	push	dword[esp+0x4]
	push	[sqcomp]
	call	[sqlite3_column_int]
	add	esp,0x8
	ret	0x4

sqcold:	push	dword[esp+0x4]
	push	[sqcomp]
	call	[sqlite3_column_double]
	add	esp,0x8
	ret	0x4


;sqexec runs the sqlite3_exec function, which allows multiple
;SQL statements to be passed.
;
;PARAMETERS:
;	esi ... Pointer to SQL statements
sqexec: 
	mov	edi,tbuf1
	push	edi
	push	0	;Parameter for optional callback function
	push	0	;Address of optional callback function
	push	esi
	push	[dbpont]
	call	[sqlite3_exec]
	add	esp,0x14
	ret


;sqpbs stands for Prepare, Bind and Step trough an SQL statement.
;To be able to do this, this function needs several arguments, that
;all get passed via esi. Arguments are the SQL command and the 
;parameters to bind. All arguments are stored in a buffer, pointed
;to through esi. esi should point to:
;	first DWORD	... SQL comment
;	next DWORD	... Options for Parameter 1
;	next DWORD	... Parameter 1
;	next DWORD	... Options for Parameter 2
;	next DWORD	... Parameter 2
;	...
;	next DWORD	... Options for Parameter n
;	next DWORD	... Parameter n
;	last DWORD	... Should be zero to indicate end of arguments
;
;The options for the parameters can be:
;	1 ... Parameter is of Type String
;	2 ... Parameter is of Type Integer
;	4 ... Like option 2, but if parameter is zero, then
;		sqpbs will bind NULL.
;
;PARAMETERS:
;	esi ... Points to arguments, as described above.
;
;RETURN VALUES:
;Returns directly from the sqstep function and therefore uses
;the same return values.
sqpbs:	;Load and prepare SQL statement:
	lodsd
	push	eax
	call	sqprep
	xor	edi,edi		;Initialise index of SQL parameters
.load_options:
	;Load options for upcoming value:
	lodsd
	test	eax,eax
	jz	.step
	;Save option:
	mov	ebx,eax
	;Load value:
	lodsd
	inc	edi		;Raise index for SQL parameters
	;Push value and index of SQL parameters:
	push	eax edi
	;Check option:
	cmp	ebx,1
	jz	.bind_string
	cmp	ebx,2
	jz	.bind_integer
.bind_null_if_zero:		;Option 4
	test	eax,eax
	jnz	.bind_integer
	pop	edi eax
	push	edi
	call	sqbindn
	jmp	.load_options
.bind_integer:
	call	sqbindi
	jmp	.load_options
.bind_string:
	call	sqbind
	jmp	.load_options
.step:	call	sqstep
	ret


;The SQPBS macro prepares the parameters for a usage in the
;sqpbs function.
;
;PARAMETERS:
;	buffer	... Points to a buffer where the parameters for the
;			sqpbs function can get stored
;	sql	... Points to a SQL statement
;	[parameter] list is a unlimited number of additional parameters
;			for the sqpbs function, that hold the options
;			and the values to pass, in that order.
;
;USAGE:
;	SQPBS buffer,sql,1,str1,2,value1,1,str2
macro SQPBS buffer,sql,[parameter] {
common
	mov	edi,buffer
	;Save address of SQL statement:
	mov	eax,sql
	stosd
forward
	;Save parameter:
	mov	eax,parameter
	stosd
common
	;Save end-of-parameters indicator:
	xor	eax,eax
	stosd
	;Call sqpbs function:
	mov	esi,buffer
	call	sqpbs
}
