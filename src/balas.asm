SECTION "Balas Code", ROM0

; ========= velocidad (frames entre pasos) =========
DEF SPEED_BALAS EQU 1000

; --------- crear bala desde el player ----------
crear_bala_entidad_desde_player:
    ; si estamos en 40, volver a 4 (slot 1) ---
    ld   a, [next_free_entity]
    cp   40
    jr   nz, .ptr_ok
    ld   a, 4
    ld  [next_free_entity], a
.ptr_ok:

    ; pos del player (slot 0)
    ld   a, [$C000]                ; x
    ld   e, a
    ld   a, [$C001]                ; y
    ld   d, a

    ; spawn justo encima: y = max(y-1, 0)
    dec  d
    bit  7, d
    jr   z, .yok
    ld   d, 0
.yok:

    ; reservar slot para bala
    call man_entity_alloc          ; HL -> slot nuevo (x,y,tile,attrs)

    ; escribir bala en el slot
    ld   a, e
    ld  [hl+], a                   ; x
    ld   a, d
    ld  [hl+], a                   ; y
    ld   a, $19
    ld  [hl+], a                   ; tile
    xor  a
    ld  [hl], a                    ; attrs=0

    ; pintar bala en BG
    push de
    call calcular_hl_bg_desde_de
    call wait_vblank
    ld   a, $19
    ld  [hl], a
    pop  de
    ret


; Recorre 4..B. Si hay balas activas en la cola B..40, procesa también ese tramo.
mover_balas:
    ld   a, [next_free_entity]
    cp   4
    ret  c

    ld   a, [balas_tick]
    inc  a
    ld  [balas_tick], a
    cp   SPEED_BALAS
    ret  c
    xor  a
    ld  [balas_tick], a

    ; snapshot del límite (para no cambiar si se crean balas este frame)
    ld   a, [next_free_entity]
    ld   b, a                      ; B = end_off (en bytes desde $C000)
    ; FIX puntual: si justo ha hecho wrap a 4, este frame procesamos 4..40
    cp   4
    jr   nz, .b_ok
    ld   b, 40
.b_ok:

    ; ---------- PRIMER TRAMO: 4 .. B ----------
    ld   c, 4
.loop_slots_1:
    ld   a, c
    cp   b
    jr   z, .after_first

    ; HL = $C000 + C
    ld   h, $C0
    ld   l, c

    ; leer x, y
    ld   a, [hl]                   ; x
    ld   e, a
    inc  hl
    ld   a, [hl]                   ; y
    ld   d, a

    ; borrar tile viejo en (D,E)
    push bc
    push hl                        ; HL -> Y del slot
    push de
    call calcular_hl_bg_desde_de
    call wait_vblank
    xor  a
    ld   [hl], a                   ; limpia BG en la posición anterior
    pop  de
    pop  hl                        ; HL -> Y del slot

    ; ¿tope superior?
    ld   a, d
    or   a
    jr   nz, .no_top_row_1

    ; y==0: vaciar slot
    dec  hl                        ; HL -> X
    xor  a
    ld  [hl+], a                   ; X = 0
    ld  [hl+], a                   ; Y = 0
    ld  [hl+], a                   ; TILE = 0
    ld  [hl],  a                   ; ATTR = 0

    pop  bc
    jr   .next_slot_1

.no_top_row_1:
    ; y > 0: y = y-1 y redibujar
    dec  a
    ld   d, a
    ld  [hl], d

    push de
    call calcular_hl_bg_desde_de
    call wait_vblank
    ld   a, $19
    ld  [hl], a
    pop  de

    pop  bc

.next_slot_1:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .loop_slots_1

.after_first:
    ; ---------- DETECCIÓN DE COLA (B .. 40) ----------
    ; Si hay alguna bala activa en [B..40), procesamos ese tramo.
    ld   a, b
    cp   40
    ret  z                         ; si B==40, no hay cola

    ; scan rápido: ¿existe tile != 0 en B..40?
    ld   c, b
.scan_tail:
    ld   a, c
    cp   40
    jr   z, .no_tail               ; no hay nada en la cola

    ; HL = $C000 + C
    ld   h, $C0
    ld   l, c
    inc  hl                        ; -> Y
    inc  hl                        ; -> TILE
    ld   a, [hl]                   ; A = tile
    or   a
    jr   nz, .do_tail              ; hay una bala activa en la cola

    ; siguiente slot
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .scan_tail

.no_tail:
    ret

.do_tail:
    ; SEGUNDO TRAMO: B .. 40 
    ld   c, b
.loop_slots_2:
    ld   a, c
    cp   40
    ret  z

    ; HL = $C000 + C
    ld   h, $C0
    ld   l, c

    ; leer x, y
    ld   a, [hl]                   ; x
    ld   e, a
    inc  hl
    ld   a, [hl]                   ; y
    ld   d, a

    ; borrar tile viejo en (D,E)
    push bc
    push hl                        ; HL -> Y del slot
    push de
    call calcular_hl_bg_desde_de
    call wait_vblank
    xor  a
    ld   [hl], a
    pop  de
    pop  hl

    ; ¿tope superior?
    ld   a, d
    or   a
    jr   nz, .no_top_row_2

    ; y==0: vaciar slot
    dec  hl
    xor  a
    ld  [hl+], a
    ld  [hl+], a
    ld  [hl+], a
    ld  [hl],  a

    pop  bc
    jr   .next_slot_2

.no_top_row_2:
    dec  a
    ld   d, a
    ld  [hl], d

    push de
    call calcular_hl_bg_desde_de
    call wait_vblank
    ld   a, $19
    ld  [hl], a
    pop  de

    pop  bc

.next_slot_2:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .loop_slots_2
