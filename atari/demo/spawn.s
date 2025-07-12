
; -----------------------------------------------------------------------------
spawn:
	; Loop over spawning
	move.w	spawn_count,d7
	beq.s	.no_spawn
	subq.w	#1,d7
.spawn_loop:
	move.w	d7,-(a7)
	move.w	next_spawn_index,d0
	cmp.w	active_move_count,d0				; check for end-of-buffer
	blt.s	.no_wrap
	moveq	#0,d0
.no_wrap:
	move.w	d0,next_spawn_index
	addq.w	#1,next_spawn_index				; prepare for next
	move.l	active_spawn_func,a2
	jsr	(a2)
	move.w	(a7)+,d7
	dbf	d7,.spawn_loop
.no_spawn:
	rts


SPAWN_BLOB	macro
		lea	.config,a2
		bra	spawn_blob
.config:
		endm

SPAWN_PART	macro
		lea	.config,a2
		bra	spawn_part
.config:
		endm

SPAWN_DIV	macro
		lea	.config,a2
		bra	spawn_divided
.config:
		endm

spawn_func_1:
	SPAWN_BLOB
	dc.w	160,100-4				; Y width + centre
	dc.w	0					; Y random_mask
	; There are 128 blobs, spawned at 4/frame
	; Speed is 2 pixels per frame
	dc.w	0,160-128+8				; X width + centre
	dc.w	0					; X random_mask
	dc.w	0					; mask off rotation anim
	dc.w	0					; rotation anim speed

spawn_func_1a:
	SPAWN_BLOB
spawn_y_scale_bodge:
	dc.w	160,100-4				; Y width + centre
	dc.w	0					; Y random_mask
	; There are 128 blobs, spawned at 4/frame
	; Speed is 2 pixels per frame
	dc.w	0,160-128+8				; X width + centre
	dc.w	0					; X random_mask
	dc.w	0					; mask off rotation anim
	dc.w	0					; rotation anim speed

spawn_func_1b:
	SPAWN_BLOB
	dc.w	160,100-4				; Y width + centre
	dc.w	0					; Y random_mask
	dc.w	(50-32)/2,(50)/2			; X width + centre
	dc.w	(8<<PBUF_FRAC_SHIFT_R)-1		; X random_mask
	dc.w	$ffff					; enable rotation mask
	dc.w	8					; rotation anim speed

spawn_func_1c:
	SPAWN_BLOB
	dc.w	160,100-4				; Y width + centre
	dc.w	(32<<PBUF_FRAC_SHIFT_R)-1		; Y random_mask
	dc.w	(50-32)/2,(50)/2			; X width + centre
	dc.w	(32<<PBUF_FRAC_SHIFT_R)-1		; X random_mask
	dc.w	$ffff					; enable rotation mask
	dc.w	16					; rotation anim speed

spawn_func_1d:
	SPAWN_BLOB
	dc.w	160,85					; Y width + centre
	dc.w	(32<<PBUF_FRAC_SHIFT_R)-1		; Y random_mask
	dc.w	(130-64)/2,(130-64)/2			; X width + centre
	dc.w	(32<<PBUF_FRAC_SHIFT_R)-1		; X random_mask
	dc.w	$ffff					; enable rotation mask
	dc.w	32					; rotation anim speed

spawn_func_2:
	SPAWN_PART
	dc.w	160,85					; Y width + centre
	dc.w	(64<<PBUF_FRAC_SHIFT_R)-1		; Y random_mask
	dc.w	(320-64)/2,(310-64)/2			; X width + centre
	dc.w	(64<<PBUF_FRAC_SHIFT_R)-1		; X random_mask

spawn_func_3:
	SPAWN_PART
	dc.w	160,85					; Y width + centre
	dc.w	(8<<PBUF_FRAC_SHIFT_R)-1		; Y random_mask
	dc.w	(320-16)/2,(310-16)/2			; X width + centre
	dc.w	(8<<PBUF_FRAC_SHIFT_R)-1		; X random_mask

spawn_func_4:
	SPAWN_PART
	dc.w	60,85					; Y width + centre
	dc.w	(32<<PBUF_FRAC_SHIFT_R)-1		; Y random_mask
	dc.w	100,(310-32)/2				; X width + centre
	dc.w	(32<<PBUF_FRAC_SHIFT_R)-1		; X random_mask

; Left side is 0-151
; Right side is 162-319
spawn_func_divided:
	SPAWN_DIV
	dc.w	(200-32)/2,(200-32)/2			; Y width + centre
	dc.w	(32<<PBUF_FRAC_SHIFT_R)-1		; Y random_mask
	dc.w	(151-16),(151-16)/2			; X width + centre
	dc.w	(16<<PBUF_FRAC_SHIFT_R)-1		; X random_mask
	dc.w	80+96					; division offset

spawn_func_united:
	SPAWN_DIV
	dc.w	(200-32)/2,(200-32)/2			; Y width + centre
	dc.w	(32<<PBUF_FRAC_SHIFT_R)-1		; Y random_mask
	dc.w	(252-32)/2,(252-32)/2			; X width + centre
	dc.w	(32<<PBUF_FRAC_SHIFT_R)-1		; X random_mask
	dc.w	60					; division offset


