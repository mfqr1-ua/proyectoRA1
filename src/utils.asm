SECTION "utils", ROM0
borrarLogo:
    ld   hl, $9904
    ld   b,  $16
    xor  a
    call limpiaArriba
    call limpiaAbajo
    ret
limpiaArriba:
    call wait_vblank
    ld   [hl+], a
    dec  b
    jr   nz, limpiaArriba

    ld   hl, $9924
    ld   b,  $0C
    ret
limpiaAbajo:
    call wait_vblank
    ld   [hl+], a
    dec  b
    jr   nz, limpiaAbajo
    ret

colocaJugador:    ; Colocar jugador
    ld   hl, $9A09
    ld   a,  $19
    ld   [hl], a
    call guardarJugador
    ret

guardarJugador:    ; Guardar HL en jug_L/jug_H
    ld   a, l
    ld  [jug_L], a
    ld   a, h
    ld  [jug_H], a
    ret
setJugador:
    ld   a, [jug_L]        
    ld   l, a
    ld   a, [jug_H]
    ld   h, a
    ret
    
wait_vblank:
    ld  a, [$FF44]
    cp  144
    jr  c, wait_vblank
    ret

; Lee DPAD
read_dpad:
    ld   a, $20
    ld  [$FF00], a
    ld   a, [$FF00]
    ld   a, [$FF00]
    ret

; Lee botones A/B/Start/Select
leer_botones:
    ld   a, $10
    ld  [$FF00], a
    ld   a, [$FF00]
    ld   a, [$FF00]
    ld   a, [$FF00]
    ret


