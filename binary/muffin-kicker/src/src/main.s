.include "main.i"
.include "menu.i"
.include "game.i"
.segment "INES"

.byte "NES"
.byte $1A           ;Magic header

.byte 2             ;32K PRG
.byte 1             ;8K CHR

.byte %00000001     ;Flags 6: NROM, vertical mirroring
.byte %00000000     ;Flags 7

.segment "TEMP": zeropage
temp_vars: .res 16

.zeropage
jump_target: .res 2

PPUCTRL_Mirror: .res 1

random_seed: .res 1
last_controller: .res 1  ;The controller state last frame.
controller: .res 1
new_controller: .res 1  ; Buttons pressed this frame but not last frame.
CONTROLLER_A        = %00000001
CONTROLLER_B        = %00000010
CONTROLLER_SELECT   = %00000100
CONTROLLER_START    = %00001000
CONTROLLER_UP       = %00010000
CONTROLLER_DOWN     = %00100000
CONTROLLER_LEFT     = %01000000
CONTROLLER_RIGHT    = %10000000

zero: .res 1
ff: .res 1

popslide_stack: .res 1   ; If popsliding, stores the original value of the stack pointer.

game_mode: .res 1    ;The current game mode.
sub_mode: .res 1     ;The current game sub-mode.

GAME_MODE_TITLE = $00
GAME_MODE_GAMEPLAY = $01

.segment "BUFFERS"
;Non-ZP RAM starts at $100

vram_buffer: .res $A0
VRAM_MAX_CMD_SIZE = $20
;Data to be copied to VRAM next frame.
;Format:
;The buffer is a list of commands.  Each command tells where and what to write.
;Each command has the following format:
;
;Byte 0: Jump index, or -1  to indicate no more data.
;The jump index is derived from the data size:
;   index = (VRAM_MAX_CMD_SIZE - size) * 4
; or:
;   eor #$FF
;   sec
;   adc #VRAM_MAX_CMD_SIZE
;   asl
;   asl                     ; clears carry
; To invert and recover the entry length:
;   lsr
;   lsr
;   clc
;   sbc #VRAM_MAX_CMD_SIZE  ; clears carry
;   eor #$FF
; This is slightly cumbersome when writing to the buffer, but it saves
; a calculation in a tight loop during VBlank, providing substantial performance gains.
;
;Byte 1: PPU address high and flags
;   i0aa aaaa
;   i:
;       0: increment PPU address by 1 every write
;       1: increment by 32
;Byte 2: PPU address low
;Bytes 3-end of command: Data to be copied.

stack: .res $60

;Shadow OAM at $200
sprites: .res $100

.data

current_palette: .res $20

nmis: .res 1

scroll_x: .res 1
scroll_y: .res 1

.segment "PPUREGS"

PPUCTRL: .res 1
PPUMASK: .res 1
PPUSTATUS: .res 1
OAMADDR: .res 1
OAMDATA: .res 1
PPUSCROLL: .res 1
PPUADDR: .res 1
PPUDATA: .res 1


.segment "IOREGS"

SQ1_VOL: .res 1
SQ1_SWEEP: .res 1
SQ1_LO: .res 1
SQ1_HI: .res 1
SQ2_VOL: .res 1
SQ2_SWEEP: .res 1
SQ2_LO: .res 1
SQ2_HI: .res 1
TRI_LINEAR: .res 2 ;$4009 is unused
TRI_LO: .res 1
TRI_HI: .res 1
NOISE_VOL: .res 2 ;$400D is unused
NOISE_LO: .res 1
NOISE_HI: .res 1
DMC_FREQ: .res 1
DMC_RAW: .res 1
DMC_START: .res 1
DMC_LEN: .res 1
OAMDMA: .res 1
SND_CHN: .res 1
JOY1: .res 1
JOY2: .res 1

.code

black_palette:   .byte $0F, $0F, $0F, $0F
                .byte $0F, $0F, $0F, $0F
                .byte $0F, $0F, $0F, $0F
                .byte $0F, $0F, $0F, $0F

                .byte $0F, $0F, $0F, $0F
                .byte $0F, $0F, $0F, $0F
                .byte $0F, $0F, $0F, $0F
                .byte $0F, $0F, $0F, $0F

