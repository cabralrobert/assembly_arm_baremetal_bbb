
/* Registers */
.equ CM_PER_GPIO1_CLKCTRL, 0x44e000AC
.equ GPIO1_OE, 0x4804C134
.equ GPIO1_SETDATAOUT, 0x4804C194
.equ GPIO1_CLEARDATAOUT, 0x4804C190

.equ WDT_BASE, 0x44E35000
.equ UART0_BASE, 0x44E09000
.equ RTC_BASE, 0x44E3E000
.equ INTC_BASE, 0x48200000
.equ INTC_ILR,  0x48200100

.equ CM_RTC_RTC_CLKCTRL, 0x44E00800
.equ CM_RTC_CLKSTCTRL,  0x44E00804

//.equ VECTOR_BASE, 0x4030CE20
.equ VECTOR_BASE, 0x4030CE00
//.equ VECTOR_BASE, 0x4030FC00

.equ CPSR_I,   0x80
.equ CPSR_F,   0x40
.equ CPSR_IRQ, 0x12
.equ CPSR_USR, 0x10
.equ CPSR_FIQ, 0x11
.equ CPSR_SVC, 0x13
.equ CPSR_ABT, 0x17
.equ CPSR_UND, 0x1B
.equ CPSR_SYS, 0x1F

//.section .text,"ax"
//         .code 32
//         .align 0

_vector_table:
    ldr   pc, _reset     /* reset - _start           */
    ldr   pc, _undf      /* undefined - _undf        */
    ldr   pc, _swi       /* SWI - _swi               */
    ldr   pc, _pabt      /* program abort - _pabt    */
    ldr   pc, _dabt      /* data abort - _dabt       */
    nop                  /* reserved                 */
    ldr   pc, _irq       /* IRQ - read the VIC       */
    ldr   pc, _fiq       /* FIQ - _fiq               */

_reset: .word _start
_undf:  .word 0x4030CE24 /* undefined               */
_swi:   .word 0x4030CE28 /* SWI                     */
_pabt:  .word 0x4030CE2C /* program abort           */
_dabt:  .word 0x4030CE30 /* data abort              */
         nop
_irq:   .word 0x4030CE38  /* IRQ                     */
_fiq:   .word 0x4030CE3C  /* FIQ                     */

_start:
    /* Set V=0 in CP15 SCTRL register - for VBAR to point to vector */
    mrc    p15, 0, r0, c1, c0, 0    // Read CP15 SCTRL Register
    bic    r0, #(1 << 13)           // V = 0
    mcr    p15, 0, r0, c1, c0, 0    // Write CP15 SCTRL Register

    /* Set vector address in CP15 VBAR register */
    ldr     r0, =_vector_table
    mcr     p15, 0, r0, c12, c0, 0  //Set VBAR

    /* init */
    mrs r0, cpsr
    bic r0, r0, #0x1F            // clear mode bits
    orr r0, r0, #CPSR_SVC        // set SVC mode
    orr r0, r0, #(CPSR_I|CPSR_F) // disable IRQ and FIQ
    msr cpsr, r0

   /* IRQ Handler */
    ldr r0, =_irq
    ldr r1, =.irq_handler
    str r1, [r0]

    /* Hardware setup */
    bl .gpio_setup
    bl .rtc_setup
    bl .disable_wdt

    /*Debug*/ 
    ldr r0,=_vector_table
    ldr r1,=#0x40
    //bl .memory_dump

    /* Enable global irq */
    mrs r0, cpsr
    ldr r2,=~CPSR_I  
    and r0, r0, r2  
    msr cpsr, r0

    mrs r0, cpsr
    bl .hex_to_ascii 

    adr r0, hello
    bl .print_string

.main_loop:
    b .
    ldr r0, =GPIO1_CLEARDATAOUT
    ldr r1, =(1<<21)
    str r1, [r0]
    bl .delay_1s
    bl .print_time
    
    ldr r0, =GPIO1_SETDATAOUT
    ldr r1, =(1<<21)
    str r1, [r0]
    bl .delay_1s
    bl .print_time
    b .main_loop    
/********************************************************
Memory Dump
------------
Imprime o conteúdo da memória.
R0 -> Endereço inicial
R1 -> Quantidade de endereços 
********************************************************/
.memory_dump:
    stmfd sp!,{r0-r3,lr}
    mov r2, r0
    mov r3, r1

dump_loop:  
    // Imprime o endereço
    ldr r0, =hex_prefix
    mov r1, #2
    bl .print_nstring
    mov r0, r2
    bl .hex_to_ascii 

    // Imprime o separador '  :  '
    ldr r0, =dump_separator
    mov r1, #5
    bl .print_nstring

    // Imprime o conteúdo
    ldr r0, =hex_prefix
    mov r1, #2
    bl .print_nstring
    ldr r0, [r2], #4
    bl .hex_to_ascii
    
    //Salta linha
    ldr r0,=CRLF
    mov r1, #2
    bl .print_nstring

    //Verifica se já terminou
    subs r3, r3, #4
    bne dump_loop

    ldmfd sp!,{r0-r3,pc}

/********************************************************
Imprime uma string até o '\0'
// R0 -> Endereço da string
/********************************************************/
.print_string:
    stmfd sp!,{r0-r2,lr}
    mov r1, r0
.print:
    ldrb r0,[r1],#1
    and r0, r0, #0xff
    cmp r0, #0
    beq .end_print
    bl .uart_putc
    b .print
    
