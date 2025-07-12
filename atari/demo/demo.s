
TOP_BORDER_LINES	equ	0
BOTTOM_BORDER_LINES	equ	0
LINES			equ	200+TOP_BORDER_LINES+BOTTOM_BORDER_LINES
BYTES_PER_LINE		equ	256
PIXELS_PER_LINE		equ	BYTES_PER_LINE*2
CHUNKS_PER_LINE		equ	20			; BYTES_PER_LINE/8

demo_init:
	jsr	sine_table_init

	; Set screen addresses
	move.l	#screen,d0
	sub.w	d0,d0
	move.l	d0,physic

	add.l	#$10000,d0
	move.l	d0,logic

	move.l	logic,a0
	jsr	clear_whole_screen
	move.l	physic,a0
	jsr	clear_whole_screen
	move.l	physic,d0
	lsr.w	#8,d0
	move.l	d0,$ffff8200.w

	move.l	#clstate1,clear_physic
	move.l	#clstate2,clear_logic

	move.l	#text_seq_none,text_seq_pos

	bsr	grid_border_init

	move.l	#sequence_1,sequence_curr_1
	move.w	#-1,wipe_counter
	move.l	#palette_black,target_palette

	move.w	#$2700,sr
	moveq	#0,d0					; track number
	jsr	music_init				; init music
	; Do this stuff last (timing related)

	move.b	$fffffa1d.w,d0
	and.b	#$f,d0					; preserve timer D control
	move.b	d0,$fffffa1d.w
	move.b	#192,$fffffa23.w			; timer C data (200Hz)
	or.b	#5<<4,d0
	move.b	d0,$fffffa1d.w				; timer C control

	; I accidentally left Timer C on, doing nothing!
	bset.b	#5,$fffffa09.w				; enable timer C
	bset.b	#5,$fffffa15.w				; mask timer C
	move.l	#timer_c,$114.w
	move.l	#demo_vbl,vbl_callback

	move.w	#0,active_move_count
	move.w	#0,active_blob_count
	move.l	#sprite_quad,active_sprite_gfx
	rts

; -----------------------------------------------------------------------------
demo_frame:

; Sequencing
	lea	sequence_curr_1,a0
	jsr	sequence_update

	; Do text early to avoid screen shear
	jsr	text_update

; Update and render
	bsr	clear_parts
	bsr	clear_blobs

	DBG_COL #$123
	bsr	update_parts2
	DBG_COL #$321

	bsr	render_parts
	bsr	render_blobs

; Spawning (for next frame)
	movem.w	spawner_speed,d0/d1
	add.w	d0,spawn_counter_x
	add.w	d1,spawn_counter_y
	jsr	spawn

	; slowly shrink Y scale at one point
	subq.w	#1,spawn_y_scale_bodge
	bpl.s	.no_clamp
	clr.w	spawn_y_scale_bodge
.no_clamp:
	addq.w	#1,spawn_rotation

	ifne	DEBUG
	cmp.b	#SCANCODE_LEFT_ARROW,last_keypress
	bne.s	.no_left
	subq.l	#4,flow_patt_ptr
.no_left:
	cmp.b	#SCANCODE_RIGHT_ARROW,last_keypress
	bne.s	.no_right
	addq.l	#4,flow_patt_ptr
.no_right:
	cmp.b	#SCANCODE_P,last_keypress
	bne.s	.no_pulse
	move.w	#0,wipe_counter
.no_pulse:
	endif

	bsr	update_wipe_2
	DBG_COL	#$000

; Buffer swaps
	; Swap screens
	move.l	logic,a0
	move.l	physic,logic
	move.l	a0,physic

	; Swap clstate
	movem.l	clear_physic,d0/d1
	exg.l	d0,d1
	movem.l	d0/d1,clear_physic

	; Flip to new physical screen
	move.l	physic,d0
	lsr.w	#8,d0
	move.l	d0,$ffff8200.w

	bsr	wait_vbl
	rts

; -----------------------------------------------------------------------------
demo_exit:
	; kill music
	jsr	music_exit
	clr.b	$FFFF8901.w			; kill sample
	rts

; -----------------------------------------------------------------------------
demo_vbl:
	addq.w	#1,sequence_vbl

	move.w	fade_counter,d0
	addq.w	#1,d0
	move.w	d0,fade_counter
	cmp.w	target_palette_speed,d0
	blt.s	.skip_fade

	clr.w	fade_counter
	; Do fading
	lea	temp_palette,a0
	move.l	target_palette,a1
	jsr	fade_multi
