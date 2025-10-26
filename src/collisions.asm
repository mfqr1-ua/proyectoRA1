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
    ld   a, [hl]                 ; Leer X de la bala
    or   a
    jr   z, .next_bala           ; Slot vacío
    
    ; Verificar que NO sea enemigo (las balas no tienen ATTR_ENEMIGO)
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    cp   ATTR_ENEMIGO
    pop  hl
    jr   z, .next_bala           ; Es enemigo, no bala
    
    ; Tenemos una bala en HL, guardar su slot
    push bc
    call check_bala_vs_all_enemies
    pop  bc
    
    ; Si hubo colisión, la bala ya fue eliminada
    
.next_bala:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .loop_balas

; ------------------------------------------------------------
; check_bala_vs_all_enemies
; HL apunta al slot de la bala
; C contiene el slot de la bala
; ------------------------------------------------------------
check_bala_vs_all_enemies:
    ; Guardar posición de la bala
    ld   a, [hl+]                ; X de bala
    ld   d, a
    ld   a, [hl]                 ; Y de bala
    ld   e, a
    
    ; D = bala_x, E = bala_y, C = slot de bala
    
    ; Recorrer enemigos
    push bc
    push de
    ld   b, 4                    ; Primer slot de enemigos
.loop_enemies:
    ld   a, b
    cp   40
    jr   z, .no_collision
    
    ; Verificar si es enemigo
    ld   h, $C0
    ld   l, b
    
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    cp   ATTR_ENEMIGO
    pop  hl
    jr   nz, .next_enemy
    
    ; Es enemigo, verificar si está activo
    ld   a, [hl]
    or   a
    jr   z, .next_enemy
    
    ; Tenemos enemigo activo, verificar colisión
    push bc
    pop  de
    pop  af                      ; Recuperar bala_y en A
    pop  bc                      ; Recuperar bala_x en B
    push bc
    push af
    push de
    
    ; B = bala_x, A = bala_y (en stack)
    ; HL apunta a enemigo
    ; E = slot de enemigo
    
    call check_collision_bala_vs_enemy_slot
    jr   nz, .collision_found
    
.next_enemy:
    ld   a, b
    add  a, 4
    ld   b, a
    jr   .loop_enemies
    
.no_collision:
    pop  de
    pop  bc
    ret

.collision_found:
    ; Colisión detectada!
    ; E = slot de enemigo
    ; C (en stack) = slot de bala
    
    pop  de                      ; Limpia stack (bala pos)
    pop  bc                      ; BC = (bala_x, bala_y) - no usado
    pop  bc                      ; C = slot de bala
    
    push bc
    push de
    
    ; Eliminar enemigo (E contiene el slot)
    ld   c, e
    call eliminar_enemigo_por_slot
    
    ; Eliminar bala
    pop  de
    pop  bc
    call eliminar_bala_actual
    
    ret

; ------------------------------------------------------------
; check_collision_bala_vs_enemy_slot
; Verifica colisión AABB entre bala y enemigo
; HL apunta al enemigo
; B = bala_x, A = bala_y (en stack top), E = slot enemigo
; Salida: Z flag clear si hay colisión
; ------------------------------------------------------------
check_collision_bala_vs_enemy_slot:
    ; Leer posición del enemigo
    ld   a, [hl+]                ; enemy_x
    ld   c, a
    ld   a, [hl]                 ; enemy_y
    ld   d, a
    
    ; C = enemy_x, D = enemy_y
    ; B = bala_x, stack top = bala_y
    
    ; Verificar X: |bala_x - enemy_x| < umbral
    ld   a, b
    sub  c
    jr   nc, .positive_x
    ; Si es negativo, negar manualmente: A = 0 - A
    cpl
    inc  a
.positive_x:
    add  a, 2                    ; Margen de colisión X
    cp   5                       ; Ancho de detección (3x2 tiles)
    jr   nc, .no_hit
    
    ; Verificar Y
    pop  hl                      ; Recuperar dirección de retorno
    pop  af                      ; A = bala_y
    push af
    push hl
    
    sub  d
    jr   nc, .positive_y
    ; Si es negativo, negar manualmente: A = 0 - A
    cpl
    inc  a
.positive_y:
    add  a, 5                    ; Margen de colisión Y
    cp   10                      ; Alto de detección
    jr   nc, .no_hit
    
    ; Colisión!
    xor  a
    inc  a                       ; Clear Z flag
    ret
    
.no_hit:
    xor  a                       ; Set Z flag
    ret

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
    xor  a
    ld   [hl], a                 ; Tile vacío
    pop  bc
    
    ret
