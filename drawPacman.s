// drawpacman.s

.global pacmanMouthState
.global drawPacmanAtCellDir
.global drawPacman16Dir
.global borrarPacmanAnterior

.balign 4
pacmanMouthState: .word 1   // 1 = boca abierta, 0 = boca cerrada


//--------------------------------------------------------------
// drawPacmanAtCellDir
// Entradas:
// x0 = framebuffer
// x1 = columna de la grilla
// x2 = fila de la grilla
// x3 = dirección
//--------------------------------------------------------------
drawPacmanAtCellDir:
    lsl x1, x1, #4      // col * 16
    add x1, x1, #8      // margen izquierdo
    lsl x2, x2, #4      // fila * 16
    add x2, x2, #8      // margen superior
    b drawPacman16Dir


//--------------------------------------------------------------
// drawPacman16Dir
// Dibuja Pac-Man 16x16 de forma programática.
//
// Entradas:
// x0 = framebuffer
// x1 = pixel X superior izquierdo
// x2 = pixel Y superior izquierdo
// x3 = dirección
//
// Dirección:
// 0 = derecha
// 1 = izquierda
// 2 = arriba
// 3 = abajo
//--------------------------------------------------------------
drawPacman16Dir:
    // centro aproximado del sprite
    mov x9, #7                  // cx
    mov x10, #7                 // cy

    // radio aproximado
    mov x11, #6                 // r
    mov x12, #36                // r^2 = 6*6

    // estado de la boca
    ldr x13, =pacmanMouthState
    ldr w14, [x13]              // 1 abierta, 0 cerrada

    mov x15, #0                 // fila = 0

pac_row_loop:
    cmp x15, #16
    b.ge pac_done

    mov x16, #0                 // col = 0

pac_col_loop:
    cmp x16, #16
    b.ge pac_next_row

    // dx = col - cx
    mov x17, x16
    sub x17, x17, x9

    // dy = fila - cy
    mov x18, x15
    sub x18, x18, x10

    // dx^2 + dy^2
    mul x19, x17, x17
    mul x20, x18, x18
    add x21, x19, x20

    // si está fuera del círculo, no dibujar
    cmp x21, x12
    b.gt pac_skip_pixel

    // ---------------------------------------------------------
    // ojo blanco (2x2), depende de la dirección
    // ---------------------------------------------------------
    cmp x3, #0
    b.eq eye_right
    cmp x3, #1
    b.eq eye_left
    cmp x3, #2
    b.eq eye_up
    b eye_down

eye_right:
    cmp x15, #4
    b.lt pac_check_mouth
    cmp x15, #5
    b.gt pac_check_mouth
    cmp x16, #7
    b.lt pac_check_mouth
    cmp x16, #8
    b.gt pac_check_mouth
    b pac_draw_white

eye_left:
    cmp x15, #4
    b.lt pac_check_mouth
    cmp x15, #5
    b.gt pac_check_mouth
    cmp x16, #5
    b.lt pac_check_mouth
    cmp x16, #6
    b.gt pac_check_mouth
    b pac_draw_white

eye_up:
    cmp x15, #5
    b.lt pac_check_mouth
    cmp x15, #6
    b.gt pac_check_mouth
    cmp x16, #4
    b.lt pac_check_mouth
    cmp x16, #5
    b.gt pac_check_mouth
    b pac_draw_white

eye_down:
    cmp x15, #4
    b.lt pac_check_mouth
    cmp x15, #5
    b.gt pac_check_mouth
    cmp x16, #9
    b.lt pac_check_mouth
    cmp x16, #10
    b.gt pac_check_mouth
    b pac_draw_white

    // ---------------------------------------------------------
    // boca: solo si está abierta
    // ---------------------------------------------------------
pac_check_mouth:
    cbz w14, pac_draw_yellow

    // |dx|
    mov x22, x17
    cmp x22, #0
    b.ge abs_dx_ok
    neg x22, x22
abs_dx_ok:

    // |dy|
    mov x23, x18
    cmp x23, #0
    b.ge abs_dy_ok
    neg x23, x23
abs_dy_ok:

    cmp x3, #0
    b.eq mouth_right
    cmp x3, #1
    b.eq mouth_left
    cmp x3, #2
    b.eq mouth_up
    b mouth_down

mouth_right:
    // muesca triangular hacia la derecha
    cmp x16, #7
    b.le pac_draw_yellow
    sub x24, x16, #7
    cmp x23, x24
    b.le pac_skip_pixel
    b pac_draw_yellow

mouth_left:
    // muesca triangular hacia la izquierda
    cmp x16, #7
    b.ge pac_draw_yellow
    mov x24, #7
    sub x24, x24, x16
    cmp x23, x24
    b.le pac_skip_pixel
    b pac_draw_yellow

mouth_up:
    // muesca triangular hacia arriba
    cmp x15, #7
    b.ge pac_draw_yellow
    mov x24, #7
    sub x24, x24, x15
    cmp x22, x24
    b.le pac_skip_pixel
    b pac_draw_yellow

mouth_down:
    // muesca triangular hacia abajo
    cmp x15, #7
    b.le pac_draw_yellow
    sub x24, x15, #7
    cmp x22, x24
    b.le pac_skip_pixel
    b pac_draw_yellow


pac_draw_white:
    add x25, x2, x15           // y actual
    mov x26, #512
    mul x27, x25, x26
    add x27, x27, x1
    add x27, x27, x16
    lsl x27, x27, #1
    add x27, x0, x27
    mov w28, #0xFFFF
    sturh w28, [x27]
    b pac_after_pixel

pac_draw_yellow:
    add x25, x2, x15           // y actual
    mov x26, #512
    mul x27, x25, x26
    add x27, x27, x1
    add x27, x27, x16
    lsl x27, x27, #1
    add x27, x0, x27
    mov w28, #0xFFE0
    sturh w28, [x27]
    b pac_after_pixel

pac_skip_pixel:
    nop

pac_after_pixel:
    add x16, x16, #1
    b pac_col_loop

pac_next_row:
    add x15, x15, #1
    b pac_row_loop

pac_done:
    ret


.global borrarPacmanAnterior

borrarPacmanAnterior:
    sub sp, sp, #16
    str x30, [sp]

    ldr x9, =pacmanOldX
    ldr w10, [x9]

    ldr x11, =pacmanOldY
    ldr w12, [x11]

    // convertir celda a píxel
    lsl x1, x10, #4
    add x1, x1, #8

    lsl x2, x12, #4
    add x2, x2, #8

    // color negro
    mov w3, #0x0000

    // dibujar bloque 16x16 negro
    mov x13, #0
borrar_loop:
    cmp x13, #16
    b.ge borrar_fin

    mov x4, #16
    bl drawHLine

    add x2, x2, #1
    add x13, x13, #1
    b borrar_loop

borrar_fin:
    ldr x30, [sp]
    add sp, sp, #16
    ret
    