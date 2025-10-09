INCLUDE "constantes.inc"

SECTION "funcionesMovimiento", ROM0


calcular_hl_bg_desde_de:
    push de                 ; guardar (y,x)
    ld   hl, $9800          ; base BG
    ld   a, d               ; A = y
    ld   b, 0
    ld   c, 32              ; BC = 32
.y_loop:
    or   a
    jr   z, .y_hecho
    add  hl, bc             ; HL += 32 por cada fila
    dec  a
    jr   .y_loop
.y_hecho:
    pop  de                 ; recuperar (y,x)
    ld   a, e               ; A = x
    ld   b, 0
    ld   c, a               ; BC = x
    add  hl, bc             ; HL += x
    ret


leer_slot0_posicion_y_tile:
    ld   hl, $C000
    ld   e, [hl]            ; x
    inc  hl
    ld   d, [hl]            ; y
    ret


escribir_slot0_x:
    ld   hl, $C000
    ld   [hl], e
    ret

mover_jugador_con_entidad:
    call read_dpad

    ; ---------- Derecha (bit0=0) ----------
    bit  0, a
    jr   nz, .comprobar_izquierda

    ; 1) Obtener (x,y) del slot
    call leer_slot0_posicion_y_tile      ; E=x, D=y

    ; 2) Borrar la celda actual
    push de
    call calcular_hl_bg_desde_de         ; HL = BG(y,x)
    call wait_vblank
    xor  a
    ld   [hl], a                         ; poner tile 0 (vacío)
    pop  de

    ; 3) x = x + 1 (con límite 31)
    inc  e
    ld   a, e
    cp   32
    jr   c, .x_ok_der
    ld   e, 31
.x_ok_der:
    call escribir_slot0_x                ; slot0.x = E

    ; 4) Pintar en la nueva celda el tile del slot
    push de
    call calcular_hl_bg_desde_de         ; HL = nueva celda
    call wait_vblank
    ld   a, [$C002]                      ; tile del slot0 (p.ej. $19)
    ld   [hl], a
    pop  de

.esperar_suelta_der:
    call read_dpad
    bit  0, a
    jr   z, .esperar_suelta_der
    ret

.comprobar_izquierda:
    ; ---------- Izquierda (bit1=0) ----------
    bit  1, a
    ret  nz

    ; 1) Obtener (x,y)
    call leer_slot0_posicion_y_tile      ; E=x, D=y

    ; 2) Borrar celda actual
    push de
    call calcular_hl_bg_desde_de
    call wait_vblank
    xor  a
    ld   [hl], a
    pop  de

    ; 3) x = x - 1 (con límite 0)
    dec  e
    bit  7, e                            ; ¿bajó de 0? (FF)
    jr   z, .x_ok_izq
    ld   e, 0
.x_ok_izq:
    call escribir_slot0_x

    ; 4) Pintar tile del slot en la nueva celda
    push de
    call calcular_hl_bg_desde_de
    call wait_vblank
    ld   a, [$C002]                      ; SIEMPRE leemos el tile del slot
    ld   [hl], a
    pop  de

.esperar_suelta_izq:
    call read_dpad
    bit  1, a
    jr   z, .esperar_suelta_izq
    ret


