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
