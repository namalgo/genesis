; ------------------------------------------------------------------------------
;
; Copyright 2022 Nameless Algorithm
; See https://namelessalgorithm.com/ for more information.
;
; LICENSE
; You may use this source code for any purpose. If you do so, please attribute
; 'Nameless Algorithm' in your source, or mention us in your game/demo credits.
; Thank you.
;
; ------------------------------------------------------------------------------


    ifnd NAMALGO_VDP_MACROS
NAMALGO_VDP_MACROS = 1

; For maximum usability,
; this code should not have any external requirements.

    ifnd VDP_CONTROL
VDP_CONTROL = $C00004
    endif
    ifnd VDP_DATA
VDP_DATA    = $C00000
    endif

; VDP registers
VDP_MODE_1          = $00
VDP_MODE_2          = $01
VDP_PLANE_A         = $02
VDP_WINDOW          = $03
VDP_PLANE_B         = $04
VDP_AUTOINC         = $0F
VDP_HORIZ_INT_COUNT = $0A
VDP_MODE_4          = $0C

; VDP command words
VDP_CMD_VRAM_WRITE = $40000000
VDP_CMD_CRAM_WRITE = $C0000000

; ----------------------------------------------------------------------------
; M_VRAM_WRITE addr.w
; fast constant address macro
; usage:
;   M_VRAM_WRITE $C000
; ----------------------------------------------------------------------------
M_VRAM_WRITE macro addr ; \1

;    Bits    [BBAA AAAA AAAA AAAA 0000 0000 BBBB 00AA]
;    B order [10.. .... .... .... .... .... 5432 ....] oper. type
;    A order [..DC BA98 7654 3210 .... .... .... ..FE] address
;    -------------------------------------------------------------
;    VRAM Write (00 0001) to addr $0000 (0000 0000 0000 0000):
;            [01.. .... .... .... .... .... 0000 ....] oper. type
;            [0100 0000 0000 0000 .... .... 0000 ..00] VRAM address
;            [0100 0000 0000 0000 0000 0000 0000 0000] add zeroes
;      Hex:      4    0    0    0    0    0    0    0

; > A is destination address, in this order:
; [..DC BA98 7654 3210 .... .... .... ..FE]

; note: don't insert spaces, VASM doesn't like it
; note: 'set' overwrites symbol, unlock '=' throws an error on the second time 
;       the macro is expanded
.command     set VDP_CMD_VRAM_WRITE
.addr0       set (((\1)&$3FFF)<<16)
.addr1       set (((\1)&$C000)>>14)

    move.l  #(.command|.addr0|.addr1),VDP_CONTROL

    endm

; ----------------------------------------------------------------------------
; m_setup_cram_write addr.w
; fast constant address macro
; usage:
;   m_setup_cram_write $C000
; ----------------------------------------------------------------------------
M_CRAM_WRITE macro addr ; \1
    ; tip: don't insert spaces, VASM doesn't like it
.command     set VDP_CMD_CRAM_WRITE
.addr0       set (((\1)&$3FFF)<<16)
.addr1       set (((\1)&$C000)>>14)

    move.l  #(.command|.addr0|.addr1),VDP_CONTROL
    endm


; ----------------------------------------------------------------------------
; m_set_VDP_CONTROL reg.b, data.b 
; fast macro, only for constant values
; ----------------------------------------------------------------------------
M_VDP_SETREG macro reg,data ; \1,\2
; Bits: [10?R RRRR DDDD DDDD]
; - ? is ignored (just set to 0)
; - R is VDP register select ($00-$1F). It has a 5-bit
;   register number, with the bits distributed like this:
;       [...4 3210 .... ....]
; - D is data, an 8-bit number:
;       [.... .... 7654 3210]
.base         set $8000
.vdp_reg      set (((\1)&$1F)<<8)
.vdp_reg_data set (\2)&$FF

    move.w  #(.base|.vdp_reg|.vdp_reg_data),VDP_CONTROL
    endm




; Usage: bgcol $00E0 ; (green)
; CPU usage: 48 (9/3) cycles
M_BGCOL macro ; (col)
    ; move.w  #$xxx,(xxx).L 20 (4/1) cycles
    ; move.l  #$xxx,(xxx).L 28 (5/2) cycles
    move.l  #VDP_CMD_CRAM_WRITE,VDP_CONTROL ; Set up write to color 0
    move.w  #\1,VDP_DATA       ; Write color 0 value
    endm



    endif ; NAMALGO_VDP_MACROS


; vim: tw=80 tabstop=4 expandtab ft=asm68k
