all: folder compiler copy

CROSS_COMPILE ?= arm-linux-gnueabihf-
TFTP = /tftpboot/
BIN = blinkLed.bin

compiler: src/blink.s
	$(CROSS_COMPILE)as src/blink.s -o obj/blink.o
	$(CROSS_COMPILE)objcopy obj/blink.o bin/$(BIN) -O binary

folder: 
	mkdir -p bin obj

copy:
	cp bin/*.bin $(TFTP)

clean:
	rm obj/*.o bin/*.bin -rf obj/ bin/
