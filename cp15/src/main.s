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

	    mrc    p15, 0, r0, c0, c0, 0    // Read CP15 for implementor
	
		mov r5, r0,LSR #24
		and r5, #0b1111111

		cmp r5, #0x41
		bleq .print_implementor

		mov r5, r0,LSR #12
		and r5, #0b1111

		cmp r5, #0x7
		blgt .print_version
		
		mov r5, r0
		and r5, #0b111

		cmp r5, #0x2
		bleq .print_revision

		b .end_program
			

.print_implementor:
    stmfd sp!,{r0-r2,lr}
    adr r1, implementor
.print_i:
    ldrb r0,[r1],#1
    and r0, r0, #0xff
    cmp r0, #0
    beq .end_print_i
    bl .uart_putc
    b .print_i
    
.end_print_i:
    ldmfd sp!,{r0-r2,pc}

.print_version:
    stmfd sp!,{r0-r2,lr}
    adr r1, version
.print_v:
    ldrb r0,[r1],#1
    and r0, r0, #0xff
    cmp r0, #0
    beq .end_print_v
    bl .uart_putc
    b .print_v
    
.end_print_v:
    ldmfd sp!,{r0-r2,pc}

.print_revision:
    stmfd sp!,{r0-r2,lr}
    adr r1, revision
.print_r:
    ldrb r0,[r1],#1
    and r0, r0, #0xff
    cmp r0, #0
    beq .end_print_r
    bl .uart_putc
    b .print_r
    
.end_print_r:
    ldmfd sp!,{r0-r2,pc}

	   
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

implementor: .asciz "Implementor: ARM\n\r"
version: .asciz "Cortex A8\n\r"
revision: .asciz "Revision 2\n\r"

