; path: src/seans_garage_giveaway.s
; Apple II (6502) – ca65 source
; Minimal, playable: HGR title + move player with WASD/IJKL, draws a tile.

; --- hardware ---
KBD      = $C000
KBDSTRB  = $C010
TXTCLR   = $C050
HIRES    = $C057
PAGE2CLR = $C055
MIXCLR   = $C052
HOME     = $FC58
COUT     = $FDED
HGR1     = $2000

; ---------- segments ----------
.segment "ZEROPAGE"
ZP_PTRL:   .res 1
ZP_PTRH:   .res 1
ZP_TMP:    .res 1
PL_X:      .res 1
PL_Y:      .res 1

.segment "RODATA"
TLINE1: .asciiz "SEAN'S GARAGE GIVEAWAY"
TLINE2: .asciiz "WASD or IJKL to move"
TLINE3: .asciiz "Press any key to start"

; 12 coarse HGR row top addresses (y=0,16,32,...,176)
ROW_LO: .byte <($2000),<($2050),<($20A0),<($20F0),<($2A00),<($2A50),<($2AA0),<($2AF0),<($3400),<($3450),<($34A0),<($34F0)
ROW_HI: .byte >($2000),>($2050),>($20A0),>($20F0),>($2A00),>($2A50),>($2AA0),>($2AF0),>($3400),>($3450),>($34A0),>($34F0)

.segment "CODE"

; entry at $0800 via linker cfg
START:
        jsr INIT
        jsr SHOW_TITLE
        jsr WAITKEY
        jsr INIT_GAME
MAIN:
        jsr INPUT
        jsr RENDER
        jmp MAIN

; ---- video init ----
INIT:   bit TXTCLR      ; graphics on
        bit HIRES       ; HGR
        bit PAGE2CLR    ; page1
        bit MIXCLR      ; mixed
        jsr CLRHGR
        jsr HOME
        rts

; ---- clear HGR page1 (8KB) ----
CLRHGR: lda #<HGR1
        sta ZP_PTRL
        lda #>HGR1
        sta ZP_PTRH
        lda #$00
        ldx #$00
        ldy #$20
@L:     sta (ZP_PTRL),y
        iny
        bne @L
        inc ZP_PTRH
        inx
        cpx #$20
        bne @L
        rts

; ---- title text ----
SHOW_TITLE:
        jsr CLRHGR
        jsr HOME
        ldx #$00
@t1:    lda TLINE1,x
        beq @nl1
        jsr COUT
        inx
        bne @t1
@nl1:   lda #$8D
        jsr COUT
        ldx #$00
@t2:    lda TLINE2,x
        beq @nl2
        jsr COUT
        inx
        bne @t2
@nl2:   lda #$8D
        jsr COUT
        ldx #$00
@t3:    lda TLINE3,x
        beq @done
        jsr COUT
        inx
        bne @t3
@done:  rts

; ---- keyboard ----
GETKEY: lda KBD
        bpl @z
        lda KBD
        bit KBDSTRB
        and #$7F
        rts
@z:     lda #$00
        rts

WAITKEY:
        jsr GETKEY
        beq WAITKEY
        rts

; ---- game state ----
INIT_GAME:
        lda #6
        sta PL_X
        sta PL_Y
        rts

; ---- input: WASD or IJKL ----
INPUT:  jsr GETKEY
        beq @done
        cmp #'W'        ; up
        beq @u
        cmp #'I'
        beq @u
        cmp #'S'        ; down
        beq @d
        cmp #'K'
        beq @d
        cmp #'A'        ; left
        beq @l
        cmp #'J'
        beq @l
        cmp #'D'        ; right
        beq @r
        cmp #'L'
        beq @r
        rts
@u:     lda PL_Y
        beq @done
        dec PL_Y
        rts
@d:     lda PL_Y
        cmp #11
        beq @done
        inc PL_Y
        rts
@l:     lda PL_X
        beq @done
        dec PL_X
        rts
@r:     lda PL_X
        cmp #13
        beq @done
        inc PL_X
        rts
@done:  rts

; ---- render: clear + draw player tile ----
RENDER: jsr CLRHGR
        lda PL_X
        ldx PL_Y
        jsr DRAW_PLAYER
        rts

; draw solid 2 bytes x 8 scanlines at (A=x, X=row [0..11])
DRAW_PLAYER:
        sta ZP_TMP              ; x (tile)
        txa                     ; y idx
        tax
        lda ROW_LO,x
        sta ZP_PTRL
        lda ROW_HI,x
        sta ZP_PTRH

        ldx ZP_TMP              ; x
        txa
        asl a                   ; x*2
        clc
        adc ZP_PTRL
        sta ZP_PTRL
        bcc @ok
        inc ZP_PTRH
@ok:    ldy #$00
        lda #$7F
@ln:    sta (ZP_PTRL),y
        iny
        sta (ZP_PTRL),y
        ; next scanline (+$80)
        lda ZP_PTRL
        clc
        adc #$80
        sta ZP_PTRL
        bcc @nc
        inc ZP_PTRH
@nc:    ldy #$00
        inc ZP_TMP
        lda ZP_TMP
        cmp #8
        bcc @ln
        lda #$00
        sta ZP_TMP
        rts
