	; Constants and macro definitions
	include	'sys/scancodes.i'			; keyboard scancodes
	include	'sys/debug.i'
	include	'sys/hardware.i'
	code

; -----------------------------------------------------------------------------
;	DEFINES
; -----------------------------------------------------------------------------

	; Reserve memory so music can work
	move.l	4(sp),a5			;address to basepage
	move.l	$0c(a5),d0			;length of text segment
	add.l	$14(a5),d0			;length of data segment
	add.l	$1c(a5),d0			;length of bss segment
	add.l	#$100,d0			;length of basepage
	add.l	#$1000,d0			;length of stackpointer
	move.l	a5,d1				;address to basepage
	add.l	d0,d1				;end of program
	and.l	#-2,d1				;make address even
	move.l	d1,sp				;new stackspace

	move.l	d0,-(sp)			;mshrink()
	move.l	a5,-(sp)			;
	move.w	#0,-(sp)			;
	move.w	#$4a,-(sp)			;
	trap	#1				;
	lea	12(sp),sp			;

	; Supervisor mode
	clr.l	-(a7)
	move.w	#$20,-(a7)
	trap	#1
	addq.l	#6,a7

	; ===================== MAIN SYSTEM START ===================
	jsr	system_save

	move.w	#$2700,sr
	clr.b	$484.w			;key beep off
	bclr	#3,$fffffa17.w
	move.l	#vbl,$70.w
	move.l	#dummy_int,$68.w
	move.l	#dummy_int,$120.w
	move.l	#dummy_int,$134.w
	move.l	#dummy_rout,vbl_callback

	; kill interrupts,...
	clr.b	$fffffa13.w		;int mask A
	clr.b	$fffffa15.w		;int mask B
	clr.b	$fffffa07.w		;int enable A
	clr.b	$fffffa09.w		;int enable B

	jsr	demo_init
	move.w	#$2300,sr
	clr.l	$466.w			; used by rocket

	; ===================== MAIN LOOP START ==============================================================
frame_loop:
	jsr	demo_frame
	addq.w	#1,frame_counter

	moveq	#-1,d0
	btst	#7,$fffffc00.w		; ikbd interrupt?
	beq.s	.no_key
	move.b	$fffffc02.w,d0
	cmp.b	#$39,d0
	beq	exit

	ifne	DEBUG
	cmp.b	#SCANCODE_T,d0
	bne.s	.no_time
	not.w	debug_show_time
.no_time:
	endif
.no_key:
	move.b	d0,last_keypress
	tst.b	exit_flag
	beq	frame_loop

	; ===================== MAIN LOOP END ==============================================================
exit:
	jsr	demo_exit
	jmp	system_exit

dummy_int:
	rte
dummy_rout:
	rts

; -----------------------------------------------------------------------------
wait_vbl:
	move.l	$466.w,d0
.wait:
	stop	#$2300
	cmp.l	$466.w,d0
	beq.s	.wait
	rts

; -----------------------------------------------------------------------------
; a0 = address of screen
clear_whole_screen:
	moveq	#0,d0
	move.w	#BYTES_PER_LINE*LINES/4/4-1,d7
.copy:
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	dbf	d7,.copy
	rts

; -----------------------------------------------------------------------------

			; systemy stuff
			include "sys/vbl.s"
			include	"sys/save_restore.s"

; -----------------------------------------------------------------------------
			even
debug_show_time:	dc.w	0
frame_counter:		dc.w	0
last_keypress:		dc.b	-1
exit_flag:		dc.b	0
			even

