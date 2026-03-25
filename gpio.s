.equ DIR_NINGUNO,   0
.equ DIR_ARRIBA,    1
.equ DIR_ABAJO,     2
.equ DIR_IZQUIERDA, 3
.equ DIR_DERECHA,   4

.equ MASK_GPIO14, 0b100000000000000 //0x00004000
.equ MASK_GPIO15, 0b1000000000000000 //0x00008000
.equ MASK_GPIO17, 0b100000000000000000 //0x00020000
.equ MASK_GPIO18, 0b1000000000000000000 //0x00040000
.equ MASK_DIRS,   0b1101100000000000000 //0x0006C000

.balign 4
direccionActual:
    .word DIR_NINGUNO

//--------DEFINICIÓN DE FUNCIONES-----------//
    .global inputRead    
	//DESCRIPCION: Lee el boton en el GPIO17. 
//------FIN DEFINICION DE FUNCIONES-------//


.global inputRead

inputRead:
    // Leer GPIO_GPLEV0
	mov w20, PERIPHERAL_BASE + GPIO_BASE     // Dirección de los GPIO.		
    ldr w22, [x20, GPIO_GPLEV0]
	

    // Filtrar solo GPIO 14,15,17,18
    ldr w23, =MASK_DIRS
    and w22, w22, w23

    // ninguno activo
    cbz w22, guardar_ninguno

    // GPIO14 = arriba
    ldr w23, =MASK_GPIO14
    cmp w22, w23
    b.eq guardar_arriba

    // GPIO15 = izquierda
    ldr w23, =MASK_GPIO15
    cmp w22, w23
    b.eq guardar_izquierda

    // GPIO17 = derecha
    ldr w23, =MASK_GPIO17
    cmp w22, w23
    b.eq guardar_derecha

    // GPIO18 = abajo
    ldr w23, =MASK_GPIO18
    cmp w22, w23
    b.eq guardar_abajo

    // dos o más activos => ignorar
    b guardar_ninguno

guardar_arriba:
    mov w15, PERIPHERAL_BASE + GPIO_BASE
    mov w14, #0b1000
    str w14, [x15, #0x1C]

    ldr x24, =direccionActual
    mov w25, #DIR_ARRIBA
    str w25, [x24]
    br x30

guardar_abajo:
    ldr x24, =direccionActual
    mov w25, #DIR_ABAJO
    str w25, [x24]
    br x30

guardar_izquierda:
    ldr x24, =direccionActual
    mov w25, #DIR_IZQUIERDA
    str w25, [x24]
    br x30

guardar_derecha:
    ldr x24, =direccionActual
    mov w25, #DIR_DERECHA
    str w25, [x24]
    br x30

guardar_ninguno:
    mov w15, PERIPHERAL_BASE + GPIO_BASE
    mov w14, #0b100
    str w14, [x15, #0x28]

    ldr x24, =direccionActual
    mov w25, #DIR_NINGUNO
    str w25, [x24]
    br x30

.global actualizarDireccionPacman

.global actualizarDireccionPacman

actualizarDireccionPacman:
    // leer direccionActual (botones)
    ldr x9, =direccionActual
    ldr w10, [x9]

    // si no hay dirección nueva, no cambiar
    cbz w10, fin_actualizarDireccionPacman

    // leer posición actual de Pac-Man
    ldr x11, =pacmanX
    ldr w12, [x11]          // x actual

    ldr x13, =pacmanY
    ldr w14, [x13]          // y actual

    // nextX / nextY candidatos
    mov w15, w12
    mov w16, w14

    // w17 = dirección del sprite candidata
    // mapear direccionActual:
    // 1 arriba    -> sprite 2
    // 2 abajo     -> sprite 3
    // 3 izquierda -> sprite 1
    // 4 derecha   -> sprite 0

    cmp w10, #1
    b.ne check_dir_abajo
    mov w17, #2
    sub w16, w16, #1       // probar arriba
    b check_cambio_bounds

check_dir_abajo:
    cmp w10, #2
    b.ne check_dir_izquierda
    mov w17, #3
    add w16, w16, #1       // probar abajo
    b check_cambio_bounds

check_dir_izquierda:
    cmp w10, #3
    b.ne check_dir_derecha
    mov w17, #1
    // portal izquierdo
    cmp w15, #0
    b.ne cambio_left_normal
    mov w15, #30
    b check_cambio_bounds
cambio_left_normal:
    sub w15, w15, #1
    b check_cambio_bounds

check_dir_derecha:
    cmp w10, #4
    b.ne fin_actualizarDireccionPacman
    mov w17, #0
    // portal derecho
    cmp w15, #30
    b.ne cambio_right_normal
    mov w15, #0
    b check_cambio_bounds
cambio_right_normal:
    add w15, w15, #1

check_cambio_bounds:
    // verificar límites verticales
    cmp w16, #0
    b.lt fin_actualizarDireccionPacman
    cmp w16, #30
    b.gt fin_actualizarDireccionPacman

    // verificar límites horizontales
    cmp w15, #0
    b.lt fin_actualizarDireccionPacman
    cmp w15, #30
    b.gt fin_actualizarDireccionPacman

    // leer mazeMap31[nextY][nextX]
    ldr x18, =mazeMap31
    mov w19, #31
    mul w20, w16, w19
    add w20, w20, w15
    add x18, x18, x20
    ldrb w21, [x18]

    // si hay pared, NO cambiar dirección
    cmp w21, #'1'
    b.eq fin_actualizarDireccionPacman

    // si no hay pared, actualizar pacmanDir
    ldr x22, =pacmanDir
    str w17, [x22]

fin_actualizarDireccionPacman:
    br x30

RedOn:
	mov w15, PERIPHERAL_BASE + GPIO_BASE
	mov w14, #0b1000
	str w14, [x15, #0x28]
	br x30

GreenOn:
	mov w15, PERIPHERAL_BASE + GPIO_BASE 
	mov w14, #0b100
	str w14, [x15, #0x28]
	br x30

RedOff:
	mov w15, PERIPHERAL_BASE + GPIO_BASE
	mov w14, #0b100
	str w14, [x15, #0x1C]
	br x30

GreenOff:
	mov w15, PERIPHERAL_BASE + GPIO_BASE
	mov w14, #0b1000
	str w14, [x15, #0x1C]
	br x30
