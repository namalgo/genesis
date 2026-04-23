; ------------------------------------------------------------------------------
; vdp.asm
;
;   ----------------------------------------------------------------------
;   Subroutine Overview                                                     
;   ---------------------------------------------------------------------- 
;   VRAM setup ...........................................................  
;   set_vdp_control( reg (D0.b), data (D1.b) )                              
;   set_plane_a_addr( vram_addr (D0.w) )                                    
;   set_plane_b_addr( vram_addr (D0.w) )                                    
;   set_window_addr ( vram_addr (D0.w) )                                    
;   set_scroll_table_addr( vram_addr (D0.w) )                               
;                                                                           
;   I/O ..................................................................  
;   clear_vram_all( )
;   clear_name_table( vram_addr (D0), value (D1) )
;   setup_vram_write( addr (D0.w) )
;   setup_vsram_write( addr (D0.w) )
;   setup_cram_write( addr (D0.w) )
;   load_palette( palette_data (a0.l), palette_idx (D0.w) [0-3] )
;                                                                           
;   Sprites (1) .......................................................... 
;   init_sprites( )                                                        
;   clear_sprites( )                                                       
;   set_sprite_addr( vram_addr (D0.w) )                                    
;   setup_sprite_struct( spritedef (A0.L) )                                
;   setup_sprite_final( idx (D0.w) )                                       
;   word1 (D0.w) = gen_sprite_word1( link (D0.w), sizes (D1.b [.... xxyy]))
;   word2 (D0.w) = gen_sprite_word2( tile (D0.w), conf  (D1.b [Pppv h000]))
;                                                                         
;   Various ..............................................................
;   set_window_pos( width (D0.b), height (D1.b) )                         
;   wait_vblank: Wait for vblank                                          
;   wait_line( line (D0.w) ) *** DOESN'T WORK ***                         
;                                                                         
;   Internal .............................................................
;   setup_sprite( idx (D0.w), link (D1.w), x (D2.w), y (D3.w),            
;                 pattern (D4.w), conf (D5.w) )                           
;                                                                         
;   Deprecated ...........................................................
;   setup_sprite_stk( idx (w), link (w), x (w), y (w), conf (w) )         
;   ------------------------------------------------------------------------
;   1) For most of these, VDP_VRAM_SPRITES must be set to sprite table addr
;
;
; CHANGELOG
; 0.5 2025-10-22 added gen_sprite_word1, gen_sprite_word2,
;                useful for manually building sprite tables in RAM
; 0.4 2025-04-02 added setup_sprite_struct, setup_sprite_stk, setup_sprite_final
;                setup_sprite_struct takes a single parameter, a ptr to a struct
;                setup_sprite_stk uses stack parameters
;                setup_sprite_final write a terminator sprite to the list
; 0.3 2025-02-17 init_sprites, setup_sprite, clear_sprites now can be configured
;                using VDP_VRAM_SPRITES
;                setup_sprite ensures autoinc is set correctly
; 0.2 2025-02-15 clear_name_table ensures autoincrement is set correctly
; 0.1 2025-02-15 First version
;
; COPYRIGHT
; Copyright 2022 Nameless Algorithm
; See https://namelessalgorithm.com/ for more information.
;
; LICENSE
; You may use this source code for any purpose. If you do so, please attribute
; 'Nameless Algorithm' in your source, or mention us in your game/demo credits.
; Thank you.
;
; NOTES
;
; USAGE
;
; ; vdp.asm config:
; VDP_VRAM_SPRITES     = $E000  ; multiple of $400
;
;     jsr     init_sprites
;     move.w  #0,d0
;     move.w  #1,d1
;     move.w  #160,d2
;     move.w  #120,d3
;     move.w  #10,d4
;     move.b  #0,d5
;     jsr     setup_sprite
; ------------------------------------------------------------------------------


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
; init_sprites( )
;
; NOTE: assumes that VDP_VRAM_SPRITES is set to the address of the sprite table
; ----------------------------------------------------------------------------
init_sprites
; set_sprite_addr( vram_addr (D0.w) )
    move.w  #VDP_VRAM_SPRITES,d0
    jsr     set_sprite_addr
    jsr     clear_sprites
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

    move.w #$8F02,VDP_CONTROL     ; Set VDP autoincrement to 2 bytes/write
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
    and.w  #%11,d0
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
; wait_line( line (D0.w) )
; destroys: D7
; FIXME: doesn't seem to work!
; ----------------------------------------------------------------------------
wait_line
    move.w  $C00008,d7       ; Read VDP status
    andi.w  #$3FF,d7         ; Mask to get only scanline number (0–261)
    cmp.w   d0,d7            ; Wait until scanline 100
    blt     wait_line
    rts


