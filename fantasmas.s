// fantasmas.s

.global fantasmasData
.global initFantasmas
.global moverFantasmas
.global dibujarFantasmas
.global borrarFantasmas
.global checkColisionFantasmas
.global gameOver
.global frightenedTimer


.balign 4
fantasmasX:     .word 15, 14, 15, 16
fantasmasY:     .word 13, 15, 15, 15
fantasmasOldX:  .word 15, 14, 15, 16
fantasmasOldY:  .word 13, 15, 15, 15
fantasmasDir:   .word 2,  2,  2,  2
fantasmasColor: .word 0xF800, 0xF81F, 0x07FF, 0xFD20
rngSeed:        .word 0x12345678
gameOver:       .word 0
frightenedTimer: .word 0


// ============================================================
// dibujarFantasma: 16x16 en la celda (x0=fb, x1=col, x2=fila, w3=color)
// ============================================================
dibujarFantasma:
    sub sp, sp, #16
    str x30, [sp]

    lsl x1, x1, #4
    add x1, x1, #8
    lsl x2, x2, #4
    add x2, x2, #8

    mov x13, #0
df_fila:
    cmp x13, #16
    b.ge df_fin
    mov x14, #0
df_col:
    cmp x14, #16
    b.ge df_next_fila

    cmp x13, #8
    b.lt df_semicirc

    cmp x13, #14
    b.lt df_pintar
    cmp x13, #15
    b.ne df_pintar
    and x15, x14, #3
    cmp x15, #2
    b.ge df_skip
    b df_pintar

df_semicirc:
    sub x16, x14, #8
    mul x16, x16, x16
    sub x17, x13, #8
    mul x17, x17, x17
    add x16, x16, x17
    cmp x16, #64
    b.gt df_skip

df_pintar:
    cmp x13, #6
    b.lt df_color_base
    cmp x13, #7
    b.gt df_color_base
    cmp x14, #4
    b.lt df_color_base
    cmp x14, #5
    b.le df_ojo
    cmp x14, #10
    b.lt df_color_base
    cmp x14, #11
    b.le df_ojo
    b df_color_base

df_color_base:
    mov w4, w3
    b df_write

df_ojo:
    mov w4, #0xFFFF

df_write:
    add x5, x2, x13
    mov x6, #512
    mul x7, x5, x6
    add x7, x7, x1
    add x7, x7, x14
    lsl x7, x7, #1
    add x7, x0, x7
    sturh w4, [x7]

df_skip:
    add x14, x14, #1
    b df_col
df_next_fila:
    add x13, x13, #1
    b df_fila
df_fin:
    ldr x30, [sp]
    add sp, sp, #16
    ret


