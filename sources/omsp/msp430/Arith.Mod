MODULE Arith; (*runtime module implementing arithmetic operations*)

(*----------------------------------------------------------------*)
(*--- W A R N I N G : never change interfaces of the functions in this module ---*)
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
    BEGIN neg := {}; IF y < 0 THEN XOR(y, -1); INC(y); (*y := -y*) neg := {0} END;
      IF x < 0 THEN XOR(x, -1); INC(x); (*x := -x*) XOR(neg, -1) END;
      r := 0; (*initialize the remainder*) q := 1; (*walk 1 across for looping, also hold quotient*)
      REPEAT
        RLA(x, 1); RLC(r); (*shift dividend into remainder*)
        IF SYSTEM.CMP(r, y, C) THEN DEC(r, y) END; (*if current remainder >= divisor, subtract*)
        RLC(q) (*set quotient bit (from carry) and advance loop bit*)
      UNTIL SYSTEM.COND(C);
      IF BIT(neg, {0}) THEN XOR(q, -1); INC(q) (*negate quotient*) END;
      IF BIT(neg, {1}) THEN XOR(r, -1); INC(r) (*negate remainder*) END;
      IF op = 1 THEN q := r (*return remainder instead of quotient*) END

      RETURN q
  END divmod16;

  PROCEDURE set*(x, y: INTEGER*): INTEGER; (*do not change this function interface*)
    VAR r, b: INTEGER*;
    BEGIN
      IF x <= y THEN r := 2; RLA(r, y); b := 1; RLA(b, x); DEC(r, b) ELSE r := 0 END 

      RETURN r
  END set;

  PROCEDURE atoiP*(string: ARRAY OF CHAR*; pos: INTEGER* ): INTEGER;
    VAR r: INTEGER*; neg: BOOLEAN*;
  BEGIN r := 0; IF string[pos] = "-" THEN neg := TRUE; INC(pos) ELSE neg := FALSE END;
    WHILE (string[pos] >= "0") & (string[pos] <= "9") DO r := r*10; INC(r, ORD(string[pos]) - ORD("0")); INC(pos) END;
    IF neg THEN XOR(r, -1); INC(r) END

    RETURN r
  END atoiP;

  PROCEDURE atoi*(string: ARRAY OF CHAR): INTEGER;
    RETURN atoiP(string, 0)
  END atoi;

END Arith.


