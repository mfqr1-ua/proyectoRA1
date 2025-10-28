INCLUDE "constantes.inc"

SECTION "utils", ROM0

borrar_logo:
    ld   hl, $9904                ; apunta a la zona superior del BG
    ld   b,  $16                  ; pone 22 bytes a 0 arriba
    xor  a                        ; pone A=0 (tile 0)
    call limpiar_arriba
    call limpiar_abajo
    ret

limpiar_arriba:
    ld   [hl+], a                 ; escribe 0 y avanza
    dec  b                        
    jr   nz, limpiar_arriba       
    ld   hl, $9924                ; cambia a la zona inferior
    ld   b,  $0C                  ;  pone 12 bytes a 0 abajo
    ret

limpiar_abajo:
    ld   [hl+], a                 
    dec  b                        
    jr   nz, limpiar_abajo
    ret

wait_vblank:
    ld  a, [$FF44]                
    cp  144                       
    jr  c, wait_vblank            
    ret

read_dpad:
    ld   a, $20                   
    ld  [$FF00], a
    ld   a, [$FF00]               
    ld   a, [$FF00]               
    ret

leer_botones:                     ; A/B/Start/Select
    ld   a, $10                  
    ld  [$FF00], a
    ld   a, [$FF00]               
    ld   a, [$FF00]               
    ld   a, [$FF00]               
    ret

memset_256:
    ld  [hl+], a                  
    dec b                         
    jr  nz, memset_256            
    ret

memcpy_256:
    ld   a, [hl+]                 
    ld  [de], a                   
    inc  de                       
    dec  b                        
    jr  nz, memcpy_256            
    ret

lcd_off:
    ld   a, [$FF40]               
    res  7, a                     ;  apaga LCD
    ld  [$FF40], a
    ret

lcd_on:
    ld   a, [$FF40]               ;  lee LCDC
    set  7, a                     ;  enciende LCD 
    ld  [$FF40], a
    ret

copy_tiles:
    ld   a, [hl+]                 ;  lee byte de ROM
    ld  [de], a                   ;  escribe byte en VRAM
    inc  de                       
    dec  b                        
    ld   a, b                     
    cp   0
    jr   nz, copy_tiles           
    ret


pintar_bloque_3x2_desde_xy_con_base:
    push af                      
    push de                       
    call calcular_direccion_bg_desde_xy  
    call wait_vblank             
    pop  de
    pop  af

    ld   [hl], a                  ; escribe TL = base
    inc  hl
    inc  a
    ld   [hl], a                  ; escribe Tm = base+1
    inc  hl
    inc  a
    ld   [hl], a                  ; escribe TR = base+2

    ld   bc, 30                   ; baja una fila (32) y vuelve 2 a la izq
    add  hl, bc

    inc  a
    ld   [hl], a                  
    inc  hl
    inc  a
    ld   [hl], a                  
    inc  hl
    inc  a
    ld   [hl], a                  
    ret

borrar_bloque_3x2_desde_xy:
    push de                       ;  guarda (x,y)
    call calcular_direccion_bg_desde_xy  
    call wait_vblank              
    pop  de

    xor  a                       

    ld   [hl], a                  
    inc  hl
    ld   [hl], a                 
    inc  hl
    ld   [hl], a                  

    ld   bc, 30                  
    add  hl, bc

    ld   [hl], a                  
    inc  hl
    ld   [hl], a                 
    inc  hl
    ld   [hl], a                
    ret

dibujaJugador:
    ld   a, [$C000]               ;  carga x del jugador
    ld   e, a
    ld   a, [$C001]               ;  carga y del jugador
    ld   d, a
    ld   a, [$C002]               
    jp   pintar_bloque_3x2_desde_xy_con_base 
ret


; Limpia OAM: pone a 00 los 160 bytes desde $FE00
; Seguro de usar durante VBlank.
clear_oam:
    ld   hl, $FE00         ; inicio OAM
    ld   b, 160            ; bytes a limpiar
    xor  a                 ; A = 0x00
.clear_loop:
    ld  [hl+], a
    dec  b
    jr  nz, .clear_loop
    ret


; copia N bytes (B) invirtiendo los bits (2bpp): 0↔3, 1↔2
; IN: HL=origen, DE=destino, B=bytes
copy_tiles_invertidoColor:
.cti_loop:
    ld   a,[hl+]
    cpl
    ld  [de],a
    inc  de
    dec  b
    jr   nz,.cti_loop
    ret
