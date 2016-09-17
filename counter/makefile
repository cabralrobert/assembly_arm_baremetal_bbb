all: folder compiler copy

CROSS_COMPILE ?= arm-linux-gnueabihf-
TFTP = /tftpboot/
BIN = robert.bin

compiler: src/contador.s
	$(CROSS_COMPILE)as src/contador.s -o obj/contador.o
	$(CROSS_COMPILE)objcopy obj/contador.o bin/$(BIN) -O binary

folder: 
	mkdir -p bin obj

copy:
	cp bin/*.bin $(TFTP)

clean:
	rm obj/*.o bin/*.bin -rf obj/ bin/
