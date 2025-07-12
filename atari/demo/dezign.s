WAIT	macro
	dc.l	cmd_wait
	dc.w	(\1*($40*7))+((\2)*7)	; pattern, step
	endm

	; There is a delay here, so we need to compensate
	; S03 at step 0
	; S30 at step 3F
PART2_START	equ	($A*64*7)+(63*4)+$30		; length of previous patterns, plus length of pattern
	printv	PART2_START

WAIT2	macro
	dc.l	cmd_wait
	dc.w	PART2_START+(\1*($40*7))+((\2)*7)	; pattern, step
	endm

FLOWMAP	macro
	dc.l	cmd_flowmap
	dc.l	flowmap_\1
	endm

FLOWADD	macro
	dc.l	cmd_movel
	dc.l	flowadd
	dc.w	\1
	dc.w	\2
	endm

WIPESPD	macro
	dc.l	cmd_wipe_speed
	dc.w	\1
	endm

SETTEXT	macro
	dc.l	cmd_text
	dc.l	\1
	endm

SETPAL	macro
	dc.l	cmd_movel
	dc.l	target_palette
	dc.l	\1
	dc.l	cmd_movew
	dc.l	target_palette_speed
	dc.w	\2
	endm

COUNTS	macro
	dc.l	cmd_counts
	dc.w	\1,\2
	endm

SHOW	macro
	dc.l	cmd_show
	dc.b	\1,\2
	endm

SP_RATE	macro
	dc.l	cmd_movew
	dc.l	spawn_count
	dc.w	\1
	endm

SP_CONF macro
	dc.l	cmd_movel
	dc.l	active_spawn_func
	dc.l	\1
	endm

SP_SPD macro
	dc.l	cmd_movel
	dc.l	spawner_speed
	dc.w	\1,\2
	endm

SEQ_END	macro
	dc.l	cmd_wait
	dc.w	-1
	endm

CLEAR	macro
	dc.l	cmd_clear
	endm

SPRITES	macro
	dc.l	cmd_movel
	dc.l	active_sprite_gfx
	dc.l	\1
	endm

LOOP	macro
	dc.l	cmd_loop
	dc.l	\1
	dc.w	PART2_START+(\2*($40*7))+((\3)*7)		; vbl value
	endm

MOVEW	macro
	dc.l	cmd_movew
	dc.l	\2
	dc.w	\1
	endm

BURST	macro
	WAIT	\1,\2
		FLOWMAP	burst
		SETPAL	pal_white,1
	WAIT	\1,(\2)+1		; wait a single step
		FLOWMAP	\3
		FLOWADD	((\4)<<PBUF_INT_BITCOUNT)/4,((\5)<<PBUF_INT_BITCOUNT)/4
		SETPAL	pal_hammer_\6,1
	endm

EXIT	macro
	dc.l	exit
	endm

; -----------------------------------------------------------------------------
cmd_wait:
	addq.l	#8,a7			; this escapes from the sequencing loop
	rts

cmd_flowmap:
	move.l	(a1)+,next_flowmap_ptr	; read arg
	move.l	a1,(a0)			; save position
	move.w	#0,wipe_counter
	rts

cmd_wipe_speed:
	move.w	(a1)+,wipe_speed	; read arg
	move.l	a1,(a0)			; save position
	rts

cmd_text:
	move.l	(a1)+,text_seq_pos	; read arg
	move.l	a1,(a0)			; save position
	bsr	clear_cursor
	rts

cmd_counts:
	move.w	(a1)+,active_blob_count		; read arg
	move.w	(a1)+,active_move_count		; read arg
	move.l	a1,(a0)				; save position
	rts

cmd_show:
	move.b	(a1)+,show_blobs		; read arg
	move.b	(a1)+,show_parts		; read arg
	move.l	a1,(a0)				; save position
	rts

cmd_clear:
	move.l	logic,a0
	jsr	clear_whole_screen
	move.l	physic,a0
	jsr	clear_whole_screen
	rts

; Generalised "move long to address"
cmd_movel:
	move.l	(a1)+,a2			; address to write
	move.l	(a1)+,(a2)			; copy data
	move.l	a1,(a0)				; save position
	rts

; Generalised "move word to address"
cmd_movew:
	move.l	(a1)+,a2			; address to write
	move.w	(a1)+,(a2)			; copy data
	move.l	a1,(a0)				; save position
	rts

