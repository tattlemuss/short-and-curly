; -----------------------------------------------------------------------------
SINE_LOOP_BITS		equ	10			; Number of bits in a quadrant
QUADRANT_COUNT		equ	(1<<SINE_LOOP_BITS)	; Number of entries in one quad
SINE_COUNT		equ	(1<<(SINE_LOOP_BITS+2))	; Number of entries in whole table
FIXED_POINT_PLACE	equ	14
THREE_FIXED		equ	3<<14			; This gives max precision in 16 bits to hold "3" (2:14)
SINE_SIZE		equ	SINE_COUNT*2		; Size of whole table in bytes
SINE_MASK		equ	SINE_SIZE-2		; Mask for byte offset when looping
COS_OFFSET		equ	2*QUADRANT_COUNT	; Offset in bytes to second quadrant

; -----------------------------------------------------------------------------
;	SINE TABLE
; -----------------------------------------------------------------------------
; NOTE: assumes 512 entries (9 bits)

;	Our target approximation is z/2 * (3 - z*z)

;
;	halfz = i << (14-(9-2)-1)
;	# Calc (3 - z*z)
;   	# starting i is 7 bits (effectively 8 with sign)
;	zmul = i #<< (16-X)
;	zsqr = (zmul * zmul) << 0		# 32-18 = 14 bit range
;	s = halfz * (three - zsqr)		# now 28-bit range again
;
;	# Shift down to range
;	s = s >> (X*4-16+1)			# +1 because of sign

; Create a sine table in the buffer pointed to by a0.
sine_table_init:
	lea	sine_table,a0
	bsr.s	.calc_1
	lea	sine_table+SINE_SIZE,a0
	; falls through and does twice :)
.calc_1:
	lea	COS_OFFSET(a0),a0		; a0 - quadrant 0 (working backwards)
	move.l	a0,a1				; a1 - quadrant 1 (working fwds)
	lea	COS_OFFSET*2(a1),a2		; a2 - quadrant 2 (working backwards)
	move.l	a2,a3				; a3 - quadrant 3 (working fwds)
	; Change of approach.
	; Keep at 16 bits precision unless stated.
	move.w	#16+2,d4			; d4 - shift amount after 1st mulu
	move.w	#(QUADRANT_COUNT-1)<<(16-SINE_LOOP_BITS),d0	; d0 - z (count backwards)
.loop:
	move.w	d0,d2				; d0 = z
	;NOTE: all calcs guarantee positive values, so use unsigned
	mulu.w	d2,d2				; d2 = z*z (fixed point 32)
	lsr.l	d4,d2				; d2 = z*z (fixed point 14)
	move.w	#THREE_FIXED,d3			; d3 = 3.0 (fixed point 14) (0xc000)
	sub.w	d2,d3				; d3 = 3.0 - z*z (fixed point 14)
	move.w	d0,d1				; d1 - Z (fixed point 16)
	mulu.w	d1,d3				; d3 = z * (3 - z*z)  (30-bit range)
	; Now at 30-bit range, but the d3 term is already *2, so effectively 31 bits
	; we want 15 bits, so just swap
	swap	d3
	;lsr.l	d5,d3				; shift
	; mirror into 4 quadrants. Can this be improved?
	add.w	d3,-(a0)
	add.w	d3,(a1)+
	sub.w	d3,-(a2)
	sub.w	d3,(a3)+
	sub.w	#1<<(16-SINE_LOOP_BITS),d0
	bne.s	.loop
        rts

; a0 = src table
; a1 = dest table
; d0 = scale
sine_table_scale:
	move.w	#SINE_COUNT-1,d7
.loop:
	move.w	(a0)+,d1
	muls.w	d0,d1
	add.l	d1,d1
	swap	d1
	move.w	d1,(a1)+
	dbf	d7,.loop
	rts

			bss
sine_table:	ds.b	SINE_SIZE*2
			code

