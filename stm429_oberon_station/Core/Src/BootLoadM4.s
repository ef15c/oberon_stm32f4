  .syntax unified
  .cpu cortex-m4
  .thumb

  .global BootLoadM4

  .thumb_func
BootLoadM4:
  .byte 0X00, 0XF0, 0X29, 0XB8, 0XBD, 0XF1, 0X08, 0X0D, 0X00, 0XB5, 0X04, 0X20, 0XC0, 0XF2, 0X08, 0X00
  .byte 0X41, 0XF2, 0X00, 0X01, 0XCD, 0XF2, 0X20, 0X01, 0X01, 0X22, 0X02, 0XDF, 0X01, 0X90, 0X41, 0XF2
  .byte 0X10, 0X00, 0XCD, 0XF2, 0X20, 0X00, 0X00, 0X68, 0X02, 0X90, 0X05, 0X20, 0XC0, 0XF2, 0X08, 0X00
  .byte 0X41, 0XF2, 0X00, 0X21, 0XCD, 0XF2, 0X20, 0X01, 0X02, 0X9A, 0X4F, 0XF2, 0XFF, 0X13, 0XC2, 0XF6
  .byte 0XDF, 0X73, 0XD2, 0X18, 0X52, 0X12, 0X52, 0X1E, 0X02, 0XDF, 0X01, 0X90, 0X5D, 0XF8, 0X04, 0XEB
  .byte 0X1D, 0XF1, 0X08, 0X0D, 0X70, 0X47, 0X42, 0X20, 0X01, 0XDF, 0XFF, 0XF7, 0XD3, 0XFF, 0X41, 0XF2
  .byte 0X0C, 0X00, 0XCD, 0XF2, 0X20, 0X00, 0X00, 0X21, 0XCD, 0XF2, 0X80, 0X01, 0X01, 0X60, 0X41, 0XF2
  .byte 0X18, 0X00, 0XCD, 0XF2, 0X20, 0X00, 0X00, 0X21, 0XC1, 0XF2, 0X01, 0X01, 0X01, 0X60, 0X44, 0X20
  .byte 0X01, 0XDF, 0X41, 0XF2, 0X01, 0X00, 0XCD, 0XF2, 0X20, 0X00, 0X00, 0X47


  // End of file.