INCLUDE "constantes.inc"

SECTION "Variables", WRAM0
disparo_cd: ds 1           ;   cooldown entre disparos
balas_tick: ds 1           ;  acumula ticks para mover balas
a_lock:     ds 1           ;  evita disparos repetidos 

DEF COOLDOWN_DISPARO EQU 15 ;  frames de cooldown (más rápido)

SECTION "Tiles ROM", ROM0
naveEspacial::
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $E7,$E7,$DB,$DB,$BD,$BD,$7E,$7E
    db $66,$66,$5A,$5A,$5A,$5A,$66,$66
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FE,$FE,$FC,$FC,$FC,$FC
    db $FC,$FC,$FD,$FD,$FF,$FF,$FF,$FF
    db $7E,$7E,$7E,$7E,$00,$00,$24,$24
    db $A5,$A5,$DB,$DB,$DB,$DB,$E7,$E7
    db $FF,$FF,$7F,$7F,$3F,$3F,$3F,$3F
    db $3F,$3F,$BF,$BF,$FF,$FF,$FF,$FF

tileNegro::
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

bala::
    db $E7,$E7,$E7,$E7,$E7,$E7,$E7,$E7
    db $E7,$E7,$E7,$E7,$E7,$E7,$E7,$E7

SECTION "Main Code", ROM0
main:
    call wait_vblank                
    call lcd_off                     

    ld   a, $E4
    ld  [$FF47], a                  ; paleta BG

    ld   hl, naveEspacial
    ld   de, $8000 + 16*$20
    ld   b,  96
    call copy_tiles                  ;  copia 6 tiles  $20 a $25

    ld   hl, tileNegro
    ld   de, $8000
    ld   b,  16
    call copy_tiles                  ;  tile 0 negro

    ld   hl, bala
    ld   de, $8000 + 16*1
    ld   b,  16
    call copy_tiles                  ;  copia el tile de la bala en  1

    call borrar_logo                  

    call lcd_on                      

    call man_entity_init             
    call ecs_init_player             ;  crea al jugador 
    call init_enemigos               ;  inicializa sistema de enemigos

    call dibujaJugador               ;  dibuja al jugador

    xor  a
    ld  [disparo_cd], a              ;  limpia cooldown
    ld  [balas_tick], a              ;  limpia tick balas
    ld  [a_lock], a                  ;  limpia el lock del botón

.bucle_principal:
    call mover_jugador   
    call mover_balas                 

    ; Sistema de enemigos
    call update_enemigos             ; Actualizar y crear enemigos
    call draw_enemigos               ; Dibujar enemigos en pantalla

    call leer_botones                ;   A/B/Start/Select
    bit  1, a                        ;   bit 1 = botón B (1=presionado)
    jr   z, .B_no_pulsado           ;   si bit=0, B no está presionado

    ; B está presionado -> disparar
    ld   a, [disparo_cd]             ;  verificar cooldown
    or   a
    jr   nz, .no_disparo             ;  si cooldown > 0, no disparar

    call crear_bala_desde_jugador    ;  crear bala
    ld   a, COOLDOWN_DISPARO         ;  establecer cooldown
    ld  [disparo_cd], a
    jr   .no_disparo

.B_no_pulsado:
    ; B no está presionado

.no_disparo:
    ; Decrementar cooldown
    ld   a, [disparo_cd]             
    or   a
    jr   z, .continuar
    dec  a
    ld  [disparo_cd], a

.continuar:
    jr .bucle_principal

    di
    halt
    ret
