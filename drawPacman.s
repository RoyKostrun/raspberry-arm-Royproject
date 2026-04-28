// drawpacman.s

.global estadoBocaPacman
.global drawPacmanAtCellDir
.global drawPacman16Dir
.global borrarPacmanAnterior

.balign 4
estadoBocaPacman: .word 1   // 1 = boca abierta, 0 = boca cerrada


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

drawPacman16Dir:
    // centro aproximado 
    mov x9, #7                  // cx
    mov x10, #7                 // cy

    // radio aproximado
    mov x11, #6                 // r
    mov x12, #36                // r^2 = 6*6

    // estado de la boca
    ldr x13, =estadoBocaPacman    // carga el valor de estadoBocaPacman desde memoria
    ldr w14, [x13]              // 1 abierta, 0 cerrada

// Loop por filas y columnas, recorre los 256 píxeles (16×16)
    mov x15, #0                 // fila = 0

pac_fil_loop:
    cmp x15, #16
    b.ge pac_done

    mov x16, #0                 // col = 0

pac_col_loop:
    cmp x16, #16
    b.ge pac_siguiente_fila

// Test del círculo
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

    // si está fuera del círculo, no dibujar, dx ^ 2 + dy ^ 2 > r ^ 2
    cmp x21, x12       // comparar con r ^ 2 = 36
    b.gt saltar_pixel  // si distancia ^ 2 > 36, fuera del círculo

    // ---------------------------------------------------------
    // ojo blanco (2x2), depende de la dirección
    // ---------------------------------------------------------
    cmp x3, #0
    b.eq ojo_der
    cmp x3, #1
    b.eq ojo_izq
    cmp x3, #2
    b.eq ojo_arriba
    b ojo_abajo

ojo_der:
    cmp x15, #4
    b.lt pac_verificar_boca
    cmp x15, #5
    b.gt pac_verificar_boca
    cmp x16, #7
    b.lt pac_verificar_boca
    cmp x16, #8
    b.gt pac_verificar_boca
    b pac_dibujar_blanco

ojo_izq:
    cmp x15, #4
    b.lt pac_verificar_boca
    cmp x15, #5
    b.gt pac_verificar_boca
    cmp x16, #5
    b.lt pac_verificar_boca
    cmp x16, #6
    b.gt pac_verificar_boca
    b pac_dibujar_blanco

ojo_arriba:
    cmp x15, #5
    b.lt pac_verificar_boca
    cmp x15, #6
    b.gt pac_verificar_boca
    cmp x16, #4
    b.lt pac_verificar_boca
    cmp x16, #5
    b.gt pac_verificar_boca
    b pac_dibujar_blanco

ojo_abajo:
    cmp x15, #4
    b.lt pac_verificar_boca
    cmp x15, #5
    b.gt pac_verificar_boca
    cmp x16, #9
    b.lt pac_verificar_boca
    cmp x16, #10
    b.gt pac_verificar_boca
    b pac_dibujar_blanco


    // boca: solo si está abierta; Si el píxel no es parte del ojo, verificamos la boca

pac_verificar_boca:
    cbz w14, pac_dibujar_amarillo // si boca cerrada (0), pintar amarillo

// Calculamos |dx| y |dy| para usar en la condición triangular. El valor absoluto se necesita porque la muesca es simétrica respecto al eje central.
    mov x22, x17   // copiar dx
    cmp x22, #0
    b.ge dx_absoluto_listo
    neg x22, x22  // |dx|
dx_absoluto_listo:

    // |dy|
    mov x23, x18
    cmp x23, #0
    b.ge dy_absoluto_listo
    neg x23, x23
dy_absoluto_listo:

    cmp x3, #0
    b.eq boca_der
    cmp x3, #1
    b.eq boca_izq
    cmp x3, #2
    b.eq boca_arriba
    b boca_abajo

boca_der:
    // muesca triangular hacia la derecha
    cmp x16, #7      // col > 7? (mitad derecha)
    b.le pac_dibujar_amarillo NO,  pintar amarillo (no hay boca a la izquierda)
    sub x24, x16, #7        // profundidad = col - 7 (cuánto me alejé del centro)
    cmp x23, x24    // |dy| ≤ profundidad?
    b.le saltar_pixel // Si, está dentro de la boca, NO pintar
    b pac_dibujar_amarillo  // No, pintar amarillo normal

boca_izq:
    // muesca triangular hacia la izquierda
    cmp x16, #7
    b.ge pac_dibujar_amarillo  // si col ≥ 7, no hay boca en la derecha
    mov x24, #7
    sub x24, x24, x16   // profundidad = 7 - col
    cmp x23, x24         // |dy| ≤ profundidad?
    b.le saltar_pixel   // SÍ = boca, no pintar
    b pac_dibujar_amarillo

boca_arriba:
    // muesca triangular hacia arriba
    cmp x15, #7
    b.ge pac_dibujar_amarillo  // si fila ≥ 7, no hay boca abajo
    mov x24, #7
    sub x24, x24, x15   // profundidad = 7 - fila (crece hacia arriba)
    cmp x22, x24    // usa |dx| en vez de |dy|,|dx| ≤ profundidad?
    b.le saltar_pixel  
    b pac_dibujar_amarillo

boca_abajo:
    // muesca triangular hacia abajo
    cmp x15, #7
    b.le pac_dibujar_amarillo  // si fila ≤ 7, no hay boca arriba
    sub x24, x15, #7        // profundidad = fila - 7 (crece hacia abajo)
    cmp x22, x24             // |dx| ≤ profundidad?
    b.le saltar_pixel
    b pac_dibujar_amarillo

//  Aplicamos formula del framebuffer 
pac_dibujar_blanco:
    add x25, x2, x15           // y actual
    mov x26, #512
    mul x27, x25, x26
    add x27, x27, x1
    add x27, x27, x16
    lsl x27, x27, #1
    add x27, x0, x27
    mov w28, #0xFFFF
    sturh w28, [x27]
    b siguiente_pixel

pac_dibujar_amarillo:
    add x25, x2, x15           // y actual
    mov x26, #512
    mul x27, x25, x26
    add x27, x27, x1
    add x27, x27, x16
    lsl x27, x27, #1
    add x27, x0, x27
    mov w28, #0xFFE0
    sturh w28, [x27]
    b siguiente_pixel

saltar_pixel:
    nop

siguiente_pixel:
    add x16, x16, #1
    b pac_col_loop

pac_siguiente_fila:
    add x15, x15, #1
    b pac_fil_loop

pac_done:
    ret


.global borrarPacmanAnterior

borrarPacmanAnterior:
    sub sp, sp, #16
    str x30, [sp]      // guardamos x30 porque va a usar bl

    ldr x9, =pacmanOldX
    ldr w10, [x9]       // columna anterior

    ldr x11, =pacmanOldY
    ldr w12, [x11]  // fila anterior

    // convertir celda a píxel
    lsl x1, x10, #4
    add x1, x1, #8  // pixelX = 8 + col×16

    lsl x2, x12, #4
    add x2, x2, #8    // pixelY = 8 + fila×16

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
    