OMSPTool.DecSym Arith.sms
decode Arith.sms
Arith 1D2566D6  2
   9 mul16 [0  form = 10 [^4] leaf UR 0070( class = 2 R6 [^4] class = 2 R5 [^4])]     1
   9 divmod16 [0  form = 10 [^4] leaf UR 03F0( class = 2 R7 [^1] class = 2 R6 [^4] class = 2 R5 [^4])]     2
   9 set [0  form = 10 [^4] leaf UR 01F0( class = 2 R6 [^4] class = 2 R5 [^4])]     3
   9 atoiP [0  form = 10 [^4] leaf UR 07F0( class = 2 R7 [^4] class = 3# R5 [0  form = 12 [^3]  len = -1  size = 4])]     4
   9 atoi [0  form = 10 [^4] UR 87F0( class = 3# [0  form = 12 [^3]  len = -1  size = 4])]     5

OMSPTool.DecObj Arith.mpc
decode Arith.mpc
Arith CA33A8B5
imports:

section     0	c   22	mul16
 0000	     4304	MOV #0,R4
 0002	     9305	CMP #0,R5
 0004	     2407	JEQ $+16, goes to  0014
 0006	     B315	BIT #1,R5
 0008	     2401	JEQ $+4, goes to  000C
 000A	     5604	ADD R6,R4
 000C	     5606	ADD R6,R6
 000E	     C312	BIC #1,SR
 0010	     1005	RRC R5
 0012	     3FF7	JMP $-16, goes to  0002
 0014	     4130	RET
fixups:

section     1	c   64	divmod16
 0000	     4309	MOV #0,R9
 0002	     9306	CMP #0,R6
 0004	     3403	JGE $+8, goes to  000C
 0006	     E336	XOR #-1,R6
 0008	     5316	ADD #1,R6
 000A	     4319	MOV #1,R9
 000C	     9305	CMP #0,R5
 000E	     3403	JGE $+8, goes to  0016
 0010	     E335	XOR #-1,R5
 0012	     5315	ADD #1,R5
 0014	     E339	XOR #-1,R9
 0016	     4308	MOV #0,R8
 0018	     4314	MOV #1,R4
 001A	     5505	ADD R5,R5
 001C	     6808	ADDC R8,R8
 001E	     9608	CMP R6,R8
 0020	     2801	JNC $+4, goes to  0024
 0022	     8608	SUB R6,R8
 0024	     6404	ADDC R4,R4
 0026	     2BF9	JNC $-12, goes to  001A
 0028	     B319	BIT #1,R9
 002A	     2402	JEQ $+6, goes to  0030
 002C	     E334	XOR #-1,R4
 002E	     5314	ADD #1,R4
 0030	     B329	BIT #2,R9
 0032	     2402	JEQ $+6, goes to  0038
 0034	     E338	XOR #-1,R8
 0036	     5318	ADD #1,R8
 0038	     9357	CMP.B #1,R7
 003A	     2001	JNE $+4, goes to  003E
 003C	     4804	MOV R8,R4
 003E	     4130	RET
fixups:

section     2	c   40	set
 0000	     9506	CMP R5,R6
 0002	     3810	JL $+34, goes to  0024
 0004	     4324	MOV #2,R4
 0006	     4608	MOV R6,R8
 0008	     5318	ADD #1,R8
 000A	     8318	SUB #1,R8
 000C	     2402	JEQ $+6, goes to  0012
 000E	     5404	ADD R4,R4
 0010	     3FFC	JMP $-6, goes to  000A
 0012	     4317	MOV #1,R7
 0014	     4508	MOV R5,R8
 0016	     5318	ADD #1,R8
 0018	     8318	SUB #1,R8
 001A	     2402	JEQ $+6, goes to  0020
 001C	     5707	ADD R7,R7
 001E	     3FFC	JMP $-6, goes to  0018
 0020	     8704	SUB R7,R4
 0022	     3C01	JMP $+4, goes to  0026
 0024	     4304	MOV #0,R4
 0026	     4130	RET
fixups:

section     3	c   86	atoiP
 0000	     4304	MOV #0,R4
 0002	     4709	MOV R7,R9
 0004	     5509	ADD R5,R9
 0006	     90F9	CMP.B #45,0(R9)
 0008	     002D
 000A	     0000
 000C	     2003	JNE $+8, goes to  0014
 000E	     4358	MOV.B #1,R8
 0010	     5317	ADD #1,R7
 0012	     3C01	JMP $+4, goes to  0016
 0014	     4348	MOV.B #0,R8
 0016	     4709	MOV R7,R9
 0018	     5509	ADD R5,R9
 001A	     90F9	CMP.B #48,0(R9)
 001C	     0030
 001E	     0000
 0020	     2815	JNC $+44, goes to  004C
 0022	     4709	MOV R7,R9
 0024	     5509	ADD R5,R9
 0026	     407A	MOV.B #57,R10
 0028	     0039
 002A	     996A	CMP.B @R9,R10
 002C	     280F	JNC $+32, goes to  004C
 002E	     4409	MOV R4,R9
 0030	     5909	ADD R9,R9
 0032	     490A	MOV R9,R10
 0034	     5A0A	ADD R10,R10
 0036	     5A0A	ADD R10,R10
 0038	     5A09	ADD R10,R9
 003A	     4904	MOV R9,R4
 003C	     4709	MOV R7,R9
 003E	     5509	ADD R5,R9
 0040	     4969	MOV.B @R9,R9
 0042	     8079	SUB.B #48,R9
 0044	     0030
 0046	     5904	ADD R9,R4
 0048	     5317	ADD #1,R7
 004A	     3FE5	JMP $-52, goes to  0016
 004C	     9348	CMP.B #0,R8
 004E	     2402	JEQ $+6, goes to  0054
 0050	     E334	XOR #-1,R4
 0052	     5314	ADD #1,R4
 0054	     4130	RET
fixups:

section     4	c   18	atoi
 0000	     4115	MOV 2(SP),R5
 0002	     0002
 0004	     4116	MOV 4(SP),R6
 0006	     0004
 0008	     4307	MOV #0,R7
 000A	     12B0	CALL #0
 000C	     0000
 000E	     440F	MOV R4,R15
 0010	     4130	RET
fixups:
 000D	s0.3

section     5	c    2	module body
 0000	     4130	RET
fixups:

section     6	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    5    0    1    2    3    4
