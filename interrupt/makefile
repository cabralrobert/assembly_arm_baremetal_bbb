all: folder compiler

CROSS_COMPILE ?= arm-linux-gnueabihf-

compiler: src/startup.s
	$(CROSS_COMPILE)as src/*.s -o obj/startup.o
	$(CROSS_COMPILE)ld -o startup -T memmap obj/*.o
	$(CROSS_COMPILE)objcopy startup bin/startup.bin -O binary
	cp bin/*.bin /tftpboot

folder:
	mkdir -p bin obj

clean:
	rm -f *.o *.bin -rf bin/ obj/