// ============================================================
dibujarFantasmas:
    sub sp, sp, #32
    str x30, [sp]
    str x0,  [sp, #8]
    str x19, [sp, #16]

    mov x19, #0
dfs_loop:
    cmp x19, #4
    b.ge dfs_fin

    ldr x9, =fantasmasX
    ldr w1, [x9, x19, lsl #2]
    ldr x9, =fantasmasY
    ldr w2, [x9, x19, lsl #2]
    // si frightened, todos azules
    ldr x9, =frightenedTimer
    ldr w4, [x9]
    cbz w4, dfs_color_normal
    mov w3, #0x001F          // azul
    b dfs_color_listo
dfs_color_normal:
    ldr x9, =fantasmasColor
    ldr w3, [x9, x19, lsl #2]
dfs_color_listo:

    ldr x0, [sp, #8]
    bl dibujarFantasma

    add x19, x19, #1
    b dfs_loop

dfs_fin:
    ldr x19, [sp, #16]
    ldr x30, [sp]
    add sp, sp, #32
    ret


// ============================================================
borrarFantasmas:
    sub sp, sp, #32
    str x30, [sp]
    str x0,  [sp, #8]
    str x19, [sp, #16]

    mov x19, #0
bf_loop:
    cmp x19, #4
    b.ge bf_fin

    ldr x9, =fantasmasOldX
    ldr w10, [x9, x19, lsl #2]
    ldr x9, =fantasmasOldY
    ldr w11, [x9, x19, lsl #2]

    lsl x1, x10, #4
    add x1, x1, #8
    lsl x2, x11, #4
    add x2, x2, #8

    mov w3, #0x0000
    mov x12, #0
bf_fila:
    cmp x12, #16
    b.ge bf_next
    mov x4, #16
    ldr x0, [sp, #8]
    bl drawHLine
    add x2, x2, #1
    add x12, x12, #1
    b bf_fila

bf_next:
    add x19, x19, #1
    b bf_loop

bf_fin:
    ldr x19, [sp, #16]
    ldr x30, [sp]
    add sp, sp, #32
    ret


// ============================================================
// moverFantasmas:
//   - Dentro de la casa: target = puerta (15,13), modo chase forzado.
//   - Dist(pacman) <= 7: modo chase (persigue al pacman).
//   - Dist(pacman) >  7: modo scatter (aleatorio entre dirs válidas).
//   - En ambos modos: sin retroceder, salvo callejón sin salida.
// Usa LCG para pseudo-aleatorio: seed = seed*1103515245 + 12345.
// ============================================================
moverFantasmas:
    sub sp, sp, #112
    str x30, [sp]
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    stp x25, x26, [sp, #64]
    stp x27, x28, [sp, #80]

    mov x19, #0
mf_loop:
    cmp x19, #4
    b.ge mf_fin

    ldr x9, =fantasmasX
    ldr w20, [x9, x19, lsl #2]
    ldr x10, =fantasmasOldX
    str w20, [x10, x19, lsl #2]

    ldr x9, =fantasmasY
    ldr w21, [x9, x19, lsl #2]
    ldr x10, =fantasmasOldY
    str w21, [x10, x19, lsl #2]

    ldr x9, =fantasmasDir
    ldr w24, [x9, x19, lsl #2]

    ldr x9, =pacmanX
    ldr w22, [x9]
    ldr x9, =pacmanY
    ldr w23, [x9]

    sub w25, w20, w22
    cmp w25, #0
    b.ge mf_abs1
    neg w25, w25
mf_abs1:
    sub w26, w21, w23
    cmp w26, #0
    b.ge mf_abs2
    neg w26, w26
mf_abs2:
    add w26, w25, w26
    // leer y decrementar frightenedTimer (solo en el primer fantasma)
    cbnz x19, mf_frightened_ok
    ldr x9, =frightenedTimer
    ldr w15, [x9]
    cbz w15, mf_frightened_ok
    sub w15, w15, #1
    str w15, [x9]
mf_frightened_ok:

    mov w27, #0
    cmp w21, #14
    b.lt mf_check_modo
    cmp w21, #17
    b.gt mf_check_modo
    cmp w20, #12
    b.lt mf_check_modo
    cmp w20, #18
    b.gt mf_check_modo
    mov w22, #15
    mov w23, #13
    mov w27, #1

mf_check_modo:
    cmp w27, #1
    b.eq mf_modo_chase
    cmp w26, #7
    b.le mf_modo_chase
    b mf_modo_random

mf_modo_chase:
    mov w9,  #9999
    mov w10, w24
    mov w11, w20
    mov w12, w21

    mov w13, #0
mf_ch_loop:
    cmp w13, #4
    b.ge mf_apply

    mov w14, w20
    mov w15, w21
    cmp w13, #0
    b.ne mf_ch1
    add w14, w14, #1
    b mf_ch_chk
mf_ch1:
    cmp w13, #1
    b.ne mf_ch2
    sub w14, w14, #1
    b mf_ch_chk
mf_ch2:
    cmp w13, #2
    b.ne mf_ch3
    sub w15, w15, #1
    b mf_ch_chk
mf_ch3:
    add w15, w15, #1

mf_ch_chk:
    eor w16, w13, w24
    cmp w16, #1
    b.ne mf_ch_noback
    lsr w17, w13, #1
    lsr w18, w24, #1
    cmp w17, w18
    b.eq mf_ch_skip
mf_ch_noback:
    cmp w14, #0
    b.lt mf_ch_skip
    cmp w14, #30
    b.gt mf_ch_skip
    cmp w15, #0
    b.lt mf_ch_skip
    cmp w15, #30
    b.gt mf_ch_skip
    ldr x16, =mazeMap31
    mov w17, #31
    mul w18, w15, w17
    add w18, w18, w14
    add x16, x16, x18
    ldrb w17, [x16]
    cmp w17, #'1'
    b.eq mf_ch_skip
    sub w16, w14, w22
    cmp w16, #0
    b.ge mf_ch_ax
    neg w16, w16
mf_ch_ax:
    sub w17, w15, w23
    cmp w17, #0
    b.ge mf_ch_ay
    neg w17, w17
mf_ch_ay:
    add w16, w16, w17
// si frightened, invertir: buscar la MAYOR distancia
    ldr x5, =frightenedTimer
    ldr w6, [x5]
    cbz w6, mf_ch_normal
    // modo huida: negar w16 para que el min se convierta en max
    neg w16, w16
mf_ch_normal:
    cmp w16, w9
    b.ge mf_ch_skip
    mov w9,  w16
    mov w10, w13
    mov w11, w14
    mov w12, w15

mf_ch_skip:
    add w13, w13, #1
    b mf_ch_loop

mf_modo_random:
    mov w28, #0

    mov w13, #0
mf_rnd_loop:
    cmp w13, #4
    b.ge mf_rnd_pick

    mov w14, w20
    mov w15, w21
    cmp w13, #0
    b.ne mf_rn1
    add w14, w14, #1
    b mf_rn_chk
mf_rn1:
    cmp w13, #1
    b.ne mf_rn2
    sub w14, w14, #1
    b mf_rn_chk
mf_rn2:
    cmp w13, #2
    b.ne mf_rn3
    sub w15, w15, #1
    b mf_rn_chk
mf_rn3:
    add w15, w15, #1

mf_rn_chk:
    eor w16, w13, w24
    cmp w16, #1
    b.ne mf_rn_noback
    lsr w17, w13, #1
    lsr w18, w24, #1
    cmp w17, w18
    b.eq mf_rn_skip
mf_rn_noback:
    cmp w14, #0
    b.lt mf_rn_skip
    cmp w14, #30
    b.gt mf_rn_skip
    cmp w15, #0
    b.lt mf_rn_skip
    cmp w15, #30
    b.gt mf_rn_skip
    ldr x16, =mazeMap31
    mov w17, #31
    mul w18, w15, w17
    add w18, w18, w14
    add x16, x16, x18
    ldrb w17, [x16]
    cmp w17, #'1'
    b.eq mf_rn_skip

    sxtw x16, w28
    lsl x16, x16, #2
    add x16, x16, #96
    str w13, [sp, x16]
    add w28, w28, #1

mf_rn_skip:
    add w13, w13, #1
    b mf_rnd_loop

mf_rnd_pick:
    cbz w28, mf_modo_chase

    ldr x9, =rngSeed
    ldr w16, [x9]
    mov w17, #0x4E6D
    movk w17, #0x41C6, lsl #16
    mul w16, w16, w17
    mov w18, #12345
    add w16, w16, w18
    str w16, [x9]

    lsr w16, w16, #16
    udiv w17, w16, w28
    msub w16, w17, w28, w16

    sxtw x16, w16
    lsl x16, x16, #2
    add x16, x16, #96
    ldr w10, [sp, x16]

    mov w11, w20
    mov w12, w21
    cmp w10, #0
    b.ne mf_rp1
    add w11, w11, #1
    b mf_commit
mf_rp1:
    cmp w10, #1
    b.ne mf_rp2
    sub w11, w11, #1
    b mf_commit
mf_rp2:
    cmp w10, #2
    b.ne mf_rp3
    sub w12, w12, #1
    b mf_commit
mf_rp3:
    add w12, w12, #1
    b mf_commit

mf_apply:
    mov w25, #9999
    cmp w9, w25
    b.ne mf_commit

    eor w10, w24, #1
    mov w11, w20
    mov w12, w21
    cmp w10, #0
    b.ne mf_fb1
    add w11, w11, #1
    b mf_fb_chk
mf_fb1:
    cmp w10, #1
    b.ne mf_fb2
    sub w11, w11, #1
    b mf_fb_chk
mf_fb2:
    cmp w10, #2
    b.ne mf_fb3
    sub w12, w12, #1
    b mf_fb_chk
mf_fb3:
    add w12, w12, #1
mf_fb_chk:
    cmp w11, #0
    b.lt mf_no_move
    cmp w11, #30
    b.gt mf_no_move
    cmp w12, #0
    b.lt mf_no_move
    cmp w12, #30
    b.gt mf_no_move
    ldr x16, =mazeMap31
    mov w17, #31
    mul w18, w12, w17
    add w18, w18, w11
    add x16, x16, x18
    ldrb w17, [x16]
    cmp w17, #'1'
    b.ne mf_commit
mf_no_move:
    mov w10, w24
    mov w11, w20
    mov w12, w21

mf_commit:
    ldr x14, =fantasmasDir
    str w10, [x14, x19, lsl #2]
    ldr x14, =fantasmasX
    str w11, [x14, x19, lsl #2]
    ldr x14, =fantasmasY
    str w12, [x14, x19, lsl #2]

    add x19, x19, #1
    b mf_loop

mf_fin:
    ldp x27, x28, [sp, #80]
    ldp x25, x26, [sp, #64]
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldr x30, [sp]
    add sp, sp, #112
    ret


// ============================================================
// checkColisionFantasmas
// Si el pacman está en la misma celda que cualquier fantasma,
// setea gameOver=1, borra al pacman de la pantalla y apaga LEDs.
// Entrada: x0 = framebuffer
// ============================================================
checkColisionFantasmas:
    sub sp, sp, #32
    str x30, [sp]
    str x0,  [sp, #8]
    str x19, [sp, #16]

    ldr x9, =pacmanX
    ldr w10, [x9]
    ldr x9, =pacmanY
    ldr w11, [x9]

    mov x19, #0
cc_loop:
    cmp x19, #4
    b.ge cc_fin

    ldr x9, =fantasmasX
    ldr w12, [x9, x19, lsl #2]
    ldr x9, =fantasmasY
    ldr w13, [x9, x19, lsl #2]

    cmp w10, w12
    b.ne cc_next
    cmp w11, w13
    b.ne cc_next

// ¡Colisión!
    // si está frightened, reset del fantasma a la casa
    ldr x9, =frightenedTimer
    ldr w14, [x9]
    cbz w14, cc_game_over

    // reset: fantasma vuelve a su posición inicial según x19
    ldr x9, =fantasmasX
    ldr x14, =fantasmasY
    cmp x19, #0
    b.ne cc_reset_1
    mov w15, #15
    mov w16, #13
    b cc_reset_apply
cc_reset_1:
    cmp x19, #1
    b.ne cc_reset_2
    mov w15, #14
    mov w16, #15
    b cc_reset_apply
cc_reset_2:
    cmp x19, #2
    b.ne cc_reset_3
    mov w15, #15
    mov w16, #15
    b cc_reset_apply
cc_reset_3:
    mov w15, #16
    mov w16, #15
cc_reset_apply:
    // borrar al fantasma visualmente en su posición actual (antes del reset)
    lsl x1, x12, #4
    add x1, x1, #8
    lsl x2, x13, #4
    add x2, x2, #8
    mov w3, #0x0000
    mov x17, #0
cc_borrar_fantasma:
    cmp x17, #16
    b.ge cc_reset_escribir
    mov x4, #16
    ldr x0, [sp, #8]
    bl drawHLine
    add x2, x2, #1
    add x17, x17, #1
    b cc_borrar_fantasma

cc_reset_escribir:
    // escribir nueva posición en la casa
    ldr x9, =fantasmasX
    str w15, [x9, x19, lsl #2]
    ldr x9, =fantasmasY
    str w16, [x9, x19, lsl #2]
    // actualizar old también con la nueva posición (para que borrar del frame próximo no haga nada raro)
    ldr x9, =fantasmasOldX
    str w15, [x9, x19, lsl #2]
    ldr x9, =fantasmasOldY
    str w16, [x9, x19, lsl #2]
    // resetear dirección a arriba
    ldr x9, =fantasmasDir
    mov w15, #2
    str w15, [x9, x19, lsl #2]
    b cc_next

cc_game_over:
    ldr x9, =gameOver
    mov w14, #1
    str w14, [x9]

    // borrar pacman: cuadro negro 16x16 en su celda
    lsl x1, x10, #4
    add x1, x1, #8
    lsl x2, x11, #4
    add x2, x2, #8
    mov w3, #0x0000
    mov x15, #0
cc_borrar_loop:
    cmp x15, #16
    b.ge cc_leds_off
    mov x4, #16
    ldr x0, [sp, #8]
    bl drawHLine
    add x2, x2, #1
    add x15, x15, #1
    b cc_borrar_loop

cc_leds_off:
    // apagar ambos LEDs (rojo GPIO3 y verde GPIO2)
    mov w20, PERIPHERAL_BASE + GPIO_BASE
    mov w21, #0b1100
    str w21, [x20, #0x1C]
    b cc_fin

cc_next:
    add x19, x19, #1
    b cc_loop

cc_fin:
    ldr x19, [sp, #16]
    ldr x30, [sp]
    add sp, sp, #32
    ret
    