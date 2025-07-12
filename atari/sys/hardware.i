	; set up base regs (constant)

; -----------------------------------------------------------------------------
; BLITTER
; -----------------------------------------------------------------------------
BLT_HALFTONE_0_W	equ	$ffff8a00	; Halftone RAM slot 0

BLT_SRC_INC_X_W		equ	$ffff8a20
BLT_SRC_INC_Y_W		equ	$ffff8a22
BLT_SRC_ADDR_L		equ	$ffff8a24
 
BLT_ENDMASK_1_W		equ	$ffff8a28
BLT_ENDMASK_2_W		equ	$ffff8a2a
BLT_ENDMASK_3_W		equ	$ffff8a2c

BLT_DST_INC_X_W		equ	$ffff8a2e
BLT_DST_INC_Y_W		equ	$ffff8a30
BLT_DST_ADDR_L		equ	$ffff8a32

BLT_COUNT_X_W		equ	$ffff8a36
BLT_COUNT_Y_W		equ	$ffff8a38

BLT_HOP_B		equ	$ffff8a3a	; halftone op (BYTE)

BLT_HOP_ALLONE		equ	0		; All bits are generated as "1"
BLT_HOP_HT		equ	1		; All bits taken from halftone patterns
BLT_HOP_SRC		equ	2		; All bits taken from source
BLT_HOP_AND		equ	3		; Source and halftone are AND combined

BLT_OP_B		equ	$ffff8a3b	; combine operator (BYTE)

BLT_OP_0		equ	0		; Target Bits are all "0"
BLT_OP_S_AND_T		equ	1		; Target Bits are Source AND Target
BLT_OP_S_AND_NT		equ	2		; Target Bits are Source AND NOT Target
BLT_OP_S 		equ	3		; Target Bits are Source
BLT_OP_NS_AND_T 	equ	4		; Target Bits are NOT Source AND Target
BLT_OP_T 		equ	5		; Target Bits are Target
BLT_OP_S_XOR_T 		equ	6		; Target Bits are Source XOR Target
BLT_OP_S_OR_T 		equ	7		; Target Bits are Source OR Target
BLT_OP_NS_AND_NT	equ	8		; Target Bits are NOT Source AND NOT Target
BLT_OP_NS_XOR_NT	equ	9		; Target Bits are NOT Source XOR NOT Target
BLT_OP_NT	        equ	10		; Target Bits are NOT Target
BLT_OP_S_OR_NT		equ	11		; Target Bits are Source OR NOT Target
BLT_OP_NS		equ	12		; Target Bits are NOT Source
BLT_OP_NS_OR_T		equ	13		; Target Bits are NOT Source OR Target
BLT_OP_NS_OR_NT		equ	14		; Target Bits are NOT Source OR NOT Target
BLT_OP_1		equ	15		; Target Bits are all "1"

BLT_MISC_1_B		equ	$ffff8a3c	; Misc. Register (8 Bits)

BLT_MISC_1_BUSY		equ	$80		; Bit 7      ; BUSY Bit (Write: Start/Stop, Read: Status Busy/Idle)
BLT_MISC_1_HOG		equ	$40		; Bit 6      ; HOG Mode (Write: HOG/BLiT mode, Read: Status)
BLT_MISC_1_SMUDGE	equ	$20		; Bit 5      ; Smudge Mode (Write: Smudge/Clean mode: Read Status)
BLT_MISC_1_HALFTONE	equ	$f		; Bit 3..0   ; Line number of Halftone Pattern to start with

BLT_MISC_2_B		equ	$ffff8a3d	; Misc. Register (8 Bits)

BLT_MISC_2_FXSR		equ	$80		; Bit 7      ; Force eXtra Source Read (FXSR)
BLT_MISC_2_NFSR		equ	$40		; Bit 6      ; No Final Source Read (NFSR)
BLT_MISC_2_SKEW		equ	$f		; Bit 3..0   ; Skew (Number of right shifts per copy)

; -----------------------------------------------------------------------------
; FALCON VIDEO MODES (XBIOS VSETMODE)
; -----------------------------------------------------------------------------

VSETMODE_1PLANE		equ	0<<0
VSETMODE_2PLANE		equ	1<<0
VSETMODE_4PLANE		equ	2<<0
VSETMODE_8PLANE		equ	3<<0
VSETMODE_TRUCOLOR	equ	4<<0

VSETMODE_640		equ	1<<3
VSETMODE_VGA		equ	1<<4
VSETMODE_PAL		equ	1<<5
VSETMODE_OVERSCAN	equ	1<<6
VSETMODE_STCOMPAT	equ	1<<7
VSETMODE_INTERLACE	equ	1<<8