; ----------------------------------------------------------------------------
; clear_sprites: Disable all sprites by writing an empty sprite table
; ----------------------------------------------------------------------------
clear_sprites
    ; Set sprite RAM to be at $F000
    ; move.w  #%1000010101111000,VDP_CONTROL  ; Sprite RAM = $F000
    ; move.w  #$8F02,VDP_CONTROL  
    ; move.l  #$70000003,VDP_CONTROL          ; VDP write to VRAM address $F000

    ; set_sprite_addr( vram_addr (D0.w) )
    ; setup_vram_write( addr (D0.w) )
    ; move.w  #VDP_VRAM_SPRITES,d0
    ; jsr set_sprite_addr
    M_VDP_SETREG VDP_AUTOINC,2               ; Set VDP autoincrement to 2 bytes
    move.w  #VDP_VRAM_SPRITES,d0
    jsr setup_vram_write

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
; setup_vsram_write( addr (D0.w) )
; ----------------------------------------------------------------------------
setup_vsram_write
    movem.l   d0/d5-d6,-(sp)

;    Bits    [BBAA AAAA AAAA AAAA 0000 0000 BBBB 00AA]
;    B order [10.. .... .... .... .... .... 5432 ....] oper. type
;    A order [..DC BA98 7654 3210 .... .... .... ..FE] address
;    -------------------------------------------------------------
;    VSRAM Write (00 0101) to addr $0000 (0000 0000 0000 0000):
;            [01.. .... .... .... .... .... 0001 ....] oper. type
;            [0100 0000 0000 0000 .... .... 0001 ..00] VSRAM address
;            [0100 0000 0000 0000 0000 0000 0001 0000] add zeroes
;      Hex:      4    0    0    0    0    0    1    0

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


    ;move.l  #$40000000,d0 ; VSRAM write command
    move.l  #%01000000000000000000000000010000,d0 ; VSRAM write command
;             CCaaaaaaaaaaaaaa00000000CCCC00aa
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


; ----------------------------------------------------------------------------
; setup_sprite( idx (D0.w), link (D1.w), x (D2.w), y (D3.w), pattern (D4.w), conf (D5.w) )
; - idx  : sprite # (0-?)
; - link : next sprite idx
; - x,y  : pos
; - conf (16-bit) [pCCxyHHVV]
;   > p is priority
;   > C is palette index
;   > x,y is horizontal and vertical flip
;   > H,V is size (in characters)
;
; NOTE: assumes that VDP_VRAM_SPRITES is set to the address of the sprite table
; ----------------------------------------------------------------------------
setup_sprite:
    movem.l   d0-d5,-(sp)

    M_VDP_SETREG VDP_AUTOINC,2
.setup_vram_write
                             ; sprite_size = 8, each sprite has 8 bytes of data
                             ; addr = idx * sprite_size + $F000
    and.l   #$0FFF,d0        ; clear upper 16 bits
    lsl.w   #3,d0            ; d0 = index * 8
    add.w   #VDP_VRAM_SPRITES,d0        ; $F000 is where we put the VRAM sprite table
    jsr     setup_vram_write ; set up VRAM write to sprite #idx
    ; move.l  #$70000003,vdp_control   ; VDP write to VRAM address $F000
    ; FIXME: replace const with dynamic code

