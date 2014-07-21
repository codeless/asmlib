
;
; Erstellt am: 09.04.2009
; Autor: M
;
; Funktionen für die SYSDATETIME-Struktur
;
; ***
;
; LETZTE ÄNDERUNG:
;
; TT.MM.JJJJ: Autor
;	Beschreibung
;


; sysdat2int wandelt die Jahres-, Monats- und Tageszahl in einer 
; SYSDATETIME Struktur um in einen Integer mit folgendem Format:
; 	JJJJMMDD
; Die SYSDATETIME-Struktur befindet sich am Punkt "systim"; der resultierende
; Integer wird in eax zurückgegeben.
;
; Die systim(SYSDATETIME)-Struktur:
;	systim:
;	systim.wYear		dw ?
;	systim.wMonth		dw ?
;	systim.wDayOfWeek	dw 0
;	systim.wDay		dw ?
;	systim.wHour		dw 0
;	systim.wMinute		dw 0
;	systim.wSecond		dw 0
;	systim.wMilliseconds	dw 0
sysdat2int:

  sd_init:

	push	edx
	xor	eax,eax
	xor	edx,edx

  sd_umwandlung:
  ._jahr:

	mov	ax,[systim.wYear]
	mov	dx,0x2710		; entspr. 10.000
	mul	edx

  ._monat:

	push	eax
	xor	eax,eax
	xor	edx,edx
	mov	ax,[systim.wMonth]
	mov	dx,0x64			; entspr. 100
	mul	edx
	pop	edx
	add	eax,edx

  ._tag:

	xor	edx,edx
	mov	dx,[systim.wDay]
	add	eax,edx

  sd_ende:

	pop	edx
	retn
