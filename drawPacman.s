// drawpacman.s

//--------------------------------------------------------------
// Sprite base de Pac-Man pequeño mirando a la derecha (16x16)
// Bit 15 = píxel más a la izquierda
//--------------------------------------------------------------
pacmanMask:
    .hword 0x0000
    .hword 0x01E0
    .hword 0x07F8
    .hword 0x0FFC
    .hword 0x1FF8
    .hword 0x1FE0
    .hword 0x3FC0
    .hword 0x3F80
    .hword 0x3F00
    .hword 0x3F80
    .hword 0x3FC0
    .hword 0x1FE0
    .hword 0x1FF8
    .hword 0x0FFC
    .hword 0x07F8
    .hword 0x0000

pacmanEyeMask:
    .hword 0x0000
    .hword 0x0000
    .hword 0x0000
    .hword 0x0180
    .hword 0x0180
    .hword 0x0000
    .hword 0x0000
    .hword 0x0000
    .hword 0x0000
    .hword 0x0000
    .hword 0x0000
    .hword 0x0000
    .hword 0x0000
    .hword 0x0000
    .hword 0x0000
    .hword 0x0000

    //--------------------------------------------------------------
// drawPacmanAtCellDir
// Dibuja Pac-Man en una celda de la grilla 31x31 con dirección.
//
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
// Dibuja Pac-Man 16x16 en una posición de píxel y con dirección.
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
    adr x9, pacmanMask
    adr x10, pacmanEyeMask

    mov x11, #0                 // fila destino = 0

pacdir_row_loop:
    cmp x11, #16
    b.ge pacdir_done

    mov x12, #0                 // col destino = 0

pacdir_col_loop:
    cmp x12, #16
    b.ge pacdir_next_row

    //----------------------------------------------------------
    // Calcular (srcRow, srcCol) según la dirección
    //----------------------------------------------------------

    cmp x3, #0
    b.eq pacdir_right

    cmp x3, #1
    b.eq pacdir_left

    cmp x3, #2
    b.eq pacdir_up

    // si no es 0,1,2 => abajo
pacdir_down:
    // abajo = rotación 90° horaria
    // srcRow = 15 - col
    // srcCol = fila
    mov x13, #15
    sub x13, x13, x12          // srcRow
    mov x14, x11               // srcCol
    b pacdir_have_src

pacdir_right:
    // derecha = sprite base
    mov x13, x11               // srcRow
    mov x14, x12               // srcCol
    b pacdir_have_src

pacdir_left:
    // izquierda = espejo horizontal
    mov x13, x11               // srcRow
    mov x14, #15
    sub x14, x14, x12          // srcCol = 15 - col
    b pacdir_have_src

pacdir_up:
    // arriba = rotación 90° antihoraria
    // srcRow = col
    // srcCol = 15 - fila
    mov x13, x12               // srcRow
    mov x14, #15
    sub x14, x14, x11          // srcCol
    b pacdir_have_src

pacdir_have_src:
    //----------------------------------------------------------
    // Cargar fila de la máscara amarilla y del ojo
    //----------------------------------------------------------
    add x15, x9, x13, lsl #1
    ldrh w16, [x15]            // fila amarilla

    add x15, x10, x13, lsl #1
    ldrh w17, [x15]            // fila ojo

    //----------------------------------------------------------
    // Construir máscara del bit según srcCol
    // bit 15 = pixel más a la izquierda
    // mask = 1 << (15 - srcCol)
    //----------------------------------------------------------
    mov w18, #15
    sub w18, w18, w14
    mov w19, #1
    lsl w19, w19, w18

    //----------------------------------------------------------
    // Prioridad: ojo blanco > cuerpo amarillo
    //----------------------------------------------------------
    and w20, w17, w19
    cmp w20, #0
    b.ne pacdir_draw_white

    and w20, w16, w19
    cmp w20, #0
    b.ne pacdir_draw_yellow

    b pacdir_skip_pixel

pacdir_draw_white:
    add x21, x2, x11           // y actual
    mov x22, #512
    mul x23, x21, x22
    add x23, x23, x1
    add x23, x23, x12
    lsl x23, x23, #1
    add x23, x0, x23
    mov w24, #0xFFFF
    sturh w24, [x23]
    b pacdir_after_pixel

pacdir_draw_yellow:
    add x21, x2, x11           // y actual
    mov x22, #512
    mul x23, x21, x22
    add x23, x23, x1
    add x23, x23, x12
    lsl x23, x23, #1
    add x23, x0, x23
    mov w24, #0xFFE0
    sturh w24, [x23]
    b pacdir_after_pixel

pacdir_skip_pixel:
    nop

pacdir_after_pixel:
    add x12, x12, #1
    b pacdir_col_loop

pacdir_next_row:
    add x11, x11, #1
    b pacdir_row_loop

pacdir_done:
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
