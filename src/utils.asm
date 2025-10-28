INCLUDE "constantes.inc"

SECTION "utils", ROM0

borrar_logo:
    ld   hl, BG_MAP0+$104         ; zona superior (antes $9904)
    ld   b,  $16
    xor  a
    call limpiar_arriba
    call limpiar_abajo
    ret

limpiar_arriba:
    ld   [hl+], a
    dec  b
    jr   nz, limpiar_arriba
    ld   hl, BG_MAP0+$124         ; antes $9924
    ld   b,  $0C
    ret

limpiar_abajo:
    ld   [hl+], a
    dec  b
    jr   nz, limpiar_abajo
    ret

wait_vblank:
    ld  a, [rLY]
    cp  VBLANK_LINE
    jr  c, wait_vblank
    ret

read_dpad:
    ld   a, P1_SELECT_DPAD
    ld  [rP1], a
    ld   a, [rP1]
    ld   a, [rP1]
    ret

leer_botones:                     ; A/B/Start/Select
    ld   a, P1_SELECT_BUTTONS
    ld  [rP1], a
    ld   a, [rP1]
    ld   a, [rP1]
    ld   a, [rP1]
    ret

memset_256:
    ld  [hl+], a
    dec b
    jr  nz, memset_256
    ret

memcpy_256:
    ld   a, [hl+]
    ld  [de], a
    inc  de
    dec  b
    jr   nz, memcpy_256
    ret

lcd_off:
    ld   a, [rLCDC]
    res  7, a
    ld  [rLCDC], a
    ret

lcd_on:
    ld   a, [rLCDC]
    set  7, a
    ld  [rLCDC], a
    ret

copy_tiles:
    ld   a, [hl+]
    ld  [de], a
    inc  de
    dec  b
    ld   a, b
    cp   0
    jr   nz, copy_tiles
    ret

pintar_bloque_3x2_desde_xy_con_base:
    push af
    push de
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    pop  de
    pop  af

    ld   [hl], a                  ; TL = base
    inc  hl
    inc  a
    ld   [hl], a                  ; TM
    inc  hl
    inc  a
    ld   [hl], a                  ; TR

    ld   bc, 30    ; 32-2 = 30
    add  hl, bc

    inc  a
    ld   [hl], a                  ; BL
    inc  hl
    inc  a
    ld   [hl], a                  ; BM
    inc  hl
    inc  a
    ld   [hl], a                  ; BR
    ret

borrar_bloque_3x2_desde_xy:
    push de
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    pop  de

    xor  a
    ld   [hl], a                  ; TL
    inc  hl
    ld   [hl], a                  ; TM
    inc  hl
    ld   [hl], a                  ; TR

    ld   bc, 30
    add  hl, bc

    ld   [hl], a                  ; BL
    inc  hl
    ld   [hl], a                  ; BM
    inc  hl
    ld   [hl], a                  ; BR
    ret

dibujaJugador:
    ld   a, [SLOT0_X]
    ld   e, a
    ld   a, [SLOT0_Y]
    ld   d, a
    ld   a, [SLOT0_BASE]
    jp   pintar_bloque_3x2_desde_xy_con_base
ret

clear_oam:
    ld   hl, OAM_BASE
    ld   b,  OAM_BYTES_TOTAL
    xor  a
.clear_loop:
    ld  [hl+], a
    dec  b
    jr  nz, .clear_loop
    ret

copy_tiles_invertidoColor:
.cti_loop:
    ld   a,[hl+]
    cpl
    ld  [de],a
    inc  de
    dec  b
    jr   nz,.cti_loop
    ret
