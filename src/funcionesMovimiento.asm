INCLUDE "constantes.inc"

SECTION "funcionesMovimiento", ROM0

calcular_direccion_bg_desde_xy:
    push de
    ld   hl, $9800
    ld   a, d
    ld   b, 0
    ld   c, 32
.loop_filas:
    or   a
    jr   z, .filas_ok
    add  hl, bc
    dec  a
    jr   .loop_filas
.filas_ok:
    pop  de
    ld   a, e
    ld   b, 0
    ld   c, a
    add  hl, bc
    ret

leer_slot0_xy:
    ld   hl, $C000
    ld   e, [hl]
    inc  hl
    ld   d, [hl]
    ret

escribir_slot0_x:
    ld   hl, $C000
    ld   [hl], e
    ret

mover_jugador:
    call read_dpad
    bit  0, a
    jr   nz, .comprobar_izquierda
    call leer_slot0_xy
    push de
    call borrar_bloque_3x2_desde_xy
    pop  de
    inc  e
    ld   a, e
    cp   17
    jr   c, .x_der_ok
    ld   e, 17
.x_der_ok:
    call escribir_slot0_x
    push de
    ld   a, [$C002]
    call pintar_bloque_3x2_desde_xy_con_base
    pop  de
    ret
.comprobar_izquierda:
    bit  1, a
    ret  nz
    call leer_slot0_xy
    push de
    call borrar_bloque_3x2_desde_xy
    pop  de
    dec  e
    bit  7, e
    jr   z, .x_izq_ok
    ld   e, 0
.x_izq_ok:
    call escribir_slot0_x
    push de
    ld   a, [$C002]
    call pintar_bloque_3x2_desde_xy_con_base
    pop  de
ret
