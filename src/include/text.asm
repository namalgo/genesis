; SEGA Genesis ROM by the Nameless Algorithm 2022-06-17
; - http://namelessalgorithm.com/


; ------------------------------------------------------------------------------
; USAGE
; ------------------------------------------------------------------------------
;
;    include 'text.asm'
;
; ; text.asm config
; TEXT_VRAM_ADDR_PRINT = $4000 ; Address of plane to print char indices to
; TEXT_VRAM_ADDR_FONT  = $0000 ; Where in VRAM is font data loaded?
;
; text
;    dc.b 'HELLO WORLD',0
;
;    jsr     load_font
;
;    ; print_at( x (D1), y (D2), str (A0), strlen (D0), palette (D5.b) [0-3] )
;    move.w  #0,d1
;    move.w  #0,d2
;    lea    text,a0
;    move.w  #11,d0
;    move.b  #0,d5
;    jsr     print_at
;

    ifnd NAMALGO_TEXT
NAMALGO_TEXT = 1

; ----------------------------------------------------------------------------
; VERIFY CONFIG
; ----------------------------------------------------------------------------
    ifnd TEXT_VRAM_ADDR_PRINT
    echo "TEXT_VRAM_ADDR_PRINT undefined"
    endif
    ifnd TEXT_VRAM_ADDR_FONT
    echo "TEXT_VRAM_ADDR_FONT undefined"
    endif

; ----------------------------------------------------------------------------
; INCLUDES
; ----------------------------------------------------------------------------
    include  "vdpmacros.asm"


; ----------------------------------------------------------------------------
; load_font( font_data (D0) )
;
; Load font data into VRAM address (D0)
;
; destroys: A0, D0
; ----------------------------------------------------------------------------
load_font:
    movem.l  d0/a0,-(sp)
    ;move.w #$8F02,vdp_control     ; Set VDP autoincrement to 2 words/write
    M_VDP_SETREG VDP_AUTOINC,2
    M_VRAM_WRITE TEXT_VRAM_ADDR_FONT

    lea    TEXT_FONT_DATA,a0                          ; Load address of TEXT_FONT_DATA into a0
    move.w #(TEXT_FONT_DATA_end-TEXT_FONT_DATA)/4,d0  ; 40 characters, 8 longwords/char

.Loop:
    move.l (a0)+,VDP_DATA ; Move data to VDP data port, increment source addr
    dbra.w d0,.Loop

    movem.l  (sp)+,d0/a0
    rts


; ----------------------------------------------------------------------------
; print_at( x (D1), y (D2), str (A0), strlen (D0) )
; ----------------------------------------------------------------------------
print_at:
    movem.l  d5,-(sp)
    move.w   #0,d5
    jsr      print_at_col
    movem.l  (sp)+,d5
    rts






; ----------------------------------------------------------------------------
; print_at_col( x (D1), y (D2), str (A0), strlen (D0), palette (D5.w) [0-3] )
;
; From genvdp.txt:
;   The window plane operates differently from plane A or B. It can be thought
;   of a 'replacement' for plane A which is used under certain conditions.
;   That said, plane A cannot be displayed in any area where plane W is
;   located, it is impossible for them to overlap.
; ----------------------------------------------------------------------------
; Bits: [BBAA AAAA AAAA AAAA 0000 0000 BBBB 00AA]
; - 0 is always just 0
; - A is destination address, in this order:
;       [..DC BA98 7654 3210 .... .... .... ..FE]
; - B is Operation type, in this order:
;       [10.. .... .... .... .... .... 5432 ....]
;
;
; Playfield map entry:
; 
; [PCCV HIII IIII IIII]
; - P is priority (set to 0 for now)
; - C selects color palette
; - V enables vertical flip (0)
; - H enables horizontal flip (0)
; - I is an 11-bit character index:
;       [.... .A98 7654 3210]
;
print_at_col:
;   d6 : str length
;   d1 : x offset
;   d2 : y offset
;   d3 : VRAM address
;   d4 : VDP command word
;   d5 : tmp
    movem.l  d0-d6/a0,-(sp)
    ;tst.w    d0
    ;bne      .skip
    ;move.w   #32,d0
    move.w   d0,d6

    and.w    #%11,d5 ; palette idx
    lsl.w    #7,d5   ; << 13
    lsl.w    #6,d5

    move.w   #(TEXT_VRAM_ADDR_FONT>>5),d4
    ;lsr.w    #5,d4   ; char idx = VRAM address / 32
    or.w     d5,d4   ; Palette idx
    ;add.w   #$10,d4; TEST

