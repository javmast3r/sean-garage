; path: src/seans_garage_giveaway.s
; Apple II (6502) – Merlin 8/16 source
; Simple playable build: HGR, title text, move the player (WASD / IJKL).
; You can expand later.

KBD       EQU   $C000
KBDSTRB   EQU   $C010
TXTSET    EQU   $C051
TXTCLR    EQU   $C050
MIXSET    EQU   $C053
MIXCLR    EQU   $C052
HIRES     EQU   $C057
PAGE2CLR  EQU   $C055
HOME      EQU   $FC58
COUT      EQU   $FDED

HGR1      EQU   $2000

; --- zero page ---
        ORG   $00
ZP_PTRL  RMB   1
ZP_PTRH  RMB   1
ZP_TMP   RMB   1
PL_X     RMB   1
PL_Y     RMB   1

; --- code ---
        ORG   $0800

START   JSR   INIT
TITLE   JSR   SHOW_TITLE
        JSR   WAITKEY

NEW     JSR   INIT_GAME

MAINLP  JSR   INPUT
        JSR   RENDER
        JMP   MAINLP

; ---- init video ----
INIT    BIT   TXTCLR       ; graphics on
        BIT   HIRES        ; hires mode
        BIT   PAGE2CLR     ; page1
        BIT   MIXCLR       ; mixed text+graphics
        JSR   CLRHGR
        JSR   HOME
        RTS

; ---- clear HGR page1 (8KB) ----
CLRHGR  LDA   #<HGR1
        STA   ZP_PTRL
        LDA   #>HGR1
        STA   ZP_PTRH
        LDA   #0
        LDX   #0
        LDY   #$20
CL0     STA   (ZP_PTRL),Y
        INY
        BNE   CL0
        INC   ZP_PTRH
        INX
        CPX   #$20
        BNE   CL0
        RTS

; ---- title text ----
SHOW_TITLE
        JSR   CLRHGR
        JSR   HOME
        LDX   #0
T1      LDA   TLINE1,X
        BEQ   T2
        JSR   COUT
        INX
        BNE   T1
T2      LDA   #$8D
        JSR   COUT
        LDX   #0
T3      LDA   TLINE2,X
        BEQ   T4
        JSR   COUT
        INX
        BNE   T3
T4      LDA   #$8D
        JSR   COUT
        LDX   #0
T5      LDA   TLINE3,X
        BEQ   TDONE
        JSR   COUT
        INX
        BNE   T5
TDONE   RTS

; ---- non-blocking GETKEY: A=0 if none ----
GETKEY  LDA   KBD
        BPL   GK0
        LDA   KBD
        BIT   KBDSTRB
        AND   #$7F
        RTS
GK0     LDA   #0
        RTS

WAITKEY JSR   GETKEY
        BEQ   WAITKEY
        RTS

; ---- game state ----
INIT_GAME
        LDA   #6
        STA   PL_X
        STA   PL_Y
        RTS

; ---- input: WASD or IJKL ----
INPUT   JSR   GETKEY
        BEQ   IN_D
        CMP   #'W'
        BEQ   IN_U
        CMP   #'I'
        BEQ   IN_U
        CMP   #'S'
        BEQ   IN_DN
        CMP   #'K'
        BEQ   IN_DN
        CMP   #'A'
        BEQ   IN_L
        CMP   #'J'
        BEQ   IN_L
        CMP   #'D'
        BEQ   IN_R
        CMP   #'L'
        BEQ   IN_R
        RTS
IN_U    LDA   PL_Y
        BEQ   IN_D
        DEC   PL_Y
        RTS
IN_DN   LDA   PL_Y
        CMP   #11
        BEQ   IN_D
        INC   PL_Y
        RTS
IN_L    LDA   PL_X
        BEQ   IN_D
        DEC   PL_X
        RTS
IN_R    LDA   PL_X
        CMP   #13
        BEQ   IN_D
        INC   PL_X
        RTS
IN_D    RTS

; ---- render: clear + draw player tile ----
RENDER  JSR   CLRHGR
        LDA   PL_X
        LDX   PL_Y
        JSR   DRAW_PLAYER
        RTS

; ---- draw one 2-byte-wide, 8-scanline tile at (A=x, X=y) ----
; uses precomputed top-scanline addresses for rows 0..11 (every 16th line)
DRAW_PLAYER
        STA   ZP_TMP         ; x
        TXA
        PHA                  ; save y index on stack
        TAX
        LDA   ROW_LO,X
        STA   ZP_PTRL
        LDA   ROW_HI,X
        STA   ZP_PTRH
        PLA                  ; restore y (unused now)

        LDX   ZP_TMP         ; x
        TXA
        ASL   A              ; x*2 bytes
        CLC
        ADC   ZP_PTRL
        STA   ZP_PTRL
        BCC   DP0
        INC   ZP_PTRH
DP0     LDY   #0
        LDA   #$7F           ; solid byte
DP_LN   STA   (ZP_PTRL),Y
        INY
        STA   (ZP_PTRL),Y
        ; next scanline (+$80)
        LDA   ZP_PTRL
        CLC
        ADC   #$80
        STA   ZP_PTRL
        BCC   DP_NC
        INC   ZP_PTRH
DP_NC   LDY   #0
        INC   ZP_TMP
        LDA   ZP_TMP
        CMP   #8
        BCC   DP_LN
        LDA   #0
        STA   ZP_TMP
        RTS

; ---- title strings ----
TLINE1  ASC   "SEAN'S GARAGE GIVEAWAY",00
TLINE2  ASC   "WASD or IJKL to move",00
TLINE3  ASC   "Press any key to start",00

; ---- HGR top-line addresses for 12 rows (y=0,16,32,...,176) ----
ROW_LO  DFB   <($2000),<($2050),<($20A0),<($20F0),<($2A00),<($2A50),<($2AA0),<($2AF0),<($3400),<($3450),<($34A0),<($34F0)
ROW_HI  DFB   >($2000),>($2050),>($20A0),>($20F0),>($2A00),>($2A50),>($2AA0),>($2AF0),>($3400),>($3450),>($34A0),>($34F0)

        END   START
