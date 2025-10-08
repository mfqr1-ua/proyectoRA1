; ============================
; Entity Manager + draw (sin constantes)
; Layout slot sprite (4 bytes): x, y, tile, attrs
; Tabla en $C000 con 10 entidades -> 40 bytes
; ============================

SECTION "EM Data", WRAM0[$C000]
component_sprite:      ds 40     ; $C000..$C027
num_entities_alive:    ds 1      ; $C028
next_free_entity:      ds 1      ; $C029

SECTION "EM Code", ROM0


; Inicializa tabla y contadores a 0
man_entity_init:
    ld   hl, component_sprite
    ld   b,  40
    xor  a
    call memset_256
    xor  a
    ld  [next_free_entity], a   ; offset=0
    ld  [num_entities_alive], a ; 0 entidades
    ret

; Reserva slot: HL = $C000 + offset; offset += 4; ++alive
man_entity_alloc:
    ld   a, [next_free_entity]  ; A = offset (0,4,8,...)
    ld   h, $C0
    ld   l, a                   ; HL = $C000 + offset
    add  a, 4                   ; siguiente offset
    ld  [next_free_entity], a
    ld   a, [num_entities_alive]
    inc  a
    ld  [num_entities_alive], a
    ret                         ; HL apunta al slot libre

; Crea player en el primer slot: x=9, y=16, tile=$19, attrs=0
ecs_init_player:
    call man_entity_alloc       ; HL = puntero al slot 0
    ld   a, 9
    ld  [hl+], a                ; x
    ld   a, 16
    ld  [hl+], a                ; y
    ld   a, $19
    ld  [hl+], a                ; tile
    xor  a
    ld  [hl], a                 ; attrs
    ret

; ----------------------------------------------------------

