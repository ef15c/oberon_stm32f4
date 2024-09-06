# MSP430 Oberon compiler
**WORK IN PROGRESS**
## Language differences from Oberon 07 for Cortex M4
### Integer and Byte pointers
PINTEGER an PBYTE types have been defined to enforce the access size on
specific memory locations. See msp430g2553.Mod as an example.
### In-line procedures and functions
Due to the difference of instruction set architectures, the following
In-line procedures or functions have been removed: **LSL(x, n)**, 
**ASR(x, n), **ROR(x, n)**  
With PINTEGER and PBYTE types, **SYSTEM.PUT** and **SYSTEM.GET** 
are no more useful and are removed.  
This compiler is board agnostic, so **LED** is removed.
<<To be completed>>
## Specific extensions
### Runtime modules
Due to the limited RAM and Flash resources, it is useful to remove the trap
overhead from the final code.  
For the MSP430 target, I implemented optional runtime modules, which are for now
Traps and Arith. The Traps module implement the trap handlers code. For example,
Traps.ArrayOutOfRange is called when an out of range index is detected at the
execution time.  
If an handler is not defined, the corresponding checking code is not generated, 
eliminating the overhead related to the associated trap.
### Vector list
An asterisk after a procedure name defines an interrupt handler. The asterisk
must be followed by one or more vector numbers separated by commas, indicating
which interrupts the handler will be servicing.
## Example
To show what a real program looks like, this is an example based on 
msp430g2xx3_lpm3_vlo.c, a C language example from TI.

(*******************************************************************************  
//  MSP430G2xx3 Demo - Basic Clock, LPM3 Using WDT ISR, VLO ACLK  
//  
//  Description: This program operates MSP430 normally in LPM3, pulsing P1.0  
//  ~ 6 second intervals. WDT ISR used to wake-up system. All I/O configured  
//  as low outputs to eliminate floating inputs. Current consumption does  
//  increase when LED is powered on P1.0. Demo for measuring LPM3 current.  
//  ACLK = VLO/2, MCLK = SMCLK = default DCO  
//  
//  
//           MSP430G2xx3  
//         ---------------  
//     /|\|            XIN|-  
//      | |               |  
//      --|RST        XOUT|-  
//        |               |  
//        |           P1.0|-->LED  
//  
//  Eason Zhou  
//  Texas Instruments Inc.  
//  January 2020  
//  Ported to Oberon by C. Schoffit 30.08.2024  
//******************************************************************************)  
  
MODULE msp430g2xx3lpm3vlo;  
  IMPORT SYSTEM, M := msp430g2553;  
  
  VAR i: INTEGER;  

  PROCEDURE* (M.WDT_VECTOR) ^0 watchdog_timer ;  
  BEGIN SYSTEM.BIC_SR_ON_EXIT(M.LPM3_bits) (* Clear LPM3 bits from SR backup *)  
  END watchdog_timer ;  

BEGIN  
  BIS(M.BCSCTL1^, M.DIVA_1); (* ACLK/2 *)  
  BIS(M.BCSCTL3^, M.LFXT1S_2); (* ACLK = VLO *)  
  M.WDTCTL^ := ORD(M.WDT_ADLY_1000); (* Interval timer *)  
  BIS(M.IE1^, M.WDTIE); (* Enable WDT interrupt *)  
  M.P1DIR^ := 0FFH; (* All P1.x outputs *)  
  M.P1OUT^ := 0; (* All P1.x reset *)  
  M.P2DIR^ := 0FFH; (* All P2.x outputs *)  
  M.P2OUT^ := 0; (* All P2.x reset *)  
  M.P3DIR^ := 0FFH; (* All P3.x outputs *)  
  M.P3OUT^ := 0; (* All P3.x reset *)  
    
  REPEAT   
    BIS(M.P1OUT^, {0}); (* Set P1.0 LED on *)  
    i := 10000; REPEAT DEC(i) UNTIL i <= 0; (* Delay *)  
    BIC(M.P1OUT^, {0}); (* Reset P1.0 LED off *)  
    SYSTEM.BIS_SR(M.LPM3_bits + M.GIE) (* Enter LPM3 *)  
  UNTIL FALSE  
END msp430g2xx3lpm3vlo.  
  
Compilation and linking is done by OMSPP and OMSPL modules:  
  
OMSPP msp430g2553 msp430g2xx3lpm3vlo ~  
OMSPL.Link 32 4000H 200H msp430g2xx3lpm3vlo ~  
  
The linker produces a program in TI-TXT format:  
  
@C000  
B1 C0 D0 00 00 00 00 13 F2 D0 10 00 57 00 F2 D0  
20 00 53 00 B2 40 1C 5A 20 01 D2 D3 00 00 F2 43  
22 00 C2 43 21 00 F2 43 2A 00 C2 43 29 00 F2 43  
1A 00 C2 43 19 00 D2 D3 21 00 B2 40 10 27 00 02  
92 83 00 02 0F 43 1F 92 00 02 FA 3B D2 C3 21 00  
32 D0 D8 00 F0 3F 30 41 31 40 00 04 B0 12 08 C0  
32 D0 10 00 FD 3F  
@FFE0  
60 C0 60 C0 60 C0 60 C0 60 C0 60 C0 60 C0 60 C0  
60 C0 60 C0 00 C0 60 C0 60 C0 60 C0 60 C0 58 C0  
q  

This program can be installed on a MSP430 device with the 
MSP Flasher tool provided by Texas Instruments.

