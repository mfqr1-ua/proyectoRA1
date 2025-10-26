SECTION "Balas Code", ROM0

DEF SPEED_BALAS EQU 2           ; velocidad (más bajo = más rápido)
DEF TILE_BALA   EQU $01         

crear_bala_desde_jugador:       
    ld   a, [next_free_entity]  
    cp   40                     ;  comprueba si llegó al final 
    jr   nz, .puntero_ok        ; si no llegó, salto a puntero_ok
    ld   a, 4                   ;  vuelve al primer slot de bala 
    ld  [next_free_entity], a   ;  guarda el nuevo puntero envuelto
.puntero_ok:

    ld   a, [$C000]             ;  carga x 
    ld   e, a                   ;  pone x en E
    ld   a, [$C001]             ;  carga y 
    ld   d, a                   ;  pone y en D

    inc  e                      ; centra la bala en el tile centro

    dec  d                      ;  sube la bala 1 celda (y-1)
    bit  7, d                   ;  comprueba si bajó de 0 (FF)
    jr   z, .y_valida           ;  si no bajó, salto a y_valida
    ld   d, 0                  
.y_valida:

    call man_entity_alloc       ;  reserva un slot para la bala 

    ld   a, e                  
    ld  [hl+], a
    ld   a, d                  
    ld  [hl+], a
    ld   a, TILE_BALA           
    ld  [hl+], a
    xor  a                     
    ld  [hl], a

    push de                     ; pinta la bala en el BG en (x,y)
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    ld   a, TILE_BALA
    ld  [hl], a
    pop  de

    ;sonido ilyas
    ld a, %01000000     ; Forma de onda: 25% Duty Cycle
    ld [$FF16], a       ; NR21 - Control de longitud y forma de onda
    ld a, %11110010     ; Volumen inicial 15, dirección decreciente, duración 2
    ld [$FF17], a       ; NR22 - Control de envolvente de volumen
    ld a, $C3           ; Frecuencia baja (ajusta para cambiar el tono)
    ld [$FF18], a       ; NR23 - Frecuencia baja
    ld a, %10000110     ; Iniciar sonido (Bit 7=1), sin control de duración (Bit 6=0), Frecuencia alta (Bits 2-0 = %110)
    ld [$FF19], a  
    ret

mover_balas:
    ; Revisar colisiones (ahora con sistema simplificado)
    call revisar_colisiones_balas_enemigos
    
    ld   a, [next_free_entity]  ; comprueba si solo está el jugador 
    cp   4
    ret  c                      ; si no hay balas, sale

    ld   a, [balas_tick]        ;  acumula ticks para la velocidad
    inc  a
    ld  [balas_tick], a
    cp   SPEED_BALAS
    ret  c                      ; si no llegó al umbral, sale
    xor  a
    ld  [balas_tick], a         ;  resetea el tick

    ld   a, [next_free_entity]  
    ld   b, a                   ; B = límite
    cp   4
    jr   nz, .limite_ok         ; si no acaba de envolver, sigue
    ld   b, 40                  ; si acaba de envolver, procesa 4..40 este frame
.limite_ok:

    ld   c, 4                   ; inicia en el primer slot de bala (offset 4)
.primer_tramo_loop:
    ld   a, c
    cp   b
    jr   z, .tras_primer_tramo  ; si llegó al límite, pasa al siguiente tramo

    ld   h, $C0                 ; HL = $C000 + C
    ld   l, c

    ld   a, [hl]                ;  lee x
    ld   e, a
    inc  hl
    ld   a, [hl]                ;  lee y
    ld   d, a

    push bc
    push hl
    push de
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    xor  a
    ld   [hl], a                ;  borra el tile anterior en BG
    pop  de
    pop  hl

    ld   a, d
    or   a
    jr   nz, .no_en_borde_1     ; si y>0, sigue
    dec  hl                     ; HL vuelve a X del slot
    xor  a
    ld  [hl+], a                ; X = 0
    ld  [hl+], a                ; Y = 0
    ld  [hl+], a                ; TILE = 0
    ld  [hl],  a                ; ATTR = 0
    pop  bc
    jr   .avanzar_slot_1        ;  pasa al siguiente slot

.no_en_borde_1:
    dec  a
    ld   d, a
    ld  [hl], d                 ;  guarda y-1 en el slot

    push de
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    ld   a, TILE_BALA
    ld  [hl], a                 ;  pinta la bala en la nueva celda
    pop  de

    pop  bc

.avanzar_slot_1:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .primer_tramo_loop

.tras_primer_tramo:
    ld   a, b
    cp   40
    ret  z                      ; si B == 40 no hay cola que procesar

    ld   c, b                   ; esto empieza el escaneo de la cola [B..40)
.escanear_cola:
    ld   a, c
    cp   40
    jr   z, .no_hay_cola        ; si llegó al final, no hay cola

    ld   h, $C0                 ; HL = $C000 + C
    ld   l, c
    inc  hl
    inc  hl
    ld   a, [hl]                ;  lee TILE del slot
    or   a
    jr   nz, .procesar_cola     ; si hay tile != 0, hay cola activa

    ld   a, c
    add  a, 4
    ld   c, a
    jr   .escanear_cola

.no_hay_cola:
    ret

.procesar_cola:
    ld   c, b                   ;  procesa desde B hasta 40
.segundo_tramo_loop:
    ld   a, c
    cp   40
    ret  z

    ld   h, $C0                 ; HL = $C000 + C
    ld   l, c

    ld   a, [hl]                
    ld   e, a
    inc  hl
    ld   a, [hl]               
    ld   d, a

    push bc
    push hl
    push de
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    xor  a
    ld   [hl], a                ;  borra el tile anterior en BG
    pop  de
    pop  hl

    ld   a, d
    or   a
    jr   nz, .no_en_borde_2     ; si y>0, sigue
    dec  hl
    xor  a
    ld  [hl+], a
    ld  [hl+], a
    ld  [hl+], a
    ld  [hl],  a
    pop  bc
    jr   .avanzar_slot_2

.no_en_borde_2:
    dec  a
    ld   d, a
    ld  [hl], d                 ;  guarda y-1 en el slot

    push de
    call calcular_direccion_bg_desde_xy
    call wait_vblank
    ld   a, TILE_BALA
    ld  [hl], a                 ;  pinta la bala en la nueva celda
    pop  de

    pop  bc

.avanzar_slot_2:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .segundo_tramo_loop
