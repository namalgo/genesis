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
;    include 'init.asm'
;
;    jsr     init_all    ; default system initialization
;
;
; Advanced usage with custom VDP config:
;
;    jsr     init_system
;    move.l  #my_vdp_regs,a0 ; Load address of register table into a0
;    jsr     init_vdp
;





; ------------------------------------------------------------------------------
; CHANGELOG
; ------------------------------------------------------------------------------
; r10420 - 'init' is now called 'init_all'. Added custom initialization.




; Use this for default init
init_all
    jsr     init_system

    move.l  #VDPRegisters_default,a0 ; Load address of register table into a0
    jsr     init_vdp

; Ignore I/O ports - we don't use them
    
; Status register
    ;move    #$2700,sr

    rts



init_system
    move    #$2700,sr     ; disable interrupts

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

    rts



PSGData:
    dc.w $9fbf, $dfff	; silence

init_vdp
    move.l  #$18,d0          ; 24 registers to write
    move.l  #$00008000,d1    ; 'Set register 0' command
                             ; (and clear the rest of d1 ready)
 
@CopyVDP:
    move.b  (a0)+,d1         ; Move register value to lower byte of d1
    move.w  d1,$00C00004     ; Write command and value to VDP control port
    add.w   #$0100,d1        ; Increment register #
    dbra    d0,@CopyVDP

    rts


Z80Code
    incbin "z80.bin"
Z80CodeEnd

; ------------------------------------------------------------------------------
; DEFAULT VDP REGISTER INITIALIZATION
; ------------------------------------------------------------------------------
; - See https://segaretro.org/Sega_Mega_Drive/VDP_registers

    align 2 ; word-align code

VDPRegisters_default:
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

; vim: tw=80 tabstop=4 expandtab ft=asm68k fdm=marker
