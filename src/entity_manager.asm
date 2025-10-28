SECTION "EM Data", WRAM0[$C000]
component_sprite:      ds 160   ; array de entidades (slots de 4 bytes: X,Y,Tile,Tipo)
num_entities_alive:    ds 1     ; cuántas entidades hay en uso
next_free_entity:      ds 1     ; siguiente índice libre (múltiplo de 4)

SECTION "EM Code", ROM0

man_entity_init:
    ; deja a cero todos los slots de entidades
    ld   hl, component_sprite
    ld   b, 160
    xor  a
    call memset_256
    ; resetea contadores
    xor  a
    ld  [next_free_entity], a
    ld  [num_entities_alive], a
    ret

man_entity_alloc:
    ; usa next_free_entity como puntero de escritura
    ld   a, [next_free_entity]
    cp   160
    jr   c, .within_limit       ; si se pasó del final, vuelve a 0
    xor  a
.within_limit:
    ld   h, $C0                 ; HL apunta al slot actual
    ld   l, a
    add  a, 4                   ; avanza al siguiente slot (4 bytes)
    ld  [next_free_entity], a
    ; aumenta el contador de entidades
    ld   a, [num_entities_alive]
    inc  a
    ld  [num_entities_alive], a
    ret

ecs_init_player:
    ; reserva el primer slot para el jugador
    call man_entity_alloc
    ; posición inicial del jugador
    ld   a, 9                   ; X
    ld  [hl+], a
    ld   a, 16                  ; Y
    ld  [hl+], a
    ; tile base del jugador
    ld   a, $20
    ld  [hl+], a
    ; tipo/flags (0)
    xor  a
    ld  [hl], a
    ret
