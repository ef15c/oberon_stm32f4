  .syntax unified
  .cpu cortex-m4
  .thumb

.global testTrap

    .thumb_func
testTrap:
    cmp R0, #10
    .byte 0xA8, 0xBF                // it ge
    .byte 0x12, 0xED, 0x56, 0x34    // Pour générer une exception
//    it ge
//    stcge p0, cr0, [r0, #0]
    bx lr

.global led

    .thumb_func
led:
    svc #1
    bx lr

.global ReadSD

    .thumb_func
ReadSD:
    svc #2
    bx lr

.global SVC_Handler

    .thumb_func
SVC_Handler:
    tst lr, #4
    ite eq
    mrseq r0, msp
    mrsne r0, psp
    b Oberon_SVC_Handler

.global UsageFault_Handler

    .thumb_func
UsageFault_Handler:
    tst lr, #4
    ite eq
    mrseq r0, msp
    mrsne r0, psp
    b Oberon_UsageFault_Handler
