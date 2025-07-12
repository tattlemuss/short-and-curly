; -----------------------------------------------------------------------------
; d0 = returned whitenoise value
generate_random:
	move.w	whitenoise_seed,d0
	add.w	#$9469,d0
	rol.w	#5,d0
	move.w	d0,whitenoise_seed
	rts

	bss
whitenoise_seed:
	ds.w	1

	text
