//--------DEFINICIÓN DE FUNCIONES-----------//
    .global inputRead    
	//DESCRIPCION: Lee el boton en el GPIO17. 
//------FIN DEFINICION DE FUNCIONES-------//

inputRead: 	
	ldr w22, [x20, GPIO_GPLEV0] 	// Leo el registro GPIO Pin Level 0 y lo guardo en X22
	and X22,X22,#0x20000	// Limpio el bit 17 (estado del GPIO17)
		
    br x30 		//Vuelvo a la instruccion link

RedOn:
	mov w15, PERIPHERAL_BASE + GPIO_BASE
	mov x14, #0b1000
	str x14, [x15, #0x28]
	br x30

GreenOn:
	mov w15, PERIPHERAL_BASE + GPIO_BASE 
	mov x14, #0b100
	str x14, [x15, #0x28]
	br x30

RedOff:
	mov w15, PERIPHERAL_BASE + GPIO_BASE
	mov x14, #0b100
	str x14, [x15, ##0x1C]
	br x30
GreenOff:
	mov w15, PERIPHERAL_BASE + GPIO_BASE
	mov x14, #0b1000
	str x14, [x15, ##0x1C]
	br x30