;Finds the next free space in the VRAM buffer.  Stores the result in Y.
;Returns carry clear
.proc find_free_buffer_space

    ldy #$00

loop:
    lda vram_buffer,y
    ;If this slot is empty, we're done.
    bmi done
    ; There's data here; skip past this command.
    ; Get length
    lsr
    lsr
    clc
    sbc #VRAM_MAX_CMD_SIZE  ; Clears carry
    eor #$FF
    ;A contains command length.  Add it (+ 3 for header) it to Y.
    adc imm_table+3, y ; Clears carry
    tay
    jmp loop

done:
    rts

.endproc

;Buffers A to VRAM address $02-$03.
.proc buffer_byte
    pha

    ;Scan the buffer for free space.
    jsr find_free_buffer_space

    ;Write the buffer's header.
    lda #((VRAM_MAX_CMD_SIZE-1) * 4)
    sta vram_buffer,y    ;1 byte of data
    iny
    ;VRAM address high
    lda $03
    sta vram_buffer,y
    iny
    ;VRAM address low
    lda $02
    sta vram_buffer,y
    iny
    ;Write the data.
    pla
    sta vram_buffer,y
    iny
    lda #$ff
    sta vram_buffer,y

    rts
.endproc

;Buffers A bytes of data pointed to by $00-$01 to big-endian VRAM address $02-$03. A must not be 0.
;If the MSB of $03 is set, the data is copied in increment-by-32 mode.
;Clobbers $04
.proc buffer_string
    pha

    jsr find_free_buffer_space
    tya
    tax

    pla
    sta $04

    ; Convert size to jump index
    eor #$FF
    sec
    adc #VRAM_MAX_CMD_SIZE
    asl
    asl
    sta vram_buffer,x

    inx
    lda $03
    sta vram_buffer,x
    inx
    lda $02
    sta vram_buffer,x

    ldy #$00

loop:
    lda ($00),y
    inx
    sta vram_buffer,x
    iny
    cpy $04
    bne loop

    lda #$00
    sta vram_buffer+1,x  ;mark the end of the buffer

    rts
.endproc

; Returns a buffer index usable for generating a string in-place.
; Parameters: None
; Returns: Y: an index (relative to vramBuffer) for a string to be written to.
; This method does not actually write to the buffer; you MUST call finalizeString
; in order to create a valid header for the buffer entry.
.proc alloc_string
    jsr find_free_buffer_space
    iny
    iny
    iny
    rts
.endproc

; Finalizes a write started by allocString.
; Parameters:   $02-$03:The VRAM address to write to. If the MSB of $02 is set,
;                       the data is copied using increment-by-32 mode.
;                       Note that this value is big-endian.
;                   A: The number of bytes written to the buffer.
;                   Y:  The value returned by allocString.
.proc finalize_string
    pha                     ; size      |
    ; write the jump index
    eor #$FF
    sec
    adc #VRAM_MAX_CMD_SIZE
    asl
    asl                     ; clears carry
    sta vram_buffer-3,y

    pla                     ; size      |
    ; write the end-of-buffer marker
    adc imm_table,y          ; carry is clear
    tax
    lda #$FF
    sta vram_buffer,x
    
    lda $03
    sta vram_buffer-2,y
    lda $02
    sta vram_buffer-1,y

    rts
.endproc

; Buffers a compressed string at [$00-01] to big-endian VRAM address $02-03.
; A is the decompressed length.
; If the MSB of $02 is set, the data isc opied in increment-by-32 mode.
; Clobbers $04 and $05.
; RLE format:
;   - 0nnnnnnn dddddddd dddddddd ...: copy n+1 literal bytes
;   - 1nnnnnnn dddddddd: copy d n+1 times
.proc buffer_rle
    sta $04

    jsr find_free_buffer_space
    tya
    tax

    ; $04 = end buffer index
    adc $04
    sta $04

    ; Convert size to jump index
    eor #$FF
    sec
    adc #VRAM_MAX_CMD_SIZE
    asl
    asl
    sta vram_buffer,x

    inx
    lda $03
    sta vram_buffer,x
    inx
    lda $02
    sta vram_buffer,x

    ldy #$FF

