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

; Configure this in your code
; MANDELBROT_ADDR = $E0FF00 ; 12 B

; Memory Map
norm_bits         = (MANDELBROT_ADDR+0)
norm_fact         = (MANDELBROT_ADDR+4)

; cpp_reference/mandel.cpp
;
;   int main()
;   {
;     const char aa[] = " .,:+*#%$";
;     char line[81];
;   
;     for (INT y = 0; y < HEIGHT; ++y)
;     {
;         for (INT x = 0; x < WIDTH; ++x)
;         {
;             INT mx = x-(WIDTH/2)-20;
;             INT my = y-(HEIGHT/2);
;             INT iteration_count = iterate(mx, my);
;             line[x] = aa[iteration_count];
;         }
;         line[WIDTH] = 0;
;         puts(line);
;     }
;     int c = getchar();
;   }


; Render Mandelbrot set to framebuffer address in a0
; a0: framebuffer ptr
; d0: offset x
; d1: offset y
; d2: zoom
; d3: screen y
; returns: updated a0
mandelbrot
    movem.l d0-d7/a1-a6,-(sp) ; push all registers to stack

; for each pixel (d6, d7) = (Px, Py) on the screen do

    move.w  d3,d7
    move.w  d0,d3
    move.w  d1,d4

; We have 32 x 28 chars
; Each char is 8x8 pixels
    ;move.w  #200-1,d7 ; d7: y
;next_row

    move.w  #128-1,d6 ; d6: x
next_2pixels

    ; pixel 1
    move.w  d6,d0       ; INT mx = x-(WIDTH/2)-20;
    asl.w   #1,d0
    sub.w   #148,d0
    move.w  d7,d1       ; INT my = y-(HEIGHT/2);
    sub.w   #100,d1
    add.w   d3,d0
    add.w   d4,d1
    jsr     iterate
    and.b   #$F,d0
    lsl.b   #4,d0
    move.b  d0,d5

    ; pixel 2
    move.w  d6,d0       ; INT mx = x-(WIDTH/2)-20;
    asl.w   #1,d0
    sub.w   #149,d0
    move.w  d7,d1       ; INT my = y-(HEIGHT/2);
    sub.w   #100,d1
    add.w   d3,d0
    add.w   d4,d1
    jsr     iterate
    and.b   #$F,d0
    or.b    d0,d5
    
    ;and.b   #$FF,d5
    move.b  d5,(a0)     ; writing bytes to odd addresses is OK (but not words)
    add.l   #1,a0       ; next char


    dbra    d6,next_2pixels

    ;dbra    d7,next_row

    movem.l (sp)+,d0-d7/a1-a6 ; push all registers to stack
    rts


; d0: real0
; d1: imag0
; d2: zoom
; d0: return color (0-15)
;
; cpp_reference/mandel.cpp:
;
;   const int MAX_ITER = 8;
;   
;   // Based on integer Mandelbrot by Bernhard Fischer
;   // https://www.cypherpunk.at/2015/10/calculating-fractals-with-integer-operations/
;   //
;   int iterate(int real0, int imag0)
;   {
;     const int NORM_BITS = 4;
;     const int NORM_FACT = 1 << NORM_BITS;
;   
;     int realq, imagq, real, imag;
;     int i;
;    
;     real = real0;
;     imag = imag0;
;     for (i = 0; i < MAX_ITER; i++)
;     {
;       realq = (real * real) >> NORM_BITS;
;       imagq = (imag * imag) >> NORM_BITS;
;    
;       if ((realq + imagq) > 4 * NORM_FACT)
;         break;
;    
;       imag = ((real * imag) >> (NORM_BITS - 1)) + imag0;
;       real = realq - imagq + real0;
;     }
;     return i;
;   }
; 
; We use a global memory as work RAM to make this as fast as possible
; MAX_ITER = 31 ; wrap around palette, render slower
; NORM_BITS = 6 ; ZOOM
; NORM_BITS = 7
; NORM_FACT = (1<<NORM_BITS)

MAX_ITER = 31 ; color values between 0 and 15

iterate
    movem.l d1-d7/a0-a1,-(sp)   ; push all registers to stack


    ; set up RAM state
    move.w  d2,(norm_bits)           ; NORM_BITS
    sub.w   #1,d2
    
    move.w  #8,d3                    ; 4 * (1<<NORM_BITS)
    asl.w   d2,d3
    move.w  d3,(norm_fact)


    ; REGISTERS

    clr.l   d2          ; d2: realq
    clr.l   d3          ; d3: imagq
    clr.l   d4          ; d4: real
    clr.l   d5          ; d5: imag

                        ; d7: iteration #
                        ; d0: temp

    move.w  d0,d4       ; real = real0
    move.w  d1,d5       ; imag = imag0

    move.w  d0,a0       ; a0: real0 (abusing address register as data)
    move.w  d1,a1       ; a1: imag0 (abusing address register as data)

    move.w  (norm_bits),d6 ; d6: NORM_BITS
    move.w  (norm_fact),d1 ; d1: NORM_FACT

    move.l  #MAX_ITER-1,d7    ; MAX_ITER
.next
    move.w  d4,d2       ; realq = (real * real) >> NORM_BITS
    muls.w  d4,d2
    asr.l   d6,d2

    move.w  d5,d3       ; imagq = (imag * imag) >> NORM_BITS
    muls.w  d5,d3
    asr.l   d6,d3

    move.w  d2,d0       ; if ((realq + imagq) > 4 * NORM_FACT)
    add.w   d3,d0       ;   break;
    cmp.w   d1,d0
    bgt     done

    muls.w  d4,d5       ; imag = ((real * imag) >> (NORM_BITS - 1)) + imag0;
    move.w  d6,d0
    sub.w   #1,d0
    asr.l   d0,d5
    add.w   a1,d5
                 
    move.w  d2,d4       ; real = realq - imagq + real0;
    sub.w   d3,d4
    add.w   a0,d4

    dbra    d7,.next
done

    add.l   #1,d7
    and.w   #$F,d7
    move.w  #16,d0
    sub.w   d7,d0

    movem.l (sp)+,d1-d7/a0-a1 ; push all registers to stack
    rts



; vim: tw=80 tabstop=4 expandtab ft=asm68k fdm=marker
