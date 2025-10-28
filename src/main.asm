INCLUDE "constantes.inc"

SECTION "Variables", WRAM0
disparo_cd: ds 1
balas_tick: ds 1
a_lock:     ds 1

      ;  evita disparos repetidos 

DEF COOLDOWN_DISPARO EQU 20 ;  frames de cooldown (ajustado para mejor jugabilidad)
DEF ATTR_ENEMIGO EQU $01     ; atributo para identificar enemigos
DEF COOLDOWN_DISPARO EQU 20

SECTION "Tiles ROM", ROM0
naveEspacial::
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $E7,$E7,$DB,$DB,$BD,$BD,$7E,$7E
    db $66,$66,$5A,$5A,$5A,$5A,$66,$66
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FE,$FE,$FC,$FC,$FC,$FC
    db $FC,$FC,$FD,$FD,$FF,$FF,$FF,$FF
    db $7E,$7E,$7E,$7E,$00,$00,$24,$24
    db $A5,$A5,$DB,$DB,$DB,$DB,$E7,$E7
    db $FF,$FF,$7F,$7F,$3F,$3F,$3F,$3F
    db $3F,$3F,$BF,$BF,$FF,$FF,$FF,$FF

tileNegro::
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

bala::
    db $E7,$E7,$E7,$E7,$E7,$E7,$E7,$E7
    db $E7,$E7,$E7,$E7,$E7,$E7,$E7,$E7

enemigo::
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FC,$FC,$FD,$FD,$FD,$FD,$FD,$FD
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $E0,$E0,$C0,$C0,$80,$80,$19,$19
    DB $19,$19,$00,$00,$00,$00,$80,$80
    DB $DF,$DF,$DF,$DF,$DF,$DF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $7F,$7F,$3F,$3F,$1F,$1F,$8F,$8F
    DB $83,$83,$0B,$0B,$0B,$0B,$1B,$1B
    DB $BF,$BF,$BF,$BF,$BF,$BF,$FF,$FF

estrella::
    DB $FF,$FF,$BD,$BD,$DB,$DB,$E7,$E7
    DB $E7,$E7,$DB,$DB,$BD,$BD,$FF,$FF

; Dígitos 0-9 para copiar a OBJ 0x30..0x39
numeros::
    ; 0
    DB $81,$81,$00,$00,$3C,$3C,$3C,$3C
    DB $3C,$3C,$3C,$3C,$00,$00,$81,$81
    ; 1
    DB $E7,$E7,$C7,$C7,$E7,$E7,$E7,$E7
    DB $E7,$E7,$E7,$E7,$E7,$E7,$81,$81
    ; 2
    DB $81,$81,$00,$00,$3C,$3C,$F9,$F9
    DB $F3,$F3,$E7,$E7,$00,$00,$00,$00
    ; 3
    DB $81,$81,$00,$00,$3C,$3C,$E1,$E1
    DB $FC,$FC,$3C,$3C,$00,$00,$81,$81
    ; 4
    DB $F9,$F9,$F1,$F1,$E1,$E1,$C9,$C9
    DB $00,$00,$00,$00,$F9,$F9,$F9,$F9
    ; 5
    DB $00,$00,$00,$00,$3F,$3F,$01,$01
    DB $FC,$FC,$3C,$3C,$00,$00,$81,$81
    ; 6
    DB $81,$81,$00,$00,$3F,$3F,$01,$01
    DB $3C,$3C,$3C,$3C,$00,$00,$81,$81
    ; 7
    DB $00,$00,$00,$00,$FC,$FC,$F9,$F9
    DB $F3,$F3,$E7,$E7,$E7,$E7,$E7,$E7
    ; 8
    DB $81,$81,$00,$00,$3C,$3C,$81,$81
    DB $3C,$3C,$3C,$3C,$00,$00,$81,$81
    ; 9
    DB $81,$81,$00,$00,$3C,$3C,$00,$00
    DB $80,$80,$FC,$FC,$00,$00,$81,$81


SECTION "Main Code", ROM0
main:
    call wait_vblank
    call lcd_off
    call clear_oam

    ; Paletas
    ld   a, $E4
    ld  [$FF47], a  
    ld   a, %11100100
    ld  [$FF48], a 
    ld   a, %00000000
    ld  [$FF49], a       ; OBP1 = todo blanco          ; OBP0 

    ; ---- Copia de tiles a $8000 (VRAM) ----
    ; tile 0: negro
    ld   hl, tileNegro
    ld   de, $8000 + 16*0
    ld   b,  16
    call copy_tiles


    ; bala -> tile 1
    ld   hl, bala
    ld   de, $8000 + 16*1
    ld   b,  16
    call copy_tiles

    ; nave -> $20..$25
    ld   hl, naveEspacial
    ld   de, $8000 + 16*$20
    ld   b,  96
    call copy_tiles

    ; enemigo -> $1A.. (ajusta si cambias índices)
    ld   hl, enemigo
    ld   de, $8000 + 16*26
    ld   b,  96
    call copy_tiles

    ; estrella -> $28
    ld   hl, estrella
    ld   de, $8000 + 16*40
    ld   b,  16
    call copy_tiles