.skip
    ; d3 = xoff*2 + yoff*128
    lsl.w   #1,d1
    lsl.w   #6,d2
    move.w   #TEXT_VRAM_ADDR_PRINT,d3
    add.w   d1,d3
    add.w   d2,d3

; setup_vram_write( addr (D0.w) )
    move.w  d3,d0
    jsr     setup_vram_write

    sub.w   #1,d6       ; 
.loop
    clr.w   d3          ; clear upper byte of d0
    move.b  (a0)+,d3    ; set lower byte
    beq     .done       ; null terminator found, exiting
    sub.w   #32,d3     ; subtract ASCII value of <space>
    add.w   d4,d3
    move.w  d3,VDP_DATA ; write to VDP
    ;move.w  d4,vdp_data ; write to VDP ; test
    dbra    d6,.loop

.done
    movem.l (sp)+,d0-d6/a0
    rts


; ----------------------------------------------------------------------------
; cls: Clear name tables
; ----------------------------------------------------------------------------
cls
clear_plane_a
    move.w  #TEXT_VRAM_ADDR_PRINT,d0
    jsr     setup_vram_write
    move.w  #$800,d0
.loop
    move.w  #0,VDP_DATA ; write to VDP
    dbra    d0,.loop

    rts


; ----------------------------------------------------------------------------
; bin2str( str (A0), number (D0), digits (D1) )
; - Output binary number characters to string
; ----------------------------------------------------------------------------
bin2str
    movem.l   d1/a0,-(sp)

    sub.b   #1,d1
.loop
    move.b  #48,(a0)
    btst    d1,d0
    beq     .dontChange
    move.b  #49,(a0)
.dontChange:
    add.l   #1,a0
    dbra    d1,.loop

    movem.l   (sp)+,d1/a0
    rts

; ----------------------------------------------------------------------------
; hex2str_l( str (A0), number (D0), digits (D1) )
; - Output hexadecimal number characters to string
; ----------------------------------------------------------------------------
hex2str_l
    movem.l   d0-d2/a0,-(sp)

    sub.b   #1,d1
    add.w   d1,a0          ; start from rightmost nibble
.outputchar
    move.l  d0,d2
    and.l   #$0000000F,d2
    cmp.b   #9,d2
    bgt     .alpha
    add.b   #'0',d2
    jmp     .done
.alpha
    add.b   #'A'-10,d2
.done
    move.b  d2,(a0)
    sub.l   #1,a0
    lsr.l   #4,d0
    dbra    d1,.outputchar

    movem.l   (sp)+,d0-d2/a0
    rts



; ----------------------------------------------------------------------------
; INCLUDES
; ----------------------------------------------------------------------------
    include 'vdp.asm' ; setup_vram_write




;==============================
;characters
;==============================

TEXT_FONT_DATA:
; [Space]
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
; ! 
   dc.l $00011000
   dc.l $00111100
   dc.l $00011000
   dc.l $00011000
   dc.l $00000000
   dc.l $00011000
   dc.l $00011000
   dc.l $00000000
; " 
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $00000000
; # 
   dc.l $55555555
   dc.l $55555555
   dc.l $55555555
   dc.l $55555555
   dc.l $55555555
   dc.l $55555555
   dc.l $55555555
   dc.l $55555555
; $ 
   dc.l $00330000 
   dc.l $33333330
   dc.l $33000000
   dc.l $33333330
   dc.l $00000330
   dc.l $33333330
   dc.l $00330000
   dc.l $00000000
; % 
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $00000000
; & 
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $00000000
; ' 
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $00000000
; ( 
   dc.l $00001110
   dc.l $00011000
   dc.l $00110000
   dc.l $00110000
   dc.l $00110000
   dc.l $00011000
   dc.l $00001110
   dc.l $00000000
; ) 
   dc.l $11100000
   dc.l $00110000
   dc.l $00011000
   dc.l $00011000
   dc.l $00011000
   dc.l $00110000
   dc.l $11100000
   dc.l $00000000
; * 
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $00000000
; + 
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $00000000
; , 
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $00000000
; - 
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $01111110
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
; . 
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00011000
   dc.l $00011000
   dc.l $00000000
; / 
   dc.l $00000011
   dc.l $00000110
   dc.l $00001100
   dc.l $00011000
   dc.l $00110000
   dc.l $01100000
   dc.l $11000000
   dc.l $00000000
