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
	
	mov w3, #0b0001000001000010    	// 0xffff = ROJO	
	add x10, x0, 0		// X10 contiene la dirección base del framebuffer
loop2:
	mov x2,512         	// Tamaño en Y
loop1:
	mov x1,512         	// Tamaño en X
loop0:
	sturh w3,[x10]	   	// Setear el color del pixel N
	add x10,x10,2	   	// Siguiente pixel
	sub x1,x1,1	   		// Decrementar el contador X
	cbnz x1,loop0	   	// Si no terminó la fila, saltar
	sub x2,x2,1	   		// Decrementar el contador Y
	cbnz x2,loop1	  	// Si no es la última fila, saltar
	
	// --- Delay loop ---
	movz x11, 0x10, lsl #16
delay1: 
	sub x11,x11,#1
	cbnz x11, delay1
	// ------------------
		
	bl inputRead		// Leo el GPIO17 y lo guardo en x22
	mov w3, #0b0001000001000010    	// 0x001F = AZUL	
	add x10, x0, 0		// X10 contiene la dirección base del framebuffer
	cbz X22, loop2
	mov w3, 0x07E0    	// 0x07E0 = VERDE			
	b loop2
	
	// --- Infinite Loop ---	
InfLoop: 
	b InfLoop
	