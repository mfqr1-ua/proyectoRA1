;; ======================================================================
;; ENEMIGOS.ASM - Sistema de enemigos usando ECS (como balas.asm)
;; ======================================================================

SECTION "Enemigos Data", WRAM0[$C030]
enemy_move_timer:      ds 1      ; Timer para movimiento lento de enemigos
enemy_spawn_timer:     ds 1      ; Timer para crear nuevos enemigos

SECTION "Enemigos Code", ROM0

DEF TILE_ENEMIGO EQU $19         ; Tile que usan los enemigos
DEF ATTR_ENEMIGO EQU $01         ; Atributo para identificar enemigos en ECS

;; ======================================================================
;; init_enemigos: Inicializar sistema de enemigos
;; ======================================================================
init_enemigos:
    ; Inicializar timers
    ld   a, 120                  ; Timer de movimiento (120 frames = 2 segundos, más lento)
    ld   [enemy_move_timer], a
    
    ld   a, 240                  ; Timer de spawn inicial (4 segundos)
    ld   [enemy_spawn_timer], a
    
    ; Crear 3 enemigos iniciales
    ld   e, 3                    ; X = 3
    ld   d, 3                    ; Y = 3
    call crear_enemigo
    
    ld   e, 9                    ; X = 9 
    ld   d, 5                    ; Y = 5
    call crear_enemigo
    
    ld   e, 15                   ; X = 15
    ld   d, 7                    ; Y = 7
    call crear_enemigo
    
    ret

;; ======================================================================
;; crear_enemigo: Crear un enemigo en posición E,D
;; Entrada: E = X, D = Y
;; ======================================================================
crear_enemigo:
    call man_entity_alloc        ; Reservar slot en el ECS
    
    ld   a, e                    ; X del enemigo
    ld  [hl+], a                
    ld   a, d                    ; Y del enemigo
    ld  [hl+], a                 
    ld   a, TILE_ENEMIGO         ; Tile del enemigo
    ld  [hl+], a                 
    ld   a, ATTR_ENEMIGO         ; Atributos (flag para identificar como enemigo)
    ld  [hl], a                  
    
    ret

;; ======================================================================
;; spawn_enemigo_aleatorio: Crear un enemigo en posición aleatoria arriba
;; ======================================================================
spawn_enemigo_aleatorio:
    ; Verificar cuántos enemigos hay vivos
    call contar_enemigos_vivos
    cp   3                       ; ¿Ya hay 3 enemigos?
    ret  nc                      ; Sí -> no crear más
    
    ; Generar posición X aleatoria (0-17 para que quepa enemigo de 2 tiles)
    ld   a, [$FF04]              ; Usar timer del sistema como random
    and  $0F                     ; 0-15
    cp   18                      ; ¿Es >= 18?
    jr   c, .valid_x             ; No -> válida
    ld   a, 17                   ; Sí -> usar 17 (máximo)
.valid_x:
    ld   e, a                    ; X en E
    ld   d, 1                    ; Y = 1 (parte superior)
    
    call crear_enemigo
    ret

;; ======================================================================
;; update_enemigos: Actualizar todos los enemigos
;; ======================================================================
update_enemigos:
    ; Actualizar timer de movimiento
    ld   a, [enemy_move_timer]
    dec  a
    ld   [enemy_move_timer], a
    jr   nz, .check_spawn        ; Si timer > 0, no mover este frame
    
    ; Resetear timer de movimiento
    ld   a, 120                  ; Mover cada 120 frames (movimiento más lento)
    ld   [enemy_move_timer], a
    
    ; Mover todos los enemigos
    call mover_enemigos
    
.check_spawn:
    ; Actualizar timer de spawn
    ld   a, [enemy_spawn_timer]
    dec  a
    ld   [enemy_spawn_timer], a
    jr   nz, .end                ; Si timer > 0, no crear enemigo
    
    ; Resetear timer de spawn
    ld   a, 240                  ; Crear enemigo cada 4 segundos
    ld   [enemy_spawn_timer], a
    
    ; Crear nuevo enemigo
    call spawn_enemigo_aleatorio
    
.end:
    ret

;; ======================================================================
;; mover_enemigos: Mover todos los enemigos hacia abajo
;; ======================================================================
mover_enemigos:
    ld   hl, component_sprite    ; Empezar desde el principio
    ld   a, [num_entities_alive] ; Número de entidades
    ld   b, a                    ; Contador
    