.end_print:
    ldmfd sp!,{r0-r2,pc}
/********************************************************
Imprime n caracteres de uma string
// R0 -> Endereço da string R1-> Número de caracteres
/********************************************************/
.print_nstring:
    stmfd sp!,{r0-r2,lr}
    mov r2, r0
.print_n:
    ldrb r0,[r2],#1
    bl .uart_putc
    subs r1, r1, #1
    beq .end_print
    b .print_n
    
.end_print_n:
    ldmfd sp!,{r0-r2,pc}
    
/********************************************************/
.delay_1s:
    stmfd sp!,{r0-r2,lr}
    ldr  r0,=RTC_BASE
    ldrb r1, [r0, #0] //seconds
.wait_second:
    ldrb r2, [r0, #0] //seconds
    cmp r2, r1
    beq .wait_second
    ldmfd sp!,{r0-r2,pc}

/********************************************************
Converte HEX para ASCCI
********************************************************/
.hex_to_ascii:
    stmfd sp!,{r0-r3,lr}
    mov r1, r0

    mov r0, #0
    mov r3, #28
    ldr r2, =ascii

ascii_loop:
    mov r0, r1, LSR r3
    and r0, r0, #0x0f 
    ldrb r0, [r2, r0]
    bl .uart_putc
    subs r3, r3, #4
    bne ascii_loop
    mov r0, r1
    and r0, r0, #0x0f 
    ldrb r0, [r2, r0]
    bl .uart_putc

    ldmfd sp!,{r0-r3,pc}

/********************************************************
GPIO Setup
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

/********************************************************/
rtc_irq:
    STMFD SP!, {R0-R2, LR}
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
    bl .print_time

end_irq:
    LDMFD SP!, {R0-R2, PC}
/********************************************************/
//Input  --> Num: R0, Den: R1 
//Output --> Quot: R0, Rem: R2
div:
    mov r2, r0 //num
    mov r3, r1 //den
    mov r0, #0
div_loop:
    cmp r2,r3
    blt fim_div 
    sub r2, r2, r3
    add r0, r0, #1
    b div_loop
fim_div:
    bx lr  
/********************************************************/
.int_to_ascii: /* de 0 a 99  */
    stmfd sp!,{r0-r2,lr}
    mov r1, #10
    bl div
    add r0, r0, #0x30
    bl .uart_putc
    add r0, r2, #0x30
    bl .uart_putc
    ldmfd sp!, {r0-r2, pc}
/********************************************************
Imprime hora do RTC
(see TRM 20.3.5.1 - 20.3.5.3)
********************************************************/
.rtc_to_ascii:
    stmfd sp!,{r0-r2,lr} 
    mov r0, r0, LSR #4
    add r0, r0,#0x30
    bl .uart_putc
    and r0, r2, #0x0f
    add r0,r0,#0x30
    bl .uart_putc
    ldmfd sp!, {r0-r2, pc}

.print_time:
    stmfd sp!,{r0-r2,lr}
    ldr r1,=RTC_BASE
    ldrb r2, [r1, #8] //hour
    and r0, r2, #0x30
    bl .rtc_to_ascii

    ldr r0,=':'
    bl .uart_putc

    ldrb r2, [r1, #4] //minute
    and r0, r2, #0x70
    bl .rtc_to_ascii

    ldr r0,=':'
    bl .uart_putc

    ldrb r2, [r1, #0] //seconds
    and r0, r2, #0x70
    bl .rtc_to_ascii

    ldr r0,='\r'
    bl .uart_putc
    ldmfd sp!, {r0-r2, pc}


/********************************************************/
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
    //ldr r1, =0x5     /* interrupt every minute */
    //ldr r1, =0x6     /* interrupt every hour */
    str r1, [r0, #0x48]

    /* Enable RTC */
    ldr r0, =RTC_BASE
    ldr r1, =0x01
    str r1, [r0, #0x40]    

    /*rtc irq setup */
.wait_rtc_update:
    ldr r1, [r0, #0x44]
    and r1, r1, #1
    cmp r1, #0
    bne .wait_rtc_update

    /* RTC Interrupt configured as IRQ Priority 0 */
    //RTC Interrupt number 75
    ldr r0, =INTC_ILR
    ldr r1, =#0    
    strb r1, [r0, #75] 

    /* Interrupt mask */
    ldr r0, =INTC_BASE
    ldr r1, =#(1<<11)    
    str r1, [r0, #0xc8] //(75 --> Bit 11 do 3º registrador (MIR CLEAR2))

    bx lr

/********************************************************/
.irq_handler:
        STMFD SP!, {R0-R3, R11, LR}
        MRS R11, SPSR

        bl rtc_irq


        /* new IRQ */
        LDR r0, =INTC_BASE 
        LDR r1, =0x1
        STR r1, [r0, #0x48]

        DSB
        MSR SPSR, R11
        LDMFD SP!, {R0-R3, R11, LR}
        SUBS PC, LR, #4




.fiq_handler:
   b .      // infinite loop
.undefined_handler:
   b .      // infinite loop
.swi_handler:
   b .      // infinite loop
.prefetch_handler:
   b .      // infinite loop
.data_handler:
   b .      // infinite loop




hello: .asciz "Hello world!!!\n\r"
ascii: .asciz "0123456789ABCDEF"
hex_prefix: .asciz "0x"
CRLF: .asciz "\n\r"
dump_separator: .asciz "  :  "




 


