.write_sprite_data
; Sprite data:
; 
;     YPOS bits:  [000000YY YYYYYYYY]
;     SZL  bits:  [0000HHVV 0LLLLLLL] (sprite size, next sprite idx)
;     CFP  bits:  [pCCxyIII IIIIIIII] (priority, palette idx, xy flip, char idx)
;     XPOS bits:  [0000000X XXXXXXXX]
; 
;     > 0 is always 0
;     > X,Y is position
;     > H,V is size (in characters, size 0 means 1 character)
;     > L is link data (FIXME: explain)
;     > p is priority bit
;     > C is palette index
;     > x,y is horizontal and vertical flip
;     > I is pattern index = VRAM address / 32

.ypos
    add.w   #128,d3
    move.w  d3,VDP_DATA     ; write YPOS

.szl
    move.w  d5,d0           ; d0 = conf
    and.w   #%00001111,d0   ; d0 = 00000000 0000HHVV (sprite size)
    lsl.w   #4,d0           ; d0 = 00000000 HHVV0000 
    lsl.w   #4,d0           ; d0 = 0000HHVV 00000000 
    and.w   #$7F,d1         ; d1 = 00000000 0LLLLLLL (link idx)
    or.w    d0,d1           ; d1 = 0000HHVV 0LLLLLLL
    move.w  d1,VDP_DATA     ; write HVL

.cfp
    move.w  d5,d0                 ; d0 = 0000000p CCxyHHVV (conf)
    and.w   #%111110000,d0        ; d0 = 0000000p CCxy0000
    lsl.w   #7,d0                 ; d0 = pCCxy000 00000000
    and.w   #%0000011111111111,d4 ; d4 = 00000III IIIIIIII
    or.w    d4,d0                 ; d0 = pCCxyIII IIIIIIII
    move.w  d0,VDP_DATA           ; write CFP

.xpos
    add.w   #128,d2
    move.w  d2,VDP_DATA                 ; write Word2

    movem.l   (sp)+,d0-d5
    rts




; ----------------------------------------------------------------------------
; struct-based wrapper for setup_sprite
;
; setup_sprite_struct( spritedef (A0.L) )
;
; spritedef
;   spr_idx     (W)
;   spr_link    (W)
;   spr_x       (W)
;   spr_y       (W)
;   spr_pattern (W)
;   spr_conf    (B)
; spr_sz = sizeof(spritedef)
; 
; Example code:
;
;     lea     my_struct,a0
;     move.w  d4,spr_idx(a0)    
;     move.w  d5,spr_link(a0)   
;     move.w  d6,spr_x(a0)      
;     move.w  d6,spr_y(a0)      
;     move.w  #8,spr_pattern(a0)
;     move.w  #0,spr_conf(a0)   
;     jsr     setup_sprite_struct ; Call function
;
; ----------------------------------------------------------------------------
spr_idx     EQU 0
spr_link    EQU 2
spr_x       EQU 4
spr_y       EQU 6
spr_pattern EQU 8
spr_conf    EQU 10
spr_sz      EQU 12

setup_sprite_struct
; setup_sprite( idx (D0.w), link (D1.w), x (D2.w), y (D3.w), pattern (D4.w), conf (D5.b) )
    movem.l   d0-d5,-(sp)
    move.w    spr_idx(a0),d0
    move.w    spr_link(a0),d1
    move.w    spr_x(a0),d2
    move.w    spr_y(a0),d3
    move.w    spr_pattern(a0),d4
    move.w    spr_conf(a0),d5
	and.w     #$1ff,d5
	jsr       setup_sprite
    movem.l   (sp)+,d0-d5
    rts




