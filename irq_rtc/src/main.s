/*
Bare metal BeagleBone Black example for turning on led USR0.
*/



/* Registers */
.equ CM_PER_GPIO1_CLKCTRL, 0x44e000AC
.equ GPIO1_OE, 0x4804C134
.equ GPIO1_SETDATAOUT, 0x4804C194
.equ GPIO1_CLEARDATAOUT, 0x4804C190

.equ WDT_BASE, 0x44E35000

.equ UART0_BASE, 0x44E09000

.equ RTC_BASE, 0x44E3E000

.equ INTC_BASE, 0x48200000

.equ CM_RTC_RTC_CLKCTRL, 0x44E00800

.equ CM_RTC_CLKSTCTRL,  0x44E00804

.equ EXCEPTION_BASE, 0x4030CE20

_start:
    /* init */
    mrs r0, cpsr
    bic r0, r0, #0x1F @ clear mode bits
    orr r0, r0, #0x13 @ set SVC mode
    orr r0, r0, #0xC0 @ disable FIQ and IRQ
    msr cpsr, r0

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

