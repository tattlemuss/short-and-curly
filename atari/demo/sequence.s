
; a0 = _pointer_ to current sequence address, which is always the value
sequence_update:
	move.l	(a0),a1			; a1 = next seq data to read, which will be a wait time
	moveq	#0,d0
	move.w	(a1)+,d0		; expected trigger time
	bmi.s	.exit
	cmp.w	sequence_vbl,d0
	ble.s	.next
.exit:	rts

; Loop through all commands until we get a "wait"
.fetch_next_command:
	move.l	(a0),a1			; a1 = next seq data to read, which will be a wait time

.next:	move.l	(a1)+,a2		; a2 = routine
	move.l	a1,(a0)			; save position
	pea	(a0)
	jsr	(a2)			; enter the routine
	move.l	(a7)+,a0
	bra	.fetch_next_command

sequence_vbl:	dc.w	0

