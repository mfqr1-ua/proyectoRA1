;; ======================================================================
;; ENTITY.ASM - Sistema simple de enemigos para Space Invaders
;; ======================================================================

;; Variables simples del sistema
SECTION "Entity Variables", WRAM0[$C010]
enemies:            ds 12      ; Array de 3 enemigos (3*4=12 bytes)
spawn_timer:        ds 1       ; Timer para crear enemigos
random_number:      ds 1       ; Número aleatorio simple
move_timer:         ds 1       ; Timer para movimiento lento

SECTION "Entity Functions", ROM0

;; Función wait_vblank local para entity.asm
wait_vblank_entity:
    ld  a, [$FF44]          
    cp   144
    jr   c, wait_vblank_entity
    ret

;; ======================================================================
;; Estructura SIMPLE de un enemigo (4 bytes):
;; Byte 0: X position (0-19)
;; Byte 1: Y position (0-17) 
;; Byte 2: Estado (0=muerto, 1=vivo)
;; Byte 3: Velocidad Y (siempre 1 = hacia abajo)
;; ======================================================================

;; ======================================================================
;; init_enemy_system: Prepara el sistema de enemigos (SIMPLIFICADO)
;; ======================================================================
init_enemy_system:
    ; Crear 3 enemigos como Space Invaders (alejados del jugador)
    ld   hl, enemies
    
    ; Enemigo 1: X=3, Y=3 (izquierda arriba)
    ld   a, 3              ; X = 3
    ld   [hl+], a
    ld   a, 3              ; Y = 3 (lejos del jugador)
    ld   [hl+], a
    ld   a, 1              ; Estado = vivo
    ld   [hl+], a
    ld   a, 1              ; Velocidad = 1
    ld   [hl+], a
    
    ; Enemigo 2: X=9, Y=5 (centro medio)
    ld   a, 9              ; X = 9 
    ld   [hl+], a
    ld   a, 5              ; Y = 5
    ld   [hl+], a
    ld   a, 1              ; Estado = vivo
    ld   [hl+], a
    ld   a, 1              ; Velocidad = 1
    ld   [hl+], a
    
    ; Enemigo 3: X=15, Y=7 (derecha medio-bajo)
    ld   a, 15             ; X = 15
    ld   [hl+], a
    ld   a, 7              ; Y = 7
    ld   [hl+], a
    ld   a, 1              ; Estado = vivo
    ld   [hl+], a
    ld   a, 1              ; Velocidad = 1
    ld   [hl], a
    
    ; Timer inicial 
    ld   a, 120            ; 120 frames para que aparezcan nuevos enemigos
    ld   [spawn_timer], a
    
    ; Timer de movimiento inicial
    ld   a, 60             ; Mover cada 60 frames (1 segundo = movimiento lento)
    ld   [move_timer], a
    
    ; Número aleatorio inicial
    ld   a, [$FF04]        ; Usar timer del sistema
    ld   [random_number], a
    
    ret

;; ======================================================================
;; get_random_simple: Número aleatorio básico
;; Salida: A = número aleatorio (0-255)
;; ======================================================================
get_random_simple:
    ld   a, [random_number]
    add  a, a              ; *2
    add  a, a              ; *4  
    add  a, 37             ; +37 (número primo)
    ld   [random_number], a
    ret

;; ======================================================================
;; spawn_enemy_simple: Crear un enemigo en posición aleatoria arriba
;; ======================================================================
spawn_enemy_simple:
    ; Buscar un hueco libre en el array de enemigos
    ld   hl, enemies
    ld   b, 3              ; 3 enemigos máximo
    
.find_free_slot:
    ; Mirar byte 2 (estado) del enemigo actual
    push hl
    inc  hl                ; Saltar X
    inc  hl                ; Saltar Y  
    ld   a, [hl]           ; Leer estado
    pop  hl
    
    cp   0                 ; ¿Está muerto? (0 = inactivo)
    jr   z, .found_free    ; Sí -> usarlo
    
    ; No está libre, probar siguiente enemigo
    ld   de, 4             ; 4 bytes por enemigo
    add  hl, de
    dec  b
    jr   nz, .find_free_slot
    
    ret                    ; No hay huecos libres
    
.found_free:
    ; Generar posición X aleatoria (0 a 17, para que quepa la nave de 2 caracteres)
    call get_random_simple
    and  $0F               ; 0-15 
    cp   18                ; ¿Es >= 18?
    jr   c, .valid_x       ; No -> válida
    ld   a, 17             ; Sí -> usar 17 (máximo para nave de 2 chars)
.valid_x:
    ld   [hl], a           ; Guardar X
    inc  hl
    
    ; Y siempre = 1 (parte superior)
    ld   a, 1
    ld   [hl], a           ; Guardar Y
    inc  hl
    
    ; Estado = vivo
    ld   a, 1              ; 1 = activo
    ld   [hl], a           ; Guardar estado
    inc  hl
    
    ; Velocidad = 1 (hacia abajo)
    ld   a, 1
    ld   [hl], a           ; Guardar velocidad
    
    ret

;; ======================================================================
;; update_enemies_simple: Mover todos los enemigos hacia abajo
;; ======================================================================
update_enemies_simple:
    ; Mover todos los enemigos (simplificado)
    ld   hl, enemies
    ld   b, 3              ; 3 enemigos
    
