; collisions.asm - Sistema de colisiones entre balas y enemigos

SECTION "Collisions Code", ROM0

; Constante importada de enemies.asm
DEF ATTR_ENEMIGO EQU $01

; ------------------------------------------------------------
; revisar_colisiones_balas_enemigos
; Revisa todas las balas del jugador (slots 4-39) contra todos los enemigos
; ------------------------------------------------------------
revisar_colisiones_balas_enemigos:
    ld   c, 4                    ; Primer slot de balas
.loop_balas:
    ld   a, c
    cp   40
    ret  z                       ; Llegó al final de las balas
    
    ; Verificar si el slot tiene una bala activa
    ld   h, $C0
    ld   l, c
    
    ; Verificar ATTR primero para saber si es bala o enemigo
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    pop  hl
    cp   ATTR_ENEMIGO
    jr   z, .next_bala           ; Es enemigo, no bala
    
    ; Ahora verificar si está activa
    ld   a, [hl]                 ; Leer X de la bala
    or   a
    jr   z, .next_bala           ; Slot vacío
    
    ; Tenemos una bala activa, guardar posición
    ld   e, a                    ; E = bala_x
    inc  hl
    ld   a, [hl]
    ld   d, a                    ; D = bala_y
    dec  hl
    
    ; E = bala_x, D = bala_y, C = slot de bala
    push bc
    push de
    call check_bala_vs_all_enemies
    pop  de
    pop  bc
    
.next_bala:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .loop_balas

; ------------------------------------------------------------
; check_bala_vs_all_enemies
; E = bala_x, D = bala_y, C = slot de bala
; ------------------------------------------------------------
check_bala_vs_all_enemies:
    ld   b, 4                    ; Primer slot de enemigos
.loop_enemies:
    ld   a, b
    cp   40
    ret  z                       ; No más enemigos
    
    ; Verificar si es enemigo
    ld   h, $C0
    ld   l, b
    
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    pop  hl
    cp   ATTR_ENEMIGO
    jr   nz, .next_enemy
    
    ; Es enemigo, verificar si está activo
    ld   a, [hl]
    or   a
    jr   z, .next_enemy
    
    ; Enemigo activo, leer posición
    push bc
    push de
    
    ld   a, [hl+]                ; enemy_x
    ld   h, a
    ld   a, [hl]                 ; enemy_y
    ld   l, a
    
    ; H = enemy_x, L = enemy_y
    ; D = bala_y, E = bala_x (en stack)
    
    pop  de                      ; E = bala_x, D = bala_y
    
    ; Verificar colisión simple: bala_x == enemy_x ± 2 && bala_y == enemy_y ± 2
    ld   a, e                    ; bala_x
    sub  h                       ; bala_x - enemy_x
    jr   nc, .diff_x_positive
    ; Negativo
    cpl
    inc  a
.diff_x_positive:
    cp   4                       ; Distancia X < 4
    jr   nc, .no_collision
    
    ld   a, d                    ; bala_y
    sub  l                       ; bala_y - enemy_y
    jr   nc, .diff_y_positive
    ; Negativo
    cpl
    inc  a
.diff_y_positive:
    cp   3                       ; Distancia Y < 3
    jr   nc, .no_collision
    
    ; ¡Colisión detectada!
    pop  bc                      ; B = slot de enemigo
    
    ; Guardar slot de bala en stack
    push de
    
    ; Eliminar enemigo (B contiene el slot)
    ld   c, b
    call eliminar_enemigo_por_slot
    
    ; Eliminar bala (C del exterior contiene el slot)
    pop  de
    pop  bc
    push bc
    call eliminar_bala_actual
    pop  bc
    
    ret                          ; Salir después de la colisión
    
.no_collision:
    pop  bc
    
.next_enemy:
    ld   a, b
    add  a, 4
    ld   b, a
    jr   .loop_enemies

; ------------------------------------------------------------
; eliminar_bala_actual
; C = slot de la bala
; ------------------------------------------------------------
eliminar_bala_actual:
    ; Leer posición de la bala
    ld   h, $C0
    ld   l, c
    ld   a, [hl+]
    ld   e, a                    ; E = x
    ld   a, [hl]
    ld   d, a                    ; D = y
    
    ; Limpiar slot
    dec  hl
    xor  a
    ld   [hl+], a
    ld   [hl+], a
    ld   [hl+], a
    ld   [hl], a
    
    ; Borrar del mapa
    push bc
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    xor  a
    ld   [hl], a                 ; Tile vacío
    pop  bc
    
    ret
