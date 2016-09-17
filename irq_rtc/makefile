all: folder compiler

CROSS_COMPILE ?= arm-linux-gnueabihf-

compiler: src/main.s
	$(CROSS_COMPILE)as src/main.s -o obj/main.o
	$(CROSS_COMPILE)objcopy obj/main.o bin/robert.bin -O binary
	cp bin/*.bin /tftpboot/

folder:
	mkdir -p bin obj

clean:
	rm -f *.o *.bin -rf bin/ obj/
