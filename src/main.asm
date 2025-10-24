INCLUDE "constantes.inc"

SECTION "Variables", WRAM0
disparo_cd: ds 1           ;   cooldown entre disparos
balas_tick: ds 1           ;  acumula ticks para mover balas
a_lock:     ds 1     

      ;  evita disparos repetidos 

DEF COOLDOWN_DISPARO EQU 40 ;  frames de cooldown

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


enemigo::
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FC,$FC,$FD,$FD,$FD,$FD,$FD,$FD
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $E0,$E0,$C0,$C0,$80,$80,$19,$19
    DB $19,$19,$00,$00,$00,$00,$80,$80
    DB $DF,$DF,$DF,$DF,$DF,$DF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $7F,$7F,$3F,$3F,$1F,$1F,$8F,$8F
    DB $83,$83,$0B,$0B,$0B,$0B,$1B,$1B
    DB $BF,$BF,$BF,$BF,$BF,$BF,$FF,$FF
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
    call copy_tiles   ;  copia el tile de la bala en  1
    
    ld   hl, enemigo
    ld   de, $8000 + 16*26
    ld   b,  96
    call copy_tiles                 

    call borrar_logo                  

    call lcd_on                      

    call man_entity_init             
    call ecs_init_player 
    call ecs_init_enemies             ;  crea al jugador 

    call dibujaJugador  

    ;sonido ilyas
    
    ld a, $FF       ; Activa todos los canales y el volumen máximo
    ld [$FF26], a   ; NR52 - Control maestro de sonido (Power ON)
    ld a, $77       ; Volumen máximo para ambos altavoces (izquierdo y derecho)
    ld [$FF25], a             ;  dibuja al jugador

    xor  a
    ld  [disparo_cd], a              ;  limpia cooldown
    ld  [balas_tick], a              ;  limpia tick balas
    ld  [a_lock], a                  ;  limpia el lock del botón

.bucle_principal:
    call mover_jugador   
    call mover_balas    
    ;call ecs_update_enemies     ; <<--- añadir esto
             

    call leer_botones                ;   A/B/Start/Select
    bit  0, a                        ;   activo a 0
    jr   nz, .A_no_pulsado

    ld   a, [a_lock]                 ;  evita auto-repetición
    or   a
    jr   nz, .no_disparo

    ld   a, [disparo_cd]             ;  aplica cooldown
    or   a
    jr   nz, .bloquear

    call crear_bala_desde_jugador ;  crea una bala
    ld   a, COOLDOWN_DISPARO
    ld  [disparo_cd], a

.bloquear:
    ld   a, 1
    ld  [a_lock], a
    jr   .no_disparo

.A_no_pulsado:
    xor  a
    ld  [a_lock], a                  ;  libera el lock al soltar A

.no_disparo:
    ld   a, [disparo_cd]             ;  decrementa cooldown
    or   a
    jr   z, .continuar
    dec  a
    ld  [disparo_cd], a

.continuar:
    jr .bucle_principal

    di
    halt
    ret
