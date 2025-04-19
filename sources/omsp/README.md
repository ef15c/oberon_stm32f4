# MSP430 Oberon compiler
## Differences from previous releases
The main point is the adding support of <b>stored objects</b>. This can be seen as immutable variables initialized at compile time and stored in flash.
Lot of bug fixes and improvements have been added.  
Two examples Thermometre (MSP430G2231) and nRF24l01+ relay (MSP430G2553) have been added.  
  
Details:

* Cleaning of the code
* Minor bugs fixed
* Adding stored objects
* Adding the standard function <B>PTR</B> (see below)

## Language differences from Oberon 07 for Cortex M4
### Stored objects
The Oberon 07 language has no support for defining constants objects like records.
 In microcontroller field, is is very useful to have compile time initialized objects stored in embedded flash memory.  
 OMSP provides a way to achieve this, a concept similar as the "one time initialization" concept implemented in OM4 compiler.
  Let'see it trough a simplified example:
  
    MODULE nrf24pRelay;
      CONST
        EMIT* = {1..3};
        LOW_POWER* = {1, 5};
        EN_DPL* = {2}; EN_ACK_PAY* = {1} + EN_DPL;

      TYPE
        RadioPipe* = RECORD payload_length*: BYTE; address*: ARRAY 6 OF CHAR END;
        RadioSetup* = RECORD direction*: BYTESET; channel*: BYTE; rf_setup*, features*: BYTESET;
          pipes_count*: BYTE; pipes*: ARRAY 6 OF RadioPipe
        END;
      VAR confEmitter: RadioSetup-;
    
    BEGIN
      confEmitter.direction := EMIT; confEmitter.channel := 110; confEmitter.rf_setup := LOW_POWER;
      confEmitter.features := EN_ACK_PAY; confEmitter.pipes_count := 1;
      confEmitter.pipes[0].payload_length := 0; confEmitter.pipes[0].address := "RSCHO";
    END nrf24pRelay.

Notice the hyphen character after N.RadioSetup type in the VAR clause.
It means that the variable `confEmitter` is immutable and will be stored in the embedded flash memory.
The actual definition of this object is computed at compiler or link time and outputted to the
 constant section of the object file.  
Because all the initialization is performed at compile/link time, no executable code is generated in the module's body.

### New types
#### Integer and Byte pointers
**PINTEGER**, **PBYTE**, **PSET** and **PBYTESET** types have been defined to enforce the access size on
specific memory locations. See msp430g2553.Mod as an example.
#### 8 bit sets
**BYTESET** type has been added to handle byte access register of the MSP430 architecture.
### In-line procedures and functions
Due to the difference of instruction set architectures, the following
In-line procedures or functions have been removed: **LSL(x, n)**, 
**ASR(x, n)**, **ROR(x, n)**  
With PINTEGER and PBYTE types, **SYSTEM.PUT** and **SYSTEM.GET** 
are no more useful and are removed.  
This compiler is board agnostic, so **LED** is removed.
#### New in-line functions
**TOSET(x)** turns type of x into SET type.  
#### New in-line procedures
**BIC(x, y)** is an optimized equivalent of **x := x - y** with x and y of type set  
**BIS(x, y)** is an optimized equivalent of **x := x + y** with x and y of type set  
**XOR(x, y)** is an optimized equivalent of **x := x / y** with x and y of type set  
**AND(x, y)** is an optimized equivalent of **x := x * y** with x and y of type set  
**CLRC** generates a "clear carry" machine instruction  
**NOP** generates a "no operation" machine instruction  
**ADC(x, y)** is an optimized equivalent of **x := x + y + <carry>** with x and y of numeric type  
**SBC(x, y)** is an optimized equivalent of **x := x - y - 1 + <carry>** with x and y of numeric type  
**RLA(x, n)** is an optimized equivalent of **x := x * 2<sup>n</sup>** with x and y of numeric type  
**RLC(x)** performs a rotate left through carry on x  
**RRA(x, n)** is an optimized equivalent of **x := x / 2<sup>n</sup>** with x and y of numeric type  
**RRC(x)** performs a rotate right through carry on **x**  
**SWPB(x)** exchanges high and low bytes of **x**  
**PTR(t, x)** is a type safe equivalent of **SYSTEM.VAL(t, SYSTEM.ADR(x))**. In addition, the compiler checks that
the type **t** is a pointer to the type of the expression **x**  
#### In-line functions with different semantics
**BIT(x, y)** is an optimized equivalent of the condition **"x*y # {}"**
#### New SYSTEM in-line procedures
**BIC_SR** allows to clear bits of the status register  
**BIS_SR** allows to set bits of the status register  
**BIC_SR_ON_EXIT** allows to clear bits of the status register at the exit of an interrupt handler  
**BIS_SR_ON_EXIT** allows to set bits of the status register at the exit of an interrupt handler  
## Specific extensions
### Leaf procedures
Leaf procedures allow parameters and local variables to be implemented in MSP430 registers.  
The user has the responsablility to choose which parameters or local variables will be stored in registers, 
by adding an asterisk after the type of the parameters or variables.  
Leaf procedures cannot call other procedures.