cmd_loop:
	move.l	(a1)+,a2			; new read pointer
	move.w	(a1)+,d0			; new vbl value
	move.l	a2,(a0)				; save new position
	move.w	d0,sequence_vbl			; reset VBL counter!
	rts

cmd_exit:
	st.b	exit_flag
	rts

; -----------------------------------------------------------------------------
sequence_1:
	; Start off with very little
	DC.W	$0						; first wait time
		CLEAR
		COUNTS	110,110
		SETPAL	pal_text_only,1
		SHOW	0,0
		SP_CONF spawn_func_1
		SP_RATE 4
		SP_SPD	+21*3,SINE_COUNT/7+4
		WIPESPD	20
		FLOWADD	(1<<PBUF_INT_BITCOUNT)/2,0<<PBUF_INT_BITCOUNT
		FLOWMAP	empty
		SPRITES	sprite_arrow

	; Show 2 blobs, just moving
	WAIT	$0,$10
		SHOW	1,0
		SETPAL	pal_blobs_2,7
		SP_RATE	1

	WAIT	0,$28
		SETTEXT	text_long_and_straight

	; Narrow down the funnel
	WAIT	$0,30
		SP_CONF spawn_func_1a
		MOVEW	160,spawn_y_scale_bodge		; this shrinks to 0

	; Start the sine wave
	WAIT	$1,$00
		SP_SPD	+21*3,SINE_SIZE/2-23*1
		SP_CONF spawn_func_1b
		MOVEW	0,spawn_counter_y		; ensure start in middle
		MOVEW	0,spawn_rotation		; fix starting rotation
		WIPESPD	5
		FLOWADD	(1<<PBUF_INT_BITCOUNT)/2,(1<<PBUF_INT_BITCOUNT)/8

	; Vary again, and "short and curly"
	WAIT	$1,$20
		SP_CONF spawn_func_1c
		WIPESPD	5
		FLOWADD	(1<<PBUF_INT_BITCOUNT)/2,-(1<<PBUF_INT_BITCOUNT)/8
		FLOWMAP	tiny
		SETTEXT	text_short_and_curly
		SETPAL	pal_blobs_1,10

	WAIT	$1,$28
		SPRITES	sprite_stick2

	; Switch to nicer flow (gradual)
	WAIT	$2,$00
		WIPESPD	3
		FLOWADD	(1<<PBUF_INT_BITCOUNT)/2,0<<PBUF_INT_BITCOUNT
		FLOWMAP	2
		SETTEXT	text_messy
		SPRITES	sprite_quad

	; More static flow
	; Spawn across the screen
	WAIT	$3,$00
		SP_CONF spawn_func_1d
		WIPESPD	3
		FLOWADD	(1<<PBUF_INT_BITCOUNT)/2,0<<PBUF_INT_BITCOUNT
		FLOWMAP	fast
		SPRITES	sprite_tri2
		SETTEXT	text_chaotic

	WAIT	3,$10
		SPRITES	sprite_arrow

	WAIT	3,$30
		SPRITES	sprite_stick2

	WAIT	3,$36
		SPRITES	sprite_quad

	WAIT	$3,$3c
		SETPAL	pal_white,7

	; Particles appear
	WAIT	$4,$00
		CLEAR
		SHOW	0,1
		COUNTS	0,MAX_PART_COUNT
		SP_RATE	8
		WIPESPD	10
		FLOWADD	0,0
		FLOWMAP	2
		;SETPAL	pal_parts_1,7
		SETPAL	pal_parts_cred2,7
		SP_CONF spawn_func_2
		SETTEXT	text_but_we_are_many

	; Division...
	WAIT	$5,$00
		SETTEXT	text_divide
		SETPAL	pal_parts_divide,7
		SP_RATE	4
		FLOWMAP	divided
		SP_CONF spawn_func_divided

	; .. then mix
	WAIT	$6,$00
		SETTEXT	text_conquer
		FLOWMAP	0
		SP_CONF spawn_func_united

	WAIT	$7,$00
		; Thinner ribbons
		SP_SPD 	SINE_COUNT/2+23,SINE_COUNT/2-31
		SETTEXT	text_dance
		SETPAL	pal_parts_1,7
		SP_RATE	8
		SP_CONF spawn_func_3
		WIPESPD	3
		FLOWMAP	0

	WAIT	$7,$3C
		SETPAL pal_white,7

	WAIT	$8,$00
	;	; Second breakdown here, needs something frenetic
	;	; Probably strong "stabs" of particles (lines?)
	;	; Flashing colours, sudden direction changes
	;	FLOWMAP	0
		SETTEXT	text_final
		SETPAL	pal_hammer_r1,1
		FLOWMAP	2
		SP_SPD 	23*4,-31*4
		COUNTS	0,MAX_PART_COUNT-50		; limit to stop frameout
		SP_RATE	10
		SHOW	0,1
		WIPESPD	40
		SP_CONF	spawn_func_4
		SP_SPD 	23*4,-31*4

	BURST	$8,$00,fast,+0,+0,r1
	BURST	$8,$03,fast,+0,+0,r1
	BURST	$8,$08,fast,+0,+0,r1
	BURST	$8,$0C,fast,+0,+0,r1
	BURST	$8,$10,fast,+0,+0,r1
	BURST	$8,$13,fast,+0,+0,r1
	BURST	$8,$18,fast,+0,+0,r1
	BURST	$8,$1C,fast,+0,+0,r1
	BURST	$8,$20,fast,+0,+0,r1
	BURST	$8,$23,fast,+0,+0,r1
	BURST	$8,$28,fast,+0,+0,r1
	BURST	$8,$2C,fast,+0,+0,r1
	BURST	$8,$30,fast,+0,+0,r1
	BURST	$8,$33,fast,+0,+0,r1
	BURST	$8,$38,fast,+0,+0,r1
	BURST	$8,$3C,fast,+0,+0,r1

	BURST	$9,$00,fast,+2,+0,r2
	BURST	$9,$03,fast,+0,+2,r2
	BURST	$9,$08,fast,-2,+0,r2
	BURST	$9,$0C,fast,+0,-2,r2
	BURST	$9,$10,fast,+2,+0,r2
	BURST	$9,$13,fast,+0,+2,r2
	BURST	$9,$18,fast,-2,+0,r2
	BURST	$9,$1C,fast,+0,-2,r2
	BURST	$9,$20,fast,+2,+0,r3
	BURST	$9,$23,fast,+0,+2,r3
	BURST	$9,$28,fast,-2,+0,r3
	BURST	$9,$2C,fast,+0,-2,r3
	BURST	$9,$30,fast,+2,+0,r3
	BURST	$9,$33,fast,+0,+2,r4
	BURST	$9,$38,fast,-2,+0,r4
	BURST	$9,$3C,fast,+0,-2,r4

	WAIT	$A,$00
		SETPAL	pal_text_only,10
		SETTEXT	text_and_then_it_stops

	;WAIT2	$0,$00

