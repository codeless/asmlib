
;
;Created on: 2009-05-19
;Author: M
;
;Load and store settings from/into a file.
;
;***
;
;LAST MODIFICATION:
;
;YYYY-MM-DD: Author
;	Description
;2010-04-06: M
;	Added the config jump mark.
;


; Konfig erwartet einen Parameter in dl: dl kann entweder auf 0 (lesen) oder
; auf 1 (schreiben) gesetzt sein.
konfig:

	mov	esi,knam
	jmp	config.init

;config allows to pass the esi parameter as a source to the absolute
;path to the configuration file.
config:

  .init:

	mov	cx,3		; OPEN_EXISTING
	mov	edi,0x80000000	; GENERIC_READ
	xor	eax,eax
	mov	al,4		; OPEN_ALWAYS
	mov	ebx,0x40000000	; GENERIC_WRITE
	cmp	dl,0
	cmovz	ax,cx
	cmovz	ebx,edi

  .oeffnen:

	push	edx
	push	0		; Template File
	push	0x80		; FILE_ATTRIBUTE_NORMAL
	push	eax
	push	0		; Security structure
	push	0		; ShareMode
	push	ebx
	push	esi		; Filename
	call	[CreateFile]
	pop	edx
	cmp	eax,0xFFFFFFFF
	jz	.beenden
	mov	[hkonf],eax
	cmp	dl,0
	jz	.laden

  .speichern:

	push	0
	push	gelesen
	push	[klen]
	push	konfiguration
	push	[hkonf]
	call	[WriteFile]
	CHKERR	0
	jmp	.schliessen

  .laden:

	push	0
	push	gelesen
	push	[klen]
	push	tbuf1
	push	[hkonf]
	call	[ReadFile]
	CHKERR	0

  .laden_pruefen:

	mov	eax,[klen]
	cmp	[gelesen],eax
	jnz	.konfig_datei_ungueltig

  .laden_ok:
  .konfiguration_initialisieren:

	mov	esi,tbuf1
	mov	edi,konfiguration
	mov	ecx,[klen]
	repz	movsb

  .konfig_datei_ungueltig:
  .schliessen:

	push	[hkonf]
	call	[CloseHandle]
	CHKERR	0

  .beenden:

	ret


; Initialisiert die Position und Größe eines Fensters anhand folgender Struktur:
;	fenster:
;	fenster.xpos	dd	0
;	fenster.ypos	dd	0
;	fenster.breite	dd	400
;	fenster.hoehe	dd	240
;
; initwpos erwartet zwei Parameter:
;	eax ... Zeiger auf die Fensterstruktur
;	edx ... Window-Handle des zu initialisierenden Fensters
initwpos:

	push	0
	push	dword[eax+0xC]		; Höhe
	push	dword[eax+0x8]		; Breite
	push	dword[eax+0x4]		; YPos
	push	dword[eax]		; XPos
	push	edx			; hwnd
	call	[MoveWindow]
	CHKERR	0
	ret


; Erwartet die Parameter wie die Funktion initwpos. savwpos speichert die
; aktuellen Daten zum Fenster (Position & Größe) in der
savwpos:

	push	eax

  .daten_anfordern:

	push	eax
	push	edx
	call	[GetWindowRect]
	CHKERR	0

  .daten_an_struktur_anpassen:

	pop	eax
	mov	edx,dword[eax+0x8]	; Breite
	sub	edx,dword[eax]
	mov	dword[eax+0x8],edx
	mov	edx,dword[eax+0xC]	; Höhe
	sub	edx,dword[eax+0x4]
	mov	dword[eax+0xC],edx

	ret