.skip_fade:
	lea	$ffff8240.w,a1
	lea	temp_palette,a0
	; Convert to STE
	rept	16
	move.w	(a0)+,d0
	move.w	d0,d1
	lsr.w	#1,d1
	and.w	#$777,d1
	lsl.w	#3,d0
	and.w	#$888,d0
	or.w	d1,d0
	move.w	d0,(a1)+
	endr

	clr.b	$fffffa1b.w
	move.w	raster_line,d0
	beq	.no_raster

	move.b	d0,$fffffa21.w
	move.b	#8,$fffffa1b.w
	bset	#0,$fffffa07.w
	bset	#0,$fffffa13.w
	move.l	#timer_b,$120.w

	move.w	$468.w,d0
	and.w	#$7,d0
	add.w	d0,d0
	move.l	rainbow_palette(pc,d0.w),d1
	swap	d1
	move.l	rainbow_palette(pc,d0.w),d1

	move.l	d1,raster_colour_1a
	move.l	d1,raster_colour_1b
	move.l	d1,raster_colour_1c
	move.l	d1,raster_colour_1d

	move.l	$ffff8250.w,raster_colour_2a
	move.l	$ffff8254.w,raster_colour_2b
	move.l	$ffff8258.w,raster_colour_2c
	move.l	$ffff825c.w,raster_colour_2d

.no_raster:
	move.b	#(BYTES_PER_LINE-160)/2,$ffff820f.w
	jsr	music_play
	rts
rainbow_palette:
	dc.w	$F80,$F80
	dc.w	$FC0,$FC0
	dc.w	$FF0,$FF0
	dc.w	$0F0,$0F0
	dc.w	$0CF,$0CF
	dc.w	$00F,$00F
	dc.w	$C0F,$C0F
	dc.w	$F0F,$F0F

; This was left on accidentally, wasting cycles...
timer_c:
	movem.l	d0-a6,-(a7)
	;jsr	music_play
	movem.l	(a7)+,d0-a6
	rte

timer_b:
raster_colour_1a = *+2
	move.l	#$0,$ffff8250.w
raster_colour_1b = *+2
	move.l	#$0,$ffff8254.w
raster_colour_1c = *+2
	move.l	#$0,$ffff8258.w
raster_colour_1d = *+2
	move.l	#$0,$ffff825c.w
	clr.b	$fffffa1b.w
	move.b	#20,$fffffa21.w
	move.b	#8,$fffffa1b.w
	move.l	#timer_b2,$120.w
	rte

timer_b2:
raster_colour_2a = *+2
	move.l	#$0,$ffff8250.w
raster_colour_2b = *+2
	move.l	#$0,$ffff8254.w
raster_colour_2c = *+2
	move.l	#$0,$ffff8258.w
raster_colour_2d = *+2
	move.l	#$0,$ffff825c.w
	clr.b	$fffffa1b.w
	rte