spawn_blob:
; d0 = particle index
; a2 = config
	move.w	d0,d1

	mulu.w	#10,d1
	lea	blob_metadata,a0
	add.w	d1,a0					; a0 = slot in blob_metadata

	; Colour/Bitplane
	moveq	#0,d1
	move.w	d0,d1
	divu	#6,d1					; choose bitplane
	swap	d1
	and.w	#$6,d1
	move.w	d1,(a0)+				; write bitplane #

	; Animation
	move.w	14(a2),(a0)+				; rotation speed
	move.w	spawn_rotation,d1
	and.w	12(a2),d1				; mask off in some modes
	move.w	d1,(a0)+				; sprite offset

	move.l	active_sprite_gfx,(a0)+			; base gfx
	; Position
	lsl.w	#2,d0
	lea	parts,a0
	add.w	d0,a0					; a0 = particle YX buffer

	lea	sine_table,a1
	; Y coord first
	move.w	spawn_counter_y,d1
	and.w	#SINE_MASK,d1
	move.w	(a1,d1.w),d1
	muls.w	0(a2),d1
	swap	d1
	add.w	2(a2),d1
	lsl.w	#PBUF_FRAC_SHIFT_R,d1

	; Apply random factor
	jsr	generate_random
	and.w	4(a2),d0
	add.w	d0,d1
	move.w	d1,(a0)+				; write Y position to particle bufferc

	; X coord
	move.w	spawn_counter_x,d1
	and.w	#SINE_MASK,d1
	move.w	(a1,d1.w),d1
	muls.w	6(a2),d1				; X range
	swap	d1
	add.w	8(a2),d1
	lsl.w	#PBUF_FRAC_SHIFT_R,d1
	jsr	generate_random
	and.w	10(a2),d0
	add.w	d0,d1
	move.w	d1,(a0)+				; write X position to particle bufferc
	rts


spawn_part:
; d0 = particle index
; a2 = config
	move.w	d0,d3					; d3 part index
	lsl.w	#2,d0
	lea	parts,a0
	add.w	d0,a0

	lea	sine_table,a1
	; Y coord first
	move.w	spawn_counter_y,d1
	and.w	#SINE_MASK,d1
	move.w	(a1,d1.w),d1
	muls.w	0(a2),d1
	swap	d1
	add.w	2(a2),d1
	lsl.w	#PBUF_FRAC_SHIFT_R,d1

	; Apply random factor
	jsr	generate_random
	and.w	4(a2),d0
	add.w	d0,d1
	move.w	d1,(a0)+				; write Y position to particle bufferc

	; X coord
	move.w	spawn_counter_x,d1
	and.w	#SINE_MASK,d1
	move.w	(a1,d1.w),d1
	muls.w	6(a2),d1				; X range
	swap	d1
	add.w	8(a2),d1
	lsl.w	#PBUF_FRAC_SHIFT_R,d1
	jsr	generate_random
	and.w	10(a2),d0
	add.w	d0,d1

	; Colour (particle)
	;move.w	d1,d2					; d1 = X pos
	;cmp.w	#160<<PBUF_FRAC_SHIFT_R,d2
	;spl	d2
	;and.w	#2,d2

	ext.l	d3
	mulu.w	#MAX_PART_COUNT/3,d3
	swap	d3
	add.w	d3,d3
	move.w	d3,d2

	lea	smc_buf_render,a2
	move.w	next_spawn_index,d0
	mulu.w	#SMC_BUF_RENDER_STRIDE,d0
	move.w	d2,6(a2,d0.l)				; write colour into smc buffer
	move.w	d1,(a0)+				; write X position to particle bufferc
	rts


spawn_divided:
; d0 = particle index
; a2 = config
	btst.l	#0,d0					; odd or even?
	sne	d6
	ext.w	d6
	and.w	12(a2),d6				; d6 = X shift for odd/even

	lsl.w	#2,d0
	lea	parts,a0
	add.w	d0,a0

	lea	sine_table,a1
	; Y coord first
	move.w	spawn_counter_y,d1
	and.w	#SINE_MASK,d1
	move.w	(a1,d1.w),d1
	muls.w	0(a2),d1
	swap	d1
	add.w	2(a2),d1
	lsl.w	#PBUF_FRAC_SHIFT_R,d1

	; Apply random factor
	jsr	generate_random
	and.w	4(a2),d0
	add.w	d0,d1
	move.w	d1,(a0)+				; write Y position to particle bufferc

	; X coord
	move.w	spawn_counter_x,d1
	and.w	#SINE_MASK,d1
	move.w	(a1,d1.w),d1
	muls.w	6(a2),d1				; X range
	swap	d1
	add.w	8(a2),d1

	add.w	d6,d1					; apply odd/even

	lsl.w	#PBUF_FRAC_SHIFT_R,d1
	jsr	generate_random
	and.w	10(a2),d0
	add.w	d0,d1

	; Colour (particle)
	move.w	d1,d2
	tst.w	d6					; check odd/even
	sne	d2
	and.w	#2,d2
	lea	smc_buf_render,a2
	move.w	next_spawn_index,d0
	mulu.w	#SMC_BUF_RENDER_STRIDE,d0
	move.w	d2,6(a2,d0.l)				; write colour into smc buffer

	move.w	d1,(a0)+				; write X position to particle bufferc
	rts

; -----------------------------------------------------------------------------
			bss
next_spawn_index:	ds.w	1
spawn_counter_x:	ds.w	1
spawn_counter_y:	ds.w	1
spawn_rotation:		ds.w	1
			text
