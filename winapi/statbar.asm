
;
; Erstellt am: 28.05.2009
; Autor: M
;
; Funktionen für Statusbar-Controls.
;
; ***
;
; LETZTE ÄNDERUNG:
;
; TT.MM.JJJJ: Autor
;	Beschreibung
; 22.06.2009: M
;	Die Wrapper-Funktion loads wird nun anstelle der Winapi-Funktion
;	LoadString verwendet.
;


; sbtxt lädt einen String aus den Resourcen und gibt diesen in der Statusbar
; aus.
;	ebx ... Spaltennr. der Statusbar für Textausgabe
;	ecx ... ID der zu ladenden Zeichenkette
sbtxt:

  .lade_nachricht:

	mov	edi,statbuf
	call	loads

  .text_an_statusbar_senden:

	push	edi
	push	ebx
	push	0x401		; SB_SETTEXT
	push	[hstat]
	call	[SendMessage]
	test	eax,eax
	jz	errout

  .beenden:

	ret


; "Löscht" Text aus einer Statusbar, indem statbuf auf 0 gesetzt wird:
;	ebx ... Spaltennr. der Statusbar für Textausgabe
sbclr:	xor	edi,edi
	jmp	sbtxt.text_an_statusbar_senden
