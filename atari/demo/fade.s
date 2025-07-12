
FADE_PART	macro
	and.w	#\1*$f,\2		; src
	and.w	#\1*$f,\3		; target
	cmp.w	\3,\2
	beq.s	.same\@
	blt.s	.d1_lower\@
	sub.w	#\1*2,\2
.d1_lower\@:
	add.w	#\1*1,\2
.same\@:
	endm

; a0 = palette
; a1 = buffer
; d0 = size of palette
; d1 = number of frames
fade_multi:
	move.w	#16-1,d7
fade_one:
	move.w	(a0),d0				; d0 = src (current)
	move.w	(a1)+,d4			; d4 = target

	move.w	d0,d1				; src
	move.w	d4,d5				; target
	FADE_PART $100,d1,d5
	move.w	d0,d2				; src
	move.w	d4,d6				; target
	FADE_PART $010,d2,d6
	; no need to copy
	FADE_PART $001,d0,d4
	or.w	d0,d1
	or.w	d1,d2
	move.w	d2,(a0)+
	dbf	d7,fade_one
	rts
