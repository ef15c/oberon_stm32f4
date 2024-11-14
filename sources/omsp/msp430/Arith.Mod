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

  PROCEDURE atoiPL*(string: ARRAY OF CHAR; pos, len: INTEGER): INTEGER;
    VAR r: INTEGER; neg: BOOLEAN;
  BEGIN r := 0; IF string[pos] = "-" THEN neg := TRUE; INC(pos); DEC(len) ELSE neg := FALSE END;
    WHILE (len > 0) & (string[pos] >= "0") & (string[pos] <= "9") DO r := r*10; INC(r, ORD(string[pos]) - ORD("0")); INC(pos); DEC(len) END; SWPB(r);
    IF len > 0 THEN r := 0 (*invalid character*) END;
    IF neg THEN XOR(r, -1); INC(r) END
    RETURN r
  END atoiPL;

  PROCEDURE atoi*(string: ARRAY OF CHAR): INTEGER;
    VAR r, len: INTEGER;
  BEGIN len := 0; WHILE string[len] # 0X DO INC(len) END;
    r := atoiPL(string, 0, len)

    RETURN r
  END atoi;

END Arith.

OMSPTool.DecObj Arith.mpc
decode Arith.mpc
Arith E38C1259 Flash   342
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0154 c 0000 c 0016 c 0056 c 007E c 011C
fixup procedures chains
 0146     0	 007E
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0154
code   342
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
 0016	     4309	MOV #0,R9
 0018	     9306	CMP #0,R6
 001A	     3403	JGE $+8, goes to  0022
 001C	     E336	XOR #-1,R6
 001E	     5316	ADD #1,R6
 0020	     4319	MOV #1,R9
 0022	     9305	CMP #0,R5
 0024	     3403	JGE $+8, goes to  002C
 0026	     E335	XOR #-1,R5
 0028	     5315	ADD #1,R5
 002A	     E339	XOR #-1,R9
 002C	     4308	MOV #0,R8
 002E	     4314	MOV #1,R4
 0030	     5505	ADD R5,R5
 0032	     6808	ADDC R8,R8
 0034	     9608	CMP R6,R8
 0036	     2801	JNC $+4, goes to  003A
 0038	     8608	SUB R6,R8
 003A	     6404	ADDC R4,R4
 003C	     2BF9	JNC $-12, goes to  0030
 003E	     B319	BIT #1,R9
 0040	     2402	JEQ $+6, goes to  0046
 0042	     E334	XOR #-1,R4
 0044	     5314	ADD #1,R4
 0046	     B329	BIT #2,R9
 0048	     2402	JEQ $+6, goes to  004E
 004A	     E338	XOR #-1,R8
 004C	     5318	ADD #1,R8
 004E	     9357	CMP.B #1,R7
 0050	     2001	JNE $+4, goes to  0054
 0052	     4804	MOV R8,R4
 0054	     4130	RET
 0056	     9506	CMP R5,R6
 0058	     3810	JL $+34, goes to  007A
 005A	     4324	MOV #2,R4
 005C	     4608	MOV R6,R8
 005E	     5318	ADD #1,R8
 0060	     8318	SUB #1,R8
 0062	     2402	JEQ $+6, goes to  0068
 0064	     5404	ADD R4,R4
 0066	     3FFC	JMP $-6, goes to  0060
 0068	     4317	MOV #1,R7
 006A	     4508	MOV R5,R8
 006C	     5318	ADD #1,R8
 006E	     8318	SUB #1,R8
 0070	     2402	JEQ $+6, goes to  0076
 0072	     5707	ADD R7,R7
 0074	     3FFC	JMP $-6, goes to  006E
 0076	     8704	SUB R7,R4
 0078	     3C01	JMP $+4, goes to  007C
 007A	     4304	MOV #0,R4
 007C	     4130	RET
 007E	     8221	SUB #4,SP
 0080	     4381	MOV #0,0(SP)
 0082	     0000
 0084	     411F	MOV 8(SP),R15
 0086	     0008
 0088	     511F	ADD 10(SP),R15
 008A	     000A
 008C	     90FF	CMP.B #45,0(R15)
 008E	     002D
 0090	     0000
 0092	     2007	JNE $+16, goes to  00A2
 0094	     43D1	MOV.B #1,2(SP)
 0096	     0002
 0098	     5391	ADD #1,8(SP)
 009A	     0008
 009C	     8391	SUB #1,6(SP)
 009E	     0006
 00A0	     3C02	JMP $+6, goes to  00A6
 00A2	     43C1	MOV.B #0,2(SP)
 00A4	     0002
 00A6	     430F	MOV #0,R15
 00A8	     911F	CMP 6(SP),R15
 00AA	     0006
 00AC	     3426	JGE $+78, goes to  00FA
 00AE	     411F	MOV 8(SP),R15
 00B0	     0008
 00B2	     511F	ADD 10(SP),R15
 00B4	     000A
 00B6	     90FF	CMP.B #48,0(R15)
 00B8	     0030
 00BA	     0000
 00BC	     381E	JL $+62, goes to  00FA
 00BE	     411F	MOV 8(SP),R15
 00C0	     0008
 00C2	     511F	ADD 10(SP),R15
 00C4	     000A
 00C6	     403E	MOV #57,R14
 00C8	     0039
 00CA	     9F6E	CMP.B @R15,R14
 00CC	     3816	JL $+46, goes to  00FA
 00CE	     412F	MOV @SP,R15
 00D0	     5F0F	ADD R15,R15
 00D2	     4F0E	MOV R15,R14
 00D4	     5E0E	ADD R14,R14
 00D6	     5E0E	ADD R14,R14
 00D8	     5E0F	ADD R14,R15
 00DA	     4F81	MOV R15,0(SP)
 00DC	     0000
 00DE	     411F	MOV 8(SP),R15
 00E0	     0008
 00E2	     511F	ADD 10(SP),R15
 00E4	     000A
 00E6	     4F6F	MOV.B @R15,R15
 00E8	     807F	SUB.B #48,R15
 00EA	     0030
 00EC	     5F81	ADD R15,0(SP)
 00EE	     0000
 00F0	     5391	ADD #1,8(SP)
 00F2	     0008
 00F4	     8391	SUB #1,6(SP)
 00F6	     0006
 00F8	     3FD6	JMP $-82, goes to  00A6
 00FA	     10A1	SWPB @SP
 00FC	     430F	MOV #0,R15
 00FE	     911F	CMP 6(SP),R15
 0100	     0006
 0102	     3402	JGE $+6, goes to  0108
 0104	     4381	MOV #0,0(SP)
 0106	     0000
 0108	     93C1	CMP.B #0,2(SP)
 010A	     0002
 010C	     2404	JEQ $+10, goes to  0116
 010E	     E3B1	XOR #-1,0(SP)
 0110	     0000
 0112	     5391	ADD #1,0(SP)
 0114	     0000
 0116	     412F	MOV @SP,R15
 0118	     5221	ADD #4,SP
 011A	     4130	RET
 011C	     8221	SUB #4,SP
 011E	     4381	MOV #0,2(SP)
 0120	     0002
 0122	     411F	MOV 2(SP),R15
 0124	     0002
 0126	     511F	ADD 6(SP),R15
 0128	     0006
 012A	     93CF	CMP.B #0,0(R15)
 012C	     0000
 012E	     2403	JEQ $+8, goes to  0136
 0130	     5391	ADD #1,2(SP)
 0132	     0002
 0134	     3FF6	JMP $-18, goes to  0122
 0136	     1211	PUSH 10(SP)
 0138	     000A
 013A	     1211	PUSH 10(SP)
 013C	     000A
 013E	     1203	PUSH #0
 0140	     1211	PUSH 10(SP)
 0142	     000A
 0144	     12B0	CALL #0
 0146	     0000
 0148	     5231	ADD #8,SP
 014A	     4F81	MOV R15,0(SP)
 014C	     0000
 014E	     412F	MOV @SP,R15
 0150	     5221	ADD #4,SP
 0152	     4130	RET
 0154	     4130	RET

OMSPTool.DecSym Arith.sms
Arith E38C1259  1
   1 mul16 [0  form = 10  size = 2 [^4] leaf UR 0070( class = 2 R6 [^4] class = 2 R5 [^4])]       1
   1 divmod16 [0  form = 10  size = 2 [^4] leaf UR 03F0( class = 2 R7 [^1] class = 2 R6 [^4] class = 2 R5 [^4])]       2
   1 set [0  form = 10  size = 2 [^4] leaf UR 01F0( class = 2 R6 [^4] class = 2 R5 [^4])]       3
   1 atoiPL [0  form = 10  size = 2 [^4] UR C000( class = 2 [^4] class = 2 [^4] class = 3# [0  form = 12  size = 4 [^3]  len = -1])]       4
   1 atoi [0  form = 10  size = 2 [^4] UR C000( class = 3# [0  form = 12  size = 4 [^3]  len = -1])]       5