outer:
    iny
    lda ($00),y
    sta $05

    bmi repeat
literal:
    iny
    lda ($00), y
    inx
    sta vram_buffer,x
    dec $05
    bpl literal
    jmp end

repeat:
    iny
    lda ($00),y
repeat_loop:
    inx
    sta vram_buffer,x
    dec $05
    bmi repeat_loop

end:
    cpx $04
    blt outer

    lda #$00
    sta vram_buffer+1,x  ;mark the end of the buffer

    rts
.endproc

;Writes the buffer to VRAM.
.proc flush_vram_buffer
    t_function_ptr = $E

    lda vram_buffer
    cmp #$FF
    bne has_data
    rts
has_data:

    ; Use popslide technique by tepples:
    ; https://forums.nesdev.com/viewtopic.php?f=22&t=15440
    ;
    ; In summary: since the VRAM buffer is in the stack page, we can use
    ; PLA as a fast autoincrementing read instruction.

    ; Save stack pointer and point to SECOND byte of buffer
    tsx
    stx popslide_stack
    ldx #$00
    txs

    ; Prepare function pointer
    ldy #>unrolled_vram_flush
    sty t_function_ptr+1
    
    clc  ; Clears carry
loop:
    ; A = jump index

    ; We're going to jump into the middle of the unrolled section (a la Duff's device)
    ; To copy X bytes, jump VRAM_MAX_CMD_SIZE - A iterations in, which is where the
    ; jump index points
    sta t_function_ptr

    ;Execute the command.
    
    ldy #%10000000
    pla ; get address byte
    bpl inc_by1
    ;Increment by 32!
    ldy #%10000100
inc_by1:
    sty PPUCTRL

    ;Load the VRAM address.  A contains the address high byte
    sta PPUADDR
    pla
    sta PPUADDR

    ; Do the write
    jmp (t_function_ptr)

end_unrolled_flush:
    pla
    cmp #$FF
    bne loop

done:
    lda #$FF    ; mark VRAM buffer as empty
    sta vram_buffer

    ; fix stack pointer
    ldx popslide_stack
    txs
    lda #$00
    sta popslide_stack
return:
    rts
.endproc


;Parameters: X (column of tile), Y (row of tile)
;Returns: A (high byte of tile address), X (low byte of tile address)
.proc get_tile_address
    stx $01 ;Store the column for later.

    tya

    jsr get_row_address   ;Get the base address for this row.
    pha

    txa
    ;A: low byte, stack: high byte
    clc
    adc $01
    tax
    pla
    adc #$00    ;add carry

    rts
.endproc

;Parameters: A (row of tile)
;Returns: A (high byte of tile address), X (low byte of tile address)
.proc get_row_address

    ldx #$00
    stx $00

    asl
    rol $00
    asl
    rol $00
    asl
    rol $00
    asl
    rol $00
    asl
    rol $00
    tax
    lda $00
    ora #$20

    rts

.endproc



;Clears the zero flag if the buttons in A are pressed this frame but not last frame.
;Preserves all registers.
.proc was_just_pressed
    bit last_controller
    bne was_pressed_last_frame

    bit controller
    rts
was_pressed_last_frame:
    bit zero  ;Set the zero flag.
    rts
.endproc

;Randomizes until VBlank.  Returns the amount of lagged frames in A.
.proc wait_vblank
    lda #$0
    sta nmis

loop:
    inc random_seed
    lda nmis
    beq loop

    dec nmis

    rts
.endproc


;Returns a pseudorandom number in A.
.proc random
    lda random_seed
    beq do_eor
    asl
    beq no_eor
    bcc no_eor
do_eor:
    eor #$1d
no_eor:
    sta random_seed
    rts
.endproc

