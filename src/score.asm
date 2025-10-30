; score.asm - Sistema de puntuación (OAM)

SECTION "Score Data", WRAM0
score_unidades:  ds 1      ; dígito 0..9
score_decenas:   ds 1      ; dígito 0..9
score_centenas:  ds 1      ; dígito 0..9
score_millares:  ds 1      ; dígito 0..9

SECTION "Score Code", ROM0

DEF TILE_0 EQU $30          ; primer tile de los números (0 en OBJ)

; OAM base y sprites usados para el marcador
DEF OAM_BASE       EQU $FE00
DEF INICIO_OAM EQU 0  ; índice de sprite inicial (usa 4 seguidos)
                            ; ojo: no debe pisar otros sprites del juego

; posición en pantalla del marcador (cuatro dígitos en línea)
DEF SCORE_OAM_Y    EQU 16
DEF SCORE_OAM_X0   EQU 136  ; millares
DEF SCORE_OAM_X1   EQU 144  ; centenas
DEF SCORE_OAM_X2   EQU 152  ; decenas
DEF SCORE_OAM_X3   EQU 160  ; unidades
DEF SCORE_ATTR     EQU $10  ; atributos de OAM (paleta por defecto)

apuntaOAM:
    ; HL = OAM_BASE + A*4 (cada sprite ocupa 4 bytes)
    ld   hl, OAM_BASE
    add  a, a
    add  a, a
    ld   b, 0
    ld   c, a
    add  hl, bc
    ret
play_point_sound:
    push af
    ld   a, %10000000  ; $FF11: Duración (corta) y patrón de onda (12.5%)
    ld   [$FF11], a
    ld   a, %11110011  ; $FF12: Envolvente de volumen (empieza alto, sube, rápido)
    ld   [$FF12], a
    ld   a, $00        ; $FF13: Frecuencia (bits bajos)
    ld   [$FF13], a
    ld   a, %10000110  ; $FF14: Frecuencia (bits altos) y Trigger (bit 7)
    ld   [$FF14], a
    pop  af
    ret

init_score:
    ; pone la puntuación a 0000 y la dibuja
    ; llama a esto al inicio y tras reset
    xor  a
    ld  [score_unidades], a
    ld  [score_decenas],  a
    ld  [score_centenas], a
    ld  [score_millares], a
    call draw_score_oam
    ret

add_score:
    ; límite superior 9999 (se queda en 9999)
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
    call play_point_sound 
    cp   10
    jr   c, .centenas_ok
    xor  a
    ld  [score_centenas], a

    ; millares++ (tope en 9)
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

get_score_total:
    ; devuelve HL = puntuación (0..9999) a partir de los cuatro dígitos
    ld   hl, 0

    ; millares * 1000
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
    ; centenas * 100
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
    ; decenas * 10
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
    ; + unidades
    ld   a, [score_unidades]
    ld   e, a
    ld   d, 0
    add  hl, de
    ret

draw_score_oam:
    ; Dibujar marcador (4 dígitos) en OAM. Se hace en VBlank para evitar parpadeo.
    call wait_vblank

    ;  Millares (sprite 0) 
    ld   a, INICIO_OAM
    call apuntaOAM          ; HL -> entrada de OAM del sprite 0
    ld   a, SCORE_OAM_Y               ; fila fija del HUD
    ld  [hl+], a
    ld   a, SCORE_OAM_X0              ; columna del dígito de millares
    ld  [hl+], a
    ld   a, [score_millares]          ; 0..9
    add  a, TILE_0                    ; convierte dígito a tile
    ld  [hl+], a
    ld   a, SCORE_ATTR                ; paleta/atributos
    ld  [hl], a

    ;  Centenas (sprite 1) 
    ld   a, INICIO_OAM+1
    call apuntaOAM
    ld   a, SCORE_OAM_Y
    ld  [hl+], a
    ld   a, SCORE_OAM_X1              ; posición X para centenas
    ld  [hl+], a
    ld   a, [score_centenas]
    add  a, TILE_0
    ld  [hl+], a
    ld   a, SCORE_ATTR
    ld  [hl], a

    ; Decenas (sprite 2) 
    ld   a, INICIO_OAM+2
    call apuntaOAM
    ld   a, SCORE_OAM_Y
    ld  [hl+], a
    ld   a, SCORE_OAM_X2              ; posición X para decenas
    ld  [hl+], a
    ld   a, [score_decenas]
    add  a, TILE_0
    ld  [hl+], a
    ld   a, SCORE_ATTR
    ld  [hl], a

    ;  Unidades (sprite 3) 
    ld   a, INICIO_OAM+3
    call apuntaOAM
    ld   a, SCORE_OAM_Y
    ld  [hl+], a
    ld   a, SCORE_OAM_X3              ; posición X para unidades
    ld  [hl+], a
    ld   a, [score_unidades]
    add  a, TILE_0
    ld  [hl+], a
    ld   a, SCORE_ATTR
    ld  [hl], a

    ret
