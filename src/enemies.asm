; enemies.asm - 3 enemigos, cada uno 3x2 tiles

SECTION "Enemies Data", WRAM0
enemy1_x: ds 1
enemy1_y: ds 1
enemy2_x: ds 1
enemy2_y: ds 1
enemy3_x: ds 1
enemy3_y: ds 1

SECTION "Enemies Code", ROM0

; Orden exacto solicitado:
DEF ENEMY_TL EQU $1A    ; top-left
DEF ENEMY_TM EQU $1C    ; top-middle
DEF ENEMY_TR EQU $1E    ; top-right
DEF ENEMY_BL EQU $1B    ; bottom-left
DEF ENEMY_BM EQU $1D    ; bottom-middle
DEF ENEMY_BR EQU $1F    ; bottom-right

; ------------------------------------------------------------
; pintar_enemigo_3x2
; E = x (tile), D = y (tile)
; Dibuja el bloque 3x2 con el orden:
;   1A 1C 1E
;   1B 1D 1F
; Espera a VBlank antes de cada fila para asegurar VRAM write.
; ------------------------------------------------------------
pintar_enemigo_3x2:
    ; ------- fila superior -------
    push de
    call wait_vblank
    call calcular_direccion_bg_desde_xy
    ld   a, ENEMY_TL
    ld   [hl], a
    inc  hl
    ld   a, ENEMY_TM
    ld   [hl], a
    inc  hl
    ld   a, ENEMY_TR
    ld   [hl], a
    pop  de

    ; ------- fila inferior (y+1) -------
    inc  d                    ; y = y + 1
    push de
    call wait_vblank
    call calcular_direccion_bg_desde_xy
    ld   a, ENEMY_BL
    ld   [hl], a
    inc  hl
    ld   a, ENEMY_BM
    ld   [hl], a
    inc  hl
    ld   a, ENEMY_BR
    ld   [hl], a
    pop  de
    ret

; ------------------------------------------------------------
; ecs_init_enemies
; Coloca y dibuja 3 enemigos en la fila superior
; Izquierda (x=1), Centro (x=9), Derecha (x=17), todos en y=2
; ------------------------------------------------------------
; ------------------------------------------------------------
; ecs_init_enemies (enemigos más juntos)
; Izquierda x=6, Centro x=9, Derecha x=12, todos y=2
; ------------------------------------------------------------
ecs_init_enemies:
    ; izquierda (pegada al centro por la izquierda)
    ld   a, 6
    ld  [enemy1_x], a
    ld   a, 2
    ld  [enemy1_y], a

    ; centro
    ld   a, 9
    ld  [enemy2_x], a
    ld   a, 2
    ld  [enemy2_y], a

    ; derecha (pegada al centro por la derecha)
    ld   a, 12
    ld  [enemy3_x], a
    ld   a, 2
    ld  [enemy3_y], a

    ; dibujar 1
    ld   a, [enemy1_x]
    ld   e, a
    ld   a, [enemy1_y]
    ld   d, a
    call pintar_enemigo_3x2

    ; dibujar 2
    ld   a, [enemy2_x]
    ld   e, a
    ld   a, [enemy2_y]
    ld   d, a
    call pintar_enemigo_3x2

    ; dibujar 3
    ld   a, [enemy3_x]
    ld   e, a
    ld   a, [enemy3_y]
    ld   d, a
    call pintar_enemigo_3x2

    ret
