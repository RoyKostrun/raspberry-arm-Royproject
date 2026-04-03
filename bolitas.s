// bolitas.s
// Mapa de puntos para Pac-Man, dibujo de puntos y lógica de comer + LEDs

.global dotMap
.global dibujarPuntos
.global comerPunto

// ============================================================
// dotMap: 31x31 bytes
// 0 = pared o vacío (sin punto)
// 1 = punto rojo
// 2 = punto verde
//
// Interior de la casa de fantasmas (cols 12-18 en filas 14-17
// y col 15 en fila 18) sin puntos.
// Todos los pasillos alrededor de la casa SÍ tienen puntos.
// ============================================================


.balign 4
dotMap:
//  Fila 0: (0 puntos)
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

//  Fila 1: (28 puntos)
.byte 0,1,2,1,2,1,2,1,2,1,2,1,2,1,2,0,2,1,2,1,2,1,2,1,2,1,2,1,2,1,0

//  Fila 2: (8 puntos)
.byte 0,2,0,0,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,0,2,0

//  Fila 3: (22 puntos)
.byte 0,1,2,1,2,0,2,0,2,1,2,1,2,0,2,0,2,0,2,1,2,1,2,0,2,0,2,1,2,1,0

//  Fila 4: (10 puntos)
.byte 0,2,0,0,1,0,1,0,0,0,0,0,1,0,1,0,1,0,1,0,0,0,0,0,1,0,1,0,0,2,0

//  Fila 5: (29 puntos)
.byte 0,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,0

//  Fila 6: (6 puntos)
.byte 0,2,0,2,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,2,0,2,0

//  Fila 7: (26 puntos)
.byte 0,1,0,1,2,1,2,1,2,1,2,1,2,1,2,0,2,1,2,1,2,1,2,1,2,1,2,1,0,1,0

//  Fila 8: (6 puntos)
.byte 0,2,0,0,0,0,1,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,1,0,0,0,0,2,0

//  Fila 9: (28 puntos)
.byte 0,1,2,1,2,1,2,1,2,1,2,1,2,1,2,0,2,1,2,1,2,1,2,1,2,1,2,1,2,1,0

//  Fila 10: (4 puntos)
.byte 0,0,0,0,0,0,0,2,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,2,0,0,0,0,0,0,0

//  Fila 11: (4 puntos)
.byte 0,0,0,0,0,0,0,1,0,0,0,0,0,0,2,0,2,0,0,0,0,0,0,1,0,0,0,0,0,0,0

//  Fila 12: (4 puntos)
.byte 0,0,0,0,0,0,0,2,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,2,0,0,0,0,0,0,0

//  Fila 13: (17 puntos) - corredor horizontal arriba de la casa
.byte 0,0,0,0,0,0,0,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,0,0,0,0,0,0,0

//  Fila 14: (2 puntos) - laterales externos, interior casa excluido
.byte 0,0,0,0,0,0,0,2,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,2,0,0,0,0,0,0,0

//  Fila 15: (16 puntos) - portal lateral, interior casa excluido
.byte 2,1,2,1,2,1,2,1,0,0,0,0,2,0,0,0,0,0,2,0,0,0,0,1,2,1,2,1,2,1,2

//  Fila 16: (2 puntos) - laterales externos, interior casa excluido
.byte 0,0,0,0,0,0,0,2,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,2,0,0,0,0,0,0,0

//  Fila 17: (2 puntos) - laterales externos, interior casa excluido
.byte 0,0,0,0,0,0,0,1,0,0,0,0,2,1,2,1,2,1,2,0,0,0,0,1,0,0,0,0,0,0,0
                            
//  Fila 18: (13 puntos) - corredor horizontal debajo de la casa
.byte 0,0,0,0,0,0,0,2,1,2,1,2,1,0,0,2,0,0,1,2,1,2,1,2,0,0,0,0,0,0,0

//  Fila 19: (3 puntos)
.byte 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0

//  Fila 20: (3 puntos)
.byte 0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0

//  Fila 21: (29 puntos)
.byte 0,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,0

//  Fila 22: (8 puntos)
.byte 0,2,0,0,1,0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,0,2,0

//  Fila 23: (14 puntos)
.byte 0,1,0,1,2,0,0,0,0,0,2,0,2,1,2,0,2,1,2,0,2,0,0,0,0,0,2,1,0,1,0

//  Fila 24: (8 puntos)
.byte 0,2,0,2,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,1,0,0,0,0,0,0,2,0,2,0

//  Fila 25: (29 puntos)
.byte 0,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,0

//  Fila 26: (8 puntos)
.byte 0,0,1,0,1,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,0

//  Fila 27: (24 puntos)
.byte 0,1,2,0,2,0,2,1,2,1,2,1,2,1,2,0,2,1,2,1,2,1,2,1,2,0,2,0,2,1,0

//  Fila 28: (6 puntos)
.byte 0,2,0,0,1,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,1,0,0,2,0

//  Fila 29: (28 puntos) - pacman en (15,29)
.byte 0,1,2,1,2,1,2,1,2,1,2,1,2,1,2,0,2,1,2,1,2,1,2,1,2,1,2,1,2,1,0

//  Fila 30: (0 puntos)
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


