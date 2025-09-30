INCLUDE "constantes.inc"

SECTION "Variables", WRAM0
disparo_cd: ds 1          ; cooldown
jug_L: ds 1
jug_H: ds 1


SECTION "Main Code", ROM0

main:
    call borrarLogo
    call colocaJugador
   
    xor  a
    ld  [disparo_cd], a     ; listo para disparar (sin cooldown)

.loop:
    ; Mover todas las balas
    call mover_balas ;falta por implementar

    ; Cooldown de disparo 
    ld   a, [disparo_cd]
    or   a
    jr   z, .puede_disparar
    dec  a
    ld  [disparo_cd], a
    jr   .mover_jugador

.puede_disparar:
    call leer_botones
    bit  0, a               
    jr   nz, .mover_jugador

    ; Crear bala justo encima del jugador

    call setJugador
    push hl
    ld   de, $FFE0          ; HL = HL - 32 (una fila arriba)
    add  hl, de
    call wait_vblank
    ld   a, $19
    ld   [hl], a
    pop hl

    ; Reinicia cooldown
    ld   a, 15
    ld  [disparo_cd], a

.mover_jugador:
    
    call read_dpad

    ; Derecha (bit0=0)
    bit  0, a
    jr   nz, .check_left
    call wait_vblank
    xor  b
    ld   [hl], b
    inc  hl
    ld   a, $19
    ld   [hl], a
    ld   a, l
    ld  [jug_L], a
    ld   a, h
    ld  [jug_H], a
.wait_right:
    call read_dpad
    bit  0, a
    jr   z, .wait_right
    jr   .loop

.check_left:
    ; Izquierda (bit1=0)
    bit  1, a
    jr   nz, .loop
    call wait_vblank
    xor  b
    ld   [hl], b
    dec  hl
    ld   a, $19
    ld   [hl], a
    ld   a, l
    ld  [jug_L], a
    ld   a, h
    ld  [jug_H], a
.wait_left:
    call read_dpad
    bit  1, a
    jr   z, .wait_left
    jr   .loop