; ================================ PARTICLES ================================
;
;	Before I forget
;
;	The _particle positions* are stored Y then X (for faster update)
;	The _flow grids_ are stored X then Y
;
MAX_PART_COUNT		=	700			; Frames out at 700 with extra FX :(
MAX_BLOB_COUNT		=	110

PBUF_Y_COUNT		=	$20			; number of accessed Y rows
PBUF_X_COUNT		=	$40			; number of accessed X columns
PBUF_Y_VIS		=	25			; how many we can see
PBUF_X_VIS		=	40

PBUF_P_TO_G_SHIFT_R	=	3			; px to GRID conversion (divide by 8)
PBUF_Y_SHIFT_L		=	6			; 512px / 8px entries per row
PBUF_X_MASK_GRID	=	(1<<PBUF_Y_SHIFT_L)-1	; bits 0-n for X mask (grid)
PBUF_Y_MASK_GRID	=	((PBUF_Y_COUNT-1)<<PBUF_Y_SHIFT_L)	; Allow 0-31 as grid index
PBUF_G_TO_B_SHIFT_L	=	2			; convert GRID entry to BYTE offset

PBUF_FRAC_SHIFT_R	=	7			; fixed-point -> integer shift count
PBUF_INT_BITCOUNT	=	9			; number of bits in integer part
PBUF_INT_MASK		=	((1<<PBUF_INT_BITCOUNT)-1)<<PBUF_FRAC_SHIFT_R

; -----------------------------------------------------------------------------
; Write in flow velocities to push particles back into the screen
grid_border_init:
	lea	flow_data,a0
	moveq	#PBUF_Y_COUNT-1,d7			; d7 = Y row
.y_loop:
	; This writes into the X-part of the grid
	move.w	#-2<<PBUF_FRAC_SHIFT_R,0+4*PBUF_X_VIS(a0)	; RHS of visible screen
	move.w	#+2<<PBUF_FRAC_SHIFT_R,0+4*(PBUF_X_COUNT-1)(a0)	; LHS of visible screen (wraps)
	lea	PBUF_X_COUNT*4(a0),a0
	dbf	d7,.y_loop

	lea	flow_data,a0
	moveq	#PBUF_X_COUNT-1,d7			; d7 = Y row
.x_loop:
	; This writes into the Y-part of the grid
	move.w	#-2<<PBUF_FRAC_SHIFT_R,2+(PBUF_X_COUNT*4)*PBUF_Y_VIS(a0)	; bottom of visible screen
	move.w	#+2<<PBUF_FRAC_SHIFT_R,2+(PBUF_X_COUNT*4)*(PBUF_Y_COUNT-1)(a0)	; LHS of visible screen (wraps)
	lea	4(a0),a0
	dbf	d7,.x_loop
	rts

; -----------------------------------------------------------------------------
grid_copy_flow_data:
	lea	flow_data,a1				; target buffer
	moveq	#PBUF_Y_VIS-1,d7			; d7 = Y row
.y_loop:
	rept	PBUF_X_VIS
	move.l	(a0)+,(a1)+
	endr
	lea	(PBUF_X_COUNT-PBUF_X_VIS)*4(a1),a1
	dbf	d7,.y_loop
	rts

; -----------------------------------------------------------------------------
; Copy tiles across from the stored flowmap, into the active flowmap
; area which is used by the particles.
update_wipe_2:
	move.w	wipe_counter,d7
	bge.s	.run
	rts
.run:
	; a0 = wipe pattern
	; a1 = pattern -> grid conversion table
	; a2 = pattern data
	; a3 = flow_data
	lea	wipe_circle,a0
	move.w	d7,d0					; offset into wipe
	add.w	d0,d0					; 2 bytes per wipe step
	add.w	d0,a0					; a0 = position in wipe
	lea	flowmap_to_grid_offset,a1
	move.l	next_flowmap_ptr,a2			; a2 = new flowmap
	lea	flow_data,a3				; a3 = target flow buffer

	move.w	#40*25,d6
	sub.w	wipe_counter,d6				; d6 = remaining wipe count
	cmp.w	wipe_speed,d6				; is this less than a frame of update?
	blt.s	.clipped
	move.w	wipe_speed,d6				; use full speed
.clipped:
	add.w	d6,d7					; update pulse position

	; Read positions from the "wipe" and copy that item to the flow
	move.l	flowadd,d2				; d2 = flowadd
	subq.w	#1,d6					; loop counter
.copy_loop:
	move.w	(a0)+,d0				; d0 = flowmap offset
	move.w	(a1,d0.w),d1				; d1 = flow offset
	move.l	(a2,d0.w),d0
	add.l	d2,d0					; apply flowadd
	move.l	d0,(a3,d1.w)				; copy across
	dbf	d6,.copy_loop

	cmp.w	#40*25,d7
	blt.s	.no_end
	moveq	#-1,d7
.no_end:
	move	d7,wipe_counter
	rts

; -----------------------------------------------------------------------------
wipe_speed	dc.w	100
; -----------------------------------------------------------------------------
; Clear particles from 2 frames ago.
clear_parts:
; Clear particles
	tst.b	show_parts
	bne.s	.show
	rts
.show:
	move.l	clear_logic,a1
	lea	clstate_part_offsets(a1),a2

	move.l	logic,d1
	;move.w	clstate_part_count,d7
	moveq	#0,d6					; d6 = clear val

	; This always wipes all 700 particles -- so how did we lose some?
	rept	MAX_PART_COUNT
	move.w	(a2)+,d1
	move.l	d1,a3
	move.w	d6,(a3)
	endr
	rts

; -----------------------------------------------------------------------------
; Update particle positions, using blitter-modified code.
; A variable subset of the smc_buf_move code will be affected, depending
; on the number of particles we want to update.
update_parts2:
; Set up move code
	lea	smc_buf_move_end,a2
	move.w	active_move_count,d0
	mulu.w	#SMC_BUF_MOVE_STRIDE,d0
	sub.l	d0,a2					; a2 = start of SMC buffer

; 0) Fixed values
	move.w	#0,BLT_SRC_INC_X_W.w
	move.w	#0,BLT_DST_INC_X_W.w
	move.w	#1,BLT_COUNT_X_W.w
	move.w	#4,BLT_SRC_INC_Y_W.w			; size of src particles
	move.w	#SMC_BUF_MOVE_STRIDE,BLT_DST_INC_Y_W.w
							; dest offset stride
	move.w	#$0000,BLT_ENDMASK_2_W.w
	move.w	#$0000,BLT_ENDMASK_3_W.w

	DBG_COL	#$020

