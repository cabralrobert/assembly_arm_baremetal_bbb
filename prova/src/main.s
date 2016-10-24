.equ CM_PER_GPIO1_CLKCTRL, 0x44e000AC
.equ GPIO1_OE, 0x4804C134
.equ GPIO1_SETDATAOUT, 0x4804C194
.equ GPIO1_CLEARDATAOUT, 0x4804C190

.equ UART0_BASE, 0x44E09000

.equ WDT_BASE, 0x44E35000

.equ RTC_BASE, 0x44E3E000

.equ CM_RTC_RTC_CLKCTRL, 0x44E00800

.equ CM_RTC_CLKSTCTRL,  0x44E00804

_start:
    /* init */
	    mrs r0, cpsr
	    bic r0, r0, #0x1F @ clear mode bits
	    orr r0, r0, #0x13 @ set SVC mode
	    orr r0, r0, #0xC0 @ disable FIQ and IRQ
	    msr cpsr, r0
	
		bl .gpio_setup
		bl .rtc_setup
   
.uart_putc:
	    stmfd sp!,{r0-r2,lr}
	    ldr     r1, =UART0_BASE

.wait_tx_fifo_empty:
	    ldr r2, [r1, #0x14] 
	    and r2, r2, #(1<<5)
	    cmp r2, #0
	    beq .wait_tx_fifo_empty

	    strb    r0, [r1]
	    ldmfd sp!,{r0-r2,pc}

.gpio_setup:
		ldr r0, =CM_PER_GPIO1_CLKCTRL
	    ldr r1, =0x40002
	    str r1, [r0]

	    ldr r0, =GPIO1_OE
	    ldr r1, [r0]
	    bic r1, r1, #(1<<21)
	    str r1, [r0]
	    bx lr

.rtc_setup:
    	ldr r0, =CM_RTC_CLKSTCTRL
    	ldr r1, =0x2
    	str r1, [r0]
    	ldr r0, =CM_RTC_RTC_CLKCTRL
    	str r1, [r0]

    	/*Disable write protection*/
    	ldr r0, =RTC_BASE
    	ldr r1, =0x83E70B13
    	str r1, [r0, #0x6c]
    	ldr r1, =0x95A4F1E0
    	str r1, [r0, #0x70]
    
    	/* Select external clock*/
    	ldr r1, =0x48
	   	str r1, [r0, #0x54]
	
    	ldr r1, =0x4     /* interrupt every second */
    	str r1, [r0, #0x48]

    	/* Enable RTC */
    	ldr r0, =RTC_BASE
    	ldr r1, =0x01
    	str r1, [r0, #0x40]

		ldr r1, =RTC_BASE
		ldr r0, ='0'
		str r0, [r1, #0]

		mov r9, #0

.teste_muda:
	    ldr r1,=RTC_BASE
		ldr r0, [r1, #0] //seconds
		cmp r6, r0
		mov r6, r0
		bne .imprime
		cmp r0, #57
		beq .pisca
		cmp r0, #56
		beq .pisca
		cmp r0, #64
		beq .end
		b .teste_muda
		
.imprime:
		add r4, r0, #57
		add r8, r0, r9
		sub r0, r4, r8
		add r9, r9, #1
	    bl .uart_putc
		ldr r0, ='\r'
		bl .uart_putc
		b .teste_muda
		
.pisca:
	
	    stmfd sp!,{r0-r2,lr}
		ldr r0, =GPIO1_CLEARDATAOUT
	    ldr r1, =(1<<21)
	    str r1, [r0]

	    ldr r1, =0xffffff
.wait_1:
	    sub r1, r1, #0x1
	    cmp r1, #0
	    bne .wait_1

	    ldr r0, =GPIO1_SETDATAOUT
		ldr r1, =(1<<21)
	    str r1, [r0]

		ldr r1, =0xffffff
.wait_2:
	    sub r1, r1, #0x1
	    cmp r1, #0
		bne .wait_2

		ldmfd sp!,{r0-r2,pc}

.end:
	    ldr r0, =WDT_BASE
    
	    ldr r1, =0xAAAA
	    str r1, [r0, #0x48]
	    bl .poll_wdt_write

	    ldr r1, =0x5555
	    str r1, [r0, #0x48]
	    bl .poll_wdt_write

		ldr r1, =0xFFFFFFFF
		str r1, [r0, #0x28]
	    bl .poll_wdt_write

	    ldr r1, =0xBBBB
	    str r1, [r0, #0x48]
	    bl .poll_wdt_write

	    ldr r1, =0x4444
	    str r1, [r0, #0x48]
	    bl .poll_wdt_write

.poll_wdt_write:
		ldr r1, [r0, #0x34]
	    and r1, r1, #(1<<4)
	    cmp r1, #0
	    bne .poll_wdt_write
	    bx lr

