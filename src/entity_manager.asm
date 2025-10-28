SECTION "EM Data", WRAM0[$C000]
component_sprite:      ds 160
num_entities_alive:    ds 1
next_free_entity:      ds 1

SECTION "EM Code", ROM0

man_entity_init:
    ld   hl, component_sprite
    ld   b, 160
    xor  a
    call memset_256
    xor  a
    ld  [next_free_entity], a
    ld  [num_entities_alive], a
    ret

man_entity_alloc:
    ld   a, [next_free_entity]
    cp   160
    jr   c, .within_limit
    xor  a
.within_limit:
    ld   h, $C0
    ld   l, a
    add  a, 4
    ld  [next_free_entity], a
    ld   a, [num_entities_alive]
    inc  a
    ld  [num_entities_alive], a
    ret

ecs_init_player:
    call man_entity_alloc        ;  reserva el 0 para el jugador
    ld   a, 9                    ;  pone x inicial del jugador
    ld  [hl+], a                
    ld   a, 16                   ;  pone y inicial 
    ld  [hl+], a                 
    ld   a, $20                  ;  pone el tile base del jugador sa
    ld  [hl+], a                 
    xor  a                       
    ld  [hl], a                  
    ret
