.globl app    //  casillero: direccion de memoria reservada
app:
	//---------------- Inicialización GPIO --------------------
// PERIPHERAL_BASE: 0x3f000000, dirección donde comienzan todos los casilleros de hw de la raspberry pies
// GPIO_BASE: 0x200000, es cuanto hay que avanzar desde el inicio oara llegar a los casilleros( de mem ) que controlan los pines
	mov w20, PERIPHERAL_BASE + GPIO_BASE     // Dirección del primer casillero  de configuración de los pines		
	
	// Configurar botones de entrada ( del 10 al 19 ): 
	mov X21,#0
	str w21,[x20,GPIO_GPFSEL1] 		// Coloco 0 en Function Select 1 (base + 4)   	
				 // Casillero que controla los pines del 10 al 19

	// Inicializamos las salidas para los led: PIN2 y PIN3
	mov w21, #0b001001000000
	str w21, [x20, GPIO_GPFSEL0]
				   // Casillero que controla los pines del 0 al 9

	// hacemos que el PIN2 sea alto, luz verde se apaga
	mov w21, #0b100    //tiene un solo 1 en la posición 2, afecta solo al pin2 
	str w21, [x20, #0x1C]
				   // es la oficina ( offset ) del casillero GPIO_SET0, q cuando escribimos 1 en este, el pin se pone en alto

	// hacemos que el PIN3 sea bajo, luz roja se prende
	mov w21, #0b1000 // tiene un 1 en la posición 3, afecta solo al pin3
	str w21, [x20, #0x28]
				// es el offset del casillero GPCLRO ( GPIO clear ), q cuando escribimos 1 en este, el pin se pone en bajo

	//---------------- Main code --------------------
	// X0 contiene la dirección base del framebuffer (NO MODIFICAR)

	ldr x19, =0x400000 // el stack arranca en esa direccion y ccrece hacia abajo
	mov sp, x19 // sp apunta a zona de memoria valida
	
	bl background
	bl drawMaze
	bl dibujarPuntos
	bl dibujarPacmanActual

	bl inputRead

	// --- Infinite Loop ---	

InfLoop:
	// si ya perdimos, pausa
    ldr x23, =gameOver
    ldr w24, [x23]
    cbnz w24, game_over_loop

	// si ganamos, pausa
    ldr x23, =gameWon
    ldr w24, [x23]
    cbnz w24, game_won_loop

    bl inputRead
    bl actualizarDireccionPacman
    bl moverPacman
    bl comerPunto
	bl checkColisionFantasmas

    bl moverFantasmas
    bl borrarFantasmas
    bl dibujarPuntos
    bl dibujarFantasmas

    bl borrarPacmanAnterior
    bl dibujarPacmanActual

    bl checkColisionFantasmas       

    bl delaySimple
    b InfLoop

game_over_loop:
    bl delaySimple
    b InfLoop

game_won_loop:
    bl delaySimple
    b InfLoop
	