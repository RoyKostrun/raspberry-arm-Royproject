ARMGNU ?= aarch64-none-linux-gnu

AOPS = --warn --fatal-warnings

asm : kernel.img

all : asm

clean :
	rm  *.o
	rm  *.img
	rm  *.hex
	rm  *.elf
	rm  *.list
	rm  *.img
	rm  memory_map.txt

main.o : main.s
	$(ARMGNU)-as $(AOPS) main.s gpio.s app.s draw.s -o main.o


kernel.img : memmap main.o
	$(ARMGNU)-ld main.o -T memmap -o main.elf -M > memory_map.txt
	$(ARMGNU)-objdump -D main.elf > main.list
	$(ARMGNU)-objcopy main.elf -O ihex main.hex
	$(ARMGNU)-objcopy main.elf -O binary kernel8.img
