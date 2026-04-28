// fantasmas.s

.global moverFantasmas
.global dibujarFantasmas
.global borrarFantasmas
.global checkColisionFantasmas
.global gameOver
.global frightenedTimer

// declaración de variables
.balign 4
fantasmasX:     .word 15, 14, 15, 16
fantasmasY:     .word 13, 15, 15, 15
fantasmasOldX:  .word 15, 14, 15, 16  // posición del frame anterior
fantasmasOldY:  .word 13, 15, 15, 15
fantasmasDir:   .word 2,  2,  2,  2  // dirección actual (0 = der, 1 = izq, 2 = arr, 3 = ab)
fantasmasColor: .word 0xF800, 0xF81F, 0x07FF, 0xFD20
rngSeed:        .word 0x12345678    //  semilla inicial del generador aleatorio (LCG: Lineal Congruetial Genrator)
gameOver:       .word 0   
frightenedTimer: .word 0, 0, 0, 0


// dibujarFantasma: 16x16 en la celda (x0=fb, x1=col, x2=fila, w3=color), dibujamos 1 solo fantasma pixel x pixel
// x0 = dirección base del framebuffer
// x1 = columna en la grilla
// x2 = fila en la grilla
// w3 = color RGB565

dibujarFantasma:
    sub sp, sp, #16  // reservar 16 bytes en el stack
    str x30, [sp]  // guardar x30 (link register) para poder volver

// Conviertimos coordenadas de celda a coordenadas de píxel
    lsl x1, x1, #4 
    add x1, x1, #8
    lsl x2, x2, #4
    add x2, x2, #8
    
//Dos loops anidados que recorren los 16×16 = 256 píxeles del sprite. Para cada píxel decide si pintarlo y con qué color.
    mov x13, #0
df_fila:
    cmp x13, #16
    b.ge df_fin
    mov x14, #0
df_col:
    cmp x14, #16
    b.ge df_next_fila

// Decisión de pintar: tronco vs cabeza, le damos forma al fantasma
    cmp x13, #8
    b.lt df_semicirc   // si fila < 8 = es cabeza, hacer otra cosa

    cmp x13, #14
    b.lt df_pintar    // si filaactual esta entre  8 y 14 = PINTAR 
    cmp x13, #15    
    b.ne df_pintar  // si no es fila 15, pintar normal (tronco)
    // fila 15(pies)
    and x15, x14, #3   // x15 = col mod 4
    cmp x15, #2         // es 2 o más?
    b.ge df_skip        // SÍ = no pintar ( hueco entre pies )
    b df_pintar         // NO ( es 0 o 1 ) = pintar (pie)

// formula (col - 8 )^ 2 + ( fila - 8)^ 2 ≤ 64
df_semicirc:
    sub x16, x14, #8        // dx = col - 8
    mul x16, x16, x16       // dx × dx = dx ^ 2
    sub x17, x13, #8        // dy = fila - 8
    mul x17, x17, x17       // dy × dy = dy ^ 2
    add x16, x16, x17    // dx ^ 2 + dy ^ 2
    cmp x16, #64            // es ≤ 64?
    b.gt df_skip    // No, no pintar (está fuera del círculo)

// pintamos los ojos, estos están en filas 6-7, columnas 4-5 (ojo izquierdo) y 10-11 (ojo derecho). Son 2 cuadrados de 2×2 píxeles blancos
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

// Escibimos el pixel, aplicamos la fórmula del framebuffer: dir = base + 2×(x + y × 512)
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
    sturh w4, [x7]   // escribimos los 16 bits del color, la usamos en todas las funciones que pintan en pantalla

// cerramos los loops 
df_skip:
    add x14, x14, #1
    b df_col    // siguiente columna
df_next_fila:
    add x13, x13, #1
    b df_fila    // siguiente fila
df_fin:
    ldr x30, [sp]
    add sp, sp, #16  // libera el stack
    ret


