;; Constantes del sistema
DEF SPR_X_OFF    = 0
DEF SPR_Y_OFF    = 1
DEF SPR_TILE_OFF = 2
DEF SPR_ATT_OFF  = 3

;; Constantes del jugador
PLAYER_CHAR         EQU $19     ; Carácter del jugador
PLAYER_START_Y      EQU 16      ; Fila donde está el jugador

;; Constantes de posición de pantalla
SCREEN_TOP_ROW      EQU $9800   ; Primera fila de la pantalla
SCREEN_WIDTH        EQU 20      ; Ancho de la pantalla en tiles
SCREEN_HEIGHT       EQU 18      ; Alto de la pantalla en tiles

;; Límites de posición horizontal para Game Boy (20x18 tiles)
MIN_X_POS           EQU 0       ; Posición X mínima (columna 0)
MAX_X_POS           EQU 19      ; Posición X máxima (columna 19)
