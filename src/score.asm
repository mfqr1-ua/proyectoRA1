; score.asm - Sistema de puntuación

SECTION "Score Data", WRAM0
score_unidades:  ds 1    ; Dígito de unidades
score_decenas:   ds 1    ; Dígito de decenas
score_centenas:  ds 1    ; Dígito de centenas
score_millares:  ds 1    ; Dígito de millares

SECTION "Score Code", ROM0

; Tiles numéricos (asumiendo que están en tiles $30-$39 = '0'-'9')
DEF TILE_0 EQU $30
DEF TILE_1 EQU $31
DEF TILE_2 EQU $32
DEF TILE_3 EQU $33
DEF TILE_4 EQU $34
DEF TILE_5 EQU $35
DEF TILE_6 EQU $36
DEF TILE_7 EQU $37
DEF TILE_8 EQU $38
DEF TILE_9 EQU $39

; Posición del marcador en pantalla (arriba derecha)
DEF SCORE_X EQU 15
DEF SCORE_Y EQU 0

; ------------------------------------------------------------
; init_score: Inicializar puntuación a 0
; ------------------------------------------------------------
init_score:
    xor  a
    ld  [score_unidades], a
    ld  [score_decenas], a
    ld  [score_centenas], a
    ld  [score_millares], a
    
    ; Dibujar marcador inicial
    call draw_score
    ret

; ------------------------------------------------------------
; add_score: Añadir puntos al marcador
; A = puntos a añadir (típicamente 10)
; ------------------------------------------------------------
add_score:
    ld   b, a                    ; Guardar puntos en B
    
.sumar_loop:
    ld   a, b
    or   a
    jr   z, .actualizar_display  ; Si B=0, terminar
    
    ; Incrementar unidades
    ld   a, [score_unidades]
    inc  a
    cp   10
    jr   c, .unidades_ok
    
    ; Carry a decenas
    xor  a
    ld  [score_unidades], a
    
    ld   a, [score_decenas]
    inc  a
    cp   10
    jr   c, .decenas_ok
    
    ; Carry a centenas
    xor  a
    ld  [score_decenas], a
    
    ld   a, [score_centenas]
    inc  a
    cp   10
    jr   c, .centenas_ok
    
    ; Carry a millares
    xor  a
    ld  [score_centenas], a
    
    ld   a, [score_millares]
    inc  a
    cp   10
    jr   c, .millares_ok
    
    ; Overflow (máximo 9999)
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
    call draw_score
    ret

; ------------------------------------------------------------
; draw_score: Dibujar marcador en pantalla
; Dibuja 4 dígitos en posición (SCORE_X, SCORE_Y)
; ------------------------------------------------------------
draw_score:
    ; Dibujar millares
    ld   e, SCORE_X
    ld   d, SCORE_Y
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    
    ld   a, [score_millares]
    add  a, TILE_0
    ld  [hl+], a
    
    ; Dibujar centenas
    ld   a, [score_centenas]
    add  a, TILE_0
    ld  [hl+], a
    
    ; Dibujar decenas
    ld   a, [score_decenas]
    add  a, TILE_0
    ld  [hl+], a
    
    ; Dibujar unidades
    ld   a, [score_unidades]
    add  a, TILE_0
    ld  [hl], a
    
    ret
