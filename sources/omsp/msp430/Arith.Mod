MODULE Arith; (*runtime module implementing arithmetic operations*)

  PROCEDURE mul16*(x, y: INTEGER*): INTEGER; (*do not change the function interface*)
    VAR r: INTEGER*;
    BEGIN r := 0; 
      WHILE x # 0 DO IF ODD(x) THEN INC(r, y) END; INC(y, y); CLRC; RRC(x) END
      RETURN r
    END mul16;

END Arith.

OMSPTool.DecObj Arith.mpc

decode Arith.mpc
Arith A6D0F04E    34
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 0018 0000
fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0018
code    26
 0000	     4307	MOV #0,R7
 0002	     9305	CMP #0,R5
 0004	     2407	JEQ #7, goes to  0014
 0006	     B315	BIT #1,R5
 0008	     2401	JEQ #1, goes to  000C
 000A	     5607	ADD R6,R7
 000C	     5606	ADD R6,R6
 000E	     C312	BIC #1,SR
 0010	     1005	RRC R5
 0012	     3FF7	JMP #-9, goes to  0002
 0014	     4704	MOV R7,R4
 0016	     4130	RET
 0018	     4130	RET
