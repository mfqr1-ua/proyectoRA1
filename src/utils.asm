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

memset_256:
    ld [hl+], a
    dec b
    jr nz, memset_256
    ret
memcpy_256:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, memcpy_256
    ret

INCLUDE "constantes.inc"


dibujaJugador:
    ; --- leer x, y, tile ---
    ld   a, [$C000]      ; x
    ld   d, a            ; D = x
    ld   a, [$C001]      ; y
    ld   e, a            ; E = y
    ld   a, [$C002]      ; tile
    push af              ; guarda tile

    ; --- HL = $9800 + y*32 ---
    ld   hl, $9800
    ld   a, e            ; A = y
    ld   b, 0
    ld   c, 32           ; BC = 32
.y_loop:
    or   a
    jr   z, .y_done
    add  hl, bc          ; HL += 32
    dec  a
    jr   .y_loop
.y_done:

    ; --- HL += x ---
    ld   a, d            ; A = x
    ld   b, 0
    ld   c, a            ; BC = x
    add  hl, bc

    call wait_vblank

    pop  af              ; A = tile
    ld   [hl], a
    ret