sequence_loop:
	WAIT2	$1,$20
		SETTEXT	text_credits
		COUNTS	0,MAX_PART_COUNT
		SETPAL	pal_parts_cred,10
		SP_RATE	4
		WIPESPD	10
		SP_CONF	spawn_func_2
		SP_SPD 	23*2,-31*2
		FLOWADD	0,0			;(1<<PBUF_INT_BITCOUNT)/2,0<<PBUF_INT_BITCOUNT
		FLOWMAP	0

	WAIT2	$2,$00
		FLOWMAP	1
		SETPAL	pal_parts_cred2,16


	WAIT2	$3,$00
		FLOWMAP	2
		SETPAL	pal_parts_cred,16

	WAIT2	$4,$00
	LOOP	sequence_loop,$01,$10
	SEQ_END

text_partyversion:
	TPOS	13,10
	dc.b	"PARTYVERSION"
	TWIPE
	dc.b	0

text_long_and_straight:
	TPOS	13,10
	dc.b	"LIFE'S NOT"
	TPOS	13,30
	dc.b	"LONG AND STRAIGHT"
	TPAUSE	200
	TWIPE
	dc.b	0

text_short_and_curly:
	TRASTER	110
	TPOS	13,10
	dc.b	"IT'S"
	TPAUSE	50
	TPOS	13,30
	dc.b	"SHORT AND CURLY"
	TPAUSE	100
	TWIPE
	TRASTER	0
	dc.b	0
	even

text_messy:
	TPAUSE	100
	TPOS	13,90
	dc.b	"MESSY"
	TPAUSE	100
	TWIPE
	dc.b	0
	even

text_chaotic:
	TPAUSE	100
	TPOS	13,90
	dc.b	"CHAOTIC"
	TPAUSE	100
	TWIPE
	dc.b	0
	even

text_but_we_are_many:
	TPAUSE	100
	TPOS	13,10
	dc.b	"BUT WE ARE MANY"
	TPAUSE	100
	TWIPE
	dc.b	0
	even

