
TEXT_SET	=	$ff
TEXT_PAUSE	=	$fe
TEXT_WIPE	=	$fd
TEXT_RASTER	=	$fc

text_update:
	tst.w	text_wipe_timer
	beq.s	.not_wipe
	bra	text_wipe				; don't continue until
.not_wipe:
	; Normal mode, show a cursor
	tst.w	text_seq_pause
	beq.s	.not_paused

	; Pausing -- flash the cursor now
	bsr	flash_cursor
	subq.w	#1,text_seq_pause
	bne.s	.done
	; About to start showing text or doing wipes.
	; Clear cursor again
	bsr	clear_cursor
.done:	rts

.not_paused:
	move.l	text_seq_pos,a0				; a0 = control codes etc
text_read_next:
	moveq	#0,d0
	move.b	(a0)+,d0
	bne.s	.valid
	bsr	flash_cursor
	rts						; 0 = end of sequence
.valid:	bpl.s	text_is_char
	cmp.b	#TEXT_SET,d0
	bne.s	.not_set
	moveq	#0,d0
	move.b	(a0)+,d0
	move.w	d0,text_x
	move.b	(a0)+,d0
	move.w	d0,text_y
	bra	text_read_next
.not_set
	cmp.b	#TEXT_PAUSE,d0
	bne.s	.not_pause
	moveq	#0,d0
	move.b	(a0)+,d0
	move.w	d0,text_seq_pause
	move.l	a0,text_seq_pos				; remember position
	rts
.not_pause:
	cmp.b	#TEXT_WIPE,d0
	bne.s	.not_wipe
	move.l	a0,text_seq_pos				; remember position
	bsr	clear_cursor
	move.w	#50,text_wipe_timer
	rts
.not_wipe:
	cmp.b	#TEXT_RASTER,d0
	bne.s	.not_raster

	move.b	(a0)+,raster_line+1
	bra	text_read_next

.not_raster:
	illegal
	bra	text_read_next

text_is_char:
	; d0 = char to draw
	; Read one char
	move.l	a0,text_seq_pos				; remember position
	cmp.w	#' ',d0
	beq.s	.space

	move.w	d0,d2
	move.w	d2,-(a7)
	; Draw char on both screens
	movem.w	text_x,d0/d1
	move.l	logic,a0
	addq.l	#6,a0
	bsr	text_draw_char

	move.w	(a7),d2					; refetch character to draw
	movem.w	text_x,d0/d1
	move.l	physic,a0
	addq.l	#6,a0
	bsr	text_draw_char

	; Apply width
	move.w	(a7)+,d2				; d2 character
	sub.w	#" ",d2
	add.w	d2,d2
	add.w	d2,d2
	lea	font_100_widths,a4
	move.w	0(a4,d2.w),d0				; Apply character width
	add.w	d0,text_x+0
	rts
.space:	add.w	#8,text_x+0
	rts

flash_cursor:
	btst	#4,sequence_vbl+1
	beq	clear_cursor

draw_cursor:
	bsr	cursor_setup
o	set	BYTES_PER_LINE
	rept	4
	or.w	d2,o(a0)
	or.w	d3,o+8(a0)
	or.w	d2,o(a1)
	or.w	d3,o+8(a1)
o	set	o+BYTES_PER_LINE
	endr
	rts

clear_cursor:
	bsr	cursor_setup
o	set	BYTES_PER_LINE
	rept	4
	and.w	d3,o(a0)
	and.w	d2,o+8(a0)
	and.w	d3,o(a1)
	and.w	d2,o+8(a1)
o	set	o+BYTES_PER_LINE
	endr
	rts
cursor_setup:
	movem.w	text_x,d0/d1
	add.w	#11,d1					; cursor pos hack
	mulu.w	#BYTES_PER_LINE,d1
	lea	text_x_offset_table,a0
	asl.w	#3,d0
	movem.w	(a0,d0.w),d0/d2				; offset, mask
	add.l	d0,d1
	move.l	logic,a0
	addq.l	#6,a0
	add.l	d1,a0
	move.l	physic,a1
	addq.l	#6,a1
	add.l	d1,a1

	move.w	d2,d3
	not.w	d3
	rts

