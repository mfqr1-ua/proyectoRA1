SECTION "Enemies Data", WRAM0
enemy_move_timer: ds 1        ; contador de frames para mover enemigos
enemy_spawn_timer: ds 1       ; contador de frames para intentar spawn

SECTION "Enemies Code", ROM0

DEF ENEMY_TL EQU $1A          ; tile superior-izquierda del enemigo (BG)
DEF ENEMY_TM EQU $1C          ; tile superior-centro
DEF ENEMY_TR EQU $1E          ; tile superior-derecha
DEF ENEMY_BL EQU $1B          ; tile inferior-izquierda
DEF ENEMY_BM EQU $1D          ; tile inferior-centro
DEF ENEMY_BR EQU $1F          ; tile inferior-derecha

DEF ATTR_ENEMIGO EQU $01      ; valor de atributo para marcar slot como enemigo

crear_enemigo_entidad:
    ; busca un slot libre en [80..159] (saltos de 4) y escribe X=E, Y=D, TILE y ATTR
    ld   c, 80
.buscar_slot:
    ld   a, c
    cp   160
    ret  z                     ; no hay huecos
    ld   h, $C0
    ld   l, c
    ld   a, [hl]               ; [slot+0] = X, si 0 consideramos libre
    or   a
    jr   z, .slot_encontrado
    ld   a, c
    add  a, 4                  ; siguiente slot
    ld   c, a
    jr   .buscar_slot
.slot_encontrado:
    ld   a, e                  ; X
    ld  [hl+], a
    ld   a, d                  ; Y
    ld  [hl+], a
    ld   a, ENEMY_TL           ; tile marcador (el dibujo 3x2 se hace aparte)
    ld  [hl+], a
    ld   a, ATTR_ENEMIGO       ; marca el slot como enemigo
    ld  [hl], a
    ret

ecs_init_enemies:
    ; inicia timers y crea 3 enemigos iniciales
    ld   a, 30
    ld  [enemy_move_timer], a  ; velocidad base
    ld   a, 50
    ld  [enemy_spawn_timer], a ; primer intento de spawn temprano
    ld   e, 6
    ld   d, 2
    call crear_enemigo_entidad
    ld   e, 9
    ld   d, 2
    call crear_enemigo_entidad
    ld   e, 12
    ld   d, 2
    call crear_enemigo_entidad
    ret

ecs_update_enemies:
    ; decrementa timer de movimiento y, si llega a 0, ajusta velocidad y mueve
    ld   a, [enemy_move_timer]
    dec  a
    ld  [enemy_move_timer], a
    jr   nz, .check_spawn
    
    ; recalcula velocidad según puntuación total (HL) y aplica mover_enemigos
    call get_score_total        ; HL = puntuación total 16-bit
    
    ; si score >= 600 -> velocidad_5
    ld   a, h
    cp   2
    jr   c, .chk450             ; H=0..1 => <600
    jr   nz, .velocidad_5       ; H>=3 => >=768 => seguro >=600
    ld   a, l                   ; H==2, comprobar parte baja
    cp   $58                    ; 512 + 0x58 = 600
    jr   nc, .velocidad_5

.chk450:
    ; si score >= 450 -> velocidad_4
    ld   a, h
    cp   1
    jr   c, .chk300             ; H=0 => <256 <450
    jr   nz, .velocidad_4       ; H>=2 => >=512 => seguro >=450
    ld   a, l                   ; H==1, comprobar parte baja
    cp   $C2                    ; 256 + 0xC2 = 450
    jr   nc, .velocidad_4

.chk300:
    ; si score >= 300 -> velocidad_3
    ld   a, h
    cp   1
    jr   c, .chk150             ; H=0 => <256 <300
    ld   a, l                   ; H==1, comprobar parte baja
    cp   $2C                    ; 256 + 0x2C = 300
    jr   nc, .velocidad_3

.chk150:
    ; si score >= 150 -> velocidad_2
    ld   a, h
    or   a
    jr   nz, .velocidad_2       ; H>=1 => >=256 => seguro >=150
    ld   a, l                   ; H==0, comprobar parte baja
    cp   $96                    ; 0x96 = 150
    jr   nc, .velocidad_2

    ; velocidad_1 (<150)
    ld   a, 30
    jr   .set_timer

.velocidad_2:
    ; 150..299
    ld   a, 20
    jr   .set_timer

.velocidad_3:
    ; 300..449
    ld   a, 12
    jr   .set_timer

.velocidad_4:
    ; 450..599
    ld   a, 8
    jr   .set_timer

.velocidad_5:
    ; >=600
    ld   a, 5

.set_timer:
    ; fija el nuevo periodo y mueve un paso
    ld  [enemy_move_timer], a
    call mover_enemigos

.check_spawn:
    ; gestiona temporizador de spawn y crea si toca
    ld   a, [enemy_spawn_timer]
    dec  a
    ld  [enemy_spawn_timer], a
    jr   nz, .end
    ld   a, 240
    ld  [enemy_spawn_timer], a
    call spawn_enemigo_si_falta
.end:
    ret

mover_enemigos:
    ; recorre slots enemigo; borra en BG, incrementa Y y mata si sale de pantalla
    ld   c, 80
.loop_slots:
    ld   a, c
    cp   160
    ret  z
    ld   h, $C0
    ld   l, c
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    cp   ATTR_ENEMIGO           ; validar que sea enemigo
    jr   nz, .next_slot
    dec  hl
    dec  hl
    dec  hl
    ld   a, [hl]                ; X
    or   a
    jr   z, .next_slot          ; X==0 => libre
    ld   e, a
    inc  hl
    ld   a, [hl]                ; Y
    ld   d, a
    push bc
    push hl
    call borrar_bloque_3x2_desde_xy  ; borra 3x2 en BG en (E,D)
    pop  hl
    pop  bc
    ld   a, [hl]                ; Y
    inc  a                      ; baja una fila
    cp   18                     ; límite visible de filas BG
    jr   nc, .kill_enemy
    ld   [hl], a                ; guarda nueva Y
    jr   .next_slot
