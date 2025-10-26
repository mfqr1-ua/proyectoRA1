; collisions.asm - Sistema de colisiones entre balas y enemigos (SIMPLIFICADO)

SECTION "Collisions Code", ROM0

; Constante importada de enemies.asm
DEF ATTR_ENEMIGO EQU $01

; Variables temporales en WRAM
SECTION "Collision Temp", WRAM0
temp_bala_x: ds 1
temp_bala_y: ds 1
temp_bala_slot: ds 1
temp_enemy_x: ds 1
temp_enemy_y: ds 1
temp_enemy_slot: ds 1

SECTION "Collisions Code2", ROM0

; ------------------------------------------------------------
; revisar_colisiones_balas_enemigos
; Revisa todas las balas contra todos los enemigos
; ------------------------------------------------------------
revisar_colisiones_balas_enemigos:
    ld   c, 4                    ; Primer slot de balas
    
.loop_balas:
    ld   a, c
    cp   40
    ret  z                       ; Terminó de revisar balas
    
    ; Guardar slot de bala
    ld   a, c
    ld   [temp_bala_slot], a
    
    ; Leer bala
    ld   h, $C0
    ld   l, c
    
    ; Verificar si es enemigo (saltar si lo es)
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    pop  hl
    cp   ATTR_ENEMIGO
    jr   z, .next_bala
    
    ; Leer X de bala
    ld   a, [hl+]
    or   a
    jr   z, .next_bala           ; Bala inactiva
    ld   [temp_bala_x], a
    
    ; Leer Y de bala
    ld   a, [hl]
    ld   [temp_bala_y], a
    
    ; Revisar contra todos los enemigos
    call check_bala_vs_enemigos
    
.next_bala:
    ld   a, [temp_bala_slot]
    add  a, 4
    ld   c, a
    jr   .loop_balas

; ------------------------------------------------------------
; check_bala_vs_enemigos
; Revisa la bala actual contra todos los enemigos
; ------------------------------------------------------------
check_bala_vs_enemigos:
    ld   b, 4                    ; Primer slot de enemigos
    
.loop_enemigos:
    ld   a, b
    cp   40
    ret  z                       ; No más enemigos
    
    ; Guardar slot de enemigo
    ld   a, b
    ld   [temp_enemy_slot], a
    
    ; Leer enemigo
    ld   h, $C0
    ld   l, b
    
    ; Verificar si es enemigo
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    pop  hl
    cp   ATTR_ENEMIGO
    jr   nz, .next_enemigo
    
    ; Leer X de enemigo
    ld   a, [hl+]
    or   a
    jr   z, .next_enemigo        ; Enemigo inactivo
    ld   [temp_enemy_x], a
    
    ; Leer Y de enemigo
    ld   a, [hl]
    ld   [temp_enemy_y], a
    
    ; Verificar colisión
    call check_simple_collision
    jr   z, .next_enemigo        ; No hay colisión
    
    ; ¡HAY COLISIÓN! - Eliminar ambos
    call eliminar_colision
    ret                          ; Salir tras primera colisión
    
.next_enemigo:
    ld   a, [temp_enemy_slot]
    add  a, 4
    ld   b, a
    jr   .loop_enemigos

; ------------------------------------------------------------
; check_simple_collision
; Verifica si hay colisión entre bala y enemigo actual
; Retorna: Z flag set si NO hay colisión
; ------------------------------------------------------------
check_simple_collision:
    ; Comparar X: |bala_x - enemy_x| < 3
    ld   a, [temp_bala_x]
    ld   b, a
    ld   a, [temp_enemy_x]
    
    cp   b
    jr   z, .check_y             ; Son iguales, revisar Y
    jr   c, .enemy_menor
    
    ; enemy_x > bala_x
    sub  b
    jr   .check_diff_x
    
.enemy_menor:
    ; enemy_x < bala_x
    ld   a, b
    ld   b, a
    ld   a, [temp_enemy_x]
    ld   c, a
    ld   a, b
    sub  c
    
.check_diff_x:
    cp   4                       ; Diferencia debe ser < 4
    jr   nc, .no_collision
    
.check_y:
    ; Comparar Y: |bala_y - enemy_y| < 3
    ld   a, [temp_bala_y]
    ld   b, a
    ld   a, [temp_enemy_y]
    
    cp   b
    jr   z, .collision           ; Son iguales, ¡colisión!
    jr   c, .enemy_y_menor
    
    ; enemy_y > bala_y
    sub  b
    jr   .check_diff_y
    
.enemy_y_menor:
    ; enemy_y < bala_y
    ld   a, b
    ld   b, a
    ld   a, [temp_enemy_y]
    ld   c, a
    ld   a, b
    sub  c
    
.check_diff_y:
    cp   3                       ; Diferencia debe ser < 3
    jr   nc, .no_collision
    
.collision:
    xor  a
    inc  a                       ; Clear Z flag
    ret
    
.no_collision:
    xor  a                       ; Set Z flag
    ret

; ------------------------------------------------------------
; eliminar_colision
; Elimina la bala y el enemigo actuales
; ------------------------------------------------------------
eliminar_colision:
    ; Eliminar enemigo
    ld   a, [temp_enemy_slot]
    ld   c, a
    call eliminar_enemigo_por_slot
    
    ; Eliminar bala
    ld   a, [temp_bala_slot]
    ld   c, a
    call eliminar_bala_simple
    
    ret

; ------------------------------------------------------------
; eliminar_bala_simple
; C = slot de la bala
; ------------------------------------------------------------
eliminar_bala_simple:
    ; Leer posición
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
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    xor  a
    ld   [hl], a
    
    ret
