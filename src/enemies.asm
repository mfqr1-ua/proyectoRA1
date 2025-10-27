SECTION "Enemies Data", WRAM0
enemy_move_timer: ds 1
enemy_spawn_timer: ds 1

SECTION "Enemies Code", ROM0

DEF ENEMY_TL EQU $1A
DEF ENEMY_TM EQU $1C
DEF ENEMY_TR EQU $1E
DEF ENEMY_BL EQU $1B
DEF ENEMY_BM EQU $1D
DEF ENEMY_BR EQU $1F

DEF ATTR_ENEMIGO EQU $01

crear_enemigo_entidad:
    ld   c, 80
.buscar_slot:
    ld   a, c
    cp   160
    ret  z
    ld   h, $C0
    ld   l, c
    ld   a, [hl]
    or   a
    jr   z, .slot_encontrado
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .buscar_slot
.slot_encontrado:
    ld   a, e
    ld  [hl+], a
    ld   a, d
    ld  [hl+], a
    ld   a, ENEMY_TL
    ld  [hl+], a
    ld   a, ATTR_ENEMIGO
    ld  [hl], a
    ret

ecs_init_enemies:
    ld   a, 30
    ld  [enemy_move_timer], a
    ld   a, 240
    ld  [enemy_spawn_timer], a
    ld   e, 6
    ld   d, 2
    call crear_enemigo_entidad
    ld   e, 9
    ld   d, 2
    call crear_enemigo_entidad
    ld   e, 12
    ld   d, 2
    call crear_enemigo_entidad
    ret

ecs_update_enemies:
    ld   a, [enemy_move_timer]
    dec  a
    ld  [enemy_move_timer], a
    jr   nz, .check_spawn
    ld   a, 30
    ld  [enemy_move_timer], a
    call mover_enemigos
.check_spawn:
    ld   a, [enemy_spawn_timer]
    dec  a
    ld  [enemy_spawn_timer], a
    jr   nz, .end
    ld   a, 240
    ld  [enemy_spawn_timer], a
    call spawn_enemigo_si_falta
.end:
    ret

mover_enemigos:
    ld   c, 80
.loop_slots:
    ld   a, c
    cp   160
    ret  z
    ld   h, $C0
    ld   l, c
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    cp   ATTR_ENEMIGO
    jr   nz, .next_slot
    dec  hl
    dec  hl
    dec  hl
    ld   a, [hl]
    or   a
    jr   z, .next_slot
    ld   e, a
    inc  hl
    ld   a, [hl]
    ld   d, a
    push bc
    push hl
    call borrar_bloque_3x2_desde_xy
    pop  hl
    pop  bc
    ld   a, [hl]
    inc  a
    cp   18
    jr   nc, .kill_enemy
    ld   [hl], a
    jr   .next_slot
.kill_enemy:
    dec  hl
    xor  a
    ld   [hl+], a
    ld   [hl+], a
    ld   [hl+], a
    ld   [hl], a
.next_slot:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .loop_slots

spawn_enemigo_si_falta:
    call contar_enemigos_vivos
    cp   3
    ret  nc
.spawn_loop:
    call contar_enemigos_vivos
    cp   3
    ret  nc
    ld   a, [$FF04]
    and  $0F
    cp   15
    jr   c, .valid_x
    ld   a, 7
.valid_x:
    ld   e, a
    ld   d, 1
    call crear_enemigo_entidad
    jr   .spawn_loop

contar_enemigos_vivos:
    ld   b, 0
    ld   c, 80
.loop_slots:
    ld   a, c
    cp   160
    jr   z, .done
    ld   h, $C0
    ld   l, c
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    cp   ATTR_ENEMIGO
    jr   nz, .next_slot
    dec  hl
    dec  hl
    dec  hl
    ld   a, [hl]
    or   a
    jr   z, .next_slot
    inc  b
.next_slot:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .loop_slots
.done:
    ld   a, b
    ret

draw_enemigos:
    ld   c, 80
.loop_slots:
    ld   a, c
    cp   160
    ret  z
    ld   h, $C0
    ld   l, c
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    cp   ATTR_ENEMIGO
    pop  hl
    jr   nz, .next_slot
    ld   a, [hl]
    or   a
    jr   z, .next_slot
    ld   e, a
    inc  hl
    ld   a, [hl]
    ld   d, a
    dec  hl
    push bc
    push hl
    call pintar_enemigo_3x2
    pop  hl
    pop  bc
.next_slot:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .loop_slots

pintar_enemigo_3x2:
    push de
    call wait_vblank
    call calcular_direccion_bg_desde_xy
    ld   a, ENEMY_TL
    ld  [hl+], a
    ld   a, ENEMY_TM
    ld  [hl+], a
    ld   a, ENEMY_TR
    ld  [hl], a
    pop  de
    inc  d
    push de
    call wait_vblank
    call calcular_direccion_bg_desde_xy
    ld   a, ENEMY_BL
    ld  [hl+], a
    ld   a, ENEMY_BM
    ld  [hl+], a
    ld   a, ENEMY_BR
    ld  [hl], a
    pop  de
    ret

get_enemy_position_by_slot:
    ld   h, $C0
    ld   l, c
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    cp   ATTR_ENEMIGO
    pop  hl
    jr   nz, .not_enemy
    ld   a, [hl]
    or   a
    ret  z
    ld   e, a
    inc  hl
    ld   a, [hl]
    ld   d, a
    xor  a
    inc  a
    ret
.not_enemy:
    xor  a
    ret

eliminar_enemigo_por_slot:
    call get_enemy_position_by_slot
    ret  z
    push de
    ld   h, $C0
    ld   l, c
    xor  a
    ld   [hl+], a
    ld   [hl+], a
    ld   [hl+], a
    ld   [hl], a
    pop  de
    call borrar_bloque_3x2_desde_xy
    ret
