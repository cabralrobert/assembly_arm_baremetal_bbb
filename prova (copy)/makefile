all: folder compiler

CROSS_COMPILE ?= arm-linux-gnueabihf-

compiler: src/main.s
	$(CROSS_COMPILE)as src/main.s -o obj/main.o
	$(CROSS_COMPILE)objcopy obj/main.o bin/prova.bin -O binary
	$(CROSS_COMPILE)objdump -DSx -b binary -marm bin/prova.bin > prova.lst
	cp bin/*.bin /tftpboot/

folder:
	mkdir -p bin obj

clean:
	rm -f *.o *.bin -rf bin/ obj/