.update_loop:
    push bc
    push hl
    
    ; ¿Está vivo este enemigo?
    inc  hl                ; Saltar X
    inc  hl                ; Ir a Y
    ld   c, [hl]           ; C = Y actual
    inc  hl               
    ld   a, [hl]           ; A = estado
    
    cp   1                 ; ¿Está vivo? (1 = activo)
    jr   nz, .next_enemy   ; No -> siguiente
    
    ; Está vivo -> mover hacia abajo cada 30 frames
    ld   a, [move_timer]
    dec  a
    ld   [move_timer], a
    jr   nz, .next_enemy   ; Si timer > 0, no mover este frame
    
    ; Resetear timer solo cuando movemos
    push bc
    ld   a, 60             ; Mover cada 60 frames (movimiento lento)
    ld   [move_timer], a
    pop  bc
    
    ; Mover hacia abajo
    inc  c                 ; Y = Y + 1
    
    ; ¿Se salió de la pantalla?
    ld   a, c
    cp   18                ; ¿Y >= 18? (altura de pantalla)
    jr   nc, .kill_enemy   ; Sí -> matarlo
    
    ; No se salió -> guardar nueva Y
    dec  hl                ; Volver a Y
    ld   [hl], c           ; Guardar nueva Y
    jr   .next_enemy
    
.kill_enemy:
    ; Matar enemigo (estado = 0)
    ld   a, 0              ; 0 = inactivo
    ld   [hl], a           ; Estado = muerto
    
.next_enemy:
    pop  hl
    pop  bc
    
    ; Siguiente enemigo
    ld   de, 4             ; 4 bytes por enemigo
    add  hl, de
    dec  b
    jr   nz, .update_loop

    ret

;; ======================================================================
;; draw_enemies_simple: Dibujar todos los enemigos vivos
;; ======================================================================
draw_enemies_simple:
    ld   hl, enemies
    ld   b, 3              ; 3 enemigos
    
.draw_loop:
    push bc
    push hl
    
    ; Leer datos del enemigo
    ld   c, [hl]           ; C = X
    inc  hl
    ld   d, [hl]           ; D = Y
    inc  hl
    ld   a, [hl]           ; A = estado
    
    cp   1                 ; ¿Está vivo? (1 = activo)
    jr   nz, .next_enemy   ; No -> siguiente
    
    ; Calcular dirección en pantalla: $9800 + (Y * 32) + X
    ld   h, 0
    ld   l, d              ; HL = Y
    add  hl, hl            ; *2
    add  hl, hl            ; *4
    add  hl, hl            ; *8
    add  hl, hl            ; *16
    add  hl, hl            ; *32 (Y * 32)
    
    ld   de, $9800         ; Base de la pantalla (volvemos a $9800)
    add  hl, de            ; + base pantalla
    
    ld   e, c              ; E = X
    ld   d, 0              ; DE = X (16-bit)
    add  hl, de            ; + X
    
    ; Dibujar enemigo (2 caracteres @ @)
    call wait_vblank_entity
    ld   a, $19            ; Mismo carácter que el jugador (sabemos que funciona)
    ld   [hl], a           ; Primer carácter
    inc  hl
    ld   a, $19            ; Mismo carácter que el jugador  
    ld   [hl], a           ; Segundo carácter
    
.next_enemy:
    pop  hl
    pop  bc
    
    ; Siguiente enemigo
    ld   de, 4             ; 4 bytes por enemigo
    add  hl, de
    dec  b
    jr   nz, .draw_loop
    
    ret

;; ======================================================================
;; clear_enemies_simple: Borrar todos los enemigos de la pantalla
;; ======================================================================
clear_enemies_simple:
    ld   hl, enemies
    ld   b, 3              ; 3 enemigos
    
.clear_loop:
    push bc
    push hl
    
    ; Leer posición del enemigo
    ld   c, [hl]           ; C = X
    inc  hl
    ld   d, [hl]           ; D = Y
    inc  hl
    ld   a, [hl]           ; A = estado
    
    cp   1                 ; ¿Está vivo? (1 = activo)
    jr   nz, .next_enemy   ; No -> siguiente
    
    ; Calcular dirección y borrar
    ld   h, 0
    ld   l, d
    add  hl, hl            ; Y * 32
    add  hl, hl
    add  hl, hl
    add  hl, hl
    add  hl, hl
    
    ld   de, $9800         ; Base de la pantalla
    add  hl, de
    
    ld   e, c              ; E = X
    ld   d, 0              ; DE = X (16-bit)
    add  hl, de            ; + X
    
    ; Borrar (poner 0 en 2 posiciones)
    call wait_vblank_entity
    ld   a, 0
    ld   [hl], a           ; Borrar primer carácter
    inc  hl
    ld   [hl], a           ; Borrar segundo carácter
    
.next_enemy:
    pop  hl
    pop  bc
    
    ; Siguiente enemigo
    ld   de, 4             ; 4 bytes por enemigo
    add  hl, de
    dec  b
    jr   nz, .clear_loop
    
    ret

;; ======================================================================
;; update_spawn_timer_simple: Crear enemigos cada cierto tiempo
;; ======================================================================
update_spawn_timer_simple:
    ld   a, [spawn_timer]
    dec  a                 ; Timer--
    ld   [spawn_timer], a
    
    jr   nz, .no_spawn     ; Si timer > 0, no crear enemigo
    
    ; Timer = 0 -> crear enemigo y resetear timer
    call spawn_enemy_simple
    
    ; Nuevo timer aleatorio (60-120 frames = 1-2 segundos)
    call get_random_simple
    and  $3F               ; 0-63
    add  a, 60             ; 60-123 frames
    ld   [spawn_timer], a
    
.no_spawn:
    ret