.kill_enemy:
    ; libera slot (pone a cero sus 4 bytes)
    dec  hl
    xor  a
    ld   [hl+], a               ; X=0
    ld   [hl+], a               ; Y=0
    ld   [hl+], a               ; TILE=0
    ld   [hl], a                ; ATTR=0
.next_slot:
    ld   a, c
    add  a, 4                   ; siguiente slot
    ld   c, a
    jr   .loop_slots

spawn_enemigo_si_falta:
    ; mantiene hasta 3 enemigos vivos; usa DIV para pseudo-azar en X
    call contar_enemigos_vivos
    cp   3
    ret  nc
.spawn_loop:
    call contar_enemigos_vivos
    cp   3
    ret  nc
    ld   a, [$FF04]             ; registro DIV
    and  $0F
    cp   13
    jr   c, .check_pos
    sub  4
.check_pos:
    ld   e, a                   ; X candidata
    call verificar_posicion_libre
    jr   nz, .valid_x           ; si no hay conflicto, crear
    ld   a, e
    add  a, 4                   ; intenta 4 tiles a la derecha
    cp   16
    jr   c, .check_pos2
    ld   e, 2                   ; si se pasa, usa X=2
    jr   .valid_x
.check_pos2:
    ld   e, a
.valid_x:
    ld   d, 1                   ; Y inicial
    call crear_enemigo_entidad
    jr   .spawn_loop

verificar_posicion_libre:
    ; entrada: E=X candidata. salida: Z=0 si libre, Z=1 si muy cerca
    ld   c, 80
.loop_slots:
    ld   a, c
    cp   160
    jr   z, .pos_libre
    ld   h, $C0
    ld   l, c
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    cp   ATTR_ENEMIGO
    pop  hl
    jr   nz, .next_slot
    ld   a, [hl]                ; X enemigo
    or   a
    jr   z, .next_slot
    ld   b, a
    ld   a, e                   ; X candidata
    cp   b
    jr   c, .calc_dist_1
    sub  b
    jr   .check_dist
.calc_dist_1:
    ld   a, b
    sub  e
.check_dist:
    cp   4                      ; distancia minima 4 tiles
    jr   c, .pos_ocupada
.next_slot:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .loop_slots
.pos_libre:
    xor  a                      ; Z=0 (libre)
    ret
.pos_ocupada:
    xor  a
    inc  a                      ; Z=1 (ocupada)
    ret

contar_enemigos_vivos:
    ; cuenta slots con ATTR_ENEMIGO y X!=0, devuelve A
    ld   b, 0
    ld   c, 80
.loop_slots:
    ld   a, c
    cp   160
    jr   z, .done
    ld   h, $C0
    ld   l, c
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    cp   ATTR_ENEMIGO
    jr   nz, .next_slot
    dec  hl
    dec  hl
    dec  hl
    ld   a, [hl]                ; X
    or   a
    jr   z, .next_slot
    inc  b
.next_slot:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .loop_slots
.done:
    ld   a, b
    ret

draw_enemigos:
    ; pinta cada enemigo activo como bloque 3x2 en BG
    ld   c, 80
.loop_slots:
    ld   a, c
    cp   160
    ret  z
    ld   h, $C0
    ld   l, c
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    cp   ATTR_ENEMIGO
    pop  hl
    jr   nz, .next_slot
    ld   a, [hl]                ; X
    or   a
    jr   z, .next_slot
    ld   e, a
    inc  hl
    ld   a, [hl]                ; Y
    ld   d, a
    dec  hl
    push bc
    push hl
    call pintar_enemigo_3x2
    pop  hl
    pop  bc
.next_slot:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .loop_slots

pintar_enemigo_3x2:
    ; escribe los 6 tiles del enemigo en el BG respetando el VBlank
    push de
    call wait_vblank
    call calcular_direccion_bg_desde_xy
    ld   a, ENEMY_TL
    ld  [hl+], a
    ld   a, ENEMY_TM
    ld  [hl+], a
    ld   a, ENEMY_TR
    ld  [hl], a
    pop  de
    inc  d
    push de
    call wait_vblank
    call calcular_direccion_bg_desde_xy
    ld   a, ENEMY_BL
    ld  [hl+], a
    ld   a, ENEMY_BM
    ld  [hl+], a
    ld   a, ENEMY_BR
    ld  [hl], a
    pop  de
    ret

get_enemy_position_by_slot:
    ; si slot C es enemigo activo, devuelve E=X, D=Y y A=1; si no, A=0
    ld   h, $C0
    ld   l, c
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    cp   ATTR_ENEMIGO
    pop  hl
    jr   nz, .not_enemy
    ld   a, [hl]                ; X
    or   a
    ret  z
    ld   e, a
    inc  hl
    ld   a, [hl]                ; Y
    ld   d, a
    xor  a
    inc  a                      ; A=1
    ret
.not_enemy:
    xor  a                      ; A=0
    ret

eliminar_enemigo_por_slot:
    ; limpia slot y borra el bloque 3x2 en BG en su posición
    call get_enemy_position_by_slot
    ret  z
    push de
    ld   h, $C0
    ld   l, c
    xor  a
    ld   [hl+], a               ; X=0
    ld   [hl+], a               ; Y=0
    ld   [hl+], a               ; TILE=0
    ld   [hl], a                ; ATTR=0
    pop  de
    call borrar_bloque_3x2_desde_xy
    ret
