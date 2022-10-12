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
; ROM HEADER
; ------------------------------------------------------------------------------
; {{{
rom_header:
    dc.l   $00FFFFFE        ; Initial stack pointer value
    dc.l   entry_point      ; Start of program
    dc.l   ignore_handler   ; Bus error
    dc.l   ignore_handler   ; Address error
    dc.l   ignore_handler   ; Illegal instruction
    dc.l   ignore_handler   ; Division by zero
    dc.l   ignore_handler   ; CHK exception
    dc.l   ignore_handler   ; TRAPV exception
    dc.l   ignore_handler   ; Privilege violation
    dc.l   ignore_handler   ; TRACE exception
    dc.l   ignore_handler   ; Line-A emulator
    dc.l   ignore_handler   ; Line-F emulator
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Spurious exception
    dc.l   ignore_handler   ; IRQ level 1
    dc.l   ignore_handler   ; IRQ level 2
    dc.l   ignore_handler   ; IRQ level 3
    dc.l   ignore_handler   ; IRQ level 4 (horizontal retrace interrupt)
    dc.l   ignore_handler   ; IRQ level 5
    dc.l   ignore_handler   ; IRQ level 6 (vertical retrace interrupt)
    dc.l   ignore_handler   ; IRQ level 7
    dc.l   ignore_handler   ; TRAP #00 exception
    dc.l   ignore_handler   ; TRAP #01 exception
    dc.l   ignore_handler   ; TRAP #02 exception
    dc.l   ignore_handler   ; TRAP #03 exception
    dc.l   ignore_handler   ; TRAP #04 exception
    dc.l   ignore_handler   ; TRAP #05 exception
    dc.l   ignore_handler   ; TRAP #06 exception
    dc.l   ignore_handler   ; TRAP #07 exception
    dc.l   ignore_handler   ; TRAP #08 exception
    dc.l   ignore_handler   ; TRAP #09 exception
    dc.l   ignore_handler   ; TRAP #10 exception
    dc.l   ignore_handler   ; TRAP #11 exception
    dc.l   ignore_handler   ; TRAP #12 exception
    dc.l   ignore_handler   ; TRAP #13 exception
    dc.l   ignore_handler   ; TRAP #14 exception
    dc.l   ignore_handler   ; TRAP #15 exception
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    dc.l   ignore_handler   ; Unused (reserved)
    
    dc.b "SEGA GENESIS    " ; Console name
    dc.b "(C) NAMELESS    " ; Copyright holder and release date
    dc.b "FRAMEBUF DEMO BY NAMELESS ALGORITHM               " ; Domest. name
    dc.b "FRAMEBUF DEMO BY NAMELESS ALGORITHM               " ; Intern. name
    dc.b "2022-10-12    "   ; Version number
    dc.w $0000              ; Checksum
    dc.b "J               " ; I/O support
    dc.l $00000000          ; Start address of ROM
    dc.l __end              ; End address of ROM
    dc.l $00FF0000          ; Start address of RAM
    dc.l $00FFFFFF          ; End address of RAM
    dc.l $00000000          ; SRAM enabled
    dc.l $00000000          ; Unused
    dc.l $00000000          ; Start address of SRAM
    dc.l $00000000          ; End address of SRAM
    dc.l $00000000          ; Unused
    dc.l $00000000          ; Unused
    dc.b "                                        " ; Notes (unused)
    dc.b "JUE             "                         ; Country codes
; }}}


; ----------------------------------------------------------------------------
; MEMORY MAP
; ----------------------------------------------------------------------------
vblanks         = $E0FF10
palette_offset  = $E0FF14
conf_offset     = $E0FF18

; VRAM MAP:
; $0000-$6FFF framebuf
; $7000-$7A00 font
; $8000-$8FFF empty
; $A000-????? window playfield
; $E000-$E800 plane A fixed playfield

; text.asm config
TEXT_VRAM_ADDR_PRINT = $A000 ; Address of plane to print char indices to
TEXT_VRAM_ADDR_FONT  = $7000 ; Where in VRAM is font data loaded?

