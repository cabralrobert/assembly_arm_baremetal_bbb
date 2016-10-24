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

_vector_table:
	ldr	pc, _reset
	ldr	pc, _undf
	ldr	pc, _swi
	ldr	pc, _pabt
	ldr	pc, _dabt
	nop
	ldr pc, _irq
	ldr pc, _fiq

	_reset:	.word _start
	_undf:	.word 0x4030CE24
	_swi:	.word 0x4030CE28
	_pabt:	.word 0x4030CE2C
	_dabt:	.word 0x4030CE30
			nop
	_irq:	.word 0x4030CE38
	_fiq:	.word 0x4030CE3C
	

_start:
	mrc p15, 0, r0, c1, c0, 0
	bic	r0, #(1 << 13)
	mcr p15, 0, r0, c1, c0, 0	

	ldr r0, =_vector_table
	mcr p15, 0, r0, c12, c0, 0	
	
    /* init */
    mrs r0, cpsr
    bic r0, r0, #0x1F @ clear mode bits
    orr r0, r0, #0x13 @ set SVC mode
    orr r0, r0, #0xC0 @ disable FIQ and IRQ
    msr cpsr, r0

	ldr r0, =_irq
	ldr r1, =.irq_handler
	str r1, [r0]

	bl .gpio_setup
	bl .rtc_setup
	bl .disable_wdt
	
	ldr r0, =_vector_table
	

handler_irq_entry:
        stmfd sp!, {r0-r3, r11, lr}
        mrs r11, spsr
        bl handler_irq
        ldr r0, =0x48200000 
        ldr r1, =0x1
        str r1, [r0, #0x48]
        dsb
        msr spsr, r11
        ldmfd sp!, {r0-r3, r11, lr}
        subs pc, lr, #4

/********************************************************/
.rtc_setup:
    ldr r0, =CM_RTC_CLKSTCTRL
    ldr r1, =0x2
    str r1, [r0]
    ldr r0, =CM_RTC_RTC_CLKCTRL
    str r1, [r0]

    ldr r0, =RTC_BASE
    ldr r1, =0x83E70B13
    str r1, [r0, #0x6c]

    ldr r1, =0x95A4F1E0
    str r1, [r0, #0x70]

    ldr r1, =0x01
    str r1, [r0, #0x40]

    ldr r1, =0x48
    str r1, [r0, #0x54]

    /*rtc irq setup*/
.wait_rtc_update:
    ldr r1, [r0, #0x44]
    and r1, r1, #1
    cmp r1, #0
    bne .wait_rtc_update

    ldr r1, =0x4     /* interrupt every second */
    str r1, [r0, #0x48]

    ldr r0, =INTC_BASE
    ldr r1, =(1<<11)
    str r1, [r0, #0xc8]
    
    bx lr
