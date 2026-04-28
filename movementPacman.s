// movementPacman
// Movimiento del Pac-Man

.global pacmanX
.global pacmanY
.global pacmanDir
.global moverPacman
.global dibujarPacmanActual
.global delaySimple
.global pacmanOldX
.global pacmanOldY



.balign 4
pacmanOldX: .word 15
pacmanOldY: .word 29
pacmanX:   .word 15     // columna inicial de la grilla
pacmanY:   .word 29     // fila inicial de la grilla
pacmanDir: .word 0      // 0=derecha, 1=izquierda, 2=arriba, 3=abajo


.global moverPacman

moverPacman:
    // leer dirección actual REAL del Pac-Man
    ldr x9, =pacmanDir
    ldr w10, [x9]

    // leer posición actual
    ldr x11, =pacmanX
    ldr w12, [x11]          // x actual

    ldr x13, =pacmanY
    ldr w14, [x13]          // y actual

// Antes de moverlo, guarda dónde estaba, sirve para que después otra rutina pueda borrar la imagen anterior.
    ldr x29, =pacmanOldX
    str w12, [x29]

    ldr x28, =pacmanOldY
    str w14, [x28]

    // copiar posisicion candidata, si avanza, a dónde iría
    mov w15, w12            // nextX
    mov w16, w14            // nextY

    // 0 = derecha, 1 = izquierda, 2 = arriba, 3 = abajo
    cmp w10, #0
    b.ne mover_check_izquierda

    // portal derecho
    cmp w15, #30
    b.ne mover_right_normal
    mov w15, #0
    b mover_check_bounds

mover_right_normal:
    add w15, w15, #1
    b mover_check_bounds

mover_check_izquierda:
    cmp w10, #1
    b.ne mover_check_arriba

    // portal izquierdo
    cmp w15, #0
    b.ne mover_left_normal
    mov w15, #30
    b mover_check_bounds

mover_left_normal:
    sub w15, w15, #1
    b mover_check_bounds

mover_check_arriba:
    cmp w10, #2
    b.ne mover_check_abajo
    sub w16, w16, #1
    b mover_check_bounds

mover_check_abajo:
    cmp w10, #3
    b.ne mover_fin
    add w16, w16, #1

// Comprobamos que la nueva posición candidata siga dentro del tablero
mover_check_bounds:
    // límites verticales
    cmp w16, #0
    b.lt mover_fin
    cmp w16, #30
    b.gt mover_fin

    // límites horizontales
    cmp w15, #0
    b.lt mover_fin
    cmp w15, #30
    b.gt mover_fin

    // leer mazeMap31[nextY][nextX], verificamos si hay pared
    ldr x17, =mazeMap31  // Lee la celda de mazeMap31 en la posición candidata (nextY, nextX)

    mov w18, #31
    mul w19, w16, w18
    add w19, w19, w15

    add x17, x17, x19
    ldrb w20, [x17]

    // si hay pared, no mover
    cmp w20, #'1'
    b.eq mover_fin

    // guardar nueva posición
    str w15, [x11]
    str w16, [x13]

    // alternar boca abierta/cerrada
    ldr x21, =estadoBocaPacman
    ldr w22, [x21]
    eor w22, w22, #1
    str w22, [x21]
    
mover_fin:
    br x30


dibujarPacmanActual:
    sub sp, sp, #16
    str x30, [sp]  // guardamos x30 porque va a hacer bl drawPacmanAtCellDir y eso pisa x30.

// Leemos posición y dirección actuales
    ldr x9, =pacmanX
    ldr w10, [x9]

    ldr x11, =pacmanY
    ldr w12, [x11]

    ldr x13, =pacmanDir
    ldr w14, [x13]

    mov x1, x10
    mov x2, x12
    mov x3, x14
    bl drawPacmanAtCellDir

    ldr x30, [sp]
    add sp, sp, #16
    ret


delaySimple:
    mov x9, #0x100000 // 0x40000
delay_loop:
    sub x9, x9, #1
    cbnz x9, delay_loop
    br x30
