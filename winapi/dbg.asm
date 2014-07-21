
;Created on 2009-07-15
;Author: M
;
;Debug Macro for Windows applications to send debug strings to an debugger.
;
;***
;
;LAST MODIFICATION:
;
;2011-03-29: M
;	Added the DBG_MB macro.
;

macro DBG str
{
	match =1,DEBUG
	\{
		pushad
		push	str
		call	[OutputDebugString]
		popad
	\}
}

macro DBGI format,int
{
	match =1,DEBUG
	\{
		pushad
		push	int
		push	format
		push	_dbgbuf
		call	[wsprintf]
		add	esp,0xC
		DBG	_dbgbuf
		popad
	\}

}

macro DBG_MB str
{
	match =1,DEBUG
	\{
		pushad
		push	0x000010	; MB_ICONERROR
		push	0
		push	str
		push	0
		call	[MessageBox]
		popad
	\}
}

macro DBGI_MB format,int
{
	match =1,DEBUG
	\{
		pushad
		push	int
		push	format
		push	_dbgbuf
		call	[wsprintf]
		add	esp,0xC
		DBG_MB	_dbgbuf
		popad
	\}

}
