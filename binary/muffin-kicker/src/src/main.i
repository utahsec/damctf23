.macro splitTable baseName, entries

    .ident (.concat(baseName, "Lo")):
        .lobytes entries
    .ident (.concat(baseName, "Hi")):
        .hibytes entries

.endmacro

;Copies X bytes of memory pointed to by src into dst.
.macro memcpy dst, src
.local loop
loop:
    lda src,x
    sta dst,x
    dex
    bne loop

.endmacro

.macro blt addr ;Branch if less than
    bcc addr
.endmacro
.macro bge addr     ;Branch if greater than or equal to
    bcs addr
.endmacro
.macro bls addr ;BLT signed
    bmi addr
.endmacro
.macro bgs addr ;BGE signed
    bpl addr
.endmacro

.macro _longbranch inv, addr
    .local skip
    inv skip
    jmp addr
skip:
.endmacro

.macro jne addr
    _longbranch beq, addr
.endmacro
.macro jeq addr
    _longbranch bne, addr
.endmacro
.macro jcc addr
    _longbranch bcs, addr
.endmacro
.macro jcs addr
    _longbranch bcc, addr
.endmacro
.macro jmi addr
    _longbranch bpl, addr
.endmacro
.macro jpl addr
    _longbranch bmi, addr
.endmacro
.macro jvc addr
    _longbranch bcs, addr
.endmacro
.macro jvs addr
    _longbranch bvc, addr
.endmacro

.macro jlt addr
    _longbranch bge, addr
.endmacro
.macro jge addr
    _longbranch blt, addr
.endmacro
.macro jls addr
    _longbranch bgs, addr
.endmacro
.macro jgs addr
    _longbranch bls, addr
.endmacro

.globalzp temp_vars
.globalzp PPUCTRL_Mirror
.globalzp PPUMASK_Mirror
.globalzp controller
.globalzp last_controller
.globalzp new_controller

.globalzp popslide_stack
.globalzp game_mode
.globalzp sub_mode

.globalzp CONTROLLER_A
.globalzp CONTROLLER_B
.globalzp CONTROLLER_START
.globalzp CONTROLLER_SELECT
.globalzp CONTROLLER_UP
.globalzp CONTROLLER_DOWN
.globalzp CONTROLLER_LEFT
.globalzp CONTROLLER_RIGHT

.globalzp GameModeDemo

.global vram_buffer
.global VRAM_MAX_CMD_SIZE
.global stack

.global sprites

.global current_palette
.global nmis
.global scroll_x
.global scroll_y


.global PPUCTRL
.global PPUMASK
.global PPUSTATUS
.global OAMADDR
.global OAMDATA
.global PPUSCROLL
.global PPUADDR
.global PPUDATA

.global SQ1_VOL
.global SQ1_SWEEP
.global SQ1_LO
.global SQ1_HI
.global SQ2_VOL
.global SQ2_SWEEP
.global SQ2_LO
.global SQ2_HI
.global TRI_LINEAR
.global TRI_LO
.global TRI_HI
.global NOISE_VOL
.global NOISE_LO
.global NOISE_HI
.global DMC_FREQ
.global DMC_RAW
.global DMC_START
.global DMC_LEN
.global OAMDMA
.global SND_CHN
.global JOY1
.global JOY2
.global get_row_address
.global get_tile_address


.global black_pallete



.global find_free_buffer_space
.global buffer_byte
.global buffer_string
.global buffer_rle
.global alloc_string
.global finalize_string

.global mainLoop

.global read_controller
.global was_just_pressed
.global wait_vblank
.global random
.global jump_table
.global jump_table_with_registers
.global clear_sprites
.global draw_spritemap
.global fill_nametable
.global clearScreen
.global fill_attribute_table
.global load_palette
.global flush_vram_buffer
.global memcpy_large

.global imm_table

.global NMI
.global IRQ
.global RESET
