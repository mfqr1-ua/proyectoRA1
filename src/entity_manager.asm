SECTION "EM Data", WRAM0[$C000]
component_sprite:      ds 160    ; 40 entidades × 4 bytes = 160 bytes
num_entities_alive:    ds 1      ; guarda cuántas entidades hay vivas
next_free_entity:      ds 1      ; guarda el offset del siguiente slot libre 

SECTION "EM Code", ROM0

man_entity_init:
    ld   hl, component_sprite    
    ld   b,  160                 ; 160 bytes
    xor  a                       
    call memset_256              ; limpia los 160 bytes de la tabla
    xor  a                       
    ld  [next_free_entity], a    
    ld  [num_entities_alive], a  
    ret

man_entity_alloc:
    ld   a, [next_free_entity]   ; carga el offset del siguiente slot libre
    cp   160                     ; Verificar límite (40 slots × 4 bytes)
    jr   c, .within_limit
    xor  a                       ; Si pasó el límite, volver al inicio
.within_limit:
    ld   h, $C0                 
    ld   l, a                    ; hace HL = $C000 + offset (apunta al slot libre)
    add  a, 4                    ; suma 4 bytes
    ld  [next_free_entity], a    ; guarda el nuevo offset libre
    ld   a, [num_entities_alive] 
    inc  a                       ; incrementa el número de entidades
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