// Llamamos a dibujarFantasma cuatro veces, una por cada fantasma

dibujarFantasmas:
    sub sp, sp, #32
    str x30, [sp]       // // guardar link register
    str x0,  [sp, #8]  // guardamos framebuffer
    str x19, [sp, #16]

    mov x19, #0    // índice del fantasma (0..3)
dfs_loop:
    cmp x19, #4
    b.ge dfs_fin

    ldr x9, = fantasmasX
    ldr w1, [x9, x19, lsl #2]   // x1 = fantasmasX[x19]; lsl x10, x19, #2(x10=x19×4), add x10, x9, x10 (x10=base+offset) ,ldr w1, [x10] (w1=memoria[x10])
    ldr x9, = fantasmasY
    ldr w2, [x9, x19, lsl #2]    // x2 = fantasmasY[x19]
 
      // ¿Colisión detectada!
    ldr x9, =frightenedTimer
    ldr w4, [x9, x19, lsl #2]      // timer[x19], leer timer de ESTE fantasma
    cbz w4, dfs_color_normal        // si timer = 0 = fantasma normal = game over
    mov w3, #0x001F                 // azul o #0x07E0 
    b dfs_color_listo

dfs_color_normal:
    ldr x9, =fantasmasColor
    ldr w3, [x9, x19, lsl #2]   // color normal del fantasma

dfs_color_listo:
    ldr x0, [sp, #8]
    bl dibujarFantasma

    add x19, x19, #1   // siguiente fantasma
    b dfs_loop

dfs_fin:
    ldr x19, [sp, #16]
    ldr x30, [sp]
    add sp, sp, #32
    ret


// -----------------------------------------
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


// moverFantasmas:
//   Dentro de la casa: target = puerta (15,13), modo chase forzado
//   Dist(pacman) <= 7: modo chase (persigue al pacman)
//   Dist(pacman) >  7: modo scatter (aleatorio entre dirs válidas)
//   En ambos modos: sin retroceder, salvo callejón sin salida
// Usa LCG para pseudo-aleatorio: seed = seed * 1103515245 + 12345

moverFantasmas:
    sub sp, sp, #112  // "baja" el stack pointer 112 bytes, reservando ese espacio para nuestro uso
    str x30, [sp]

    // stp = store pair, guarda 2 registros de 64  bits(16 bytes) en la memeoria apuntada por el stack
    stp x19, x20, [sp, #16]   // guardar x19 y x20 en UNA instrucción
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    stp x25, x26, [sp, #64]
    stp x27, x28, [sp, #80]

// loop principal, itera sobre los 4 fantasmas
    mov x19, #0
mf_loop:
    cmp x19, #4
    b.ge mf_fin

 //Cargamos datos del fantasma y guardamos old, para que en el proximo frame ( borrar fantasmas ) sepa donde borrar
    ldr x9, =fantasmasX
    ldr w20, [x9, x19, lsl #2]  // w20 = X actual, ARMv8 permite incluir un shift dentro de la instrucción ldr
    ldr x10, =fantasmasOldX
    str w20, [x10, x19, lsl #2]  // guardar oldX = X actual

    ldr x9, =fantasmasY
    ldr w21, [x9, x19, lsl #2]
    ldr x10, =fantasmasOldY
    str w21, [x10, x19, lsl #2]

    ldr x9, =fantasmasDir
    ldr w24, [x9, x19, lsl #2]  // w24 = dirección actual

// Cargamos posición del Pac-Man, es el target inicial de todod
    ldr x9, =pacmanX
    ldr w22, [x9]
    ldr x9, =pacmanY
    ldr w23, [x9]
// -----
// Calculamos distancia Manhattan al Pac-Man
//---
    sub w25, w20, w22  // dx = fantasmaX - pacmanX
    cmp w25, #0
    b.ge mf_abs1
    neg w25, w25    // |dx|

mf_abs1:
    sub w26, w21, w23
    cmp w26, #0
    b.ge mf_abs2
    neg w26, w26    // |dy|

mf_abs2:
    add w26, w25, w26  // w26 = |dx| + |dy| = distancia Manhattan, si el fantasma persigue o no

    // decrementar el timer del fantasma actual si está activo
    ldr x9, =frightenedTimer
    ldr w15, [x9, x19, lsl #2]
    cbz w15, mf_frightened_ok  // si timer = 0, no hacer nada
    sub w15, w15, #1
    str w15, [x9, x19, lsl #2]  // timer[x19]--

mf_frightened_ok:
    mov w27, #0   // flag: ¿está en la casa?
    cmp w21, #14    
    b.lt mf_check_modo  // si fila < 14, no está en la casa
    cmp w21, #17
    b.gt mf_check_modo // si fila > 17, no está
    cmp w20, #12
    b.lt mf_check_modo // si col < 12, no está
    cmp w20, #18
    b.gt mf_check_modo  // si col > 18, no está

    // SÍ estoy en la casa, target se cambia a la puerta  (15,13)
    mov w22, #15 // sobrescribir target X = puerta
    mov w23, #13
    mov w27, #1 // marcar: está en la casa  

mf_check_modo:
    cmp w27, #1
    b.eq mf_modo_chase  // si está en la casa:  modo chase FORZADO
    cmp w26, #7
    b.le mf_modo_chase  // si distancia ≤ 7, modo chase
    b mf_modo_random   // si no, modo scatter

mf_modo_chase:
    mov w9,  #9999
    mov w10, w24
    mov w11, w20
    mov w12, w21

    mov w13, #0  // iterador: 0,1,2,3 = der,izq,arr,ab
mf_ch_loop:
    cmp w13, #4
    b.ge mf_apply  // si ya probé las 4 direcciones, aplicar

// Calculamos la posición candidata
    mov w14, w20  // newX = X actual
    mov w15, w21  // newY = Y actual
    cmp w13, #0
    b.ne mf_ch1
    add w14, w14, #1  // derecha: X + 1
    b mf_ch_chk
mf_ch1:
    cmp w13, #1
    b.ne mf_ch2
    sub w14, w14, #1   // izquierda: X - 1
    b mf_ch_chk
mf_ch2:
    cmp w13, #2
    b.ne mf_ch3
    sub w15, w15, #1    // arriba: Y - 1
    b mf_ch_chk
mf_ch3:
    add w15, w15, #1    // abajo: Y + 1

// "no retroceder". Dos direcciones son opuestas si su XOR es 1 (difieren solo en el bit bajo) 
// y sus bits altos son iguales (mismo eje: ambas horizontales o ambas verticales)
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

    // Verificamos que la nueva posición esté dentro del tablero 31×31.
    ldr x16, =mazeMap31
    mov w17, #31
    mul w18, w15, w17
    add w18, w18, w14
    add x16, x16, x18
    ldrb w17, [x16] // leer 1 byte del mapa, la usa cvez q consulto el maze
    cmp w17, #'1'
    b.eq mf_ch_skip    // si es pared, saltear

    // Calculamos la distancia Manhattan desde la nueva posición candidata hasta el objetivo 
    sub w16, w14, w22   // dx = newX - targetX
    cmp w16, #0
    b.ge mf_ch_ax
    neg w16, w16      // |dx|
    
mf_ch_ax:
    sub w17, w15, w23   // dy = newY - targetY
    cmp w17, #0
    b.ge mf_ch_ay
    neg w17, w17      // |dy|

mf_ch_ay:
    add w16, w16, w17    // distancia desde newPos al target

// Si está asustado, invertir la lógica
    ldr x5, =frightenedTimer
    ldr w6, [x5, x19, lsl #2]
    cbz w6, mf_ch_normal
    neg w16, w16     // si frightened: negar distancia (huir), si timer > 0

// Es mejor que la mejor candidata hasta ahora?
mf_ch_normal:
    cmp w16, w9        // esta distancia < mejor_distancia?
    b.ge mf_ch_skip    // No: descartar
    mov w9,  w16       // Si: nueva mejor_distancia
    mov w10, w13       // nueva mejor_dir
    mov w11, w14       // nueva mejor_newX
    mov w12, w15        // nueva mejor_newY

// // probamos la siguiente dirección
mf_ch_skip:
    add w13, w13, #1
    b mf_ch_loop

// Modo random (scatter)

// Juntamos las direcciones válidas
mf_modo_random:
    mov w28, #0     // contador de direcciones válidas, contador = 0

    mov w13, #0     // probar dir 0
mf_rnd_loop:
    cmp w13, #4
    b.ge mf_rnd_pick   // si probé las 4, elegir una al azar
     // ... (mismo cálculo de newX, newY que chase)
    // ... (mismos chequeos: no retroceder, límites, pared)

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

// sxtw = Sign Extend Word. Toma un valor de 32 bits (un w register) y lo extiende a 64 bits (un x register), preservando el signo
// en ARMv8, las direcciones de memoria son de 64 bits. Cuando hacés str w13, [sp, x16], el procesador suma sp (64 bits) + x16 (64 bits)
// para calcular la dirección final, El problema es que w28 es un registro de 32 bits, usado sin extenderlo tendria 32 bits con basura
    sxtw x16, w28
    lsl x16, x16, #2
    add x16, x16, #96
    str w13, [sp, x16]
    add w28, w28, #1
    // El buffer está en el stack (offset 96-111, los últimos 16 bytes de los 112 reservados)
    // Puede guardar hasta 4 direcciones (una por cada .word de 4 bytes).


mf_rn_skip:
    add w13, w13, #1     
    b mf_rnd_loop

//Elegir una al azar con el LCG, éste genera un número gigante pseudo-aleatorio
mf_rnd_pick:
    cbz w28, mf_modo_chase

    ldr x9, =rngSeed
    ldr w16, [x9]

    // aplicamos fórmula: nueva_semilla = semilla × 1103515245 + 12345
    // movk= cargamos constantes de 32 bits( conatante LCG )
    mov w17, #0x4E6D
    movk w17, #0x41C6, lsl #16   // multiplicador = 1103515245
    mul w16, w16, w17   // seed × multiplicador 
    mov w18, #12345
    add w16, w16, w18
    str w16, [x9]

//Un fantasma llega a una intersección y tiene que elegir una dirección al azar
// El código ya recorrió las 4 direcciones posibles y descartó las inválidas
// Calculamos el modulo, para convertir a índice entre 0 y count-1
//Ahora necesitás un índice que sea 0, 1 o 2 para elegir una de las tres
// Pero el LCG te genera un número gigante, por ejemplo 48291573, entonces lo convertimos con modulo

    lsr w16, w16, #16
    udiv w17, w16, w28  //   (a/b),  a = w16 = número random grande (resultado del LCG, bits altos)
    msub w16, w17, w28, w16   // mod b = a - (a/b) × b, b = w28 = count (cuántas direcciones válidas hay, entre 1 y 4)

// Usamos la dirección elegida
    sxtw x16, w16    // extender count a 64 bits
    lsl x16, x16, #2
    add x16, x16, #96
    ldr w10, [sp, x16] // leer la dirección elegida del buffer

// calcular (newX, newY) según la dirección
    mov w11, w20
    mov w12, w21
    cmp w10, #0
    b.ne mf_rp1
    add w11, w11, #1 // derecha
    b mf_commit
mf_rp1:
    cmp w10, #1
    b.ne mf_rp2
    sub w11, w11, #1   // izquierda
    b mf_commit
mf_rp2:
    cmp w10, #2
    b.ne mf_rp3
    sub w12, w12, #1  // arriba
    b mf_commit
mf_rp3:
    add w12, w12, #1  // abajo
    b mf_commit

//  retroceder en callejones sin salida
mf_apply:
    mov w25, #9999
    cmp w9, w25
    b.ne mf_commit

    // no encontramos ninguna dirección válida, forzar retroceso
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
    // verificar si el retroceso es válido
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

// Guardamos el resultado
mf_commit:
    ldr x14, =fantasmasDir
    str w10, [x14, x19, lsl #2]  // guardamos nueva dirección
    ldr x14, =fantasmasX
    str w11, [x14, x19, lsl #2]  // guardamos nueva X
    ldr x14, =fantasmasY
    str w12, [x14, x19, lsl #2]  // guardamos nueva Y

    add x19, x19, #1            // siguiente fantasma
    b mf_loop

mf_fin:
//ldp = Load Pair, operación inversa: carga dos registros desde la memoria en una sola instrucción
    ldp x27, x28, [sp, #80]
    ldp x25, x26, [sp, #64]
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldr x30, [sp]
    add sp, sp, #112
    ret


// checkColisionFantasmas
// Si el pacman está en la misma celda que cualquier fantasma,
// setea gameOver=1, borra al pacman de la pantalla y apaga LEDs.
// Entrada: x0 = framebuffer

checkColisionFantasmas:
    sub sp, sp, #32
    str x30, [sp]
    str x0,  [sp, #8]
    str x19, [sp, #16]

    // leer posición del Pac-Man
    ldr x9, =pacmanX
    ldr w10, [x9]
    ldr x9, =pacmanY
    ldr w11, [x9]

    mov x19, #0    // chequeamos los 4 fantasmas
cc_loop:
    cmp x19, #4
    b.ge cc_fin

    ldr x9, =fantasmasX
    ldr w12, [x9, x19, lsl #2]
    ldr x9, =fantasmasY
    ldr w13, [x9, x19, lsl #2]

    // misma posición?
    cmp w10, w12
    b.ne cc_next        // X diferente, no hay colisión
    cmp w11, w13 
    b.ne cc_next        // Y diferente, no hay colisión

// fantasma está asustado?
    // si el timer del fantasma está activo, reset (no game over)
    ldr x9, =frightenedTimer
    ldr w14, [x9, x19, lsl #2]
    cbz w14, cc_game_over   // timer = 0 → el fantasma mata al Pac-Man

    // reset: fantasma vuelve a su posición inicial según x19
    ldr x9, =fantasmasX
    ldr x14, =fantasmasY

    // Se elige la posición inicial del fantasma según su índice: 
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
    // Borra al fantasma visualmente de donde estaba
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

//Escribe la posición inicial en todos los arrays:
cc_reset_escribir:
    // escribir nueva posición en la casa
    ldr x9, =fantasmasX
    str w15, [x9, x19, lsl #2]  // X = posición inicial
    ldr x9, =fantasmasY
    str w16, [x9, x19, lsl #2]  // Y = posición inicial

    // actualizar old también con la nueva posición
    ldr x9, =fantasmasOldX
    str w15, [x9, x19, lsl #2]  // OldX = mismo valor
    ldr x9, =fantasmasOldY
    str w16, [x9, x19, lsl #2]  // OldY = mismo valor

    // resetear dirección a arriba (para que salga de la casa):
    ldr x9, =fantasmasDir
    mov w15, #2   // dirección = arriba
    str w15, [x9, x19, lsl #2]

    // apagar el timer de ESTE fantasma
    ldr x9, =frightenedTimer
    mov w15, #0
    str w15, [x9, x19, lsl #2]
    b cc_next    // seguir con el siguiente fantasma

    // en el siguiente frame despues del reset, el fantasma está dentro de la casa
    // (en su posicion inicial) y se pregunta: linea 273

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
    