text_wipe:
	move.w	text_wipe_timer,d0
	subq.w	#1,d0
	move.w	d0,text_wipe_timer
	mulu.w	#BYTES_PER_LINE*4,d0
	addq.l	#6,d0
	move.l	logic,a0
	move.l	physic,a1
	add.l	d0,a0
	add.l	d0,a1
	moveq	#0,d0
	moveq	#4-1,d7
.row_loop:
o	set	0
	rept	20
	move.w	d0,o(a0)
	move.w	d0,o(a1)
o	set	o+8
	endr
	lea	BYTES_PER_LINE(a0),a0
	lea	BYTES_PER_LINE(a1),a1
	dbf	d7,.row_loop
	move.w	#13,text_x
	move.w	#10,text_y
	rts

; TODO add as a command
	ifne	0
text_draw_centred:
	; Calculate centre position
	lea	font_100_widths,a4
	add.w	d0,d0					; we divide through later
.loop:
	moveq	#0,d7
	move.b	(a1)+,d7
	beq.s	.finished
	sub.w	#' ',d7
	add.w	d7,d7
	add.w	d7,d7					; d7 = gfx table lookup
	sub.w	0(a4,d7.w),d0				; Apply character width
	bra.s	.loop
.finished:
	move.l	(a7)+,a1
	asr.w	#1,d0					; centred value
	illegal
	endif

; -----------------------------------------------------------------------------
; d0,d1	x,y
; d2 char
;,a0 screen
; a1 text
text_draw_char:
	move.b	#BLT_OP_S_OR_T,BLT_OP_B.w
	move.b	#BLT_HOP_SRC,BLT_HOP_B.w
	move.w	#0,BLT_SRC_INC_X_W.w
	move.w	#2,BLT_SRC_INC_Y_W.w
	move.w	#8,BLT_DST_INC_X_W.w
	move.w	#BYTES_PER_LINE-8*1,BLT_DST_INC_Y_W.w
	move.w	#2,BLT_COUNT_X_W.w			; assume shift
	move.w	#$ffff,BLT_ENDMASK_3_W.w

	lea	font_100_bitmaps,a3			; a3 = bitmap data
	lea	font_100_widths,a4			; a4 = widths and bitmap offsets

	lea	text_x_offset_table(pc),a5
	lsl.w	#3,d0					; adjust X
	add.w	d0,a5					; a5 = current table position
	mulu.w	#BYTES_PER_LINE,d1
	add.l	d1,a0					; a0 = screen position (for x=0)

	sub.w	#' ',d2
	add.w	d2,d2
	add.w	d2,d2					; d2 = gfx table lookup
	move.w	2(a4,d2.w),d2				; look up in gfx offset table
	bmi.s	.skip					; skip empty entries

	move.l	a3,a6
	add.w	d2,a6					; a5 glyph gfx
	move.l	a6,BLT_SRC_ADDR_L.w

	movem.w	(a5),d2/d3/d4				; from current X position
							; d2 = screen offset
							; d3 = leftmask
							; d4 = MISC_1 Data

	lea	(a0,d2.w),a2				; a2 = screen address
	move.b	d4,BLT_MISC_2_B.w
	move.w	d3,BLT_ENDMASK_1_W.w
	move.l	a2,BLT_DST_ADDR_L.w
	move.w	#16,BLT_COUNT_Y_W.w
	move.b	#BLT_MISC_1_BUSY|BLT_MISC_1_HOG,BLT_MISC_1_B.w	; go
.skip:
	rts

text_x_offset_table:
	REPT	PIXELS_PER_LINE
	dc.w	(REPTN/16)*8			; screen offset
	dc.w	$ffff>>(REPTN&15)		; left mask
	dc.w	(REPTN&15)|BLT_MISC_2_NFSR	; BLT_MISC_2 control word
	dc.w	0
	ENDR

text_seq_none:
	dc.b	0
	even

TPOS	macro
	dc.b	TEXT_SET,\1,\2
	endm

TPAUSE	macro
	dc.b	TEXT_PAUSE,\1
	endm

TWIPE	macro
	dc.b	TEXT_WIPE
	endm

TRASTER	macro
	dc.b	TEXT_RASTER,\1
	endm


text_seq_pause:	ds.w	1
text_seq_pos:	ds.l	1
text_x		ds.w	1
text_y		ds.w	1
text_wipe_timer	ds.w	1