; 0 
   dc.l $01111100
   dc.l $11000110
   dc.l $11010110
   dc.l $11010110
   dc.l $11010110
   dc.l $11000110
   dc.l $01111100
   dc.l $00000000
; 1 
   dc.l $00011000
   dc.l $00111000
   dc.l $01111000
   dc.l $00011000
   dc.l $00011000
   dc.l $00011000
   dc.l $11111110
   dc.l $00000000
; 2 
   dc.l $01111100
   dc.l $11000110
   dc.l $00000110
   dc.l $00001100
   dc.l $00110000
   dc.l $01100000
   dc.l $11111110
   dc.l $00000000
; 3 
   dc.l $01111100
   dc.l $11000110
   dc.l $00000110
   dc.l $00011100
   dc.l $00000110
   dc.l $11000110
   dc.l $01111100
   dc.l $00000000
; 4
   dc.l $00001100
   dc.l $00011100
   dc.l $00111100
   dc.l $01101100
   dc.l $11111110
   dc.l $00001100
   dc.l $00001100
   dc.l $00000000
; 5 
   dc.l $11111110 
   dc.l $11000000
   dc.l $11000000
   dc.l $11111100
   dc.l $00000110
   dc.l $11000110
   dc.l $01111100
   dc.l $00000000
; 6 
   dc.l $00111100 
   dc.l $01100000
   dc.l $11000000
   dc.l $11111100
   dc.l $11000110
   dc.l $11000110
   dc.l $01111100
   dc.l $00000000
; 7
   dc.l $11111110 
   dc.l $00000110
   dc.l $00001100
   dc.l $00011000
   dc.l $00110000
   dc.l $01100000
   dc.l $01100000
   dc.l $00000000
; 8
   dc.l $01111100
   dc.l $11000110
   dc.l $11000110
   dc.l $01111100
   dc.l $11000110
   dc.l $11000110
   dc.l $01111100
   dc.l $00000000
; 9
   dc.l $01111100 
   dc.l $11000110
   dc.l $11000110
   dc.l $01111110
   dc.l $00000110
   dc.l $00000110
   dc.l $01111100
   dc.l $00000000
; :
   dc.l $00000000
   dc.l $00011000
   dc.l $00011000
   dc.l $00000000
   dc.l $00000000
   dc.l $00011000
   dc.l $00011000
   dc.l $00000000
; ;
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $00000000
; <
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $00000000
; =
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $00000000
; >
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $00000000
; ?
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $01010101
   dc.l $10101010
   dc.l $00000000
; @
   dc.l $11223344
   dc.l $11223344
   dc.l $55667788
   dc.l $55667788
   dc.l $99AABBCC
   dc.l $99AABBCC
   dc.l $DDEEFF00
   dc.l $DDEEFF00