text_divide:
	TPAUSE	100
	TPOS	13,10
	dc.b	"THEY DIVIDE"
	TPAUSE	100
	TWIPE
	dc.b	0
	even

text_conquer:
	TPAUSE	100
	TPOS	13,10
	dc.b	"BUT WE CONQUER"
	TPAUSE	100
	TWIPE
	dc.b	0
	even

text_dance:
	TPAUSE	100
	TPOS	13,10
	dc.b	"AND WE DANCE"
	TPAUSE	100
	TWIPE
	dc.b	0
	even

text_final:
	TPOS	13,10
	dc.b	"THE FINAL CURVE"
	TPAUSE	150
	TWIPE
	dc.b	0
	even

text_and_then_it_stops:
	TPOS	13,10
	dc.b	"ONE DAY IT STOPS"
	TPAUSE	200
	TPOS	13,110
	dc.b	"DON'T FORGET TO DANCE"
	TPAUSE	200
	TPAUSE	100

	TWIPE
	TPOS	13,10
	dc.b	"DEDICATED TO"
	TPOS	13,30
	dc.b	"TORSTEN AND EDD"
	TPOS	13,110
	dc.b	"YOU DANCED"
	TPAUSE	200
	TWIPE
	dc.b	0

text_credits:
	TRASTER	9
	TPOS	13,10
	dc.b	"SHORT AND CURLY"
	TPOS	13,30
	dc.b	"WAS HACKED IN "
	TPOS	13,50
	dc.b	"TWO WEEKS BY"
	TPOS	13,70
	dc.b	"DAMO-RG AND TAT"
	TPOS	13,90
	dc.b	"FOR SOMMARHACK 2025"
	TPAUSE	200
	TPAUSE	200
	TWIPE

	TRASTER	0
	TPOS	13,10
	dc.b	"GREETINGS TO ALL"
	TPOS	13,30
	dc.b	"AT THE PARTY"
	TPOS	13,50
	dc.b	"AND EVERYONE NOT"
	TPOS	13,70
	dc.b	"AT THE PARTY"
	TPOS	13,90
	dc.b	"WE LOVE YOU ALL"
	TPOS	13,170
	dc.b	"///WRAP///"
	TPAUSE	200
	TPAUSE	200
	TWIPE

	dc.b	0
	even


PAL_LAYERED	macro
		dc.w	\1,\2,\3,\3
		dc.w	\4,\4,\4,\4
		dc.w	\5,\5,\5,\5
		dc.w	\5,\5,\5,\5
		endm

PAL_ADDITIVE	macro
		dc.w	\1
		dc.w	\2
		dc.w	\3
		dc.w	\3+\2
		dc.w	\4
		dc.w	\4+\2
		dc.w	\4+\3
		dc.w	\4+\2+\3
		; These are fixed
		dc.w	\5,\5,\5,\5
		dc.w	\5,\5,\5,\5
		endm

pal_text_only:		PAL_LAYERED	$665,$665,$665,$665,$EDC

pal_blobs_1:		PAL_LAYERED	$365,$EA5,$99A,$FC0,$EDC

pal_blobs_2:		PAL_ADDITIVE	$365,$E00,$0C0,$00E,$EDC

pal_hammer_r1:		PAL_LAYERED	$456,$EC8,$F48,$CDF,$EDC
pal_hammer_r2:		PAL_LAYERED	$844,$EC8,$F48,$CDF,$EDC
pal_hammer_r3:		PAL_LAYERED	$A33,$FCC,$F8C,$CDF,$EDC
pal_hammer_r4:		PAL_LAYERED	$D33,$FCE,$FCE,$CDF,$EDC

pal_hammer_flash:	PAL_LAYERED	$A88,$FDC,$FAC,$FFF,$FFF

pal_parts_1:		PAL_LAYERED	$113,$FF2,$F48,$28F,$EDC
pal_parts_divide:	PAL_LAYERED	$113,$FF2,$F48,$28F,$EDC
pal_parts_cred:		PAL_LAYERED	$334,$EC8,$F48,$CDF,$EDC
pal_parts_cred2:	PAL_LAYERED	$334,$F25,$FF2,$2FD,$EDC	; green/blue
;pal_parts_cred2:	PAL_LAYERED	$334,$8CE,$8F8,$F98,$EDC	; green/blue

pal_white:		dcb.w		16,$FFF