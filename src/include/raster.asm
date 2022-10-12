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


; ------------------------------------------------------------------------------
; USAGE
; ------------------------------------------------------------------------------
;
;    include 'raster.asm'
;
;    vram_raster_playfield = $E000 ; playfield VRAM address
;    vram_framebuf         = $1000 ; framebuffer VRAM address
;
;    ; Generate mapping to VRAM framebuffer
;    move.w #vram_raster_playfield,d0
;    move.w #vram_framebuf,d1
;    jsr     gen_playfield
;
;    ; render pixels to RAM frame buffer in $E00000 here
;
;    ; Copy RAM framebuffer to VRAM
;    move.w  #vram_framebuf,d0  ; VRAM write to framebuffer VRAM address
;    lea     $E00000,a0         ; Framebuf RAM ptr
;    jsr     copy_framebuf      ; copy RAM framebuffer to VRAM



; ------------------------------------------------------------------------------
; NOTES
; ------------------------------------------------------------------------------
; The Genesis uses 11-bit char indices
; This means we can use char indices in [0;2047] [$0;$7ff]



    ifnd NAMALGO_RASTER
NAMALGO_RASTER = 1

; gen_playfield( VRAM_playfield_addr (d0.w), VRAM_framebuf_addr (d1.w) )
;
;    Bits: [BBAA AAAA AAAA AAAA 0000 0000 BBBB 00AA]
;    - 0 is always just 0
;    - A is destination address, in this order:
;          [..DC BA98 7654 3210 .... .... .... ..FE]
;    - B is Operation type, in this order:
;          [10.. .... .... .... .... .... 5432 ....]
;
;      B = 000000: VRAM read  (normal VRAM)
;      B = 000001: VRAM write
;      B = 001000: CRAM read  (color palette RAM)
;      B = 000011: CRAM write
;      B = 000100: VSRAM read (vertical scroll RAM)
;      B = 000101: VSRAM write
; Playfield maps are matrices that specify which character is shown at any given
; grid cell on the screen. The playfield maps consist of 16-bit values:
;
; - An 11 bit character index that specifies which character to use
; - 2 bits selecting one of 4 color palettes
; - 2 bits enabling horizontal and vertical flipping
; - 1 priority bit
;
gen_playfield
    movem.l d0-d1/d7,-(sp)
    move.w  sr,-(sp)

    move    #$2700,sr               ; disable interrupts

    M_VDP_SETREG VDP_AUTOINC,2
;   move.w  #$8F02,vdp_control     ; Set VDP autoincrement to 2 bytes/write
;    Bits  : [BBAA AAAA AAAA AAAA 0000 0000 BBBB 00AA]
;         B = 000001: VRAM write
;            [01AA AAAA AAAA AAAA 0000 0000 0000 00AA]
;
;                               FEDCBA9876543210
; VRAM write to address $E000, %1110000000000000
;          [..DC BA98 7654 3210 .... .... .... ..FE]
;          [..10 0000 0000 0000                  11]
;          [0110 0000 0000 0000 0000 0000 0000 0011]
    ;move.l  #%01100000000000000000000000000011,vdp_control ; VRAM write to address $E000



    ; setup_vram_write( addr (D0.w) )
    jsr     setup_vram_write


    ; D0: char idx

    move.w  d1,d0               ; D0 = VRAM_playfield_addr / 32
    lsr.w   #5,d0

    move.w  #$380,d7            ; write full screen of char indices
.loop
    and.w   #$07ff,d0           ; 11 bit char index
    move.w  d0,VDP_DATA         ; output char idx to playfield
    add.w   #1,d0               ; 

    dbra    d7,.loop

    move.w   (sp)+,sr            ; Re-enable ints
    movem.l  (sp)+,d0-d1/d7

    rts




; copy_framebuf( framebuf_addr (A0.L), VRAM_char_memory (D0.w) )
;
; copy framebuffer from framebuf_addr in RAM (e.g. $E00000) to VRAM_char_memory 
; in VRAM (e.g. $0000)
copy_framebuf
    movem.l d0-d7/a0-a6,-(sp) ; push all registers to stack
    move.w  sr,-(sp)

; Framebuffer is in RAM $E00000
; copy to char memory in VRAM $0000
; A char is 8 pixels wide, 4 bits/pixel = 32 bits = 4 bytes
;
; RAM base + $000        $004         $008            $09C
;            Char0Line0  Char1Line0   Char2Line0  ... Char31Line0
; RAM base + $080        $084                         $0FC
;            Char0Line1  Char1Line1   Char2Line1  ... Char31Line1
; RAM base + $100        $104                         $1FC
;            Char0Line2  Char1Line1   Char2Line1  ... Char31Line1

    move    #$2700,sr               ; disable interrupts

    M_VDP_SETREG VDP_AUTOINC,2 ; Set VDP autoincrement to 2 words/write

    ; setup_vram_write( addr (D0.w) )
    jsr     setup_vram_write

    ;lea     $E00000,a0      ; a0 : Framebuf RAM ptr

    move.w  #28-1,d5        ; d5 : char row idx

write_char_row

    move.w  #32-1,d6        ; d6 : char idx
    ;lea     $000000,a0      ; a0 : Framebuf RAM ptr

write_char 
    move.w  #8-1,d7
    move.l  a0,a1

.write_line
    move.l  (a1),d0         ; d0 = line pixels
    move.l  d0,VDP_DATA     ; write line to VRAM
    add.l   #$80,a1         ; next line
    dbra    d7,.write_line

.next_char
    add.l   #4,a0
    dbra    d6,write_char

    add.l   #$380,a0
    dbra    d5,write_char_row

    move.w   (sp)+,sr            ; Re-enable ints
    movem.l (sp)+,d0-d7/a0-a6 ; pop all registers from stack

    rts


    include 'vdp.asm' ; setup_vram_write


    endif ; NAMALGO_RASTER

; vim: tw=80 tabstop=4 expandtab ft=asm68k fdm=marker
