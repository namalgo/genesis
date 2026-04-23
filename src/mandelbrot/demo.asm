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

ENABLE_COLOR_CYCLING = 0

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

    ifne ENABLE_COLOR_CYCLING
    dc.l   vblank_interrupt ; IRQ level 6 (vertical retrace interrupt)
    else
    dc.l   ignore_handler   ; IRQ level 6 (vertical retrace interrupt)
    endif

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
    dc.b "MANDELBROT RASTER DEMO BY NAMELESS ALGORITHM    " ; Domest. name
    dc.b "MANDELBROT RASTER DEMO BY NAMELESS ALGORITHM    " ; Intern. name
    dc.b "2022-07-09    "   ; Version number
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
MANDELBROT_ADDR = $E0FF00 ; 12 B
vblanks         = $E0FF10
palette_offset  = $E0FF14
conf_offset     = $E0FF18
;str_conf        = $E0FF20 ; 64 B

INIT_VRAM_PLANE_A = $E000
INIT_VRAM_PLANE_B = $E000
INIT_VRAM_WINDOW  = $A000

VDP_VRAM_SPRITES = 0

; VRAM MAP:
; $0000-$6FFF framebuf
; $7000-$7A00 font
; $8000-$8FFF empty
; $E000-$E800 plane A fixed playfield
; $A000-????? window playfield

; text.asm config
TEXT_VRAM_ADDR_PRINT = $A000 ; Address of plane to print char indices to
TEXT_VRAM_ADDR_FONT  = $7000 ; Where in VRAM is font data loaded?

    ;move.w #$A000,d3
    ;move.w #$7000,d4 ; char offset, palette select
; ----------------------------------------------------------------------------
; STATIC DATA
; ----------------------------------------------------------------------------
conf_x
    dc.w 0,0,0,0,40,120,250,500
conf_y
    dc.w 0,0,0,0,80,120,300,400
conf_zoom
    dc.w 3,4,5,6, 7,  8,  9,10
text
    dc.b 'MANDELBROT RASTER DEMO          NAMELESS ALGORITHM 2022         ',0
;text_conf
    ;dc.b 'CONFIG                                                          ',0

    even


; ------------------------------------------------------------------------------
; MAIN PROGRAM
; ------------------------------------------------------------------------------
    align   4
.marker dc.b "__main  "

__main
entry_point
    jsr     init_all

    jsr    clear_vram_all ; set all of VRAM to 0s

;forever
    ;jmp    forever

.set_vdp_regs
    ; set_vdp_control( reg (D0.b), data (D1.b) )
    ; $00 Mode Register 1         | Default %00000101 | move.w #$80xx,vdp_control
    move.b #$00,d0
    move.b #$04,d1
    jsr    set_vdp_control

    ; $0C Mode register 4         | Default %10000001 | move.w #$8Cxx,vdp_control
    move.b #$0C,d0
    move.b #%00000000,d1
    jsr    set_vdp_control

    ; $10 Plane size              | Default %00000000 | move.w #$90xx,vdp_control
    move.b #$10,d0
    move.b #$00,d1
    jsr    set_vdp_control

    ; set Window Base Point Y = 2
; set_vdp_control( reg (D0.b), data (D1.b) )
    move.b #$12,d0
    move.b #$02,d1
    jsr    set_vdp_control



.load_font
    move.w #$7000,d0
    jsr    load_font


; print_at( x (D1), y (D2), str (A0), strlen (D0), palette (D5.b) [0-3] )
    move.w #0,d1
    move.w #0,d2
    lea    text,a0
    move.w #64,d0
    ;move.w #$A000,d3
    ;move.w #$7000,d4 ; char offset, palette select
    move.w #1,d5
    jsr    print_at_col

; load_palette( palette_data (a0.l), palette_idx (D0.w) [0-3] )
    lea    Palette,a0
    move.w #0,d0
    jsr    load_palette

    lea    text_palette,a0
    move.w #1,d0
    jsr    load_palette

    move.w #$8B70,VDP_CONTROL ;  Plane A address = $E000

    ; gen_playfield( VRAM_address (d0.w) )
    move.w #$E000,d0
    jsr gen_playfield         ;  fixed plane A playfield





    ; color cycling
    move.l  #0,vblanks
    move.l  #0,palette_offset
    move.w  #%1000000101100100,VDP_CONTROL ; enable vblank in VDP
    move.w  #$2500,sr                      ; set Interrupt Priority Mask to 5


    move.w  #0,(conf_offset)

mainloop

    move.w  (conf_offset),d4
    lea     conf_x,a1
    lea     conf_y,a2
    lea     conf_zoom,a3
    add.w   #2,d4
    and.w   #%1111,d4
    move.w  d4,(conf_offset)

    ; jsr     output_conf

    lea     $E00000,a0
    move.w  (a1,d4),d0    ; x
    move.w  (a2,d4),d1    ; y
    move.w  (a3,d4),d2 ; zoom
    move.w  #200-1,d3 ; d3: screen y