; 1) - X position -> X grid offset

	move.l	#parts+2,BLT_SRC_ADDR_L.w		; X data
	lea	2(a2),a3				; write offset
	move.l	a3,BLT_DST_ADDR_L.w

	move.b	#BLT_OP_S,BLT_OP_B.w			; source only
	move.b	#BLT_HOP_SRC,BLT_HOP_B.w
	move.w	#PBUF_X_MASK_GRID<<PBUF_G_TO_B_SHIFT_L,BLT_ENDMASK_1_W.w
	; Combine all shifts for X
	move.b	#PBUF_FRAC_SHIFT_R+PBUF_P_TO_G_SHIFT_R-PBUF_G_TO_B_SHIFT_L,BLT_MISC_2_B.w  ; skew

	; Start the op
	moveq.l	#0,d0
	bsr	blit_run
	DBG_COL	#$030

; 2) - Y position -> Y grid offset

	move.l	#parts+0,BLT_SRC_ADDR_L.w		; Y data src
	lea	2(a2),a3				; write offset
	move.l	a3,BLT_DST_ADDR_L.w			; reset dest

	move.b	#BLT_OP_S,BLT_OP_B.w			; source only
	move.b	#BLT_HOP_SRC,BLT_HOP_B.w
	move.w	#PBUF_Y_MASK_GRID<<PBUF_G_TO_B_SHIFT_L,BLT_ENDMASK_1_W.w
	; Combine all shifts for Y
	move.b	#PBUF_FRAC_SHIFT_R+PBUF_P_TO_G_SHIFT_R-PBUF_Y_SHIFT_L-PBUF_G_TO_B_SHIFT_L,BLT_MISC_2_B.w			; skew

	; Start the op
	moveq.l	#0,d0
	bsr	blit_run
	DBG_COL	#$040
	lea	parts,a0				; a0 = particle pos
	move.l	flow_patt_ptr,a1

	jsr	(a2)
	DBG_COL	#$060
	rts

; -----------------------------------------------------------------------------
; Render particle positions, using a blitter-modified buffer.
render_parts:
	tst.b	show_parts
	bne.s	.show
	rts
.show:
smc_setup_render:
; Generate SMC for render
	lea	smc_buf_render_end,a6
	move.w	active_move_count,d0
	mulu.w	#SMC_BUF_RENDER_STRIDE,d0
	sub.l	d0,a6					; a6 = start of SMC buffer

; 0) Invariants

	move.w	#0,BLT_SRC_INC_X_W.w
	move.w	#0,BLT_DST_INC_X_W.w
	move.w	#1,BLT_COUNT_X_W.w
	move.w	#4,BLT_SRC_INC_Y_W.w			; size of src particles
	move.w	#SMC_BUF_RENDER_STRIDE,BLT_DST_INC_Y_W.w
							; dest offset stride
; 1) Y position -> Y table lookup

	move.l	#parts+0,BLT_SRC_ADDR_L.w		; Y data src
	lea	2(a6),a3
	move.l	a3,BLT_DST_ADDR_L.w			; reset dest
	move.b	#BLT_OP_S,BLT_OP_B.w			; source only
	move.b	#BLT_HOP_SRC,BLT_HOP_B.w
	; -1 here is for *2 result value
	;move.w	#PBUF_INT_MASK>>(PBUF_FRAC_SHIFT_R-1),BLT_ENDMASK_1_W.w
	move.w	#$FF<<1,BLT_ENDMASK_1_W.w		; limit to 256 entries
	move.b	#(PBUF_FRAC_SHIFT_R-1),BLT_MISC_2_B.w	; skew

	; Start the op
	moveq.l	#0,d0
	bsr	blit_run
	DBG_COL	#$600