; A
   dc.l $01111100
   dc.l $11000110
   dc.l $11000110
   dc.l $11111110
   dc.l $11000110
   dc.l $11000110
   dc.l $11000110
   dc.l $00000000
 
   dc.l $11111100
   dc.l $11000110
   dc.l $11000110
   dc.l $11111100
   dc.l $11000110
   dc.l $11000110
   dc.l $11111100
   dc.l $00000000

   dc.l $01111100 
   dc.l $11101110
   dc.l $11000000
   dc.l $11000000
   dc.l $11000000
   dc.l $11101110
   dc.l $01111100
   dc.l $00000000
 
   dc.l $11111000 
   dc.l $11001110
   dc.l $11000110
   dc.l $11000110
   dc.l $11000110
   dc.l $11001110
   dc.l $11111000
   dc.l $00000000 

   dc.l $11111110 
   dc.l $11000000
   dc.l $11000000
   dc.l $11111100
   dc.l $11000000
   dc.l $11000000
   dc.l $11111110
   dc.l $00000000
 
   dc.l $11111110 
   dc.l $11000000
   dc.l $11000000
   dc.l $11111110
   dc.l $11000000
   dc.l $11000000
   dc.l $11000000
   dc.l $00000000

   dc.l $01111100 
   dc.l $11101110
   dc.l $11000000
   dc.l $11001110
   dc.l $11000110
   dc.l $11101110
   dc.l $01111100
   dc.l $00000000
 
   dc.l $11000110 
   dc.l $11000110
   dc.l $11000110
   dc.l $11111110
   dc.l $11000110
   dc.l $11000110
   dc.l $11000110
   dc.l $00000000
 
   dc.l $01111110 
   dc.l $00011000
   dc.l $00011000
   dc.l $00011000
   dc.l $00011000
   dc.l $00011000
   dc.l $01111110
   dc.l $00000000
 
   dc.l $11111110 
   dc.l $00000110
   dc.l $00000110
   dc.l $00000110
   dc.l $11000110
   dc.l $11101110
   dc.l $01111100
   dc.l $00000000

   dc.l $11000110 
   dc.l $11001100
   dc.l $11011000
   dc.l $11110000
   dc.l $11011000
   dc.l $11001100
   dc.l $11000110
   dc.l $00000000

   dc.l $11000000 
   dc.l $11000000
   dc.l $11000000
   dc.l $11000000
   dc.l $11000000
   dc.l $11000000
   dc.l $11111110
   dc.l $00000000
 
   dc.l $11000110 
   dc.l $11101110
   dc.l $11111110
   dc.l $11010110
   dc.l $11010110
   dc.l $11000110
   dc.l $11000110
   dc.l $00000000
 
   dc.l $11000110 
   dc.l $11100110
   dc.l $11110110
   dc.l $11011110
   dc.l $11001110
   dc.l $11000110
   dc.l $11000110
   dc.l $00000000
 
   dc.l $01111100 
   dc.l $11101110
   dc.l $11000110
   dc.l $11000110
   dc.l $11000110
   dc.l $11101110
   dc.l $01111100
   dc.l $00000000
 
   dc.l $11111100 
   dc.l $11000110
   dc.l $11000110
   dc.l $11111100
   dc.l $11000000
   dc.l $11000000
   dc.l $11000000
   dc.l $00000000

   dc.l $01111100 
   dc.l $11101110
   dc.l $11000110
   dc.l $11000110
   dc.l $11010110
   dc.l $11101100
   dc.l $01110110
   dc.l $00000000

   dc.l $11111100 
   dc.l $11000110
   dc.l $11000110
   dc.l $11111100
   dc.l $11001110
   dc.l $11000110
   dc.l $11000110
   dc.l $00000000

   dc.l $01111100 
   dc.l $11000110
   dc.l $11000000
   dc.l $01111100
   dc.l $00000110
   dc.l $11000110
   dc.l $01111100
   dc.l $00000000
 
   dc.l $11111110 
   dc.l $00110000
   dc.l $00110000
   dc.l $00110000
   dc.l $00110000
   dc.l $00110000
   dc.l $00110000
   dc.l $00000000
 
   dc.l $11000110 
   dc.l $11000110
   dc.l $11000110
   dc.l $11000110
   dc.l $11000110
   dc.l $11000110
   dc.l $01111100
   dc.l $00000000
 
   dc.l $11000110 
   dc.l $11000110
   dc.l $11000110
   dc.l $11000110
   dc.l $01101100
   dc.l $01101100
   dc.l $00111000
   dc.l $00000000
 
   dc.l $11000110 
   dc.l $11000110
   dc.l $11000110
   dc.l $11000110
   dc.l $11010110
   dc.l $11101110
   dc.l $11000110
   dc.l $00000000

   dc.l $11000110 
   dc.l $01101100
   dc.l $00111000
   dc.l $00111000
   dc.l $01101100
   dc.l $11000110
   dc.l $11000110
   dc.l $00000000

   dc.l $11000110 
   dc.l $11000110
   dc.l $01101100
   dc.l $01101100
   dc.l $00111000
   dc.l $00111000
   dc.l $00111000
   dc.l $00000000
 
   dc.l $11111110 
   dc.l $00000110
   dc.l $00001100
   dc.l $00011000
   dc.l $00110000
   dc.l $01100000
   dc.l $11111110
   dc.l $00000000
; [ 
   dc.l $01111100 
   dc.l $01100000
   dc.l $01100000
   dc.l $01100000
   dc.l $01100000
   dc.l $01100000
   dc.l $01111100
   dc.l $00000000
; \ 
   dc.l $00010000 
   dc.l $00010000
   dc.l $00010000
   dc.l $00010000
   dc.l $00010000
   dc.l $00010000
   dc.l $00010000
   dc.l $00010000
; ] 
   dc.l $01111100 
   dc.l $00001100
   dc.l $00001100
   dc.l $00001100
   dc.l $00001100
   dc.l $00001100
   dc.l $01111100
   dc.l $00000000
