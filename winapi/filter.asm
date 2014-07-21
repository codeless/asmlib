
;
; Erstellt am: 28.04.2009
; Autor: M
;
; Filterfunktion für ListViews. Diese Filterfunktion kann für jede ListView
; verwendet werden, denn die Items werden nicht mittels einer SQL Anweisung
; gefiltert, sondern es wird jedes Item und jedes Subitem auf den Filter
; kontrolliert und je nach Ergebnis dann gelöscht oder stehen gelassen.
; Ist kein Textfilter gesetzt, gibt die Funktion 0 zurück!
;
; ***
;
; LETZTE ÄNDERUNG:
;
; TT.MM.JJJJ: Autor
;	Beschreibung
;

; Parameter:
;	hwnd	... ListView-Handle 
dlgfilter:

  df_init_parameter:

	sub	esp,0x4
	push	ebp
	mov	ebp,esp
	hctrl	equ dword[ebp+0x4]
	hwnd	equ dword[ebp+0xC]

  df_hole_lv_headercontrol:

	push	0
	push	hwnd
	call	[GetDlgItem]
	CHKERR	0
	mov	hctrl,eax

  df_init_hditm_fuer_HDM_GETITEM:

	push	[aheap]
	pop	hdtxtf.pszText
	mov	hdtxtf.cchTextMax,0x32
	mov	[hditm.mask],0x100	; HDI_FILTER
	mov	[hditm.type],0		; HDFT_ISSTRING
	mov	[hditm.pvFilter],hdtxtf

  df_lv_redraw_ausschalten:

	SENDMSG	hwnd,0xB,0,0		; WM_SETREDRAW

  df_hole_spaltenanz:

	SENDMSG	hctrl,0x1200,0,0	; HDM_GETITEMCOUNT
	mov	ecx,eax
	push	ecx

  df_init_rc:

	xor	edx,edx

  df_hole_textfilter:

	dec	ecx
	push	ecx edx
	SENDMSG	hctrl,0x1203,ecx,hditm	; HDM_GETITEM
	pop	edx
	add	edx,eax

  df_hole_filterlaenge:

	xor	eax,eax
	mov	esi,hdtxtf.pszText
	cmp	byte[esi],0
	jz	df_speicher_filterlaenge
	push	edx
	push	hdtxtf.pszText
	call	[lstrlenA]
	pop	edx

  df_speicher_filterlaenge:

	mov	ebx,hdtxtf.pszText
	virtual at ebx
		text	rb 0x32
		strlen	dd ?
	end virtual
	mov	[strlen],eax
	add	hdtxtf.pszText,0x36

  df_naechster_textfilter:

	pop	ecx
	inc	ecx
	loopd	df_hole_textfilter

  df_kein_textfilter_gesetzt:

	cmp	dx,0
	jz	df_ende

  df_hole_anz_items:

	SENDMSG	hwnd,0x1004,0,0		; LVM_GETITEMCOUNT
	mov	ecx,eax

  df_init_lvitm:

	pop	edx
	dec	edx
	push	edx			; Spaltenanzahl
	mov	[lvitm.mask],0x1	; LVIF_TEXT
	mov	[lvitm.iItem],0
	mov	[lvitm.iSubItem],edx
	mov	[lvitm.pszText],tbuf1
	mov	[lvitm.cchTextMax],0x32
	mov	ebx,[aheap]

  df_items_abfragen:

	push	ecx
	
  df_abfrage_notwendig:

	cmp	dword[ebx+0x32],0
	jz	df_keine_abfrage_notwendig

  df_abfrage_ausfuehren:

	push	hwnd
	call	lvm_getitem_ex

  df_text_auf_filterlaenge_begrenzen:

	mov	eax,[ebx+0x32]
	mov	esi,tbuf1
	lea	esi,[esi+eax]
	mov	byte[esi],0

  df_text_mit_filter_vergleichen:

	push	ebx
	push	tbuf1
	push	ebx
	call	[lstrcmpiA]
	pop	ebx
	cmp	eax,0
	jz	df_keine_abfrage_notwendig

  df_item_zum_loeschen_markieren:

	mov	[lvitm.mask],0x4	; LVIF_PARAM
	mov	[lvitm.lParam],0xFFFFFFFF
	push	lvitm
	push	0
	push	0x1006			; LVM_SETITEM
	push	hwnd
	call	[SendMessage]
	mov	[lvitm.iSubItem],0	; springe zum nächsten Item

  df_keine_abfrage_notwendig:

	pop	ecx
	cmp	[lvitm.iSubItem],0
	jnz	df_naechstes_subitem

  df_naechstes_item:

	inc	[lvitm.iItem]
	pop	edx			; Spaltenanzahl
	push	edx
	mov	[lvitm.iSubItem],edx
	mov	ebx,[aheap]
	jmp	df_schleife_fortsetzen

  @@:	jmp	df_items_abfragen

  df_naechstes_subitem:

	dec	[lvitm.iSubItem]
	inc	ecx
	lea	ebx,[ebx+0x36]

  df_schleife_fortsetzen:

	;loop	df_items_abfragen
	loop	@b			; direkter sprung zu weit...

  df_markierte_items_suchen:

	mov	lvfind.flags,0x1	; LVFI_PARAM
	mov	lvfind.lParam,0xFFFFFFFF
	;SENDMSG	hwnd,0x100D,0xFFFFFFFF,lvfind	; LVM_FINDITEM
	push	lvfind
	push	0xFFFFFFFF
	push	0x100D			; LVM_FINDITEM
	push	hwnd
	call	[SendMessage]
	CHKERR	0xFFFFFFFF

  df_lv_neu_zeichnen:

	SENDMSG	hwnd,0xB,1,0

  df_ende:

	pop	edx
	add	esp,0x4
	pop	ebp
	ret	0x4
