.include "menu.i"
.include "main.i"
.include "game.i"

.segment "ZEROPAGE"

menu_selection: .res 1

MENU_STATE_INIT     = 0
MENU_STATE_MAIN     = 1
MENU_STATE_PASSWORD = 2

.data

menu_timer: .res 1
menu_char: .res 1
menu_input: .res 22
.code

.proc run_menu
    lda sub_mode
    jsr jump_table
    .word menu_init, menu_main, menu_password
.endproc

.proc menu_init
    lda #$00
    sta menu_selection
    sta menu_char
    sta PPUMASK

    lda #$20
    sta PPUADDR
    ldy #$00
    sty PPUADDR

    lda #<(title_screen)
    sta $00
    lda #>(title_screen)
    sta $01

    lda title_screen
loop:
    sta PPUDATA
    iny
    beq overflow
overflow_done:
    lda ($00),y
    bne loop

    lda #$00
    sta scroll_x
    sta scroll_y
    jsr fill_attribute_table

    ldx #$20
    memcpy current_palette, title_palette
    jsr load_palette

    jsr wait_vblank
    lda #%00011110
    sta PPUMASK

    inc sub_mode
    rts

overflow:
    inc $01
    jmp overflow_done

.endproc

.proc menu_main
    lda #CONTROLLER_SELECT | CONTROLLER_UP | CONTROLLER_DOWN
    and new_controller
    beq skip_change_selection

    lda menu_selection
    eor #$01
    sta menu_selection
skip_change_selection:

    lda #CONTROLLER_START | CONTROLLER_A
    and new_controller
    bne selected

    lda menu_selection
    ldx #$54
    ldy #$B7
    jmp draw_selection

selected:
    lda menu_selection
    bne load_password

    ; Load password not selected
    jmp game_init_new

load_password:
    inc sub_mode

    ; Load password screen
    lda #$00
    sta menu_selection
    sta PPUMASK

    lda #$20
    sta PPUADDR
    ldy #$00
    sty PPUADDR
    lda #$00
    jsr fill_nametable

    lda #$20
    sta PPUADDR
    lda #$88
    sta PPUADDR
    ldx #$00

enter_password_loop:
    inx
    lda enter_password-1,x
    sta PPUDATA
    bne enter_password_loop

    lda #$22
    sta PPUADDR
    lda #$03
    sta PPUADDR
    ldx #$00
    ldy #$00
alphabet_row0_loop:
    lda base64,x
    sta PPUDATA
    sty PPUDATA
    inx
    cpx #13
    bne alphabet_row0_loop

    lda #$22
    sta PPUADDR
    lda #$43
    sta PPUADDR
alphabet_row1_loop:
    lda base64,x
    sta PPUDATA
    sty PPUDATA
    inx
    cpx #26
    bne alphabet_row1_loop

    lda #$22
    sta PPUADDR
    lda #$83
    sta PPUADDR
alphabet_row2_loop:
    lda base64,x
    sta PPUDATA
    sty PPUDATA
    inx
    cpx #39
    bne alphabet_row2_loop

    lda #$22
    sta PPUADDR
    lda #$C3
    sta PPUADDR
alphabet_row3_loop:
    lda base64,x
    sta PPUDATA
    sty PPUDATA
    inx
    cpx #52
    bne alphabet_row3_loop

    lda #$23
    sta PPUADDR
    lda #$03
    sta PPUADDR
alphabet_row4_loop:
    lda base64,x
    sta PPUDATA
    sty PPUDATA
    inx
    cpx #64
    bne alphabet_row4_loop

    sty menu_selection

    jsr clear_password

    jsr wait_vblank
    lda #%00011110
    sta PPUMASK
    rts

enter_password:
    .byte "ENTER PASSWORD:", $00
.endproc

.proc clear_password
    jsr alloc_string
    sty $02
    lda #'_'
    ldx #$16

loop:
    sta vram_buffer,y
    iny
    dex
    bne loop

    ldy $02
    lda #$21
    sta $03
    lda #$24
    sta $02
    lda #$16
    jmp finalize_string
.endproc

; A: row index
; X: X-coordinate
; Y: Y-coordinate of top row
.proc draw_selection
    stx sprites+3
    asl
    asl
    asl
    adc imm_table, y
    sta sprites

    lda #$80        ; tile
    sta sprites+1
    lda #$00        ; attributes
    sta sprites+2
    rts
.endproc

.proc menu_password
    ldy #$FF

    lda new_controller
    and #CONTROLLER_UP
    beq skip_up

    lda menu_selection
    sec
    sbc #13
    bcs skip_fix_up
    adc #65
    cmp #64
    bne skip_fix_up
    lda #63
skip_fix_up:
    sta menu_selection
    sty menu_timer
skip_up:

    lda new_controller
    and #CONTROLLER_DOWN
    beq skip_down
    lda menu_selection
    clc
    adc #13
    cmp #64
    bcc skip_fix_down
    sbc #65
    bpl skip_fix_down
    lda #12
skip_fix_down:
    sta menu_selection
    sty menu_timer
skip_down:

    lda new_controller
    and #CONTROLLER_RIGHT
    beq skip_right
    sty menu_timer
    ldx menu_selection
    inx
    stx menu_selection
    cpx #64
    bne skip_right
    ldx #00
    stx menu_selection
skip_right:

    lda new_controller
    and #CONTROLLER_LEFT
    beq skip_left
    sty menu_timer
    ldx menu_selection
    dex
    stx menu_selection
    bpl skip_left
    ldx #63
    stx menu_selection
