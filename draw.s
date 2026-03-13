
// subrutinas

background:
	mov w3, #0b0001000001000010   // 0xFFFF
	add x10, x0, 0		// X0 contiene la dirección base del framebuffer
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

pared1:
    mov w3, 0x001f
    mov x1, 10                  // x
pared1loop:
    mov x4, 512                // ancho
    mov x5, 10                  // y
    mul x6, x5, x4             // y * 512
    add x6, x6, x1             // y*512 + x
    lsl x6, x6, 1              // *2 bytes por pixel
    add x6, x0, x6             
    sturh w3, [x6]
    add x1, x1, 1
    cmp x1, 501
    b.ne pared1loop
pared2:
    mov w3, 0x001f
    mov x1, 10                  // y
    mov x5, 10                  // x
pared2loop:
    mov x4, 512                // alto
    mul x6, x1, x4             // y * 512
    add x6, x6, x5             // y*512 + x
    lsl x6, x6, 1              // *2 bytes por pixel
    add x6, x0, x6             
    sturh w3, [x6]
    add x1, x1, 1
    cmp x1, 501
    b.ne pared2loop
pared3:
    mov w3, 0x001f
    mov x1, 10                  // y
    mov x5, 501                  // x
pared3loop:
    mov x4, 512                // alto
    mul x6, x1, x4             // y * 512
    add x6, x6, x5             // y*512 + x
    lsl x6, x6, 1              // *2 bytes por pixel
    add x6, x0, x6             
    sturh w3, [x6]
    add x1, x1, 1
    cmp x1, 501
    b.ne pared3loop 
pared4:
    mov w3, 0x001f
    mov x1, 10                  // x
    mov x5, 501                  // y
pared4loop:
    mov x4, 512                // ancho
    mul x6, x5, x4             // y * 512
    add x6, x6, x1             // y*512 + x
    lsl x6, x6, 1              // *2 bytes por pixel
    add x6, x0, x6             
    sturh w3, [x6]
    add x1, x1, 1
    cmp x1, 501
    b.ne pared4loop 
    ret

