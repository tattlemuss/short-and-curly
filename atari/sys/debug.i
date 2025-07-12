; Debug macros (so this can be included at the top)
;==================================================================================================
DBG_BRK 		macro
			ifne	DEBUG
			move.b	d1,$ffffc123.w
			endif
			endm

DBG_COL			macro
			ifne	DEBUG
			tst.w	debug_show_time
			beq.s	.\@
			move.w	\1,$ffff8240.w
.\@:
			endif
			endm