; ----------------------------------------------------------------------------
; stack-based wrapper for setup_sprite
;
; setup_sprite_stk(
;   idx  (w) : sprite # (0-?)
;   link (w) : next sprite idx
;   x    (w) : pos
;   y    (w) : pos
;   conf (w) : [pCCxyHHVV]
;               p is priority bit
;               C is palette index
;               x,y is horizontal and vertical flip
;               H,V is size (in characters)
;  )
;
; Example
;
;    move.w  #0,-(a7)         ; idx
;    move.w  #1,-(a7)         ; link
;    move.w  d0,-(a7)         ; x
;    move.w  d1,-(a7)         ; y
;    move.w  #$54,-(a7)       ; pattern
;    move.w  #0,-(a7)         ; conf
;    jsr     setup_sprite_stk ; Call subroutine
;    lea     12(a7), a7       ; Clean up stack (6 * 2 bytes)
;
; NOTE: assumes that VDP_VRAM_SPRITES is set to the address of the sprite table
; ----------------------------------------------------------------------------
setup_sprite_stk
; setup_sprite( idx (D0.w), link (D1.w), x (D2.w), y (D3.w), pattern (D4.w), conf (D5.b) )
    move.w 12(a7),d0
    move.w 10(a7),d1
    move.w 8(a7),d2
    move.w 6(a7),d3
    move.w 4(a7),d4
    move.w 2(a7),d5
    and.w  #$1ff,d5
	bra    setup_sprite
    


; ----------------------------------------------------------------------------
; setup_sprite_final( idx (D0.w) )
; - idx  : sprite # (0-?)
; NOTE: assumes that VDP_VRAM_SPRITES is set to the address of the sprite table
; ----------------------------------------------------------------------------
setup_sprite_final
    move.w   #0,d1  ; link to 0
    move.w   #0,d2
    move.w   #0,d3
    move.w   #0,d4 ; any sprite will do
    move.w   #0,d5
    bra      setup_sprite


; word 0 0000 00xx xxxx xxxx  x   : x position     (10-bit)
; word 1 0000 hhvv 0lll llll  h/v : horiz/vert size (2-bit)
;                             l   : link            (6-bit)
; word 2 PppV Httt tttt tttt  P   : priority
;                             p   : color palette   (2-bit)
;                             V/H : vert/horiz flip (1-bit)
;                             t   : tile ID        (11-bit)
; word 3 0000 000y yyyy yyyy  y   : y position      (9-bit)


; ----------------------------------------------------------------------------
; word1 (D0.w) = gen_sprite_word1( link (D0.w), sizes (D1.b [.... xxyy]))
; - link  : next sprite idx (7-bit)
; - sizes : bitmask: ....xxyy , xx is horizontal size (xx = 00 : 1 sprite)
;                               yy is vertical size   (yy = 00 : 1 sprite)
; - result : 0000 xxyy 0lll llll
;
; NOTE: for manually generating a sprite table, e.g. in RAM
; ----------------------------------------------------------------------------
gen_sprite_word1
    movem.l  d1,-(sp)
    and.w    #%01111111,d0
    and.w    #$000F,d1
    lsl.w    #8,d1
    or.w     d1,d0
    movem.l  (sp)+,d1
    rts

; ----------------------------------------------------------------------------
; word2 (D0.w) = gen_sprite_word2( tile (D0.w), conf (D1.b [Pppv h000]))
; - tile  : 10-bit tile idx
; - conf  : bitmask: Pppv h000, P is Priority bit
;                               pp is palette idx
;                               vh is vertical and horizontal flip
;
; - result : Pppv httt tttt tttt
;
; NOTE: for manually generating a sprite table, e.g. in RAM
; ----------------------------------------------------------------------------
gen_sprite_word2
    movem.l  d1,-(sp)
    and.w    #%0000001111111111,d1
    lsl.w    #8,d1
    or.w     d1,d0
    movem.l  (sp)+,d1
    rts



    endif

; vim: tw=80 tabstop=4 expandtab ft=asm68k
