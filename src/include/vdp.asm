    ifnd NAMALGO_VDP
NAMALGO_VDP = 1

;    printt "including vdp.asm"

; For maximum usability,
; this code should not have any external requirements.

    ifnd VDP_CONTROL
VDP_CONTROL = $C00004
    endif
    ifnd VDP_DATA
VDP_DATA    = $C00000
    endif

    include 'vdpmacros.asm'

; ----------------------------------------------------------------------------
; set_vdp_control( reg (D0.b), data (D1.b) )
; destroys: D7
;
; Bits: [10?R RRRR DDDD DDDD]
; - ? is ignored (just set to 0)
; - R is VDP register select ($00-$1F). It has a 5-bit
;   register number, with the bits distributed like this:
;       [...4 3210 .... ....]
; - D is data, an 8-bit number:
;       [.... .... 7654 3210]
; ----------------------------------------------------------------------------
set_vdp_control
    movem.l   d0-d1/d7,-(sp)

    clr.l   d7
    move.b  d0,d7          ; d7.w = 0000 0000 ???R RRRR
    and.w   #%00011111,d7  ; d7.w = 0000 0000 000R RRRR
    lsl.w   #8,d7          ; d7.w = 000R RRRR 0000 0000
    or.w    #%1000000000000000,d7  ; d7.w = 100R RRRR 0000 0000
            ; 10?RRRRRDDDDDDDD
    ; and.w   #%11111111,d1  ; d1.w = 0000 0000 DDDD DDDD
    or.b    d1,d7          ; d7.w = 100R RRRR DDDD DDDD
    move.w  d7,VDP_CONTROL

    movem.l   (sp)+,d0-d1/d7
    rts

; ----------------------------------------------------------------------------
; set_plane_a_addr( vram_addr (D0.w) )
; ----------------------------------------------------------------------------
set_plane_a_addr
    movem.l   d0-d1,-(sp)

    move.w  d0,d1
; set_vdp_control( reg (D0.b), data (D1.b) )
    lsr.w   #7,d1               ; addr>>10
    lsr.w   #3,d1               ; 
    move.b  #$02,d0		        ; ScrollA address
    jsr     set_vdp_control

    movem.l   (sp)+,d0-d1
    rts

; ----------------------------------------------------------------------------
; set_plane_b_addr( vram_addr (D0.w) )
; ----------------------------------------------------------------------------
set_plane_b_addr
    movem.l   d0-d1,-(sp)

    move.w  d0,d1
; set_vdp_control( reg (D0.b), data (D1.b) )
    lsr.w   #7,d1               ; addr>>13
    lsr.w   #6,d1               ; 
    move.b  #$04,d0		        ; ScrollB address
    jsr     set_vdp_control

    movem.l   (sp)+,d0-d1
    rts

; ----------------------------------------------------------------------------
; set_window_addr( vram_addr (D0.w) )
; ----------------------------------------------------------------------------
set_window_addr
    movem.l   d0-d1,-(sp)

    move.w  d0,d1
; set_vdp_control( reg (D0.b), data (D1.b) )
    lsr.w   #5,d1               ; addr>>10
    lsr.w   #5,d1               ; 
    move.b  #$03,d0		        ; Window address
    jsr     set_vdp_control

    movem.l   (sp)+,d0-d1
    rts

; ----------------------------------------------------------------------------
; set_sprite_addr( vram_addr (D0.w) )
; ----------------------------------------------------------------------------
set_sprite_addr
    movem.l   d1,-(sp)

    move.w  d0,d1
    lsr.w   #7,d1               ; addr>>9
    lsr.w   #2,d1               ; 
    move.b  #5,d0		        ; Sprite table address
; set_vdp_control( reg (D0.b), data (D1.b) )
    jsr     set_vdp_control

    movem.l   (sp)+,d1
    rts

; ----------------------------------------------------------------------------
; set_scroll_table_addr( vram_addr (D0.w) )
; ----------------------------------------------------------------------------
set_scroll_table_addr
    movem.l   d1,-(sp)

    move.w  d0,d1
    lsr.w  #7,d1                 ; address bit 10-15
    lsr.w  #3,d1
    move.b #$d,d0                ; HScroll table address
    jsr    set_vdp_control

    movem.l   (sp)+,d1
    rts