For example, in the module **Arith** the function **mul16** uses register to store
the parameters **x** and **y** and the the local parameter **r**

    PROCEDURE mul16*(x, y: INTEGER*): INTEGER;
      VAR r: INTEGER*;
    BEGIN r := 0; 
      WHILE x # 0 DO IF ODD(x) THEN INC(r, y) END; INC(y, y); CLRC; RRC(x) END
      RETURN r
    END mul16;
  
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
### Register protection
An interrupt handler must restore all register to their initial value before exiting.
The MSP430 compiler automatically build a list of altered register and triggers an error 
if they are not properly restored before the interrupt handler exit. To deal with this, 
the user can declare a set of registers to be save, in any procedure or function declaration.
The compiler uses this to generate the appropriate set of **PUSH** and **POP** instructions,
protecting the specified registers from corruption.  
  
For example, the following handler code pushes R4 on the stack at entry and pops the saved value of
R4 from the stack on exit:  
  
	PROCEDURE* (M.USCIAB0TX_VECTOR) {4} USCIAB0TX_ISR;
	  VAR rx_val: BYTE;
	BEGIN
 	  .
 	  .
	END USCIAB0TX_ISR;

Additionally, the register set declaration can be used in the declaration of procedure or function types.
In that case, it plays the role of a contract between the procedure type and actual procedure assigned to a
variable of the procedure type. The compiler ensures that the actual procedure protects all the registers
specified in the procedure type declaration.

For example, the module **HALGUImsp430g255x** exports the Callback function type, requesting that any assigned function
protects the registers R4 to R15. Please note that as the Callback type denotes a non-leaf function, the register R15 is
used to convey the return value and therefore is automatically excluded from the register protection set.

	MODULE HALGUImsp430g255x;
	  IMPORT SYSTEM, HALSYSmsp430g255x, HALIOmsp430g255x, M := msp430g2553;
	
	  TYPE Callback* = PROCEDURE {4..15} (data: CHAR): BOOLEAN;
	    .
	    .
	END HALGUImsp430g255x.

 The actual procedure, defined in the module **GUIMpack**, complies wtih this requirement.

	MODULE GUIMpack;
	  IMPORT SYSTEM, MP := mpack, MC := MpackCallbacks, HG := HALGUImsp430g255x;
	    .
	    .
	  PROCEDURE {4..14} RxByteCallback(data: CHAR): BOOLEAN;
	    VAR ret: BOOLEAN;
	  BEGIN ret := FALSE;
	    IF ~rxInProgress THEN
	      IF data # 0AX THEN rxInProgress := TRUE; charCnt := 0; rxString[charCnt] := data END
	    ELSE (* in progress *)
	      INC(charCnt);
	      IF data # 0AX THEN
	        IF charCnt >= MAX_STR_LEN THEN rxInProgress := FALSE ELSE rxString[charCnt] := data END
	      ELSE (* String receive complete *) rxInProgress := FALSE; rxString[charCnt] := 0X;
	        IF ParseString() THEN ret := TRUE; (* wake-up MCU *) END
	      END
	    END
	
	    RETURN ret
	  END RxByteCallback;
	    .
	    .
	END GUIMpack.

## Another example
To show what a real program looks like, this is an example based on 
msp430g2xx3_lpm3_vlo.c, a C language example from TI.

	(******************************************************************************
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
	
	  PROCEDURE* (M.WDT_VECTOR) watchdog_timer;
	  BEGIN SYSTEM.BIC_SR_ON_EXIT(M.LPM3_bits) (* Clear LPM3 bits from SR backup *)
	  END watchdog_timer;
	
	BEGIN
	  BIS(M.BCSCTL1^, M.DIVA_1); (* ACLK/2 *)
	  BIS(M.BCSCTL3^, M.LFXT1S_2); (* ACLK = VLO *)
	  M.WDTCTL^ := M.WDT_ADLY_1000; (* Interval timer *)
	  BIS(M.IE1^, M.WDTIE); (* Enable WDT interrupt *)
	  M.P1DIR^ := {0..7}; (* All P1.x outputs *)
	  M.P1OUT^ := {}; (* All P1.x reset *)
	  M.P2DIR^ := {0..7}; (* All P2.x outputs *)
	  M.P2OUT^ := {}; (* All P2.x reset *)
	  M.P3DIR^ := {0..7}; (* All P3.x outputs *)
	  M.P3OUT^ := {}; (* All P3.x reset *)
	  
	  REPEAT 
	    BIS(M.P1OUT^, {0}); (* Set P1.0 LED on *)
	    i := 10000; REPEAT DEC(i) UNTIL i <= 0; (* Delay *)
	    BIC(M.P1OUT^, {0}); (* Reset P1.0 LED off *)
	    SYSTEM.BIS_SR(M.LPM3_bits + M.GIE) (* Enter LPM3 *)
	  UNTIL FALSE
	END msp430g2xx3lpm3vlo.

Compilation and linking is done by OMSPP and OMSPL modules:  
  
OMSPP.Compile msp430g2553 msp430g2xx3lpm3vlo ~  
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

