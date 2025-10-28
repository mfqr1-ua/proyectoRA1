SECTION "Balas Code", ROM0

DEF SPEED_BALAS EQU 2
DEF TILE_BALA   EQU $01

crear_bala_desde_jugador:
    ld   a, [next_free_entity]
    cp   40
    jr   nz, .puntero_ok
    ld   a, 4
    ld  [next_free_entity], a
.puntero_ok:
    ld   a, [$C000]
    ld   e, a
    ld   a, [$C001]
    ld   d, a
    inc  e
    dec  d
    bit  7, d
    jr   z, .y_valida
    ld   d, 0
.y_valida:
    call man_entity_alloc
    ld   a, e
    ld  [hl+], a
    ld   a, d
    ld  [hl+], a
    ld   a, TILE_BALA
    ld  [hl+], a
    xor  a
    ld  [hl], a
    push de
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    ld   a, TILE_BALA
    ld  [hl], a
    pop  de
    ld a, %01000000
    ld [$FF16], a
    ld a, %11110010
    ld [$FF17], a
    ld a, $C3
    ld [$FF18], a
    ld a, %10000110
    ld [$FF19], a
    ret

mover_balas:
    call revisar_colisiones_balas_enemigos
    ld   a, [next_free_entity]
    cp   4
    ret  c
    ld   a, [balas_tick]
    inc  a
    ld  [balas_tick], a
    cp   SPEED_BALAS
    ret  c
    xor  a
    ld  [balas_tick], a
    ld   a, [next_free_entity]
    ld   b, a
    cp   4
    jr   nz, .limite_ok
    ld   b, 40
.limite_ok:
    ld   c, 4
.primer_tramo_loop:
    ld   a, c
    cp   b
    jr   z, .tras_primer_tramo
    ld   h, $C0
    ld   l, c
    ld   a, [hl]
    ld   e, a
    inc  hl
    ld   a, [hl]
    ld   d, a
    push bc
    push hl
    push de
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    xor  a
    ld   [hl], a
    pop  de
    pop  hl
    ld   a, d
    or   a
    jr   nz, .no_en_borde_1
    dec  hl
    xor  a
    ld  [hl+], a
    ld  [hl+], a
    ld  [hl+], a
    ld  [hl],  a
    pop  bc
    jr   .avanzar_slot_1
.no_en_borde_1:
    dec  a
    ld   d, a
    ld  [hl], d
    push de
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    ld   a, TILE_BALA
    ld  [hl], a
    pop  de
    pop  bc
.avanzar_slot_1:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .primer_tramo_loop

.tras_primer_tramo:
    ld   a, b
    cp   40
    ret  z
    ld   c, b
.escanear_cola:
    ld   a, c
    cp   40
    jr   z, .no_hay_cola
    ld   h, $C0
    ld   l, c
    inc  hl
    inc  hl
    ld   a, [hl]
    or   a
    jr   nz, .procesar_cola
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .escanear_cola
.no_hay_cola:
    ret

.procesar_cola:
    ld   c, b
.segundo_tramo_loop:
    ld   a, c
    cp   40
    ret  z
    ld   h, $C0
    ld   l, c
    ld   a, [hl]
    ld   e, a
    inc  hl
    ld   a, [hl]
    ld   d, a
    push bc
    push hl
    push de
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    xor  a
    ld   [hl], a
    pop  de
    pop  hl
    ld   a, d
    or   a
    jr   nz, .no_en_borde_2
    dec  hl
    xor  a
    ld  [hl+], a
    ld  [hl+], a
    ld  [hl+], a
    ld  [hl],  a
    pop  bc
    jr   .avanzar_slot_2
.no_en_borde_2:
    dec  a
    ld   d, a
    ld  [hl], d
    push de
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    ld   a, TILE_BALA
    ld  [hl], a
    pop  de
    pop  bc
.avanzar_slot_2:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .segundo_tramo_loop
