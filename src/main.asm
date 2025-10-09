INCLUDE "constantes.inc"

SECTION "Variables", WRAM0
 disparo_cd: ds 1          ; contador de cooldown (tiempo entre disparos)
 balas_tick: ds 1          ; contador de frames para mover balas
 a_lock:     ds 1          ; 0 = listo (no pulsado), 1 = ya disparó y espera soltar A

DEF COOLDOWN_DISPARO EQU 15   ; frames de espera antes de poder disparar otra vez

SECTION "Main Code", ROM0

main:
    ; --- Inicialización básica ---
    call borrarLogo
    call man_entity_init
    call ecs_init_player
    call dibujaJugador
    xor  a
    ld  [disparo_cd], a
    ld  [balas_tick], a
    ld  [a_lock], a
    call wait_vblank

; ===================== BUCLE PRINCIPAL =====================
.bucle_principal:

    ; -------- 1) Mover al jugador con DPAD --------
    call mover_jugador_con_entidad

    ; -------- 2) Mover balas cada N frames --------
    call mover_balas

    ; -------- 3) Disparo con A: UNA bala por pulsación (flanco) --------
    call leer_botones
    bit  0, a                    ; bit0 = A (activo a 0)
    jr   nz, .A_no_pulsado       ; si no está pulsado, liberamos lock

    ; A pulsado (bit=0)
    ld   a, [a_lock]
    or   a
    jr   nz, .no_disparo         ; si ya está bloqueado, no crear otra

    ; si hay cooldown, no disparamos pero bloqueamos hasta soltar
    ld   a, [disparo_cd]
    or   a
    jr   nz, .bloquear

    ; puede disparar -> crear bala
    call crear_bala_entidad_desde_player

    ; reiniciar cooldown
    ld   a, COOLDOWN_DISPARO
    ld  [disparo_cd], a

.bloquear:
    ld   a, 1
    ld  [a_lock], a
    jr   .no_disparo

.A_no_pulsado:
    xor  a
    ld  [a_lock], a              ; liberar: próxima pulsación creará 1 bala

.no_disparo:
    ; -------- 4) Decrementar cooldown si está activo --------
    ld   a, [disparo_cd]
    or   a
    jr   z, .continuar
    dec  a
    ld  [disparo_cd], a

.continuar:
    ; -------- 5) Repetir el bucle principal --------
    jr .bucle_principal

; -------- nunca se debe llegar aquí --------
    di
    halt
    ret
