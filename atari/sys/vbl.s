; -----------------------------------------------------------------------------
vbl:
	movem.l	d0-a6,-(a7)
	clr.b	$ffff8260.w			; lo res in the safe area...
	move.b	#2,$ffff820a.w			;... and 50Hz

	addq.l	#1,$466.w

	; Run effect-specific stuff
	move.l	vbl_callback,a0
	jsr	(a0)

	movem.l	(a7)+,d0-a6
	rte					;HBL is just a dummy

	bss
vbl_callback:
	ds.l	1

	text