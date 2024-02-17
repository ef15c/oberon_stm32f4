  .syntax unified
  .cpu cortex-m4
  .thumb

.global SVC_Handler

    .thumb_func
SVC_Handler:
    tst lr, #4
    ite eq
    mrseq r0, msp
    mrsne r0, psp
    b Oberon_SVC_Handler

