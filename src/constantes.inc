
; ===== constantes.inc ===============================================

; --- I/O regs principales ---
DEF rP1     EQU $FF00    ; Joypad
DEF rLCDC   EQU $FF40    ; LCD Control
DEF rLY     EQU $FF44    ; Current scanline (LY)
DEF rBGP    EQU $FF47    ; BG palette
DEF rOBP0   EQU $FF48    ; OBJ palette 0
DEF rOBP1   EQU $FF49    ; OBJ palette 1

; --- Selección de líneas del joypad (bits 5 y 4) ---
DEF P1_SELECT_DPAD    EQU $20    ; seleccionar cruceta
DEF P1_SELECT_BUTTONS EQU $10    ; seleccionar A/B/Start/Select

; --- Pantalla / timings ---
DEF VBLANK_LINE       EQU 144    ; a partir de esta LY estamos en VBlank

; --- OAM / sprites ---
DEF OAM_BASE          EQU $FE00
DEF OAM_BYTES_TOTAL   EQU 160
DEF OAM_STRIDE        EQU 4      ; bytes por sprite

; --- BG map / VRAM ---
DEF BG_MAP0           EQU $9800  ; tilemap 0
DEF BG_MAP1           EQU $9C00  ; tilemap 1
DEF BG_ROW_STRIDE     EQU 32     ; tiles por fila en BG
DEF TILE_BYTES        EQU 16     ; bytes por tile (2bpp)

; atajo usado en bloques 3x2: bajar 1 fila (32) y volver 2 = +30
DEF BG_NEXTROW_MINUS2 EQU 30

; --- RAM del jugador (slot 0 en tu layout) ---
DEF SLOT0_X           EQU $C000
DEF SLOT0_Y           EQU $C001
DEF SLOT0_BASE        EQU $C002


DEF SPR_X_OFF    = 0
DEF SPR_Y_OFF    = 1
DEF SPR_TILE_OFF = 2
DEF SPR_ATT_OFF  = 3


