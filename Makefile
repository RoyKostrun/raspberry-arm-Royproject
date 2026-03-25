ARMGNU ?= aarch64-none-linux-gnu

AOPS = --warn --fatal-warnings

asm: kernel8.img
all: asm

clean:
	rm -f *.o *.img *.hex *.elf *.list memory_map.txt kernel8.img

main.o: main.s gpio.s app.s draw.s drawPacman.s movementPacman.s
	$(ARMGNU)-as $(AOPS) main.s gpio.s app.s draw.s drawPacman.s movementPacman.s -o main.o

kernel8.img: memmap main.o
	$(ARMGNU)-ld main.o -T memmap -o main.elf -M > memory_map.txt
	$(ARMGNU)-objdump -D main.elf > main.list
	$(ARMGNU)-objcopy main.elf -O ihex main.hex
	$(ARMGNU)-objcopy main.elf -O binary kernel8.img
	copy /Y kernel8.img D:\kernel8.img