INCLUDE "constantes.inc"

SECTION "funcionesMovimiento", ROM0

calcular_direccion_bg_desde_xy:
    ; recibe D=Y, E=X y devuelve HL apuntando al tile del BG en (X,Y)
    push de
    ld   hl, $9800             ; inicio del mapa de BG
    ld   a, d                  ; Y
    ld   b, 0
    ld   c, 32                 ; ancho de una fila en tiles
.loop_filas:
    or   a
    jr   z, .filas_ok          ; cuando Y llega a 0, estamos en la fila
    add  hl, bc                ; bajar una fila
    dec  a
    jr   .loop_filas
.filas_ok:
    pop  de
    ld   a, e                  ; X
    ld   b, 0
    ld   c, a
    add  hl, bc                ; moverse X columnas
    ret

leer_slot0_xy:
    ; devuelve en DE la posición del jugador del slot 0 (X en E, Y en D)
    ld   hl, $C000             ; slot 0
    ld   e, [hl]               ; X
    inc  hl
    ld   d, [hl]               ; Y
    ret

escribir_slot0_x:
    ; escribe E como nueva X del jugador en el slot 0
    ld   hl, $C000
    ld   [hl], e
    ret

mover_jugador:
    ; mueve el jugador a derecha o izquierda y repinta su bloque 3x2
    call read_dpad
    bit  0, a                  ; derecha?
    jr   nz, .comprobar_izquierda

    ; mover a la derecha
    call leer_slot0_xy
    push de
    call borrar_bloque_3x2_desde_xy   ; borra dibujo actual
    pop  de
    inc  e                           ; X = X + 1
    ld   a, e
    cp   17                          ; límite derecho
    jr   c, .x_der_ok
    ld   e, 17
.x_der_ok:
    call escribir_slot0_x            ; guarda nueva X
    push de
    ld   a, [$C002]                  ; tile base del jugador
    call pintar_bloque_3x2_desde_xy_con_base
    pop  de
    ret

.comprobar_izquierda:
    bit  1, a                  ; izquierda?
    ret  nz                    ; si no hay izquierda, no se mueve

    ; mover a la izquierda
    call leer_slot0_xy
    push de
    call borrar_bloque_3x2_desde_xy   ; borra dibujo actual
    pop  de
    dec  e                           ; X = X - 1
    bit  7, e                        ; ¿pasó por debajo de 0?
    jr   z, .x_izq_ok
    ld   e, 0
.x_izq_ok:
    call escribir_slot0_x            ; guarda nueva X
    push de
    ld   a, [$C002]                  ; tile base del jugador
    call pintar_bloque_3x2_desde_xy_con_base
    pop  de
ret