; ----------------------------------------------------------------------------
; set_window_pos( width (D0.b), height (D1.b) )
; ----------------------------------------------------------------------------
set_window_pos
    movem.l   d1-d2,-(sp)

    move.b  d1,d2               ; d2 = height

    move.b  d0,d1
    move.b  #$11,d0             ; Window HPos
    jsr     set_vdp_control

    move.b  d2,d1
    move.b  #$12,d0             ; Window VPos
    jsr     set_vdp_control

    movem.l   (sp)+,d1-d2
    rts



; ----------------------------------------------------------------------------
; clear_name_table: Clear name table at VRAM address (D0) with value (D1)
; ----------------------------------------------------------------------------
clear_name_table
    movem.l   d0,-(sp)

    jsr     setup_vram_write
    move.w  #$800,d0
.loop
    move.w  d1,VDP_DATA ; write to VDP
    dbra    d0,.loop

    movem.l   (sp)+,d0
    rts


; ----------------------------------------------------------------------------
; clear_vram_all()
;
; Clear all of VRAM
; ----------------------------------------------------------------------------
clear_vram_all
    movem.l   d0-d1,-(sp)

    move.w  #0,d0
    move.w #$8F02,VDP_CONTROL     ; Set VDP autoincrement to 2 bytes/write
    jsr     setup_vram_write

    move.w  #64-1,d1     ; clear 64 KB
.loop_outer

    move.w  #1024-1,d0   ; clear 1 KB
.loop

    move.w  #$0000,VDP_DATA ; write to VDP
    move.w  #$0000,VDP_DATA ; write to VDP

    dbra    d0,.loop

    dbra    d1,.loop_outer

    movem.l   (sp)+,d0-d1

    rts


; ------------------------------------------------------------------------------
; load_palette( palette_data (a0.l), palette_idx (D0.w) [0-3] )
;
; Load palette data from A0 into CRAM
; ------------------------------------------------------------------------------
    align   4
.marker dc.b "load_pal"
load_palette:
    movem.l   d0/a0,-(sp)

    ;move.w #$8F02,VDP_CONTROL     ; Set VDP autoincrement to 1 word/write
    M_VDP_SETREG VDP_AUTOINC,2

    ; setup_cram_write( addr (D0.w) )
    and.w  #%0000000000000111,d0
    lsl.w  #5,d0
    jsr    setup_cram_write

    ; move.l #$C0000000+($xx<<16),($C00004).l
    ;move.l #$C0000003,VDP_CONTROL ; Set up VDP to write to CRAM address $0000

    move.w #16-1,d0 ; 32 bytes of data (8 longwords, minus 1 for counter)
                   ; in palette
.loop:
    move.w (a0)+,VDP_DATA ; Move data to VDP data port, increment source address
    dbra.w d0,.loop
    ;move.w #$8708,VDP_CONTROL ; Set BG col to palette 0, col 8 - purple
    ;move.w #$8700,d0           ; Set BG col to palette 0, col 0 - black

    movem.l   (sp)+,d0/a0
    rts


; ----------------------------------------------------------------------------
; wait_vblank: Wait for vblank
; destroys: D7
; ----------------------------------------------------------------------------
wait_vblank
    move.w VDP_CONTROL,d7  ; Move VDP status word to d0
    andi.w #$0008,d7       ; AND with bit 4 (vblank), result in status register
    beq    wait_vblank   ; Branch if equal (to zero)
    rts


; ----------------------------------------------------------------------------
; clear_sprites: Disable all sprites by writing an empty sprite table
; ----------------------------------------------------------------------------
clear_sprites
    ; Set sprite RAM to be at $F000
    move.w  #%1000010101111000,VDP_CONTROL  ; Sprite RAM = $F000
    move.w  #$8F02,VDP_CONTROL              ; Set VDP autoincrement to 2 bytes
    move.l  #$70000003,VDP_CONTROL          ; VDP write to VRAM address $F000
    move.w  #0,VDP_DATA
    move.w  #0,VDP_DATA
    move.w  #0,VDP_DATA
    move.w  #0,VDP_DATA
    rts