.loop_entities:
    push bc
    push hl
    
    ; Saltar a atributos para ver si es enemigo
    inc  hl                      ; Saltar X
    inc  hl                      ; Saltar Y  
    inc  hl                      ; Saltar tile
    ld   a, [hl]                 ; Leer atributos
    
    cp   ATTR_ENEMIGO            ; ¿Es enemigo?
    jr   nz, .next_entity        ; No -> siguiente
    
    ; Es enemigo -> moverlo hacia abajo
    pop  hl                      ; Recuperar puntero base
    push hl
    
    inc  hl                      ; Ir a Y
    ld   a, [hl]                 ; Leer Y actual
    inc  a                       ; Y + 1 (hacia abajo)
    
    cp   18                      ; ¿Se salió de pantalla?
    jr   nc, .kill_enemy         ; Sí -> matarlo
    
    ld   [hl], a                 ; Guardar nueva Y
    jr   .next_entity
    
.kill_enemy:
    ; Marcar como muerto (X = 255)
    pop  hl                      ; Recuperar puntero base
    push hl
    ld   a, 255                  ; Marca de "muerto"
    ld   [hl], a                 ; X = 255 (fuera de pantalla)
    
.next_entity:
    pop  hl
    pop  bc
    
    ; Siguiente entidad (4 bytes)
    ld   de, 4
    add  hl, de
    dec  b
    jr   nz, .loop_entities
    
    ret

;; ======================================================================
;; draw_enemigos: Dibujar todos los enemigos vivos
;; ======================================================================
draw_enemigos:
    ld   hl, component_sprite    ; Empezar desde el principio
    ld   a, [num_entities_alive] ; Número de entidades
    ld   b, a                    ; Contador
    
.loop_entities:
    push bc
    push hl
    
    ; Leer datos de la entidad
    ld   e, [hl]                 ; E = X
    inc  hl
    ld   d, [hl]                 ; D = Y
    inc  hl
    ld   c, [hl]                 ; C = tile
    inc  hl
    ld   a, [hl]                 ; A = atributos
    
    cp   ATTR_ENEMIGO            ; ¿Es enemigo?
    jr   nz, .next_entity        ; No -> siguiente
    
    ld   a, e                    ; Verificar si está "vivo"
    cp   255                     ; ¿X = 255? (muerto)
    jr   z, .next_entity         ; Sí -> no dibujar
    
    ; Dibujar enemigo en pantalla (2x2 tiles)
    push bc
    push de
    call calcular_direccion_bg_desde_xy  ; HL = dirección en pantalla
    call wait_vblank
    pop  de
    pop  bc
    
    ; Fila superior: 2 tiles
    ld   a, c                    ; Tile del enemigo
    ld   [hl], a                 ; Tile superior izquierdo
    inc  hl
    ld   [hl], a                 ; Tile superior derecho
    
    ; Fila inferior: saltar a siguiente línea (32 bytes - 1 = 31)
    ld   bc, 31
    add  hl, bc
    
    ld   a, TILE_ENEMIGO         ; Tile del enemigo
    ld   [hl], a                 ; Tile inferior izquierdo
    inc  hl
    ld   [hl], a                 ; Tile inferior derecho
    
.next_entity:
    pop  hl
    pop  bc
    
    ; Siguiente entidad
    ld   de, 4
    add  hl, de
    dec  b
    jr   nz, .loop_entities
    
    ret

;; ======================================================================
;; contar_enemigos_vivos: Contar cuántos enemigos están vivos
;; Salida: A = número de enemigos vivos
;; ======================================================================
contar_enemigos_vivos:
    ld   hl, component_sprite    ; Empezar desde el principio
    ld   a, [num_entities_alive] ; Número de entidades
    ld   b, a                    ; Contador
    ld   c, 0                    ; Contador de enemigos vivos
    
.loop_entities:
    push bc
    push hl
    
    ; Saltar a atributos para ver si es enemigo
    inc  hl                      ; Saltar X
    inc  hl                      ; Saltar Y  
    inc  hl                      ; Saltar tile
    ld   a, [hl]                 ; Leer atributos
    
    cp   ATTR_ENEMIGO            ; ¿Es enemigo?
    jr   nz, .next_entity        ; No -> siguiente
    
    ; Es enemigo -> verificar si está vivo
    pop  hl
    push hl
    ld   a, [hl]                 ; Leer X
    cp   255                     ; ¿X = 255? (muerto)
    jr   z, .next_entity         ; Sí -> no contar
    
    inc  c                       ; Contar este enemigo
    
.next_entity:
    pop  hl
    pop  bc
    
    ; Siguiente entidad (4 bytes)
    ld   de, 4
    add  hl, de
    dec  b
    jr   nz, .loop_entities
    
    ld   a, c                    ; Devolver contador
    ret