next_row
    jsr     mandelbrot     ; render mandelbrot to RAM framebuffer

    move.w  d3,d4          ; copy framebuffer every 8th line
    and.w   #%00000111,d4  ; this will set zero flag if d4 is 0
    bne     skip_copy      ; if not zero, skip

    ; copy_framebuf( framebuf_addr (A0.L), VRAM_char_memory (D0.w) )
    move.l  a0,a1
    move.w  d0,d5
    move.w  #$0000,d0       ; VRAM write to address $0000
    lea     $E00000,a0      ; a0 : Framebuf RAM ptr
    jsr     copy_framebuf  ; copy RAM framebuffer to VRAM
    move.w  d5,d0
    move.l  a1,a0

skip_copy
    dbra    d3,next_row


    move.w  #$fff0,d3
busywait
    muls.w  d2,d2          ; busywork
    muls.w  d2,d2          ; busywork
    muls.w  d2,d2          ; busywork
    muls.w  d2,d2          ; busywork
    muls.w  d2,d2          ; busywork
    muls.w  d2,d2          ; busywork
    muls.w  d2,d2          ; busywork
    muls.w  d2,d2          ; busywork
    muls.w  d2,d2          ; busywork
    muls.w  d2,d2          ; busywork
    muls.w  d2,d2          ; busywork
    dbra    d3,busywait
  

    jmp     mainloop


;output_conf
;    movem.l   d0-d5/a0,-(sp)
;
;; print_at( x (D1), y (D2), str (A0), strlen (D0),
;;           palette (D5.b) [0-3],
;;           print_map_base (D3.w), font_addr (D4.w)    )
;    move.w #0,d1
;    move.w #1,d2
;    lea    text_conf,a0
;    move.w #16,d0
;    move.w #$A000,d3
;    move.w #$7000,d4 ; char offset, palette select
;    move.b #1,d5
;    jsr    print_at
;
;    movem.l   (sp)+,d0-d5/a0
;
;    rts


; ------------------------------------------------------------------------------
; EXCEPTION AND INTERRUPT HANDLERS
; ----------------------------------------------------------------------------
; {{{
    align 2 ; word-align code

ignore_handler
    rte ; return from exception (seems to restore PC)


    align   4
.marker dc.b "__vblank" 
    align   4 ; word-align code

vblank_interrupt
    rte
	;movem.l	d0/a0,-(sp)

    move.l  vblanks,d0  ; every Nth frame
    add.l   #1,vblanks
    and.l   #$3,d0
    cmp.l   #0,d0
    bne     .done

    lea     Palette,a0
    move.l  palette_offset,d0
    add.l   d0,a0

    move.w  #$8F02,VDP_CONTROL     ; Set VDP autoincrement to 2 words/write
    move.l  #$C0000003,VDP_CONTROL ; Set up VDP to write to CRAM address $0000

    move.w  (a0)+,d0
    move.w  #$0000,VDP_DATA        ; always black

    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR
    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR
    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR

    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR
    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR
    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR
    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR

    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR
    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR
    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR
    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR

    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR
    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR
    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR
    move.w  (a0)+,d0
    move.w  d0,VDP_DATA            ; BGR



    add.l   #2,palette_offset
    and.l   #$3F,palette_offset

.done
	movem.l	(sp)+,d0/a0
    rte
; }}}





; ------------------------------------------------------------------------------
; PALETTE
; ------------------------------------------------------------------------------
; {{{
    even
Palette:
        ;      BGR
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

; color cycling stuff
	dc.w $001e
	; dc.w $002d
	dc.w $0fff
	dc.w $003c
	dc.w $004b
	dc.w $005a
	dc.w $0069
	dc.w $0078
	dc.w $0087
	dc.w $0096
	dc.w $00a5
	dc.w $00b4
	dc.w $00c3
	dc.w $00d2
	dc.w $00e1
	dc.w $00f0
	dc.w $00e0

	dc.w $00d0
	dc.w $00c0
	dc.w $00b0
	dc.w $01a0
	dc.w $0290
	dc.w $0380
	dc.w $0470
	dc.w $0560
	dc.w $0650
	dc.w $0740
	dc.w $0830
	dc.w $0920
	dc.w $0a10
	dc.w $0b00
	dc.w $0c00

	dc.w $0d00
	dc.w $0e01
	dc.w $0d02
	dc.w $0c03
	dc.w $0b04
	dc.w $0a05
	dc.w $0906
	dc.w $0807
	dc.w $0708
	dc.w $0609
	dc.w $050a
	dc.w $040b
	dc.w $030c
	dc.w $020d
	dc.w $010e
	dc.w $000f

text_palette:
    dc.w $0000
    dc.w $0ee4
    dc.w $0e00
    dc.w $00e0
    dc.w $000e
    dc.w $0ee0
    dc.w $00ee
    dc.w $0e0e
    dc.w $0eee
    dc.w $0eee
    dc.w $0eee
    dc.w $0eee
    dc.w $0eee
    dc.w $0eee
    dc.w $0eee
    dc.w $0eee
    dc.w $0eee
    dc.w $0eee
; }}}


; ----------------------------------------------------------------------------
; INCLUDES
; ----------------------------------------------------------------------------
    incdir  '../include'
    include 'init.asm'
    include 'vdp.asm'
    include 'text.asm'
    include 'raster.asm'

    include 'mandelbrot.asm'




__end

; vim: tw=80 tabstop=4 expandtab ft=asm68k fdm=marker
