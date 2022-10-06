; SEGA Genesis ROM by the Nameless Algorithm 2022-07-18
; - http://namelessalgorithm.com/
;
; ----------------------------------------------------------------------------
; ROM HEADER
; ------------------------------------------------------------------------------
; {{{
rom_header:
    dc.l   $00FFFFFE        ; Initial stack pointer value
    dc.l   EntryPoint       ; Start of program
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
    dc.b "(C) NAMELESS    " ; Copyrght holder and release date
    dc.b "SCROLLY BY NAMELESS ALGORITHM                     " ; Domest. name
    dc.b "SCROLLY BY NAMELESS ALGORITHM                     " ; Intern. name
    dc.b "2022-07-18    "   ; Version number
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
        
; VRAM memory map
; $0000
; $2000 plane A playfield
; $4000 plane B playfield
; $6000
; $8000 font data
vram_playfield_a = $2000
vram_playfield_b = $4000

; text.asm config
TEXT_VRAM_ADDR_PRINT = vram_playfield_a ; Address of plane to print char indices to
TEXT_VRAM_ADDR_FONT  = $8000 ; Where in VRAM is font data loaded?

text
    dc.b 'HELLO WORLD',0


; ----------------------------------------------------------------------------
; INIT
; ------------------------------------------------------------------------------
EntryPoint:               ; Entry point address set in ROM header
    jsr     init_all

    ; clear_vram_all()
    jsr     clear_vram_all

    ; load_palette( palette_data (a0.l), palette_idx (D0.w) [0-3] )
    lea     palette,a0
    move.w  #0,d0
    jsr     load_palette

    lea     palette1,a0
    move.w  #1,d0
    jsr     load_palette

    ; set_plane_a_addr( vram_addr (D0.w) )
    move.w  #TEXT_VRAM_ADDR_PRINT,d0
    jsr     set_plane_a_addr

    ; set_plane_b_addr( vram_addr (D0.w) )
    move.w  #$4000,d0
    jsr     set_plane_b_addr

    ; load_font( font_data (D0) )
    jsr     load_font

    move.w  #28,d3
    move.w  #0,d1
    move.w  #0,d2
print_loop
    ; print_at_col( x (D1), y (D2), str (A0), strlen (D0), palette (D5.b) [0-3] )
    lea    text,a0
    move.w  #11,d0
    move.b  d3,d5 ; d5 = d3 % 2
    and.b   #1,d5
    jsr     print_at_col

    add.w   #1,d2
    dbra    d3,print_loop




; ----------------------------------------------------------------------------
; MAIN PROGRAM
; ------------------------------------------------------------------------------
__main

    
    move.w  #0,d0
    move.w  #$8F00,VDP_CONTROL     ; VDP autoincrement
    move.l  #$C0000003,VDP_CONTROL ; Set up VDP to write to CRAM address $0000
loop
    move.w  d0,VDP_DATA        ; black (BGR)
    add.w   #1,d0
    move.w  #19,d1
.wait
    dbra    d1,.wait
    jmp     loop



; ----------------------------------------------------------------------------
; EXCEPTION AND INTERRUPT HANDLERS
; ----------------------------------------------------------------------------
    align 2 ; word-align code

ignore_handler
    rte ; return from exception (seems to restore PC)


; ----------------------------------------------------------------------------
; INCLUDES
; ----------------------------------------------------------------------------
    incdir   "../include"
    include  "init.asm"
    include  "vdp.asm"
    include  "text.asm"




; ----------------------------------------------------------------------------
; DATA
; ----------------------------------------------------------------------------
palette:
        ;      BGR
	dc.w $0000 ; Colour 0 - Transparent
	dc.w $06ee
	dc.w $0e00
	dc.w $00e0
	dc.w $000e
	dc.w $00f0
	dc.w $00EE ; Colour 6 - Yellow
	dc.w $008E ; Colour 7 - Orange
	dc.w $0E0E ; Colour 8 - Pink
	dc.w $0808 ; Colour 9 - Purple
	dc.w $0444 ; Colour A - Dark grey
	dc.w $0888 ; Colour B - Light grey
	dc.w $0EE0 ; Colour C - Turquoise
	dc.w $000A ; Colour D - Maroon
	dc.w $0600 ; Colour E - Navy blue
	dc.w $0060 ; Colour F - Dark green
   
   
palette1:
        ;      BGR
	dc.w $000f ; Colour 0 - Transparent
	dc.w $0e07
	dc.w $0000
	dc.w $000f
	dc.w $00ee
	dc.w $00f0
	dc.w $00EE ; Colour 6 - Yellow
	dc.w $008E ; Colour 7 - Orange
	dc.w $0E0E ; Colour 8 - Pink
	dc.w $0808 ; Colour 9 - Purple
	dc.w $0444 ; Colour A - Dark grey
	dc.w $0888 ; Colour B - Light grey
	dc.w $0EE0 ; Colour C - Turquoise
	dc.w $000A ; Colour D - Maroon
	dc.w $0600 ; Colour E - Navy blue
	dc.w $0060 ; Colour F - Dark green



__end




; vim: tw=80 tabstop=4 expandtab ft=asm68k fdm=marker
