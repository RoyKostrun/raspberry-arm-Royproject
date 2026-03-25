.globl app
app:
	//---------------- Inicialización GPIO --------------------

	mov w20, PERIPHERAL_BASE + GPIO_BASE     // Dirección de los GPIO.		
	
	// Configurar GPIO 17 ( del 10 al 19 ) como input:
	mov X21,#0
	str w21,[x20,GPIO_GPFSEL1] 		// Coloco 0 en Function Select 1 (base + 4)   	


	// Inicializamos las salidas para los led: PIN2 y PIN3
	mov w21, #0b001001000000
	str w21, [x20, GPIO_GPFSEL0]
	
	// hacemos que el PIN2 sea alto
	mov w21, #0b100
	str w21, [x20, #0x1C]
	
	// hacemos que el PIN3 sea bajo
	mov w21, #0b1000
	str w21, [x20, #0x28]

	//---------------- Main code --------------------
	// X0 contiene la dirección base del framebuffer (NO MODIFICAR)

	ldr x19, =0x400000
	mov sp, x19
	
	bl background
	bl drawMaze
	bl dibujarPacmanActual

	bl inputRead

	// --- Infinite Loop ---	
InfLoop: 
	bl inputRead
	bl actualizarDireccionPacman
	bl moverPacman
	bl borrarPacmanAnterior

	bl dibujarPacmanActual
	bl delaySimple

	b InfLoop
	