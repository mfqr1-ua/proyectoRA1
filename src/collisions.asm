SECTION "Collisions Code", ROM0

DEF ATTR_ENEMIGO EQU $01

SECTION "Collision Temp", WRAM0
temp_bala_x: ds 1
temp_bala_y: ds 1
temp_bala_slot: ds 1
temp_enemy_x: ds 1
temp_enemy_y: ds 1
temp_enemy_slot: ds 1

SECTION "Collisions Code2", ROM0

revisar_colisiones_balas_enemigos:
    ld   c, 4
.loop_balas:
    ld   a, c
    cp   40
    ret  z
    ld   a, c
    ld   [temp_bala_slot], a
    ld   h, $C0
    ld   l, c
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    pop  hl
    cp   ATTR_ENEMIGO
    jr   z, .next_bala
    ld   a, [hl+]
    or   a
    jr   z, .next_bala
    ld   [temp_bala_x], a
    ld   a, [hl]
    ld   [temp_bala_y], a
    call check_bala_vs_enemigos
.next_bala:
    ld   a, [temp_bala_slot]
    add  a, 4
    ld   c, a
    jr   .loop_balas

check_bala_vs_enemigos:
    ld   b, 80
.loop_enemigos:
    ld   a, b
    cp   160
    ret  z
    ld   a, b
    ld   [temp_enemy_slot], a
    ld   h, $C0
    ld   l, b
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    pop  hl
    cp   ATTR_ENEMIGO
    jr   nz, .next_enemigo
    ld   a, [hl+]
    or   a
    jr   z, .next_enemigo
    ld   [temp_enemy_x], a
    ld   a, [hl]
    ld   [temp_enemy_y], a
    call check_simple_collision
    jr   z, .next_enemigo
    call eliminar_colision
    ret
.next_enemigo:
    ld   a, [temp_enemy_slot]
    add  a, 4
    ld   b, a
    jr   .loop_enemigos

check_simple_collision:
    ld   a, [temp_bala_x]
    ld   b, a
    ld   a, [temp_enemy_x]
    cp   b
    jr   z, .check_y
    jr   c, .enemy_menor
    sub  b
    jr   .check_diff_x
.enemy_menor:
    ld   a, b
    ld   b, a
    ld   a, [temp_enemy_x]
    ld   c, a
    ld   a, b
    sub  c
.check_diff_x:
    cp   4
    jr   nc, .no_collision
.check_y:
    ld   a, [temp_bala_y]
    ld   b, a
    ld   a, [temp_enemy_y]
    cp   b
    jr   z, .collision
    jr   c, .enemy_y_menor
    sub  b
    jr   .check_diff_y
.enemy_y_menor:
    ld   a, b
    ld   b, a
    ld   a, [temp_enemy_y]
    ld   c, a
    ld   a, b
    sub  c
.check_diff_y:
    cp   3
    jr   nc, .no_collision
.collision:
    xor  a
    inc  a
    ret
.no_collision:
    xor  a
    ret

eliminar_colision:
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
    ld   h, $C0
    ld   l, c
    ld   a, [hl+]
    ld   e, a
    ld   a, [hl]
    ld   d, a
    dec  hl
    xor  a
    ld   [hl+], a
    ld   [hl+], a
    ld   [hl+], a
    ld   [hl], a
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    xor  a
    ld   [hl], a
    ret