.proc read_controller ;From wiki.nesdev.com
    jsr do_read
loop:
    sta $F
    jsr do_read
    cmp $F
    bne loop
    rts

    .proc do_read
        ; Strobe controller
        lda #$1
        sta $4016
        lda #$0
        sta $4016

        ; Read all 8 buttons
        ldx #$8
loop:
        pha

        ;Load the button into the carry flag
        lda $4016
        and #$03
        cmp #$01

        ; Now, rotate the carry flag into the top of A,
        ; land shift all the other buttons to the right
        pla
        ror a

        dex
        bne loop

        sta controller
        rts
    .endproc
.endproc


;Jumps to inex A in a table.  Usage example:
;jsr jumpTable
;.word LocationToJumpIfAIs0, LocationToJumpIfAIs1, LocationToJumpIfAIs2, etc.
.proc jump_table
    asl a
    tay
    iny
    
    pla
    sta jump_target
    pla
    sta jump_target+1

    lda (jump_target), y
    tax
    iny
    lda (jump_target), y

    stx jump_target
    sta jump_target+1

    jmp (jump_target)
.endproc

;jumpTable, except pulls the registers from the stack before jumping.
.proc jump_table_with_registers
    asl a
    tay
    iny
    
    pla
    sta jump_target
    pla
    sta jump_target+1

    lda (jump_target), y
    tax
    iny
    lda (jump_target), y

    stx jump_target
    sta jump_target+1

    pla
    tay
    pla
    tax
    pla

    jmp (jump_target)
.endproc

;Clears all of the sprites.
.proc clear_sprites
    lda #$FF
    ldx #$00

loop:
    sta sprites,x
    inx
    inx
    inx
    inx
    bne loop

    rts
.endproc

; Draws a spritemap pointed to by $00-$01, to screen coordinates $02-03.
; Format: a size byte, followed by the OAM bytes (X and Y positions are relative)
; X contains the OAM index to draw to
; Clobbers $04
.proc draw_spritemap
spritemap = $00
origin_x = $02
origin_y = $03
size = $04
    ldy #$00
    lda (spritemap),y
    iny
    sta size

loop:
    ; Y position
    lda (spritemap),y
    iny
    clc
    adc origin_y
    sta sprites,x
    inx

    ; Tile
    lda (spritemap),y
    iny
    sta sprites,x
    inx

    ; Attributes
    lda (spritemap),y
    iny
    sta sprites,x
    inx

    ; X position
    lda (spritemap),y
    iny
    clc
    adc origin_x
    sta sprites,x
    inx

    dec size
    bne loop

    rts
.endproc

;Fills 960 bytes at PPUADDR with the value in A.
.proc fill_nametable
    ldx #$00
    ldy #$3

    loop1:
    sta PPUDATA
    inx
    bne loop1

    dey
    bne loop1

    ;C0 bytes left to go.
    ldx #$C0
    loop2:
    sta PPUDATA
    dex
    bne loop2

    rts
.endproc

;Fills 64 bytes at PPUADDR with the value in A.
.proc fill_attribute_table
    ldx #$40

    loop:
    sta PPUDATA
    dex
    bne loop

    rts
.endproc

.proc load_palette   ;Loads the currentPalette into the PPU.
    lda #$3f
    sta PPUADDR
    lda #$00
    sta PPUADDR
    tay

loop:
    lda current_palette,y
    sta PPUDATA
    iny
    cpy #$20
    bne loop

    rts
.endproc

.scope memcpy_large  ;Copies XY bytes of memory pointed to by $00/$01 into $02/$03.
loop:
    lda ($00),y
    sta ($02),y
.endscope
memcpy_large:
    dey
    cpy #$FF
    bne memcpy_large::loop
    dex
    cpx #$FF
    bne memcpy_large::loop

    rts

.proc NMI
 ;Save registers
    pha
    txa
    pha

    ; If we're popsliding, we need to fix up the stack pointer
    ; before we can safely push any more data. We have a 4-byte deadzone,
    ; and we never popslide from $0100, so we can safely push 5 bytes
    ; to the stack (return address x2, flags, A, and X).

    ;lda popslide_stack
    ;beq skip_popslide_fixup
    ; Swap popslide_stack and SP.
    ;tsx
    ;stx popslide_stack
    ;tax
    ;txs
