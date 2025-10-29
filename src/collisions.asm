SECTION "Collisions Code", ROM0

DEF ATTR_ENEMIGO EQU $01      ; marca para reconocer un enemigo

SECTION "Collision Temp", WRAM0
temp_bala_x: ds 1             ; x de la bala
temp_bala_y: ds 1             ; y de la bala
temp_bala_slot: ds 1          ; slot de la bala
temp_enemy_x: ds 1            ; x del enemigo
temp_enemy_y: ds 1            ; y del enemigo
temp_enemy_slot: ds 1         ; slot del enemigo

SECTION "Collisions Code2", ROM0

revisar_colisiones_balas_enemigos:
    ; recorre todas las balas y las prueba contra los enemigos
    ld   c, 4
.loop_balas:
    ld   a, c
    cp   40
    ret  z                     ; no hay más balas
    ld   a, c
    ld   [temp_bala_slot], a
    ld   h, $C0
    ld   l, c
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]               ; byte de tipo
    pop  hl
    cp   ATTR_ENEMIGO
    jr   z, .next_bala         ; esto no es bala
    ld   a, [hl+]              ; x bala
    or   a
    jr   z, .next_bala         ; vacío
    ld   [temp_bala_x], a
    ld   a, [hl]               ; y bala
    ld   [temp_bala_y], a
    call check_bala_vs_enemigos
.next_bala:
    ld   a, [temp_bala_slot]
    add  a, 4
    ld   c, a
    jr   .loop_balas

check_bala_vs_enemigos:
    ; prueba la bala actual contra todos los enemigos
    ld   b, 80
.loop_enemigos:
    ld   a, b
    cp   160
    ret  z                     ; no hay más enemigos
    ld   a, b
    ld   [temp_enemy_slot], a
    ld   h, $C0
    ld   l, b
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]               ; tipo
    pop  hl
    cp   ATTR_ENEMIGO
    jr   nz, .next_enemigo     ; no es enemigo
    ld   a, [hl+]              ; x enemigo
    or   a
    jr   z, .next_enemigo      ; vacío
    ld   [temp_enemy_x], a
    ld   a, [hl]               ; y enemigo
    ld   [temp_enemy_y], a
    call check_simple_collision
    jr   z, .next_enemigo      ; no chocan
    call eliminar_colision     ; chocan: borrar y sumar
    ret
.next_enemigo:
    ld   a, [temp_enemy_slot]
    add  a, 4
    ld   b, a
    jr   .loop_enemigos

check_simple_collision:
    ; bala (1x1) vs enemigo (3x2): verifica si bala dentro del rect enemigo
    ld   a, [temp_bala_x]
    ld   b, a
    ld   a, [temp_enemy_x]
    cp   b
    jr   nc, .check_x_max      ; bala_x >= enemy_x
    jr   .no_collision         ; bala_x < enemy_x
.check_x_max:
    ld   a, [temp_enemy_x]
    add  a, 3                  ; enemy_x + 3
    ld   c, a
    ld   a, [temp_bala_x]
    cp   c
    jr   nc, .no_collision     ; bala_x >= enemy_x+3
.check_y_min:
    ld   a, [temp_bala_y]
    ld   b, a
    ld   a, [temp_enemy_y]
    cp   b
    jr   nc, .check_y_max      ; bala_y >= enemy_y
    jr   .no_collision         ; bala_y < enemy_y
.check_y_max:
    ld   a, [temp_enemy_y]
    add  a, 2                  ; enemy_y + 2
    ld   c, a
    ld   a, [temp_bala_y]
    cp   c
    jr   nc, .no_collision     ; bala_y >= enemy_y+2
.collision:
    xor  a
    inc  a
    ret
.no_collision:
    xor  a
    ret

eliminar_colision:
    ; quita enemigo y bala, y suma puntos
    ld   a, [temp_enemy_slot]
    ld   c, a
    call eliminar_enemigo_por_slot
    ld   a, [temp_bala_slot]
    ld   c, a
    call eliminar_bala_simple
    ld   a, 10
    call add_score
    ret

eliminar_bala_simple:
    ; borra la bala del mapa y limpia su slot
    ld   h, $C0
    ld   l, c
    ld   a, [hl+]              ; x
    ld   e, a
    ld   a, [hl]               ; y
    ld   d, a
    dec  hl
    xor  a
    ld   [hl+], a              ; x=0
    ld   [hl+], a              ; y=0
    ld   [hl+], a              ; tile=0
    ld   [hl], a               ; tipo=0
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    xor  a
    ld   [hl], a               ; borra el tile en pantalla
    ret
