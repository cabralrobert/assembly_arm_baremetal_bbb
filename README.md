# assembly_arm_baremetal_bbb
Codes in assembly to ARM for bare metal on black beaglebone

To compile configure the folder of the TFTP server and the name of the binary file. Finally use the command "make" the files are generated.

Use the "make clean" command to clear the generated files.

	1) blinkLed program is simply making the exchange of states set GPIO.
	2) counter program is an counter of 0x0 to 0xF using the LED's of board.
	3) irq_rtc program is an exemple of UART to write in serial port on beaglebone black.
