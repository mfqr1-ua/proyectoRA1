; enemies.asm - Sistema de enemigos usando ECS (entidades dinámicas 3x2)

SECTION "Enemies Data", WRAM0
enemy_move_timer: ds 1      ; Timer para movimiento lento
enemy_spawn_timer: ds 1     ; Timer para reaparecer enemigos

SECTION "Enemies Code", ROM0

; Tiles de los enemigos (sprite 3x2)
DEF ENEMY_TL EQU $1A    ; top-left
DEF ENEMY_TM EQU $1C    ; top-middle
DEF ENEMY_TR EQU $1E    ; top-right
DEF ENEMY_BL EQU $1B    ; bottom-left
DEF ENEMY_BM EQU $1D    ; bottom-middle
DEF ENEMY_BR EQU $1F    ; bottom-right

; Atributo para identificar enemigos en el ECS (diferente de balas)
DEF ATTR_ENEMIGO EQU $01

; ------------------------------------------------------------
; crear_enemigo_entidad: Crear enemigo como entidad en ECS
; E = x, D = y
; ------------------------------------------------------------
crear_enemigo_entidad:
    call man_entity_alloc
    
    ld   a, e
    ld  [hl+], a                ; X
    ld   a, d
    ld  [hl+], a                ; Y
    ld   a, ENEMY_TL            ; Usamos tile TL como identificador
    ld  [hl+], a
    ld   a, ATTR_ENEMIGO        ; Marca como enemigo
    ld  [hl], a
    
    ret

; ------------------------------------------------------------
; ecs_init_enemies: Crear 3 enemigos iniciales como entidades
; ------------------------------------------------------------
ecs_init_enemies:
    ; Inicializar timers
    ld   a, 15
    ld  [enemy_move_timer], a
    ld   a, 180
    ld  [enemy_spawn_timer], a

    ; Enemigo 1 (izquierda)
    ld   e, 6
    ld   d, 2
    call crear_enemigo_entidad

    ; Enemigo 2 (centro)
    ld   e, 9
    ld   d, 2
    call crear_enemigo_entidad

    ; Enemigo 3 (derecha)
    ld   e, 12
    ld   d, 2
    call crear_enemigo_entidad

    ret

; ------------------------------------------------------------
; ecs_update_enemies: Actualizar lógica de enemigos
; ------------------------------------------------------------
ecs_update_enemies:
    ; Timer de movimiento
    ld   a, [enemy_move_timer]
    dec  a
    ld  [enemy_move_timer], a
    jr   nz, .check_spawn
    
    ld   a, 15                  ; Movimiento más rápido (similar a balas)
    ld  [enemy_move_timer], a
    call mover_enemigos
    
.check_spawn:
    ; Timer de spawn
    ld   a, [enemy_spawn_timer]
    dec  a
    ld  [enemy_spawn_timer], a
    jr   nz, .end
    
    ld   a, 180                 ; Spawn cada 3 segundos
    ld  [enemy_spawn_timer], a
    call spawn_enemigo_si_falta
    
.end:
    ret

; ------------------------------------------------------------
; mover_enemigos: Mover todos los enemigos hacia abajo
; ------------------------------------------------------------
mover_enemigos:
    ld   c, 80                  ; Empezar en slots de enemigos (80+)
.loop_slots:
    ld   a, c
    cp   160
    ret  z                      ; Llegó al final de los slots
    
    ld   h, $C0
    ld   l, c
    
    ; Verificar si es enemigo
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]                ; Leer ATTR
    cp   ATTR_ENEMIGO
    jr   nz, .next_slot
    
    ; Es enemigo, moverlo
    dec  hl
    dec  hl
    dec  hl                     ; Volver a X
    
    ld   a, [hl]
    or   a
    jr   z, .next_slot          ; Slot vacío
    
    ; Guardar posición actual para borrar del mapa
    ld   e, a                   ; E = X actual
    inc  hl
    ld   a, [hl]
    ld   d, a                   ; D = Y actual
    
    ; Borrar sprite antiguo del mapa (antes de mover)
    push bc
    push hl
    call borrar_bloque_3x2_desde_xy
    pop  hl
    pop  bc
    
    ; Mover Y
    ld   a, [hl]
    inc  a                      ; Y + 1
    
    cp   18
    jr   nc, .kill_enemy
    
    ld   [hl], a
    jr   .next_slot
    
