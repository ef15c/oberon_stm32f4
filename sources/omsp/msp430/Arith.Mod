MODULE Arith; (*runtime module implementing arithmetic operations*)
  IMPORT SYSTEM;

  CONST C = 3; (*carry*)

  PROCEDURE mul16*(x, y: INTEGER*): INTEGER; (*do not change this function interface*)
    VAR r: INTEGER*;
    BEGIN r := 0; 
      WHILE x # 0 DO IF ODD(x) THEN INC(r, y) END; INC(y, y); CLRC; RRC(x) END
      RETURN r
    END mul16;

  (*borrowed from TI's  MSP430 c runtime library*)
  PROCEDURE divmod16*(x, y: INTEGER*; op: BYTE*): INTEGER; (*do not change this function interface*)
    VAR q, r: INTEGER*; neg: SET*;
    BEGIN neg := {}; IF y < 0 THEN XOR(y, -1); INC(y, 1); (*y := -y*) neg := {0} END;
      IF x < 0 THEN XOR(x, -1); INC(x, 1); (*x := -x*) XOR(neg, -1) END;
      r := 0; (*initialize the remainder*) q := 1; (*walk 1 across for looping, also hold quotient*)
      REPEAT
        RLA(x, 1); RLC(r); (*shift dividend into remainder*)
        IF SYSTEM.CMP(r, y, C) THEN DEC(r, y) END; (*if current remainder > divisor, subtract*)
        RLC(q) (*set quotient bit (from carry) and advance loop bit*)
      UNTIL SYSTEM.COND(C);
(*todo update sign*)

      RETURN q
  END divmod16;

END Arith.

OMSPTool.DecObj Arith.mpc

decode Arith.mpc
Arith 0A7B9B13    76
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 0040 0000 0016
fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0040
code    66
 0000	     4304	MOV #0,R4
 0002	     9305	CMP #0,R5
 0004	     2407	JEQ #7, goes to  0014
 0006	     B315	BIT #1,R5
 0008	     2401	JEQ #1, goes to  000C
 000A	     5604	ADD R6,R4
 000C	     5606	ADD R6,R6
 000E	     C312	BIC #1,SR
 0010	     1005	RRC R5
 0012	     3FF7	JMP #-9, goes to  0002
 0014	     4130	RET
 0016	     4309	MOV #0,R9
 0018	     9306	CMP #0,R6
 001A	     3403	JGE #3, goes to  0022
 001C	     E336	XOR #-1,R6
 001E	     5316	ADD #1,R6
 0020	     4319	MOV #1,R9
 0022	     9305	CMP #0,R5
 0024	     3403	JGE #3, goes to  002C
 0026	     E335	XOR #-1,R5
 0028	     5315	ADD #1,R5
 002A	     E339	XOR #-1,R9
 002C	     4308	MOV #0,R8
 002E	     4314	MOV #1,R4
 0030	     5505	ADD R5,R5
 0032	     6808	ADDC R8,R8
 0034	     9608	CMP R6,R8
 0036	     2801	JNC #1, goes to  003A
 0038	     8608	SUB R6,R8
 003A	     6404	ADDC R4,R4
 003C	     2BF9	JNC #-7, goes to  0030
 003E	     4130	RET
 0040	     4130	RET
