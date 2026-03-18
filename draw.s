
mazeMap31:
    .ascii "1111111111111111111111111111111"
    .ascii "1000000000000001000000000000001"
    .ascii "1011110101111101011111010111101"
    .ascii "1000010100000101010000010100001"
    .ascii "1011010111110101010111110101101"
    .ascii "1000000000000000000000000000001"
    .ascii "1010110111111111111111110110101"
    .ascii "1010000000000001000000000000101"
    .ascii "1011110111111101011111110111101"
    .ascii "1000000000000001000000000000001"
    .ascii "1111111011111101011111101111111"
    .ascii "1111111011111101011111101111111"
    .ascii "1111111011111101011111101111111"
    .ascii "1111111000000000000000001111111"
    .ascii "1111111011110110110111101111111"
    .ascii "0000000011110100010111100000000"
    .ascii "1111111011110111110111101111111"
    .ascii "1111111011110000000111101111111"
    .ascii "1111111000000110110000001111111"
    .ascii "1111111011111110111111101111111"
    .ascii "1111111011111110111111101111111"
    .ascii "1000000000000000000000000000001"
    .ascii "1011011111010111110101111101101"
    .ascii "1010011111010001000101111100101"
    .ascii "1010111111011101011101111110101"
    .ascii "1000000000000000000000000000001"
    .ascii "1101010111110111110111110101011"
    .ascii "1001010000000001000000000101001"
    .ascii "1011011111111101011111111101101"
    .ascii "1000000000000000000000000000001"
    .ascii "1111111111111111111111111111111"

    
.balign 4
drawHLine:
    mov x5, #0
hline_loop:
    mov x6, #512
    mul x7, x2, x6
    add x7, x7, x1
    add x7, x7, x5
    lsl x7, x7, #1
    add x7, x0, x7
    sturh w3, [x7]
    add x5, x5, #1
    cmp x5, x4
    b.lt hline_loop
    ret

drawVLine:
    mov x5, #0
vline_loop:
    add x6, x2, x5
    mov x7, #512
    mul x8, x6, x7
    add x8, x8, x1
    lsl x8, x8, #1
    add x8, x0, x8
    sturh w3, [x8]
    add x5, x5, #1
    cmp x5, x4
    b.lt vline_loop
    ret

background: 
    mov w3,#0x0000 // #0b0001000001000010 
    add x10, x0, #0 
    bg_y: mov x2, #512 
    bg_x: mov x1, #512 
bg_loop: 
    sturh w3, [x10] 
    add x10, x10, #2 
    sub x1, x1, #1 
    cbnz x1, bg_loop 
    sub x2, x2, #1 
    cbnz x2, bg_x 
    ret

drawMaze:
    sub sp, sp, #16
    str x30, [sp]
    mov w3, #0x001F

    // x9 = puntero base al mapa
    ldr x9, =mazeMap31

    // x20 = fila (0..30)
    mov x20, #0

maze_row_loop:
    cmp x20, #31
    b.ge maze_done

    // x21 = columna (0..30)
    mov x21, #0

maze_col_loop:
    cmp x21, #31
    b.ge next_row

    // ---------------------------------------------------------
    // cargar celda actual: mapa[fila][col]
    // dirección = base + fila*31 + col
    // ---------------------------------------------------------
    mov x22, #31
    mul x23, x20, x22
    add x23, x23, x21
    add x24, x9, x23
    ldrb w25, [x24]

    // si no es '1', pasar a la siguiente celda
    cmp w25, #'1'
    b.ne next_col

    // ---------------------------------------------------------
    // convertir celda a píxel
    // pixelX = 8 + col*16
    // pixelY = 8 + fila*16
    // ---------------------------------------------------------
    lsl x26, x21, #4      // col * 16
    add x26, x26, #8      // pixelX

    lsl x27, x20, #4      // fila * 16
    add x27, x27, #8      // pixelY

    // =========================================================
    // BORDE SUPERIOR
    // si fila == 0, o la celda de arriba no es '1'
    // =========================================================
    cbz x20, draw_top

    sub x28, x20, #1
    mov x22, #31
    mul x23, x28, x22
    add x23, x23, x21
    add x24, x9, x23
    ldrb w25, [x24]
    cmp w25, #'1'
    b.eq skip_top

draw_top:
    mov x1, x26
    mov x2, x27
    mov x4, #16
    bl drawHLine

skip_top:

    // =========================================================
    // BORDE INFERIOR
    // si fila == 30, o la celda de abajo no es '1'
    // =========================================================
    cmp x20, #30
    b.eq draw_bottom

    add x28, x20, #1
    mov x22, #31
    mul x23, x28, x22
    add x23, x23, x21
    add x24, x9, x23
    ldrb w25, [x24]
    cmp w25, #'1'
    b.eq skip_bottom

draw_bottom:
    mov x1, x26
    add x2, x27, #15
    mov x4, #16
    bl drawHLine

skip_bottom:

    // =========================================================
    // BORDE IZQUIERDO
    // si col == 0, o la celda de la izquierda no es '1'
    // =========================================================
    cbz x21, draw_left

    sub x28, x21, #1
    mov x22, #31
    mul x23, x20, x22
    add x23, x23, x28
    add x24, x9, x23
    ldrb w25, [x24]
    cmp w25, #'1'
    b.eq skip_left

draw_left:
    mov x1, x26
    mov x2, x27
    mov x4, #16
    bl drawVLine

skip_left:

    // =========================================================
    // BORDE DERECHO
    // si col == 30, o la celda de la derecha no es '1'
    // =========================================================
    cmp x21, #30
    b.eq draw_right

    add x28, x21, #1
    mov x22, #31
    mul x23, x20, x22
    add x23, x23, x28
    add x24, x9, x23
    ldrb w25, [x24]
    cmp w25, #'1'
    b.eq skip_right

draw_right:
    add x1, x26, #15
    mov x2, x27
    mov x4, #16
    bl drawVLine

skip_right:

next_col:
    add x21, x21, #1
    b maze_col_loop

next_row:
    add x20, x20, #1
    b maze_row_loop

maze_done:
    ldr x30, [sp]
    add sp, sp, #16
    ret

//----------- GRILLA -----------
    mov x1, #8
grillaVloop:
    mov x2, #8          // empieza en y = 8
    mov x4, #496        // altura útil = 496 px
    mov w3, #0xffff     // blanco
    bl drawVLine

    add x1, x1, #16
    cmp x1, #520        // último valor válido dibujado es 504
    b.lt grillaVloop

    // líneas horizontales: y = 8, 24, 40, ..., 504
    mov x2, #8
grillaHloop:
    mov x1, #8          // empieza en x = 8
    mov x4, #496        // ancho útil = 496 px
    mov w3, #0xffff     // blanco
    bl drawHLine

    add x2, x2, #16
    cmp x2, #520        // último valor válido dibujado es 504
    b.lt grillaHloop

    ret