; dígitos 0..9 -> OBJ 0x30..0x39 (invertidos)
    ld   hl, numeros
    ld   de, $8000 + 16*$30
    ld   b,  10*16
    call copy_tiles_invert2bpp


  
 

    ; ---- Habilitar sprites y 8x8 antes de encender LCD ----
    ld   a, [$FF40]          ; LCDC
    set  1, a                ; OBJ enable = 1
    res  2, a                ; OBJ size   = 8x8
    ld  [$FF40], a

    call borrar_logo
    call lcd_on
 

    ; ---- Inicialización juego ----
    call man_entity_init
    call ecs_init_player

    ; Limpiar slots de balas (4..79)
    ld   hl, $C004
    ld   b, 76
    xor  a
.clear_balas:
    ld  [hl+], a
    dec  b
    jr  nz, .clear_balas

    call ecs_init_enemies
    call dibujaJugador
    call draw_enemigos

    ; ---- Marcador ----
    call init_score          ; pone 0000 y pinta en OAM (sprites 0..3)

    ; ---- Sonido (si procede) ----
    ld a, $FF
    ld [$FF26], a
    ld a, $77
    ld [$FF25], a

    xor  a
    ld  [disparo_cd], a
    ld  [balas_tick], a
    ld  [a_lock], a

; ------------------- BUCLE PRINCIPAL -------------------
.bucle_principal:
    call mover_jugador
    call mover_balas
    call ecs_update_enemies          ; Actualizar lógica de enemigos
    call draw_enemigos               ; Redibujar enemigos
    
    ; y>=17 termina porque colisiona MIGUEL
    call check_game_over
    jr   z, .game_over               ; Si Z flag, hay game over
             

    ; Pintar HUD al final del frame (para que no lo pisen otras rutinas)
    call draw_score_oam

    ; Entrada / disparo
    call leer_botones
    bit  0, a
    jr   nz, .A_no_pulsado

    ld   a, [a_lock]
    or   a
    jr   nz, .no_disparo

    ld   a, [disparo_cd]
    or   a
    jr   nz, .bloquear

    call crear_bala_desde_jugador
    ld   a, COOLDOWN_DISPARO
    ld  [disparo_cd], a

.bloquear:
    ld   a, 1
    ld  [a_lock], a
    jr   .no_disparo

.A_no_pulsado:
    xor  a
    ld  [a_lock], a

.no_disparo:
    ld   a, [disparo_cd]
    or   a
    jr   z, .continuar
    dec  a
    ld  [disparo_cd], a

.continuar:
    jr .bucle_principal

.game_over:
    ; reinicio
    call reset_game
    jr .bucle_principal

    di
    halt
    ret

; Z flag si hay game over
check_game_over:
    ld   c, 80                   ; Slots de enemigos (80-159)
.loop_check:
    ld   a, c
    cp   160
    jr   z, .no_game_over
    
    ld   h, $C0
    ld   l, c
    
    ; Verificar si es enemigo
    push hl
    inc  hl
    inc  hl
    inc  hl
    ld   a, [hl]
    pop  hl
    cp   ATTR_ENEMIGO
    jr   nz, .next_check
    
    ; Es enemigo, verificar si está activo
    ld   a, [hl]
    or   a
    jr   z, .next_check
    
    ; Leer Y del enemigo
    inc  hl
    ld   a, [hl]
    cp   17                      ; Y >= 17 es game over
    jr   nc, .is_game_over
    dec  hl
    
.next_check:
    ld   a, c
    add  a, 4
    ld   c, a
    jr   .loop_check
    
.no_game_over:
    xor  a
    inc  a                       ; Clear Z flag (no game over)
    ret
    
.is_game_over:
    xor  a                       ; Set Z flag (game over!)
    ret

; ------------------------------------------------------------
; reset_game: Reinicia el juego completamente
; ------------------------------------------------------------
reset_game:
    ; Limpiar pantalla completa
    ld   hl, $9800
    ld   de, 32*18               ; 576 tiles
    xor  a
.clear_screen:
    call wait_vblank
    ld   b, 32
.clear_row:
    ld   [hl+], a
    dec  b
    jr   nz, .clear_row
    dec  de
    ld   a, d
    or   e
    ld   a, 0
    jr   nz, .clear_screen
    
    ; Reiniciar sistema de entidades
    call man_entity_init
    call ecs_init_player
    
    ; Limpiar slots de balas
    ld   hl, $C004
    ld   b, 76
    xor  a
.clear_balas:
    ld   [hl+], a
    dec  b
    jr   nz, .clear_balas
    
    ; Limpiar slots de enemigos
    ld   hl, $C050               ; Slot 80
    ld   b, 80
.clear_enemies:
    ld   [hl+], a
    dec  b
    jr   nz, .clear_enemies
    
    ; Reiniciar enemigos
    call ecs_init_enemies
    
    ; Redibujar todo
    call dibujaJugador
    call draw_enemigos
    
    ; Reiniciar puntuación
    call init_score
    
    ; Reiniciar variables de juego
    xor  a
    ld  [disparo_cd], a
    ld  [balas_tick], a
    ld  [a_lock], a
    
    ret