skip_left:

    lda new_controller
    and #CONTROLLER_A | CONTROLLER_START
    beq skip_confirm
    sty menu_timer

    lda menu_char
    tax
    clc
    adc #$24
    sta $02
    lda #$21
    sta $03

    lda menu_selection
    sta menu_input,x
    tax
    lda base64,x
    jsr buffer_byte

    ldx menu_char
    inx
    stx menu_char
    cpx #$16
    beq check_password
skip_confirm:

    lda new_controller
    and #CONTROLLER_B
    beq skip_backspace

    ldx menu_char
    beq skip_backspace
    sty menu_timer

    dex
    stx menu_char

    lda #$21
    sta $03
    lda #$24
    clc
    adc imm_table,x
    sta $02
    lda #'_'
    jsr buffer_byte

skip_backspace:

    lda menu_timer
    clc
    adc #$01
    sta menu_timer
    and #$18
    beq skip_cursor

    lda menu_selection
    sec

row_loop:
    iny
    sbc #13
    bcs row_loop

    adc #13
    ; A = x position of selection
    ; convert to pixels
    asl
    asl
    asl
    asl
    adc #$18

    sta $02

    tya
    ; A = y position of selection
    ; convert to pixels
    asl
    asl
    asl
    asl
    adc #$7F
    sta $03

    lda #<cursor_metasprite
    sta $00
    lda #>cursor_metasprite
    sta $01

    ldx #$00
    jsr draw_spritemap

skip_cursor:
    rts
.endproc

.proc check_password
    ldx #$F
    ldy #$15

    lda #$80
    sta $F
    lda menu_input+$15
    ora #$40
    lsr
    lsr
    lsr
    lsr

copy_char:
    lsr
copy_bit:
    ror $00,x
    bcs next_byte
next_byte_done:
    lsr
    bne copy_bit

    ; We've reached the end of a character, time to go to the next one.
    dey
    bmi decoded
    lda menu_input,y
    ora #$40
    bne copy_char   ; always branches

next_byte:
    dex
    pha
    lda #$80
    sta $00,x
    pla
    jmp next_byte_done

decoded:
    nop
    ; now do the rotation
    
rotate_loop:
    lda $1
    asl
    lda $F
    rol
    eor #$FF
    sta $F
    lda $E
    rol
    eor #$EE
    sta $E
    lda $D
    rol
    eor #$DD
    sta $D
    lda $C
    rol
    eor #$CC
    sta $C
    lda $B
    rol
    eor #$BB
    sta $B
    lda $A
    rol
    eor #$AA
    sta $A
    lda $9
    rol
    eor #$99
    sta $9
    lda $8
    rol
    eor #$88
    sta $8
    lda $7
    rol
    eor #$77
    sta $7
    lda $6
    rol
    eor #$66
    sta $6
    lda $5
    rol
    eor #$55
    sta $5
    lda $4
    rol
    eor #$44
    sta $4
    lda $3
    rol
    eor #$33
    sta $3
    lda $2
    rol
    eor #$22
    sta $2
    lda $1
    rol
    eor #$11
    sta $1
    dec $00
    bne rotate_loop

    ; now a checksum
    ; add each byte + 1, compute a 16-bit result, compare to $01-$02
    lda #$00
    ldx #$00
    ldy #$C
checksum_loop:
    sec
    adc $3,y
    bcc skip_carry
    inx
skip_carry:
    dey
    bne checksum_loop

    ldy $3
rotate_checksum_loop:
    sta $3
    asl
    lda $3
    rol
    dey
    bne rotate_checksum_loop


    cmp $1
    bne invalid_password
    cpx $2
    bne invalid_password

.ifdef HARD_MODE
    lda $4
    cmp #$4
    bcs invalid_password
.endif

    jmp game_init_password

invalid_password:
    lda #$00
    sta menu_char
    jsr clear_password
    rts
.endproc


title_screen:
    .byte "                                "
    .byte "                                "
    .byte "                                "
    .byte "                                "
    .byte "                                "
    .byte "                                "
    .byte "                                "
    .byte "                                "
    .byte "   M   M U U FFF FFF III N  N   "
    .byte "   MM MM U U F   F    I  NN N   "
    .byte "   M M M U U FFF FFF  I  N NN   "
    .byte "   M   M U U F   F    I  N  N   "
    .byte "   M   M UUU F   F   III N  N   "
    .byte "                                "
    .byte "    K  K I CCC K  K EEE  RRR    "
    .byte "    K K  I C   K K  E    R R    "
    .byte "    KK   I C   KK   EEE  RRR    "
    .byte "    K K  I C   K K  E    R R    "
    .byte "    K  K I CCC K  K EEE  R  R   "
    .byte "                                "
    .byte "                                "
    .byte "                                "
    .byte "                                "
    .byte "            NEW GAME            "
    .byte "            CONTINUE            "
    .byte "                                "
    .byte "                                "
    .byte "                                "
    .byte "                                "
    .byte "                                "
    .byte "                                "
    .byte 00

title_palette:
    .byte $0F, $30, $30, $30
    .byte $0F, $30, $30, $30
    .byte $0F, $30, $30, $30
    .byte $0F, $30, $30, $30

    .byte $0F, $08, $18, $0F
    .byte $0F, $30, $30, $30
    .byte $0F, $30, $30, $30
    .byte $0F, $30, $30, $30

base64:
    .byte "ABCDEFGHIJKLMNOP"
    .byte "QRSTUVWXYZabcdef"
    .byte "ghijklmnopqrstuv"
    .byte "wxyz0123456789+/"

cursor_metasprite:
    .byte $04
    .byte $01, $81, $01, $FF
    .byte $01, $81, $41, $01
    .byte $FF, $81, $C1, $01
    .byte $FF, $81, $81, $FF
