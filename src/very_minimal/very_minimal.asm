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


; ROM HEADER
; ------------------------------------------------------------------------------
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
    dc.b "(C) NAMELESS    " ; Copyright holder and release date
    dc.b "VERY MINIMAL GENESIS CODE BY NAMELESS ALGORITHM   " ; Domest. name
    dc.b "VERY MINIMAL GENESIS CODE BY NAMELESS ALGORITHM   " ; Intern. name
    dc.b "2022-08-04    "   ; Version number
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
        


; CONSTANTS
; ------------------------------------------------------------------------------
vdp_control     = $C00004 ; Memory mapped I/O
vdp_data        = $C00000 ;



; INIT
; ------------------------------------------------------------------------------
EntryPoint:               ; Entry point address set in ROM header
    move    #$2700,sr     ; disable interrupts


; Skip clear RAM - we don't use RAM at all in this example

TMSS
    move.b  $00A10001,d0      ; Move Megadrive hardware version to d0
    andi.b  #$0F,d0           ; The version is stored in last four bits,
                              ; so mask it with 0F
    beq     .skip             ; If version is equal to 0,skip TMSS signature
    move.l  #'SEGA',$00A14000 ; Move the string "SEGA" to $A14000
.skip

Z80
    move.w  #$0100,$00A11100 ; Request access to the Z80 bus
    move.w  #$0100,$00A11200 ; Hold the Z80 in a reset state
.wait
    btst    #$0,$00A11101    ; Check if we have access to the Z80 bus yet
    bne     .wait            ; If we don't yet have control,branch back up to Wait
    move.l  #$00A00000,a1    ; Copy Z80 RAM address to a1
    move.l  #$00C30000,(a1)  ; Copy data,and increment the source/dest addresses
 
    move.w  #$0000,$00A11200 ; Release reset state
    move.w  #$0000,$00A11100 ; Release control of bus
 
; Initialize PSG to silence
    ;move.l  #$9fbfdfff,$00C00011  ; silence

init_vdp
    move.l  #VDPRegisters,a0 ; Load address of register table into a0
    move.l  #$18,d0          ; 24 registers to write
    move.l  #$00008000,d1    ; 'Set register 0' command
                             ; (and clear the rest of d1 ready)
 
copy_vdp
    move.b  (a0)+,d1         ; Move register value to lower byte of d1
    move.w  d1,$00C00004     ; Write command and value to VDP control port
    add.w   #$0100,d1        ; Increment register #
    dbra    d0,copy_vdp

; Ignore I/O ports - we don't use them
    



; MAIN PROGRAM
; ------------------------------------------------------------------------------
main
    move.w  #0,d0
    move.w  #$8F00,vdp_control     ; Set VDP autoincrement to 2 words/write
    move.l  #$C0000003,vdp_control ; Set up VDP to write to CRAM address $0000
loop
    move.w  d0,vdp_data        ; black (BGR)
    add.w   #1,d0
    move.w  #100,d1
.wait
    dbra    d1,.wait
    jmp     loop



; EXCEPTION AND INTERRUPT HANDLERS
; ----------------------------------------------------------------------------
    align 2 ; word-align code

ignore_handler
    rte ; return from exception (seems to restore PC)



; VDP REGISTER INITIALIZATION
; ------------------------------------------------------------------------------
; - Explanations (albeit short explanations) of the VDP registers can be found
;   in chapter 4 of the SEGA2 doc 

    align 2 ; word-align code

VDPRegisters:
; Mode
reg00:  dc.b %00000101  ; MD colors on, display on, hblank off
reg01:  dc.b %01000100  ; Display on, vblank off, DMA off, NTSC, Genesis mode

; VRAM layout
reg02:  dc.b $38        ; Pattern table for Scroll Plane A at VRAM $E000
reg03:  dc.b $00        ; Pattern table for Window Plane   at VRAM $0000
reg04:  dc.b $07        ; Pattern table for Scroll Plane B at VRAM $E000
reg05:  dc.b $78        ; Sprite table at VRAM $F000 (bits 0-6 = bits 9-15)
reg06:  dc.b $00        ; Sprite table 128KB VRAM (ignore)

; BG color
reg07:  dc.b $00        ; Background colour - bits 0-3 = colour
                        ;                     bits 4-5 = palette

; Unused
reg08:  dc.b $00        ; SMS HScroll reg
reg09:  dc.b $00        ; SMS VScroll reg

; General
reg0A:  dc.b $00        ; hblank counter (# scanlines between hblank)

reg0B:  dc.b %0000000   ; Ext. interrupts off, HScroll fullscreen
reg0C:  dc.b %0000000   ; H40 (320px) mode, no external pixel bus, disable 
                        ; shadow/highlight mode, no interlace
reg0D:  dc.b $3F        ; Horiz. scroll table at VRAM $FC00 (bits 0-5)
reg0E:  dc.b $00        ; Unused
reg0F:  dc.b $02        ; Autoincrement 2 bytes
reg10:  dc.b $00        ; Vert. scroll 32, Horiz. scroll 32

; Window
reg11: dc.b $00         ; Window Plane X pos 0 left
                        ; (pos in bits 0-4, left/right in bit 7)
reg12: dc.b $00         ; Window Plane Y pos 0 up
                        ; (pos in bits 0-4, up/down in bit 7)

; DMA
reg13: dc.b $00         ; DMA length lo byte
reg14: dc.b $00         ; DMA length hi byte
reg15: dc.b $00         ; DMA source address lo byte
reg16: dc.b $00         ; DMA source address mid byte
reg17: dc.b $80         ; DMA source address hi byte,
                        ; memory-to-VRAM mode (bits 6-7)

__end:
; vim: tw=80 tabstop=4 expandtab ft=asm68k
