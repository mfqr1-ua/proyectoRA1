INCLUDE "constantes.inc"

SECTION "Main Code", ROM0

main:
    call borrarLogo
    call man_entity_init
    call ecs_init_player
    call dibujaJugador
    
    
    call wait_vblank

.loop:
    ; (si tienes cosas de balas/cooldown, déjalas)
    call mover_jugador_con_entidad

jr   .loop
di 
halt
   
   