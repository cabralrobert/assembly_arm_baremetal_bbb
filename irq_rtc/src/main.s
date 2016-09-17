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

   // bl .exception_setup
    bl .gpio_setup
    //bl .rtc_setup
    bl .disable_wdt

    mrs r0, cpsr
    ldr r2,=~(1<<7)  //enable irq
    and r0, r0, r2  
    msr cpsr, r0

    bl .print_string

.main_loop:

    /* logical 1 turns on the led, TRM 25.3.4.2.2.2 */
    ldr r0, =GPIO1_CLEARDATAOUT
    ldr r1, =(1<<21)
    str r1, [r0]
    bl .delay
    
    
    ldr r0, =GPIO1_SETDATAOUT
    ldr r1, =(1<<21)
    str r1, [r0]
    bl .delay

    b .main_loop    

/********************************************************/
.exception_setup:
    ldr r0, =EXCEPTION_BASE
   // ldr r1, =handler_undefined_entry
   // str r1, [r0, #4]

    ldr r1, =handler_irq_entry
    str r1, [r0, #0x18]

    bx lr
/********************************************************/
.print_string:
    stmfd sp!,{r0-r2,lr}
    adr r1, hello
.print:
    ldrb r0,[r1],#1
    and r0, r0, #0xff
    cmp r0, #0
    beq .end_print
    bl .uart_putc
    b .print
    
.end_print:
    ldmfd sp!,{r0-r2,pc}
    
/********************************************************/
.delay:
    ldr r1, =0xfffffff
.wait:
    sub r1, r1, #0x1
    cmp r1, #0
    bne .wait
    bx lr

/********************************************************
UART0 PUTC (Default configuration)  
********************************************************/
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

/********************************************************
  Registers (see TRM 20.4.4.1):
    WDT_BASE -> 0x44E35000
    WDT_WSPR -> 0x44E35048
    WDT_WWPS -> 0x44E35034
********************************************************/
.gpio_setup:
    /* set clock for GPIO1, TRM 8.1.12.1.31 */
    ldr r0, =CM_PER_GPIO1_CLKCTRL
    ldr r1, =0x40002
    str r1, [r0]

    /* set pin 21 for output, led USR0, TRM 25.3.4.3 */
    ldr r0, =GPIO1_OE
    ldr r1, [r0]
    bic r1, r1, #(1<<21)
    str r1, [r0]
    bx lr

/********************************************************
  WDT disable sequence (see TRM 20.4.3.8):
    1- Write XXXX AAAAh in WDT_WSPR.
    2- Poll for posted write to complete using WDT_WWPS.W_PEND_WSPR. (bit 4)
    3- Write XXXX 5555h in WDT_WSPR.
    4- Poll for posted write to complete using WDT_WWPS.W_PEND_WSPR. (bit 4)
    
  Registers (see TRM 20.4.4.1):
    WDT_BASE -> 0x44E35000
    WDT_WSPR -> 0x44E35048
    WDT_WWPS -> 0x44E35034
********************************************************/
.disable_wdt:
    stmfd sp!,{r0-r1,lr}
    ldr r0, =WDT_BASE
    
    ldr r1, =0xAAAA
    str r1, [r0, #0x48]
    bl .poll_wdt_write

    ldr r1, =0x5555
    str r1, [r0, #0x48]
    bl .poll_wdt_write

    ldmfd sp!,{r0-r1,pc}

.poll_wdt_write:
    ldr r1, [r0, #0x34]
    and r1, r1, #(1<<4)
    cmp r1, #0
    bne .poll_wdt_write
    bx lr
/********************************************************/
handler_irq:
    ldr r0,=INTC_BASE
    ldr r1, [r0, #0x40]
    ldr r2, =#~0x7f
    tst r1, r2

    bne end_irq
    
    /* if rtc interrupt */
    and r1,r1, #0x7f
    cmp r1, #75
    bne end_irq

    /*print time*/
    ldr r1,=RTC_BASE
    ldr r0, [r1, #0] //seconds
    bl .uart_putc
    ldr r0,=':'
    bl .uart_putc
    ldr r0, [r1, #4] //minute
    bl .uart_putc
    ldr r0,=':'
    bl .uart_putc
    ldr r0, [r1, #8] //hour
    bl .uart_putc

end_irq:
    bx lr


handler_irq_entry:
        STMFD SP!, {R0-R3, R11, LR}
        MRS R11, SPSR
        BL handler_irq
        LDR r0, =0x48200000 
        LDR r1, =0x1
        STR r1, [r0, #0x48]
        DSB
        MSR SPSR, R11
        LDMFD SP!, {R0-R3, R11, LR}
        SUBS PC, LR, #4

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

/********************************************************/

hello: .asciz "Hello world!!!\n\r"



 


















