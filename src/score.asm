; score.asm - Sistema de puntuación (OAM)

SECTION "Score Data", WRAM0
score_unidades:  ds 1
score_decenas:   ds 1
score_centenas:  ds 1
score_millares:  ds 1

SECTION "Score Code", ROM0

; Tiles numéricos (0..9 en OBJ $30..$39)
DEF TILE_0 EQU $30

; --- OAM constants ---
DEF OAM_BASE       EQU $FE00
; Sprites a usar para el HUD (0..3)
DEF SCORE_SPR_BASE EQU 100

; Coordenadas OAM que cubren BG $9810..$9813
; $9810=(x=16,y=0) -> Y_oam=16, X_oam=136
DEF SCORE_OAM_Y    EQU 16
DEF SCORE_OAM_X0   EQU 136   ; $9810 (millares)
DEF SCORE_OAM_X1   EQU 144   ; $9811 (centenas)
DEF SCORE_OAM_X2   EQU 152   ; $9812 (decenas)
DEF SCORE_OAM_X3   EQU 160   ; $9813 (unidades)
DEF SCORE_ATTR     EQU $10   ; paleta 0, sin flips

; ------------------------------------------------------------
; Helper: HL = $FE00 + A*4  (A = índice de sprite)
; ------------------------------------------------------------
oam_addr_from_index:
    ld   hl, OAM_BASE
    add  a, a          ; *2
    add  a, a          ; *4
    ld   b, 0
    ld   c, a
    add  hl, bc
    ret

; ------------------------------------------------------------
; init_score
; ------------------------------------------------------------
init_score:
    xor  a
    ld  [score_unidades], a
    ld  [score_decenas],  a
    ld  [score_centenas], a
    ld  [score_millares], a
    call draw_score_oam
    ret

; ------------------------------------------------------------
; add_score: A = puntos a sumar (0..255)
; ------------------------------------------------------------
add_score:
    ld   b, a
.sumar_loop:
    ld   a, b
    or   a
    jr   z, .actualizar_display

    ; unidades++
    ld   a, [score_unidades]
    inc  a
    cp   10
    jr   c, .unidades_ok
    xor  a
    ld  [score_unidades], a

    ; decenas++
    ld   a, [score_decenas]
    inc  a
    cp   10
    jr   c, .decenas_ok
    xor  a
    ld  [score_decenas], a

    ; centenas++
    ld   a, [score_centenas]
    inc  a
    cp   10
    jr   c, .centenas_ok
    xor  a
    ld  [score_centenas], a

    ; millares++
    ld   a, [score_millares]
    inc  a
    cp   10
    jr   c, .millares_ok
    ld   a, 9
.millares_ok:
    ld  [score_millares], a
    jr   .continuar

.centenas_ok:
    ld  [score_centenas], a
    jr   .continuar

.decenas_ok:
    ld  [score_decenas], a
    jr   .continuar

.unidades_ok:
    ld  [score_unidades], a

.continuar:
    dec  b
    jr   .sumar_loop

.actualizar_display:
    call draw_score_oam
    ret

; ------------------------------------------------------------
; get_score_total: Obtener puntuación total
; Retorna en HL la puntuación total (máximo 9999)
; ------------------------------------------------------------
get_score_total:
    ; Calcular: millares*1000 + centenas*100 + decenas*10 + unidades
    ld   hl, 0
    
    ; Millares × 1000
    ld   a, [score_millares]
    or   a
    jr   z, .centenas
    ld   b, a
.loop_millares:
    ld   de, 1000
    add  hl, de
    dec  b
    jr   nz, .loop_millares
    
.centenas:
    ; Centenas × 100
    ld   a, [score_centenas]
    or   a
    jr   z, .decenas
    ld   b, a
.loop_centenas:
    ld   de, 100
    add  hl, de
    dec  b
    jr   nz, .loop_centenas
    
.decenas:
    ; Decenas × 10
    ld   a, [score_decenas]
    or   a
    jr   z, .unidades
    ld   b, a
.loop_decenas:
    ld   de, 10
    add  hl, de
    dec  b
    jr   nz, .loop_decenas
    
.unidades:
    ; Unidades
    ld   a, [score_unidades]
    ld   e, a
    ld   d, 0
    add  hl, de
    
    ret

; ------------------------------------------------------------
; draw_score_oam: pinta 4 sprites (M C D U) en OAM 0..3
; Escribe OAM durante VBlank
; ------------------------------------------------------------
draw_score_oam:
    call wait_vblank

    ; --- millares -> sprite 0 ---
    ld   a, SCORE_SPR_BASE        ; 0
    call oam_addr_from_index      ; HL = FE00
    ld   a, SCORE_OAM_Y           ; Y
    ld  [hl+], a
    ld   a, SCORE_OAM_X0          ; X
    ld  [hl+], a
    ld   a, [score_millares]      ; TILE
    add  a, TILE_0
    ld  [hl+], a
    ld   a, SCORE_ATTR            ; ATTR
    ld  [hl], a

    ; --- centenas -> sprite 1 ---
    ld   a, SCORE_SPR_BASE+1
    call oam_addr_from_index
    ld   a, SCORE_OAM_Y
    ld  [hl+], a
    ld   a, SCORE_OAM_X1
    ld  [hl+], a
    ld   a, [score_centenas]
    add  a, TILE_0
    ld  [hl+], a
    ld   a, SCORE_ATTR
    ld  [hl], a

    ; --- decenas -> sprite 2 ---
    ld   a, SCORE_SPR_BASE+2
    call oam_addr_from_index
    ld   a, SCORE_OAM_Y
    ld  [hl+], a
    ld   a, SCORE_OAM_X2
    ld  [hl+], a
    ld   a, [score_decenas]
    add  a, TILE_0
    ld  [hl+], a
    ld   a, SCORE_ATTR
    ld  [hl], a

    ; --- unidades -> sprite 3 ---
    ld   a, SCORE_SPR_BASE+3
    call oam_addr_from_index
    ld   a, SCORE_OAM_Y
    ld  [hl+], a
    ld   a, SCORE_OAM_X3
    ld  [hl+], a
    ld   a, [score_unidades]
    add  a, TILE_0
    ld  [hl+], a
    ld   a, SCORE_ATTR
    ld  [hl], a

    ret