; 2) X position -> X screen offset value (shifted up 3)

	move.l	#parts+2,BLT_SRC_ADDR_L.w		; X data src
	lea	6(a6),a3
	move.l	a3,BLT_DST_ADDR_L.w			; reset dest
	move.b	#BLT_OP_S,BLT_OP_B.w			; source only
	move.b	#BLT_HOP_SRC,BLT_HOP_B.w

	; Shift top (9-3) bits down
	; We could mask to $F8 here since line length <= 256
	move.w	#$0F8,BLT_ENDMASK_1_W.w
	; 7 bits of fraction, 4 to divide by sixteen, 3 to multiply by 8
	move.b	#PBUF_FRAC_SHIFT_R+4-3,BLT_MISC_2_B.w	; skew
	; Start the op
	moveq.l	#0,d0
	bsr	blit_run
	DBG_COL	#$500

; 3) X position -> X pixel write value

	; Fill halftone RAM
	; (We don't really need to do this every frame...)
	move.w	#$8000,BLT_HALFTONE_0_W+$00.w
	move.w	#$4000,BLT_HALFTONE_0_W+$02.w
	move.w	#$2000,BLT_HALFTONE_0_W+$04.w
	move.w	#$1000,BLT_HALFTONE_0_W+$06.w
	move.w	#$0800,BLT_HALFTONE_0_W+$08.w
	move.w	#$0400,BLT_HALFTONE_0_W+$0a.w
	move.w	#$0200,BLT_HALFTONE_0_W+$0c.w
	move.w	#$0100,BLT_HALFTONE_0_W+$0e.w
	move.w	#$0080,BLT_HALFTONE_0_W+$10.w
	move.w	#$0040,BLT_HALFTONE_0_W+$12.w
	move.w	#$0020,BLT_HALFTONE_0_W+$14.w
	move.w	#$0010,BLT_HALFTONE_0_W+$16.w
	move.w	#$0008,BLT_HALFTONE_0_W+$18.w
	move.w	#$0004,BLT_HALFTONE_0_W+$1a.w
	move.w	#$0002,BLT_HALFTONE_0_W+$1c.w
	move.w	#$0001,BLT_HALFTONE_0_W+$1e.w

	move.l	#parts+2,BLT_SRC_ADDR_L.w		; X data src
	lea	12(a6),a3
	move.l	a3,BLT_DST_ADDR_L.w			; reset dest

	move.b	#BLT_OP_S,BLT_OP_B.w			; source only
	move.b	#BLT_HOP_HT,BLT_HOP_B.w			; read from Halftone RAM
	move.w	#$FFFF,BLT_ENDMASK_1_W.w		; write whole word
	move.b	#PBUF_FRAC_SHIFT_R,BLT_MISC_2_B.w	; shift integer part to bottom

	; Start the op
	move.b	#BLT_MISC_1_SMUDGE,d0
	bsr	blit_run
	DBG_COL	#$400
	;rts

	; Now execute
	lea	y_mul_table,a0
	move.l	logic,d0
	move.l	clear_logic,a3
	lea	clstate_part_offsets(a3),a2
	move.w	active_move_count,clstate_part_count(a3)
	jsr	(a6)
	rts

; -----------------------------------------------------------------------------
; X0 = MISC_1 bits
blit_run:
	lea	BLT_COUNT_Y_W.w,a0
	lea	BLT_MISC_1_B.w,a1
	or.b	#BLT_MISC_1_BUSY|BLT_MISC_1_HOG,d0
	move.w	active_move_count,d2
	move.w	d2,d3
	and.w	#$f,d3					; remaining Y count

	lsr.w	#4,d2					; number of full loops
	beq.s	.no_full
	subq.w	#1,d2
	move.w	#16,d1					; full Y count
.full_loop
	move.w	d1,(a0)					; reset Y count each time
	move.b	d0,(a1)					; kick
	dbf	d2,.full_loop
.no_full:
	move.w	d3,(a0)					; reset Y count with remainder
	beq.s	.skip_last
	move.b	d0,(a1)					; kick
.skip_last:
	rts

; -----------------------------------------------------------------------------
; Reference render code (unused)
;	ifne	0
;	lea	parts,a0				; a0 = particle pos
;	move.l	flow_patt_ptr,a1
;	lea	last_clears,a2
;	add.w	clear_offset,a2
;	move.l	logic,a3
;	lea	x_table,a4
;
;	move.w	#MAX_PART_COUNT-1,d7
;.part_loop:
;	; Render new point
;	move.w	(a0)+,d1				; d1 = int(Y)
;	move.w	(a0)+,d0				; d0 = int(X)
;
;	; These are now in fixed-point, so scale it down to pixels
;	lsr.w	#PBUF_FRAC_SHIFT_R,d0
;	asr.w	#PBUF_FRAC_SHIFT_R,d1			; treat as signed
;	muls.w	#BYTES_PER_LINE,d1			; d1 = screen offset from Y
;	lsl.w	#2,d0
;	movem.w	(a4,d0.w),d2/d3				; d2 = X addr offset
;							; d3 = pixel draw value
;	add.w	d2,d1					; final offset
;	or.w	d3,(a3,d1.w)				; draw pixel
;	move.w	d1,(a2)+				; save clear offset
;	dbf	d7,.part_loop
;	endif
; -----------------------------------------------------------------------------
; Clear blob sprites from 2 frames ago, in the most terrible way ever.
clear_blobs:
	tst.b	show_blobs
	bne.s	.show
	rts
.show:
	move.l	clear_logic,a1
	move.w	clstate_blob_count(a1),d7
	beq	.skip
	lea	clstate_blob_offsets(a1),a2
	move.l	logic,d1
	subq.w	#1,d7
	moveq	#0,d6					; d6 = clear val
.loop:
	move.w	(a2)+,d1
	move.l	d1,a3
	REPT	16
	move.w	d6,REPTN*BYTES_PER_LINE+0(a3)
	move.w	d6,REPTN*BYTES_PER_LINE+8(a3)
	endr
	dbf	d7,.loop
.skip:
	rts

; -----------------------------------------------------------------------------
; This routine is utterly appalling, but was done in a rush.
render_blobs:
	tst.b	show_blobs
	bne.s	.show
	rts
.show:
	DBG_COL	#$765
	lea	parts,a0				; a0 = particle pos
	move.l	flow_patt_ptr,a1
	move.l	clear_logic,a3
	lea	clstate_blob_offsets(a3),a2
	move.w	active_blob_count,d7
	move.w	d7,clstate_blob_count(a3)

	move.l	logic,d4				; d4 = screen address low
	lea	x_table_sprite,a4
	lea	blob_metadata,a5

	move.w	#0,BLT_SRC_INC_X_W.w
	move.w	#2,BLT_SRC_INC_Y_W.w
	move.w	#0,BLT_SRC_INC_X_W.w
	move.w	#8,BLT_DST_INC_X_W.w
	move.w	#BYTES_PER_LINE-8,BLT_DST_INC_Y_W.w
	move.w	#2,BLT_COUNT_X_W.w
	move.b	#BLT_HOP_SRC,BLT_HOP_B.w
	move.b	#BLT_OP_S_OR_T,BLT_OP_B.w
	move.w	#-1,BLT_ENDMASK_1_W.w
	move.w	#-1,BLT_ENDMASK_2_W.w
	move.w	#-1,BLT_ENDMASK_3_W.w

	subq.w	#1,d7
.part_loop:
	; Render new point
	move.w	(a0)+,d1				; d1 = int(Y)
	move.w	(a0)+,d0				; d0 = int(X)

	; These are now in fixed-point, so scale it down to pixels
	lsr.w	#PBUF_FRAC_SHIFT_R,d0
	asr.w	#PBUF_FRAC_SHIFT_R,d1			; treat as signed
	mulu.w	#BYTES_PER_LINE,d1			; d1 = screen offset from Y
	lsl.w	#3,d0
	movem.w	(a4,d0.w),d2/d3/d5			; d2 = X addr offset
							; d3 = skew value/MISC_1 bits
							; d5 = left mask
	add.w	(a5)+,d1				; bitplane
	add.w	d2,d1					; final offset
	move.w	d1,d4					; set lower part of scr address
	move.w	d1,(a2)+				; save clear offset
	move.l	d4,BLT_DST_ADDR_L.w
	move.w	d5,BLT_ENDMASK_1_W.w
	not.w	d5
	move.w	d5,BLT_ENDMASK_3_W.w

	; sprite image selection
	moveq	#0,d6
	move.w	(a5)+,d6				; anim speed
	add.w	(a5),d6					; sprite offset
	move.w	d6,(a5)+				; write back sprite offset
	and.w	#%11111100000,d6			; clamp to range
	add.l	(a5)+,d6				; move into sprite gfx
	move.l	d6,BLT_SRC_ADDR_L.w

	; Kick
	move.w	#16,BLT_COUNT_Y_W.w
	move.w	d3,BLT_MISC_1_B.w			; writes MISC1 and MISC2 together...
	dbf	d7,.part_loop

	DBG_COL	#$00
	rts
; -----------------------------------------------------------------------------
; Converts X position to sprite offsets, shifts and blitter registers.
			rept	512
			dc.w	0,0					; show clamped
			dc.w	0,0
			endr
x_table_sprite:
o			set	0
			rept	PIXELS_PER_LINE
			dc.w	(o/16)*8				; offset
			dc.b	BLT_MISC_1_BUSY|BLT_MISC_1_HOG		; flags to trigger blit
			dc.b	BLT_MISC_2_NFSR|(o&15)			; read flags + skew
			dc.w	($ffff>>(o&15))				; left mask
			dc.w	0					; pad
o			set	o+1
			endr

			rept	512-PIXELS_PER_LINE
			dc.w	BYTES_PER_LINE-8,0			; show clamped
			dc.w	0,0
			endr

; -----------------------------------------------------------------------------
; Do the particle update.
; The offset inside is modified by blitter passes, based on the XY of the particles.
; ------------------------
	; SELF-MODIFIED AREA START
smc_buf_move:
	rept	MAX_PART_COUNT
							;    		    | Look up YX velocity
	move.l	$0010(a1),d0				; 0 [2 4] 	16cy| (careful with the placeholder value!)
	add.w	d0,(a0)+				; 6		12cy| update Y
	swap	d0					; 8		 4cy|
	add.w	d0,(a0)+				; 10		12cy| update X
							; total 10 bytes, 44 cycles
	endr
smc_buf_move_end:					; used to calc reduced sizes
	rts
SMC_BUF_MOVE_STRIDE	equ	10
	; SELF-MODIFIED AREA END
	; ------------------------

; -----------------------------------------------------------------------------
; Needs 64K screen buffer align
; So we might as well do 256-byte screen lengths
; d0 = screen address, 64K align
; a0 = Y table lookup
; a1 = [trashed]
; a2 = clear offsets
smc_buf_render:
	; 48 CPU + blitter 8, 8, 8 with HOP? = 68
	; Could even combine first 2 instructions with 256-wide screen
o	set	0
	rept	MAX_PART_COUNT
	move.w	128(a0),d0				; 0 / [2]	12cy| Y offset lookup, allows 160
	add.w	#128+(o*2/MAX_PART_COUNT)*2,d0		; 4 / [6]	 8cy|
	move.l	d0,a1					; 8		 4cy|
	or.w	#$80,(a1)				; 10 / [12]	16cy| X pixel + x offset
	move.w	d0,(a2)+				; 14		 8cy| save location
							; 16	Total   48cy|
o	set	o+1
	endr
smc_buf_render_end:
SMC_BUF_RENDER_STRIDE	equ	16
	; SELF-MODIFIED AREA END
	; ------------------------
	rts

; Possible -- 60 CPU + blitter 8 + 8 = 76
; Allows for a custom table lookup

; rept 400
; move.w 128(a0),d0	; 0 / [2]			; Y offset lookup, allows 160
; move.l 128(a3),d1
; add d1,d0
; swap d1
; move.l d0,a1
; or.w d1,(a1)
; move.w d0,(a2)+					; save location
; endr

; -----------------------------------------------------------------------------
; Base of the flow grid (this can probably stay fixed now)
flow_patt_ptr:		dc.l	flow_data

; -----------------------------------------------------------------------------
; We have a problem if we don't zero-fill the LHS of the flow grid each time --
; points will continue to spiral off
x_table_border_l:
			rept	512
			dc.w	0,$8000					; show clamped
			endr
x_table:
o			set	0
			rept	PIXELS_PER_LINE
			dc.w	(o/16)*8				; offset
			dc.w	$8000>>(o&15)
o			set	o+1
			endr
x_table_border_r:
			rept	512-PIXELS_PER_LINE
			dc.w	BYTES_PER_LINE-8,$0001			; show clamped
			endr

; -----------------------------------------------------------------------------
y_mul_table_topborder:	dcb.w	256-LINES,BYTES_PER_LINE*(LINES+1)	; offscreen
y_mul_table:
o			set	0
			rept	LINES
			dc.w	BYTES_PER_LINE*o
o			set	o+1
			endr
y_mul_table_bottomborder:
			dcb.w	256-LINES,BYTES_PER_LINE*(LINES+1)

; -----------------------------------------------------------------------------
; Converts an offset in the "flowmap" design to an offset in the final
; runtime flow grid
flowmap_to_grid_offset:
y			set	0
			rept	PBUF_Y_VIS
x				set	0
				rept	PBUF_X_VIS
					dc.w	y+x,0				; the "0" is to pad for lookup alignment
x					set	x+4
				endr
y				set	y+(4*PBUF_X_COUNT)
			endr

; -----------------------------------------------------------------------------

			include	'demo/spawn.s'
			include	'demo/text.s'
			include	'demo/sequence.s'
			include	'demo/dezign.s'
			include	'demo/fade.s'

; -----------------------------------------------------------------------------
			include	'demo/data/font_100.s'
; -----------------------------------------------------------------------------
			even
flowmap_0:		include	'demo/data/flowdat0.s'
flowmap_1:		include	'demo/data/flowdat1.s'
flowmap_2:		include	'demo/data/flowdat2.s'
flowmap_fast:		include	'demo/data/flowdatfast.s'
flowmap_tiny:		include	'demo/data/flowdattiny.s'
flowmap_burst:		include	'demo/data/flowburst.s'
flowmap_divided:	include	'demo/data/flowdatdiv0.s'
wipe_circle:		incbin	'demo/data/wipe_circle.bin'
			include	'demo/data/sprites.s'

			even
music_init		=	* + 0
music_exit		=	* + 4
music_play		=	* + 8
			incbin	'demo/data/CURLY.SND'
			even


; -----------------------------------------------------------------------------
			bss
; -----------------------------------------------------------------------------
show_blobs:		ds.b	1
show_parts:		ds.b	1
target_palette:		ds.l	1
fade_counter:		ds.w	1		; counts up to target_palette_speed
target_palette_speed:	ds.w	1		; num VBLS before palette update step
active_move_count:	ds.w	1		; count of particles really
active_blob_count:	ds.w	1
active_spawn_func:	ds.l	1
active_sprite_gfx:	ds.l	1
spawn_count:		ds.w	1
spawner_speed:		ds.w	2

			rsreset
clstate_part_count	rs.w	1
clstate_part_offsets	rs.w	MAX_PART_COUNT*2
clstate_blob_count	rs.w	1
clstate_blob_offsets	rs.w	MAX_BLOB_COUNT*2
clstate_size		rs.b	1
clstate1		ds.b	clstate_size
clstate2		ds.b	clstate_size


next_flowmap_ptr:	ds.l	1			; used in wipe
flowadd			ds.l	1			; XY values to add to next wipe's flowmap
sequence_curr_1:	ds.l	1

wipe_counter:		ds.w	1
raster_line:		ds.w	1

physic:			ds.l	1
logic:			ds.l	1

clear_physic:		ds.l	1
clear_logic:		ds.l	1

temp_palette:		ds.w	16			; where mixing is done
palette_black:		ds.w	16
			even
; -----------------------------------------------------------------------------
; Particle positions stored as YX
parts:			ds.w	2*MAX_PART_COUNT
blob_metadata:		ds.w	5*MAX_BLOB_COUNT	; bitplane, anim speed, sprite offset, gfx_baseaddr

; -----------------------------------------------------------------------------
; Empty flow to stop all particles
flowmap_empty:		ds.w	40*25*2

; -----------------------------------------------------------------------------
; The active flow grid which we affect
; (8K)
flow_data:		ds.w	2*PBUF_X_COUNT*PBUF_Y_COUNT

; We need an extra N lines here for the blob sprites that over/under-draw.
; So if screen_areas is exactly 64K-aligned, this area can be overwritten
			ds.b	BYTES_PER_LINE*32
; -----------------------------------------------------------------------------
screen_areas:
			ds.b	$10000			; slop for align :(
screen:			ds.b	$10000*2		; physic+logic

end: