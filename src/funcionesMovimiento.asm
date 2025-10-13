INCLUDE "constantes.inc"

SECTION "funcionesMovimiento", ROM0

calcular_direccion_bg_desde_xy:
    push de                 ;  guarda (y,x)
    ld   hl, $9800          ;  carga base del BG map
    ld   a, d               
    ld   b, 0
    ld   c, 32             
.loop_filas:
    or   a                  ; comprueba si y==0
    jr   z, .filas_ok       
    add  hl, bc             ; siguiente fila
    dec  a                  ; decrementa y
    jr   .loop_filas        ; repite mientras queden filas
.filas_ok:
    pop  de                 ; recupera (y,x)
    ld   a, e               
    ld   b, 0
    ld   c, a               
    add  hl, bc             
    ret


;  lee x,y del slot0 en E,D
leer_slot0_xy:
    ld   hl, $C000          ;  apunta al slot0
    ld   e, [hl]            ;  lee x en E
    inc  hl
    ld   d, [hl]            ;  lee y en D
    ret


;  escribe E en slot0.x
escribir_slot0_x:
    ld   hl, $C000          
    ld   [hl], e            ;  guarda x
    ret

mover_jugador:
    call read_dpad         

    bit  0, a               
    jr   nz, .comprobar_izquierda ; si no pulsa derecha, salta a izquierda

    call leer_slot0_xy      ; pone E=x, D=y del jugador

    push de
    call borrar_bloque_3x2_desde_xy ; borra el bloque actual 3x2
    pop  de

    inc  e                  
    ld   a, e
    cp   30                 
    jr   c, .x_der_ok       ;si x<30, salta a x_der_ok
    ld   e, 29              ; satura a 29 (3 tiles de ancho)
.x_der_ok:
    call escribir_slot0_x  

    push de
    ld   a, [$C002]         ;  carga el tile base (TL) del bloque
    call pintar_bloque_3x2_desde_xy_con_base ;  pinta el bloque 3x2 en la nueva posición
    pop  de

.esperar_soltar_derecha:
    call read_dpad          ; espera a soltar derecha
    bit  0, a
    jr   z, .esperar_soltar_derecha
    ret

.comprobar_izquierda:
    bit  1, a               ; comprueba izquierda (activo a 0)
    ret  nz                 ; si no pulsa izquierda, sale

    call leer_slot0_xy      ; pone E=x, D=y del jugador

    push de
    call borrar_bloque_3x2_desde_xy ; borra el bloque actual 3x2
    pop  de

    dec  e                  
    bit  7, e                ;comprueba si bajó de 0 (FF)
    jr   z, .x_izq_ok       ; si no bajó, salta a x_izq_ok
    ld   e, 0              
.x_izq_ok:
    call escribir_slot0_x   
    push de
    ld   a, [$C002]         ;
    call pintar_bloque_3x2_desde_xy_con_base ; pinta el bloque 3x2 en la nueva posición
    pop  de

.esperar_soltar_izquierda:
    call read_dpad          ; espera a soltar izquierda
    bit  1, a
    jr   z, .esperar_soltar_izquierda
    ret
