.globl app
app:
	//---------------- Inicialización GPIO --------------------

	mov w20, PERIPHERAL_BASE + GPIO_BASE     // Dirección de los GPIO.		
	
	// Configurar GPIO 17 como input:
	mov X21,#0
	str w21,[x20,GPIO_GPFSEL1] 		// Coloco 0 en Function Select 1 (base + 4)   	



	// Inicializamos las salidas para los led: PIN2 y PIN3
	mov x21,#0b001001000000
	str w21,[x20,GPIO_GPFSEL0]
	
	// hacemos que el PIN2 sea alto 
	mov x21, #0b100
	str w21, [x20, #0x1C]
	
	// hacemos que el PIN3 sea bajo
	mov x21, #0b1000
	str x21, [x20, #0x28]

	//---------------- Main code --------------------
	// X0 contiene la dirección base del framebuffer (NO MODIFICAR)

	ldr x19, =0x400000
	mov sp, x19
	
	bl background
	bl drawMaze
	mov x1, #15
	mov x2, #29
	mov x3, #0      // derecha
	bl drawPacmanAtCellDir

	// --- Infinite Loop ---	
InfLoop: 
	bl drawMaze
	b InfLoop
	