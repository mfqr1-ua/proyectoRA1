
SECTION "Stars Data", ROM0
DEF STAR_TILE  EQU $28
DEF STAR_ATTR  EQU $10

; Tabla de posiciones OAM (Y, X) ya en píxeles visibles
stars_coor:
    db  20,  20
    db  28, 140
    db  44,  96
    db  36,  40
    db  60, 152
    db  72,  24
    db  88, 128
    db 104,  56
    db 116, 168   
    db 124,  88
    db 136,  12
    db  88,  88   
    db 150, 150

SECTION "Stars Code", ROM0

init_stars:
    ld   hl, $FE10              
    ld   de, stars_coor     ; DE -> tabla (Y,X)
    ld   b,  13    ; cuántas estrellas
.star_loop:
    ld   a, [de]                ; Y
    inc  de
    ld  [hl+], a
    ld   a, [de]                ; X
    inc  de
    ld  [hl+], a
    ld   a, STAR_TILE           ; TILE = $28
    ld  [hl+], a
    ld   a, STAR_ATTR           ; ATTR
    ld  [hl], a
    inc  hl                     ; salta a Y del siguiente sprite (4 bytes por sprite)

    dec  b
    jr   nz, .star_loop
    ret
