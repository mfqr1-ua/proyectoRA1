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

    ret


main:
    call borrarLogo
    call init_player          ; Inicializar jugador
    call init_enemy_system    ; Inicializar sistema de enemigos

    ; Dibujar jugador inicial usando la función de dibujo
    call draw_player

.loop:
    ; Esperar vblank una sola vez por frame
    call wait_vblank
    
    ; Sistema de enemigos completo con movimiento
    call update_spawn_timer_simple   ; Crear nuevos enemigos cuando se mueran
    call clear_enemies_simple        ; Borrar enemigos de pantalla
    call update_enemies_simple       ; Mover enemigos hacia abajo
    call draw_enemies_simple         ; Dibujar enemigos en pantalla
    
    ; Manejar input del jugador
    call read_dpad

    ; Comprobar derecha
    bit  0, a
    jr   nz, .check_left        ; Si no se presiona derecha, check izquierda
    
    ; Mover derecha con límites
    call move_player_right
    jr   .loop

.check_left:
    ; Comprobar izquierda  
    bit  1, a
    jr   nz, .loop              ; Si no se presiona izquierda, continuar

    ; Mover izquierda con límites
    call move_player_left
    jr   .loop