; ^ 
   dc.l $22222220 
   dc.l $22222220
   dc.l $22222220
   dc.l $22222220
   dc.l $22222220
   dc.l $22222220
   dc.l $22222220
   dc.l $00000000
; _ 
   dc.l $00000000 
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $11111111
   dc.l $00000000
; `
   dc.l $11111111 
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000


;   0000000000000000 
;   0000000000000000
;   0033333333000000
;   0444444443300000
;   4411111144330000
;   4121121114440000
;   4121121114440000
;   4114111144330000
;   4444444443331000 
;   3443344433301000
;   0333333333111000
;   0034333343000000
;   0004000040000000
;   0444404444000000
;   0000000000000000
;   0000000000000000
   
; pooka0 (1:white, 2:black, 3:red, 4:yellow)
   dc.l $00000000 
   dc.l $00000000
   dc.l $00333333
   dc.l $04444444
   dc.l $44111111
   dc.l $41211211
   dc.l $41211211
   dc.l $41141111
; pooka2 
   dc.l $44444444 
   dc.l $34433444
   dc.l $03333333
   dc.l $00343333
   dc.l $00040000
   dc.l $04444044
   dc.l $00000000
   dc.l $00000000
; pooka1 
   dc.l $00000000 
   dc.l $00000000
   dc.l $33000000
   dc.l $43300000
   dc.l $44330000
   dc.l $14440000
   dc.l $14440000
   dc.l $44330000
; pooka3 
   dc.l $43331000 
   dc.l $33301000
   dc.l $33111000
   dc.l $43000000
   dc.l $40000000
   dc.l $44000000
   dc.l $00000000
   dc.l $00000000

; red flower      yellow flower
; 0000333330000   0000444440000
; 0003333333000   0004444444000
; 0003333333000   0004444444000
; 0330334330330   0440443440440
; 3333034303333   4444043404444
; 3333344433333   4444433344444
; 3334444444333   4443333333444
; 3333344433333   4444433344444
; 3333034303333   4444043404444
; 0330334330330   0440443440440
; 0003333333000   0004444444000
; 0003333333000   0004444444000
; 0000333330000   0000444440000

; red flower0 (1:white, 2:black, 3:red, 4:yellow)
   dc.l $00003333
   dc.l $00033333
   dc.l $00033333
   dc.l $03303343
   dc.l $33330343
   dc.l $33333444
   dc.l $33344444
   dc.l $33333444
; red flower1
   dc.l $33330343
   dc.l $03303343
   dc.l $00033333
   dc.l $00033333
   dc.l $00003333
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000
; red flower2
   dc.l $30000000
   dc.l $33000000
   dc.l $33000000
   dc.l $30330000
   dc.l $03333000
   dc.l $33333000
   dc.l $44333000
   dc.l $33333000
; red flower3
   dc.l $03333000
   dc.l $30330000
   dc.l $33000000
   dc.l $33000000
   dc.l $30000000
   dc.l $00000000
   dc.l $00000000
   dc.l $00000000

; bullet0
   dc.l $00000000
   dc.l $00000000
   dc.l $00033000
   dc.l $00333300
   dc.l $00333300
   dc.l $00033000
   dc.l $00000000
   dc.l $00000000
; bullet1
   dc.l $00000000
   dc.l $00033000
   dc.l $00333300
   dc.l $03344330
   dc.l $03344330
   dc.l $00333300
   dc.l $00033000
   dc.l $00000000
; bullet2
   dc.l $00000000
   dc.l $00333300
   dc.l $03333330
   dc.l $03344330
   dc.l $03344330
   dc.l $03333330
   dc.l $00333300
   dc.l $00000000
; bullet3
   dc.l $00033000
   dc.l $03344330
   dc.l $03444430
   dc.l $34444443
   dc.l $34444443
   dc.l $03444430
   dc.l $03344330
   dc.l $00033000
; tile0
   dc.l $22222222
   dc.l $22222222
   dc.l $22222222
   dc.l $22222222
   dc.l $22222222
   dc.l $22222222
   dc.l $22222222
   dc.l $22222222
; tile1
   dc.l $55555555
   dc.l $55555555
   dc.l $55555555
   dc.l $55555555
   dc.l $55555555
   dc.l $55555555
   dc.l $55555555
   dc.l $55555555
TEXT_FONT_DATA_end

    endif ; NAMALGO_TEXT

; vim: tw=80 tabstop=4 expandtab ft=asm68k fdm=marker
