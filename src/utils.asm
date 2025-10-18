SECTION "Player Variables", WRAM0[$C000]
player_pos:      ds 2      ; Posición del jugador (X,Y)

SECTION "Player Functions", ROM0

;; Función wait_vblank local para utils.asm
wait_vblank_utils:
    ld  a, [$FF44]          
    cp   144
    jr   c, wait_vblank_utils
    ret

;; ======================================================================
;; init_player: Inicializa la posición del jugador
;; ======================================================================
init_player:
    ; Inicializar posición del jugador
    ld   a, 10             ; Posición X inicial del jugador (centro)
    ld   [player_pos], a
    ld   a, 16             ; PLAYER_START_Y = 16
    ld   [player_pos+1], a
    ret

;; ======================================================================
;; get_player_screen_address: Calcula la dirección de pantalla del jugador
;; Entrada: ninguna (usa player_pos)
;; Salida: HL = dirección de pantalla
;; ======================================================================
get_player_screen_address:
    ld   a, [player_pos]       ; Cargar X
    ld   c, a
    ld   a, [player_pos+1]     ; Cargar Y
    
    ; Calcular Y * 32
    ld   h, 0
    ld   l, a
    add  hl, hl                ; *2
    add  hl, hl                ; *4
    add  hl, hl                ; *8
    add  hl, hl                ; *16
    add  hl, hl                ; *32
    
    ; Añadir base de la pantalla
    ld   de, $9800             ; SCREEN_TOP_ROW = $9800
    add  hl, de
    
    ; Añadir coordenada X
    ld   b, 0
    add  hl, bc
    
    ret

;; ======================================================================
;; move_player_right: Mueve al jugador hacia la derecha si es posible
;; ======================================================================
move_player_right:
    ; Verificar límite derecho
    ld   a, [player_pos]
    cp   19                    ; MAX_X_POS = 19
    ret  nc                    ; Si ya está en el límite, no mover
    
    ; Borrar posición actual
    call get_player_screen_address
    call wait_vblank_utils
    ld   a, 0
    ld   [hl], a
    
    ; Actualizar posición
    ld   a, [player_pos]
    inc  a
    ld   [player_pos], a
    
    ; Dibujar en nueva posición
    call get_player_screen_address
    call wait_vblank_utils
    ld   a, $19                ; PLAYER_CHAR = $19
    ld   [hl], a
    
    ret

;; ======================================================================
;; move_player_left: Mueve al jugador hacia la izquierda si es posible
;; ======================================================================
move_player_left:
    ; Verificar límite izquierdo
    ld   a, [player_pos]
    cp   0                     ; Si posición == 0, no mover
    ret  z                     ; Si ya está en el límite, no mover
    
    ; Borrar posición actual
    call get_player_screen_address
    call wait_vblank_utils
    ld   a, 0
    ld   [hl], a
    
    ; Actualizar posición
    ld   a, [player_pos]
    dec  a
    ld   [player_pos], a
    
    ; Dibujar en nueva posición
    call get_player_screen_address
    call wait_vblank_utils
    ld   a, $19                ; PLAYER_CHAR = $19
    ld   [hl], a
    
    ret

;; ======================================================================
;; draw_player: Dibuja al jugador en su posición actual
;; ======================================================================
draw_player:
    call get_player_screen_address
    call wait_vblank_utils
    ld   a, $19                ; PLAYER_CHAR = $19
    ld   [hl], a
    ret