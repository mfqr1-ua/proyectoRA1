SECTION "Entry point", ROM0[$150]

wait_vblank:
    ld  a, [$FF44]          
    cp   144
    jr   c, wait_vblank
    ret



read_dpad:
    ld   a, $20            ; seleccionar dpad
    ld  [$FF00], a          
    ld  a, [$FF00]
    ld  a, [$FF00]          ; estabiliza
    ret

borrarLogo:
    ld   hl, $9904
    ld   b, $16
    xor  a
    .parteArriba:
        call wait_vblank
        ld   [hl+], a
        dec  b
        jr   nz, .parteArriba

    ld   hl, $9924
    ld   b, $0C
    .parteAbajo:
        call wait_vblank
        ld   [hl+], a
        dec  b
        jr   nz, .parteAbajo

        ld   hl, $9A09
        ld   a,  $19
        ld   [hl], a
    ret


main:

call borrarLogo

.loop:
    call read_dpad

    bit  0, a
    jr   nz, .comprobarIzquierda         ; si no, miramos izquierda

    call wait_vblank
    xor  b                       
    ld   [hl], b                 ; borra casilla actual
    inc  hl                      ; avanza a la derecha
    ld   a, $19
    ld   [hl], a                 

.esperaRigth:              
    call read_dpad
    bit  0, a
    jr   z, .esperaRigth
    jr   .loop

.comprobarIzquierda:
    bit  1, a
    jr   nz, .loop               ; si tampoco, no hacemos nada

    call wait_vblank
    xor  b                       
    ld   [hl], b                 ; borra casilla actual
    dec  hl                      ; retrocede a la izquierda
    ld   a, $19
    ld   [hl], a

.esperaLeft:               
    call read_dpad
    bit  1, a 
    jr   z, .esperaLeft
    jr   .loop