; ----------------------------------------------------------------------------
; setup_vram_write( addr (D0.w) )
; ----------------------------------------------------------------------------
setup_vram_write
    movem.l   d0/d5-d6,-(sp)

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


    ; Note: d0 is a *word*, may have garbage in upper 16 bit

    move.l  d0,d5                 ; d5 = (???? ???? ???? ???? FEDC BA98 7654 3210)

    and.l   #%1100000000000000,d5 ; d5 = (0000 0000 0000 0000 FE00 0000 0000 0000)
    lsr.l   #7,d5                 ; d5 = (0000 0000 0000 0000 0000 000F E000 0000)
    lsr.l   #7,d5                 ; d5 = (0000 0000 0000 0000 0000 0000 0000 00FE)


    move.l  d0,d6                 ; d6 = (???? ???? ???? ???? FEDC BA98 7654 3210)

    ; 
    and.l   #%0011111111111111,d6 ; d6 = (0000 0000 0000 0000 00DC BA98 7654 3210)
;             xxxxooooxxxxoooo
    lsl.l   #4,d6            ; d6 = (0000 0000 0000 00DC BA98 7654 3210 0000)
    lsl.l   #4,d6            ; d6 = (0000 0000 00DC BA98 7654 3210 0000 0000)
    lsl.l   #4,d6            ; d6 = (0000 00DC BA98 7654 3210 0000 0000 0000)
    lsl.l   #4,d6            ; d6 = (00DC BA98 7654 3210 0000 0000 0000 0000)


    move.l  #$40000000,d0 ; VRAM write command
    ; move.l  #%01000000000000000000000000000000,d0 ; VRAM write command
;             xxxxooooxxxxooooxxxxooooxxxxoooo
    or.l    d6,d0            ; d0 = (01DC BA98 7654 3210 0000 0000 0000 0000)
    or.l    d5,d0            ; d0 = (01DC BA98 7654 3210 0000 0000 0000 00FE)
    move.l  d0,VDP_CONTROL   ; VDP write

    movem.l   (sp)+,d0/d5-d6

    rts



; ----------------------------------------------------------------------------
; setup_cram_write( addr (D0.w) )
; ----------------------------------------------------------------------------
setup_cram_write
    movem.l   d0/d6,-(sp)

;    Bits    [BBAA AAAA AAAA AAAA 0000 0000 BBBB 00AA]
;    B order [10.. .... .... .... .... .... 5432 ....] oper. type
;    A order [..DC BA98 7654 3210 .... .... .... ..FE] address
;    -------------------------------------------------------------
;    CRAM Write (00 0001) to addr $0000 (0000 0000 0000 0000):
;            [11.. .... .... .... .... .... 0000 ....] oper. type
;            [1100 0000 0000 0000 .... .... 0000 ..00] VRAM address
;            [1100 0000 0000 0000 0000 0000 0000 0000] add zeroes
;      Hex:      C    0    0    0    0    0    0    0

; > A is destination address, in this order:
; [..DC BA98 7654 3210 .... .... .... ..FE]


    ; Note: d0 is a *word*, may have garbage in upper 16 bit

    move.l  d0,d6                 ; d6 = (???? ???? ???? ???? FEDC BA98 7654 3210)
    and.l   #%0011111111111111,d6 ; d6 = (0000 0000 0000 0000 00DC BA98 7654 3210)
;             xxxxooooxxxxoooo
    lsl.l   #4,d6            ; d6 = (0000 0000 0000 00DC BA98 7654 3210 0000)
    lsl.l   #4,d6            ; d6 = (0000 0000 00DC BA98 7654 3210 0000 0000)
    lsl.l   #4,d6            ; d6 = (0000 00DC BA98 7654 3210 0000 0000 0000)
    lsl.l   #4,d6            ; d6 = (00DC BA98 7654 3210 0000 0000 0000 0000)


    move.l  #$C0000000,d0 ; VRAM write command
    ; move.l  #%11000000000000000000000000000000,d0 ; CRAM write command
;             xxxxooooxxxxooooxxxxooooxxxxoooo
    or.l    d6,d0            ; d0 = (11DC BA98 7654 3210 0000 0000 0000 0000)
    move.l  d0,VDP_CONTROL   ; VDP write

    movem.l   (sp)+,d0/d6

    rts



    endif




; vim: tw=80 tabstop=4 expandtab ft=asm68k