skip_popslide_fixup:
    tya
    pha
    
    ;Save variables used by jumpTable.
    lda $0E
    pha
    lda $0F
    pha

    inc nmis

    bit PPUSTATUS   ; reset latch

    lda #$0
    ;DMA sprites to OAM
    sta OAMADDR
    lda #>sprites
    sta $4014

    jsr flush_vram_buffer

    ;set the scroll
    lda scroll_x
    sta PPUSCROLL
    lda scroll_y
    sta PPUSCROLL

    lda PPUCTRL_Mirror
    sta PPUCTRL

    lda controller
    sta last_controller
    jsr read_controller

    lda last_controller
    eor #$FF
    and controller
    sta new_controller


endNMI:
    ;Restore registers from the stack.
    pla
    sta $0F
    pla
    sta $0E

    pla
    tay
    pla
    tax
    pla
    rti
.endproc

;Clears all PPU memory.
.proc clear_screen
    ;Increment by 1 per PPU write.
    lda PPUCTRL_Mirror
    pha
    and #%11111011
    sta PPUCTRL_Mirror
    sta PPUCTRL

    ;Load the palette.
    jsr load_palette

    ;Clear the nametables and attribute tables.
    lda #$20
    sta PPUADDR
    lda #00
    sta PPUADDR

    jsr fill_nametable
    jsr fill_attribute_table
    jsr fill_nametable
    jsr fill_attribute_table
    jsr fill_nametable
    jsr fill_attribute_table
    jsr fill_nametable
    jsr fill_attribute_table

    ;Clear the shadow OAM.
    jsr clear_sprites
    lda #>sprites
    sta OAMDMA

    pla
    sta PPUCTRL
    sta PPUCTRL_Mirror
    rts
.endproc

.proc RESET
    sei
    cld
    lda #$40
    sta $4017 ;disable APU frame counter IRQs

    ; Set up stack with a 4-byte deadzone for safety in the event of an NMI while popsliding
    ldx #($FF - 4)
    txs
    ldx #$00
    stx PPUCTRL
    stx PPUCTRL_Mirror
    stx PPUMASK    ;disable NMI, rendering
    stx DMC_FREQ   ;disable DMC IRQ

    ;wait for PPU
    bit PPUSTATUS ;clear vblank flag
vblankwait1:
    bit PPUSTATUS
    bpl vblankwait1

vblankwait2:
    bit PPUSTATUS
    bpl vblankwait2
    ;The PPU is ready!

    txa ;A and X are 0
    ;Clear memory
clear_memory:
    sta $000,x
    sta $100,x
    ;$200 skipped intentionally -- OAM needs to be initialized with $FF, not $00
    sta $300,x
    sta $400,x
    sta $500,x
    sta $600,x
    sta $700,x

    inx
    bne clear_memory

    lda #$FF
    sta ff
    sta vram_buffer  ; init VRAM buffer with length 0

    lda #$00
    sta PPUSCROLL
    sta PPUSCROLL

    ;enable NMIs, 8x8 sprites at $1000, BG at $0000, nametable at $2000
    lda #%10001000
    sta PPUCTRL
    sta PPUCTRL_Mirror
.endproc

.proc main_loop
    jsr wait_vblank
    jsr clear_sprites
    jsr call_game_routine
    jmp main_loop

    .proc call_game_routine
        lda game_mode
        jsr jump_table
        .word run_menu, run_game
    .endproc
.endproc


.align 256

imm_table:
.repeat 256, i
.byte i
.endrepeat

unrolled_vram_flush:
.repeat VRAM_MAX_CMD_SIZE
    pla
    sta PPUDATA
.endrepeat
    jmp flush_vram_buffer::end_unrolled_flush

.segment "VECTORS"

.word NMI
.word RESET
.word 00

.segment "CHR"

.incbin "chr.bin"