.kill_enemy:
    dec  hl                     ; Volver a X
    xor  a
    ld   [hl+], a
    ld   [hl+], a
    ld   [hl+], a
    ld   [hl], a
    
.next_slot:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .loop_slots

; ------------------------------------------------------------
; spawn_enemigo_si_falta: Reaparecer enemigos hasta tener 3
; ------------------------------------------------------------
spawn_enemigo_si_falta:
    call contar_enemigos_vivos
    cp   3
    ret  nc                     ; Ya hay 3 o más
    
.spawn_loop:
    call contar_enemigos_vivos
    cp   3
    ret  nc
    
    ; Crear enemigo en posición aleatoria
    ld   a, [$FF04]             ; Random del timer
    and  $0F                    ; 0-15
    cp   15
    jr   c, .valid_x
    ld   a, 7
.valid_x:
    ld   e, a
    ld   d, 1                   ; Fila 1 (arriba)
    call crear_enemigo_entidad
    
    jr   .spawn_loop

; ------------------------------------------------------------
; contar_enemigos_vivos: Cuenta enemigos activos
; Salida: A = número de enemigos
; ------------------------------------------------------------
contar_enemigos_vivos:
    ld   b, 0                   ; Contador
    ld   c, 80                  ; Slots de enemigos
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
    ld   a, [hl]
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

; ------------------------------------------------------------
; draw_enemigos: Dibujar todos los enemigos (sprite 3x2)
; ------------------------------------------------------------
draw_enemigos:
    ld   c, 80                  ; Slots de enemigos
.loop_slots:
    ld   a, c
    cp   160
    ret  z
    
    ld   h, $C0
    ld   l, c
    
    ; Verificar si es enemigo
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    cp   ATTR_ENEMIGO
    pop  hl
    jr   nz, .next_slot
    
    ; Leer X,Y
    ld   a, [hl]
    or   a
    jr   z, .next_slot
    ld   e, a
    inc  hl
    ld   a, [hl]
    ld   d, a
    dec  hl
    
    ; Dibujar sprite 3x2
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

; ------------------------------------------------------------
; pintar_enemigo_3x2: Dibuja un enemigo 3x2 en el mapa
; E = x (columna), D = y (fila)
; ------------------------------------------------------------
pintar_enemigo_3x2:
    ; Calcular dirección del tilemap
    push de
    call wait_vblank
    call calcular_direccion_bg_desde_xy
    
    ; Fila superior
    ld   a, ENEMY_TL
    ld  [hl+], a
    ld   a, ENEMY_TM
    ld  [hl+], a
    ld   a, ENEMY_TR
    ld  [hl], a
    pop  de

    ; Fila inferior (y+1)
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

; ------------------------------------------------------------
; get_enemy_position_by_slot: Obtiene posición de enemigo por slot
; C = slot (debe ser múltiplo de 4)
; Salida: E = x, D = y, Z flag si no es enemigo
; ------------------------------------------------------------
get_enemy_position_by_slot:
    ld   h, $C0
    ld   l, c
    
    ; Verificar ATTR
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    cp   ATTR_ENEMIGO
    pop  hl
    jr   nz, .not_enemy
    
    ; Leer X
    ld   a, [hl]
    or   a
    ret  z                      ; Z flag si está vacío
    ld   e, a
    
    ; Leer Y
    inc  hl
    ld   a, [hl]
    ld   d, a
    
    xor  a
    inc  a                      ; Clear Z flag
    ret
    
.not_enemy:
    xor  a                      ; Set Z flag
    ret

; ------------------------------------------------------------
; eliminar_enemigo_por_slot: Elimina un enemigo del ECS y del mapa
; C = slot del enemigo
; ------------------------------------------------------------
eliminar_enemigo_por_slot:
    ; Primero obtener posición para borrar del mapa
    call get_enemy_position_by_slot
    ret  z                      ; No existe
    
    ; E=x, D=y guardarlos
    push de
    
    ; Limpiar slot en ECS
    ld   h, $C0
    ld   l, c
    xor  a
    ld   [hl+], a
    ld   [hl+], a
    ld   [hl+], a
    ld   [hl], a
    
    ; Borrar del mapa
    pop  de
    call borrar_bloque_3x2_desde_xy
    
    ret
