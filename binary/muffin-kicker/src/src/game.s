.include "main.i"
.include "game.i"

.segment "ZEROPAGE"

player_x: .res 2
player_y: .res 1

camera_x: .res 2

level_ptr: .res 2
level_width: .res 1     ; Level width in blocks

.data

current_screen: .res 1
num_deaths:     .res 2
time_hours:     .res 1
time_minutes_tens: .res 1
time_minutes_ones: .res 1
time_seconds_tens: .res 1
time_seconds_ones: .res 1
time_frames: .res 1

load_progress: .res 1

.code

.proc run_game
    lda sub_mode
    jsr jump_table
    .word game_load, game_run
.endproc

.proc game_init_new
    lda #$00
    sta current_screen
    sta num_deaths
    sta time_hours
    sta time_minutes_tens
    sta time_minutes_ones
    sta time_seconds_tens
    sta time_seconds_ones
    sta time_frames
    beq game_init   ; always branches
.endproc

.proc game_init_password
    lda $4
    sta current_screen
    lda $5
    sta num_deaths
    lda $6
    sta time_hours
    lda $7
    sta time_minutes_tens
    lda $8
    sta time_minutes_ones
    lda $9
    sta time_seconds_tens
    lda $A
    sta time_seconds_ones
    lda $B
    sta time_frames
.endproc

.proc game_init
    lda #1
    sta game_mode
    lda #GAME_LOAD
    sta sub_mode

    lda #$00
    sta camera_x
    lda current_screen
    asl
    tax
    lda level_data,x
    sta level_ptr
    lda level_data+1,x
    sta level_ptr+1

    ldy #$00
    sty player_x
    sty camera_x
    sty load_progress
    lda (level_ptr), y
    sta level_width

    iny
    lda (level_ptr), y
    asl
    asl
    asl
    sbc #$08
    sta player_y

.endproc

.proc game_load
    ldy load_progress
    cpy #$20
    beq done

    jsr draw_col
    inc load_progress
    rts
done:
    inc sub_mode
.endproc

.proc game_run
    ldy #$00

    ldx time_frames
    inx
    stx time_frames
    cpx #60
    bne game_time_done
    sty time_frames

    ldx time_seconds_ones
    inx
    stx time_seconds_ones
    cpx #10
    bne game_time_done
    sty time_seconds_ones

    ldx time_seconds_tens
    inx
    stx time_seconds_tens
    cpx #6
    bne game_time_done
    sty time_seconds_tens

    ldx time_minutes_ones
    inx
    stx time_minutes_ones
    cpx #10
    bne game_time_done
    sty time_minutes_ones

    ldx time_minutes_tens
    inx
    stx time_minutes_tens
    cpx #6
    bne game_time_done
    sty time_minutes_tens

    inc time_hours
game_time_done:
    rts
.endproc

.proc draw_col
left = $00
mid = $01
right = $02
buf = $03
col = $04
addr = $02
    sty col

    jsr read_col
    sta left
    jsr read_col
    sta mid
    jsr read_col
    sta right

    jsr alloc_string
    sty buf
    ldx #$1D

    lda current_screen
    cmp #$4
    beq write_flag

    dec left
    dec right
loop:
    ; if --mid is positive: continue
    ; if it's 0 or negative:
    ;   if mid == 0: a |= MID
    ;   if --left is positive: a |= LEFT
    ;   if --right is positive: a |= RIGHT
    lda #$00
    dec mid
    bmi walls
    beq floor

    dec left
    dec right
    jmp continue

floor:
    ora #$84
walls:
    dec left
    bmi skip_left
    ora #$81
skip_left:
    dec right
    bmi skip_right
    ora #$82
skip_right:
continue:
    sta vram_buffer, y
    iny
    dex
    bpl loop
    jmp write_buf

write_flag:
    ldx #$1D
    lda #$00

clear_loop:
    sta vram_buffer, y
    iny
    dex
    bpl clear_loop

    ldy buf
    ldx col
    lda flag, x
    sta vram_buffer+8,y

write_buf:
    ldy buf
    lda #$20
    bit col
    beq skip_adj_nametable
    lda #$24
skip_adj_nametable:
    ora #$80
    sta addr+1

    lda col
    sta addr

    lda #$1D
    jmp finalize_string
.endproc

.proc read_col
    cpy #$00
    beq clamp_l
    cpy level_width
    bcs clamp_r

    lda (level_ptr),y
    iny
    rts

clamp_l:
    ldy #$01
    lda (level_ptr),y
    rts

clamp_r:
    ldy level_width
    lda (level_ptr),y
    rts
.endproc

.proc level_data
    .word screen0, screen1, screen2, screen3, screen4

screen0:
    .byte $17
    .byte $8, $8, $8, $8, $9, $9, $9, $9, $9, $A, $A, $B, $C, $C, $C, $C
    .byte $F, $F, $F, $F, $F, $F, $12
screen1:
    .byte $20
    .byte $12, $12, $12, $12, $11, $10, $9, $8, $7, $6, $5, $4, $4, $4, $4, $4
    .byte $5, $6, $7, $8, $9, $A, $9, $8, $7, $6, $5, $4, $3, $3, $3, $3
screen2:
    .byte $20
    .byte $3, $3, $3, $3, $A, $A, $A, $A, $11, $11, $11, $11, $18, $18, $11, $11
    .byte $11, $11, $20, $20, $11, $11, $11, $11, $20, $20, $1A, $1A, $1A, $1A, $1A, $1A
screen3:
    .byte $20
    .byte $1A, $1A, $1A, $1A, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
    .byte $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $18, $18, $18

screen4:
    .byte $01
    .byte $18
.endproc

flag:
.ifdef REDACT
    .byte "         dam{REDACTED}          "
.else
    .ifdef HARD_MODE
        .byte "  dam{just_g0nna_put_th1s_h--}  "
    .else
        .byte "     dam{i_<3_th3_c4rry_b1t}    "
    .endif
.endif
