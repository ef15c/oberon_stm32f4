MODULE Arith; (*runtime module implementing arithmetic operations*)

(*----------------------------------------------------------------*)
(*--- W A R N I N G : never change interfaces of the functions in this module ---*)
(*however, you can comment an unused function here to free some program space*)
(*----------------------------------------------------------------*)

  IMPORT SYSTEM;

  CONST C = 3; (*carry*)

  PROCEDURE mul16*(x, y: INTEGER*): INTEGER; (*do not change this function interface*)
    VAR r: INTEGER*;
    BEGIN r := 0; 
      WHILE x # 0 DO IF ODD(x) THEN INC(r, y) END; INC(y, y); CLRC; RRC(x) END
      RETURN r
    END mul16;

  PROCEDURE divmod16*(x, y: INTEGER*; op: BYTE*): INTEGER; (*do not change this function interface*)
    (*borrowed from TI's  MSP430 C runtime library*)
    VAR q, r: INTEGER*; neg: SET*;
    BEGIN neg := {}; IF y < 0 THEN XOR(y, -1); INC(y, 1); (*y := -y*) neg := {0} END;
      IF x < 0 THEN XOR(x, -1); INC(x, 1); (*x := -x*) XOR(neg, -1) END;
      r := 0; (*initialize the remainder*) q := 1; (*walk 1 across for looping, also hold quotient*)
      REPEAT
        RLA(x, 1); RLC(r); (*shift dividend into remainder*)
        IF SYSTEM.CMP(r, y, C) THEN DEC(r, y) END; (*if current remainder > divisor, subtract*)
        RLC(q) (*set quotient bit (from carry) and advance loop bit*)
      UNTIL SYSTEM.COND(C);
      IF BIT(neg, 0) THEN XOR(q, -1); INC(q, 1) (*negate quotient*) END;
      IF BIT(neg, 1) THEN XOR(r, -1); INC(r, 1) (*negate remainder*) END;
      IF op = 1 THEN q := r (*return remainder instead of quotien*) END

      RETURN q
  END divmod16;

  PROCEDURE set*(x, y: INTEGER*): INTEGER; (*do not change this function interface*)
    VAR r, b: INTEGER*;
    BEGIN
      IF x <= y THEN r := 2; RLA(r, y); b := 1; RLA(b, x); DEC(r, b) ELSE r := 0 END 

      RETURN r
  END set;

END Arith.

OMSPTool.DecObj Arith.mpc

decode Arith.mpc
Arith 82E1081E Flash   128
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 007E 0000 0016 0056
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  007E
code   128
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
 003E	     B319	BIT #1,R9
 0040	     2402	JEQ #2, goes to  0046
 0042	     E334	XOR #-1,R4
 0044	     5314	ADD #1,R4
 0046	     B329	BIT #2,R9
 0048	     2402	JEQ #2, goes to  004E
 004A	     E338	XOR #-1,R8
 004C	     5318	ADD #1,R8
 004E	     9357	CMP.B #1,R7
 0050	     2001	JNE #1, goes to  0054
 0052	     4804	MOV R8,R4
 0054	     4130	RET
 0056	     9506	CMP R5,R6
 0058	     3810	JL #16, goes to  007A
 005A	     4324	MOV #2,R4
 005C	     4608	MOV R6,R8
 005E	     5318	ADD #1,R8
 0060	     8318	SUB #1,R8
 0062	     2402	JEQ #2, goes to  0068
 0064	     5404	ADD R4,R4
 0066	     3FFC	JMP #-4, goes to  0060
 0068	     4317	MOV #1,R7
 006A	     4508	MOV R5,R8
 006C	     5318	ADD #1,R8
 006E	     8318	SUB #1,R8
 0070	     2402	JEQ #2, goes to  0076
 0072	     5707	ADD R7,R7
 0074	     3FFC	JMP #-4, goes to  006E
 0076	     8704	SUB R7,R4
 0078	     3C01	JMP #1, goes to  007C
 007A	     4304	MOV #0,R4
 007C	     4130	RET
 007E	     4130	RET