; ----------------------------------------------------------------------------
; STATIC DATA
; ----------------------------------------------------------------------------
text
    dc.b 'FRAMBUFFER DEMO                 NAMELESS ALGORITHM 2022         ',0

    even


; ------------------------------------------------------------------------------
; MAIN PROGRAM
; ------------------------------------------------------------------------------
    align   4
.marker dc.b "__main  "

__main
entry_point
    jsr    init_all
    jsr    clear_vram_all ; set all of VRAM to 0s

    ; set_plane_a_addr( vram_addr (D0.w) )
    move.w #$E000,d0
    jsr    set_plane_a_addr

    ; set_plane_b_addr( vram_addr (D0.w) )
    move.w #$E000,d0
    jsr    set_plane_b_addr

    ; set_window_addr( vram_addr (D0.w) )
    move.w #$A000,d0
    jsr    set_window_addr

    move.w #$7000,d0
    jsr    load_font


    ; set Window Base Point Y = 2
; set_vdp_control( reg (D0.b), data (D1.b) )
    move.b #$12,d0
    move.b #$02,d1
    jsr    set_vdp_control

; print_at( x (D1), y (D2), str (A0), strlen (D0), palette (D5.b) [0-3] )
    move.w #0,d1
    move.w #0,d2
    lea    text,a0
    move.w #64,d0
    move.w #1,d5
    jsr    print_at_col

; load_palette( palette_data (a0.l), palette_idx (D0.w) [0-3] )
    lea    pattern_palette,a0
    move.w #0,d0
    jsr    load_palette

    lea    text_palette,a0
    move.w #1,d0
    jsr    load_palette

    move.w #$8B70,VDP_CONTROL ;  Plane A address = $E000

    ; gen_playfield( VRAM_address (d0.w) )
    move.w #$E000,d0
    jsr gen_playfield         ; fixed plane A playfield





    move.l  #$11111111,d1     ; pattern
mainloop
    lea     $E00800,a0

    move.w  #$10-1,d6
.render_loop1
    move.w  #$180-1,d7
.render_loop2

    move.l  d1,(a0)+          ; write number to framebuf

    dbra    d7,.render_loop2

    cmp.l   #$FFFFFFFF,d1
    bne     .skip
    move.l  #0,d1
.skip
    add.l   #$11111111,d1

    dbra    d6,.render_loop1

    
    ; copy_framebuf( framebuf_addr (A0.L), VRAM_char_memory (D0.w) )
    lea     $E00000,a0        ; a0 : Framebuf RAM ptr
    move.w  #$0000,d0         ; VRAM write to address $0000
    jsr     copy_framebuf     ; copy RAM framebuffer to VRAM

    jmp     mainloop



; ------------------------------------------------------------------------------
; EXCEPTION AND INTERRUPT HANDLERS
; ----------------------------------------------------------------------------
    align 2 ; word-align code
ignore_handler
    rte ; return from exception (seems to restore PC)



; ------------------------------------------------------------------------------
; PALETTE
; ------------------------------------------------------------------------------
; {{{
    even
pattern_palette: ; BGR
	dc.w $0000   ; Colour 0 - Transparent
	dc.w $0e00
	dc.w $0c02
	dc.w $0a04
	dc.w $0806
	dc.w $0608
	dc.w $040a
	dc.w $020c
	dc.w $000e
	dc.w $002e
	dc.w $004c
	dc.w $006a
	dc.w $0088
	dc.w $00a6
	dc.w $00c4
	dc.w $00e0

text_palette:  ; BGR
	dc.w $0000 ; Colour 0 - Transparent
	dc.w $0e00
	dc.w $0c02
	dc.w $0a04
	dc.w $0806
	dc.w $0608
	dc.w $040a
	dc.w $020c
	dc.w $000e
	dc.w $002e
	dc.w $004c
	dc.w $006a
	dc.w $0088
	dc.w $00a6
	dc.w $00c4
	dc.w $00e0
; }}}


; ----------------------------------------------------------------------------
; INCLUDES
; ----------------------------------------------------------------------------
    incdir  '../include'
    include 'init.asm'
    include 'vdp.asm'
    include 'text.asm'
    include 'raster.asm'





__end

; vim: tw=80 tabstop=4 expandtab ft=asm68k fdm=marker
