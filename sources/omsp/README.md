# MSP430 Oberon compiler
<b>WORK IN PROGRESS<b>
## Specific extensions
### Runtime modules
Due to the limited RAM and Flash resources, it is useful to remove the trap
overhead from the final code.<br>
For the MSP430 target, I implemented optional runtime modules, which are for now
Traps and Arith. The Traps module implement the trap handlers code. For example,
Traps.ArrayOutOfRange is called when an out of range index is detected at the
execution time.<br>
If an handler is not defined, the corresponding checking code is not generated, 
eliminating the overhead related to the associated trap.
### Vector list
An asterisk after a procedure name defines an interrupt handler. The asterisk
must be followed by one or more vector numbers separated by commas, indicating
which interrupts the handler will be servicing.