// ============================================================
// dibujarPuntos
// Recorre dotMap y dibuja un cuadradito 4x4 centrado en cada
// celda de 16x16 según el color:
//   1 = rojo  (0xF800)
//   2 = verde (0x07E0)
//
// Entrada: x0 = framebuffer base
// ============================================================
.balign 4
dibujarPuntos:
    sub sp, sp, #32
    str x30, [sp]
    str x0,  [sp, #8]

    ldr x9, =dotMap

    mov x16, #0              // fila = 0

dp_row_loop:
    cmp x16, #31
    b.ge dp_done

    mov x21, #0              // col = 0

dp_col_loop:
    cmp x21, #31
    b.ge dp_next_row

    // calcular índice en dotMap
    mov x22, #31
    mul x23, x16, x22
    add x23, x23, x21
    add x24, x9, x23
    ldrb w25, [x24]

    // si es 0, no hay punto
    cbz w25, dp_next_col

    // determinar color
    cmp w25, #1
    b.eq dp_color_rojo
    cmp w25, #2
    b.eq dp_color_verde
    b dp_next_col

dp_color_rojo:
    mov w3, #0xF800
    b dp_dibujar_punto

dp_color_verde:
    mov w3, #0x07E0
    b dp_dibujar_punto

dp_dibujar_punto:
    // centro de la celda: pixelX = 8 + col*16 + 6, pixelY = 8 + fila*16 + 6
    // punto 4x4 centrado
    lsl x1, x21, #4
    add x1, x1, #8
    add x1, x1, #6          // x inicio del punto

    lsl x2, x16, #4
    add x2, x2, #8
    add x2, x2, #6          // y inicio del punto

    // dibujar 4 filas de 4 píxeles
    ldr x0, [sp, #8]        // recuperar framebuffer

    mov x13, #0              // contador de filas del punto
dp_punto_fila:
    cmp x13, #4
    b.ge dp_next_col

    mov x14, #0              // contador de columnas del punto
dp_punto_col:
    cmp x14, #4
    b.ge dp_punto_next_fila

    // calcular dirección del píxel
    add x5, x2, x13          // y actual
    mov x6, #512
    mul x7, x5, x6
    add x7, x7, x1
    add x7, x7, x14          // x actual
    lsl x7, x7, #1           // *2 (16 bits por píxel)
    add x7, x0, x7
    sturh w3, [x7]

    add x14, x14, #1
    b dp_punto_col

dp_punto_next_fila:
    add x13, x13, #1
    b dp_punto_fila

dp_next_col:
    add x21, x21, #1
    b dp_col_loop

dp_next_row:
    add x16, x16, #1
    b dp_row_loop

dp_done:
    ldr x0, [sp, #8]
    ldr x30, [sp]
    add sp, sp, #32
    ret


// ============================================================
// comerPunto
// Verifica si en la posición actual de Pac-Man hay un punto.
// Si lo hay, lo marca como comido (0) y enciende el LED
// correspondiente (rojo=GPIO3, verde=GPIO2).
// Si no hay punto, apaga ambos LEDs.
//
// Entrada: (usa las variables globales pacmanX, pacmanY)
// ============================================================
.balign 4
comerPunto:
    sub sp, sp, #16
    str x30, [sp]

    // leer posición de Pac-Man
    ldr x9, =pacmanX
    ldr w10, [x9]

    ldr x11, =pacmanY
    ldr w12, [x11]

    // calcular índice en dotMap: fila*31 + col
    ldr x13, =dotMap
    mov w14, #31
    mul w15, w12, w14
    add w15, w15, w10
    add x16, x13, x15

    ldrb w17, [x16]

    // si no hay punto, apagar LEDs
    cbz w17, cp_apagar_leds

    // marcar como comido
    mov w18, #0
    strb w18, [x16]

    // verificar color
    cmp w17, #1
    b.eq cp_punto_rojo
    cmp w17, #2
    b.eq cp_punto_verde
    b cp_fin

cp_punto_rojo:
    // Encender LED rojo (GPIO3): GPCLR0, poner bit 3 en 1 (activo bajo = enciende)
    mov w20, PERIPHERAL_BASE + GPIO_BASE
    mov w21, #0b1000           // bit 3
    str w21, [x20, #0x28]      // GPCLR0

    // Apagar LED verde (GPIO2): GPSET0, poner bit 2 en 1 (activo bajo = apaga)
    mov w21, #0b100            // bit 2
    str w21, [x20, #0x1C]      // GPSET0

    b cp_fin

cp_punto_verde:
    // Encender LED verde (GPIO2): GPCLR0, poner bit 2 en 1
    mov w20, PERIPHERAL_BASE + GPIO_BASE
    mov w21, #0b100            // bit 2
    str w21, [x20, #0x28]      // GPCLR0

    // Apagar LED rojo (GPIO3): GPSET0, poner bit 3 en 1
    mov w21, #0b1000           // bit 3
    str w21, [x20, #0x1C]      // GPSET0

    b cp_fin

cp_apagar_leds:
    // Apagar ambos LEDs (GPSET0: poner en alto = apagar)
    mov w20, PERIPHERAL_BASE + GPIO_BASE
    mov w21, #0b1100           // bits 2 y 3
    str w21, [x20, #0x1C]      // GPSET0

cp_fin:
    ldr x30, [sp]
    add sp, sp, #16
    ret
