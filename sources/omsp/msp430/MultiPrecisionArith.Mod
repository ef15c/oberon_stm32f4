MODULE MultiPrecisionArith; (*C. Schoffit 15.09.24 *)
  IMPORT SYSTEM;

  CONST C = 3; (*carry*)

  PROCEDURE mulu1632*(x, y: INTEGER*; VAR rl, rh: INTEGER*);
    VAR yl, yh: INTEGER*;
    BEGIN rl := 0; rh := 0; yl := y; yh := 0;
      WHILE x # 0 DO IF ODD(x) THEN INC(rl, yl); ADC(rh, yh) END; INC(yl, yl); ADC(yh, yh); CLRC; RRC(x) END
    END mulu1632;

  PROCEDURE SetLongInt*(VAR lh, ll: INTEGER*; n: INTEGER*);
  (*Initialize long integer lh-ll with an integer value n*)
  BEGIN ll := n; IF n < 0 THEN lh := -1 ELSE lh := 0 END
  END SetLongInt;

  PROCEDURE SubLongInt*(VAR lh, ll: INTEGER*; n: INTEGER*);
  (*Subtract integer n from long integer lh-ll*)
  BEGIN DEC(ll, n); SBC(lh, 0)
  END SubLongInt;

  PROCEDURE AddLongInt*(VAR lh, ll: INTEGER*; n: INTEGER*);
  (*Subtract integer n from long integer lh-ll*)
  BEGIN INC(ll, n); ADC(lh, 0)
  END AddLongInt;

  PROCEDURE LongNegate*(VAR lh, ll: INTEGER*);
  BEGIN XOR(ll, -1); XOR(lh, -1); INC(ll, 1); ADC(lh, 0) 
  END LongNegate;

  PROCEDURE MulLongInt*(VAR lh, ll: INTEGER*; n: INTEGER*);
  (*Multiply long integer lh-ll by integer value n*)
    VAR negate: BOOLEAN*; tl, th: INTEGER*;
  BEGIN negate := FALSE;
    IF lh < 0 THEN XOR(negate, -1); XOR(ll, -1); XOR(lh, -1); INC(ll); ADC(lh, 0) END;
    IF n < 0 THEN XOR(negate, -1); XOR(n, -1); INC(n) END;
    th := lh; tl := ll; lh := 0; ll := 0;
    WHILE n # 0 DO IF ODD(n) THEN INC(ll, tl); ADC(lh, th) END; INC(tl, tl); ADC(th, th); CLRC; RRC(n) END;
    IF negate THEN XOR(ll, -1); XOR(lh, -1); INC(ll, 1); ADC(lh, 0) END
  END MulLongInt;

  PROCEDURE DivLongLong*(VAR lh, ll, nh, nl: INTEGER*);
    (*Divide long integer lh-ll by long value nh-nl
      quotient returned in lh-ll, remainder in nh, hl*)
    (*borrowed from TI's  MSP430 C runtime library*)
    VAR ql, qh, rl, rh: INTEGER*; neg: SET*;
    BEGIN neg := {}; IF nh < 0 THEN XOR(nl, -1); XOR(nh, -1); INC(nl); ADC(nh, 0); (*n := -n*) neg := {0} END;
      IF lh < 0 THEN XOR(ll, -1); XOR(lh, -1); INC(ll); ADC(lh, 0); (*l := -l*) XOR(neg, -1) END;
      rh := 0; rl := 0; (*initialize the remainder*) qh := 0; ql := 1; (*walk 1 across for looping, also hold quotient*)
      REPEAT
        RLA(ll, 1); RLC(lh); RLC(rl); RLC(rh); (*shift dividend into remainder*)
        IF (rh > nh) OR (rh = nh) & SYSTEM.CMP(rl, nl, C) THEN DEC(rl, nl); SBC(rh, nh) END; (*if current remainder >= divisor, subtract*)
        RLC(ql); RLC(qh) (*set quotient bit (from carry) and advance loop bit*)
      UNTIL SYSTEM.COND(C);
      IF BIT(neg, {0}) THEN XOR(ql, -1); XOR(qh, -1); INC(ql); ADC(qh, 0) (*negate quotient*) END;
      IF BIT(neg, {1}) THEN XOR(rl, -1); XOR(rh, -1); INC(rl); ADC(rh, 0) (*negate remainder*) END;
      lh := qh; ll := ql; nh := rh; nl := rl (*return remainder and quotient*)
  END DivLongLong;

  PROCEDURE ASRLongInt*(VAR lh, ll: INTEGER*; n: INTEGER*);
  BEGIN WHILE n # 0 DO RRA(lh, 1); RRC(ll); DEC(n) END
  END ASRLongInt;

END MultiPrecisionArith.

OMSPTool.DecObj MultiPrecisionArith.mpc
decode MultiPrecisionArith.mpc
MultiPrecisionArith E9142E2F Flash   346
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0158 c 0000 c 0028 c 003C c 0046 c 0050 c 0062 c 00C2 c 014A
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0158
code   346
 0000	     4386	MOV #0,0(R6)
 0002	     0000
 0004	     4387	MOV #0,0(R7)
 0006	     0000
 0008	     4508	MOV R5,R8
 000A	     4309	MOV #0,R9
 000C	     9304	CMP #0,R4
 000E	     240B	JEQ $+24, goes to  0026
 0010	     B314	BIT #1,R4
 0012	     2404	JEQ $+10, goes to  001C
 0014	     5886	ADD R8,0(R6)
 0016	     0000
 0018	     6987	ADDC R9,0(R7)
 001A	     0000
 001C	     5808	ADD R8,R8
 001E	     6909	ADDC R9,R9
 0020	     C312	BIC #1,SR
 0022	     1004	RRC R4
 0024	     3FF3	JMP $-24, goes to  000C
 0026	     4130	RET
 0028	     4685	MOV R6,0(R5)
 002A	     0000
 002C	     9306	CMP #0,R6
 002E	     3403	JGE $+8, goes to  0036
 0030	     43B4	MOV #-1,0(R4)
 0032	     0000
 0034	     3C02	JMP $+6, goes to  003A
 0036	     4384	MOV #0,0(R4)
 0038	     0000
 003A	     4130	RET
 003C	     8685	SUB R6,0(R5)
 003E	     0000
 0040	     7384	SUBC #0,0(R4)
 0042	     0000
 0044	     4130	RET
 0046	     5685	ADD R6,0(R5)
 0048	     0000
 004A	     6384	ADDC #0,0(R4)
 004C	     0000
 004E	     4130	RET
 0050	     E3B5	XOR #-1,0(R5)
 0052	     0000
 0054	     E3B4	XOR #-1,0(R4)
 0056	     0000
 0058	     5395	ADD #1,0(R5)
 005A	     0000
 005C	     6384	ADDC #0,0(R4)
 005E	     0000
 0060	     4130	RET
 0062	     4347	MOV.B #0,R7
 0064	     9384	CMP #0,0(R4)
 0066	     0000
 0068	     3409	JGE $+20, goes to  007C
 006A	     E377	XOR.B #-1,R7
 006C	     E3B5	XOR #-1,0(R5)
 006E	     0000
 0070	     E3B4	XOR #-1,0(R4)
 0072	     0000
 0074	     5395	ADD #1,0(R5)
 0076	     0000
 0078	     6384	ADDC #0,0(R4)
 007A	     0000
 007C	     9306	CMP #0,R6
 007E	     3403	JGE $+8, goes to  0086
 0080	     E377	XOR.B #-1,R7
 0082	     E336	XOR #-1,R6
 0084	     5316	ADD #1,R6
 0086	     4429	MOV @R4,R9
 0088	     4528	MOV @R5,R8
 008A	     4384	MOV #0,0(R4)
 008C	     0000
 008E	     4385	MOV #0,0(R5)
 0090	     0000
 0092	     9306	CMP #0,R6
 0094	     240B	JEQ $+24, goes to  00AC
 0096	     B316	BIT #1,R6
 0098	     2404	JEQ $+10, goes to  00A2
 009A	     5885	ADD R8,0(R5)
 009C	     0000
 009E	     6984	ADDC R9,0(R4)
 00A0	     0000
 00A2	     5808	ADD R8,R8
 00A4	     6909	ADDC R9,R9
 00A6	     C312	BIC #1,SR
 00A8	     1006	RRC R6
 00AA	     3FF3	JMP $-24, goes to  0092
 00AC	     9347	CMP.B #0,R7
 00AE	     2408	JEQ $+18, goes to  00C0
 00B0	     E3B5	XOR #-1,0(R5)
 00B2	     0000
 00B4	     E3B4	XOR #-1,0(R4)
 00B6	     0000
 00B8	     5395	ADD #1,0(R5)
 00BA	     0000
 00BC	     6384	ADDC #0,0(R4)
 00BE	     0000
 00C0	     4130	RET
 00C2	     430C	MOV #0,R12
 00C4	     9386	CMP #0,0(R6)
 00C6	     0000
 00C8	     3409	JGE $+20, goes to  00DC
 00CA	     E3B7	XOR #-1,0(R7)
 00CC	     0000
 00CE	     E3B6	XOR #-1,0(R6)
 00D0	     0000
 00D2	     5397	ADD #1,0(R7)
 00D4	     0000
 00D6	     6386	ADDC #0,0(R6)
 00D8	     0000
 00DA	     431C	MOV #1,R12
 00DC	     9384	CMP #0,0(R4)
 00DE	     0000
 00E0	     3409	JGE $+20, goes to  00F4
 00E2	     E3B5	XOR #-1,0(R5)
 00E4	     0000
 00E6	     E3B4	XOR #-1,0(R4)
 00E8	     0000
 00EA	     5395	ADD #1,0(R5)
 00EC	     0000
 00EE	     6384	ADDC #0,0(R4)
 00F0	     0000
 00F2	     E33C	XOR #-1,R12
 00F4	     430B	MOV #0,R11
 00F6	     430A	MOV #0,R10
 00F8	     4309	MOV #0,R9
 00FA	     4318	MOV #1,R8
 00FC	     55A5	ADD @R5,0(R5)
 00FE	     0000
 0100	     64A4	ADDC @R4,0(R4)
 0102	     0000
 0104	     6A0A	ADDC R10,R10
 0106	     6B0B	ADDC R11,R11
 0108	     9B86	CMP R11,0(R6)
 010A	     0000
 010C	     3804	JL $+10, goes to  0116
 010E	     962B	CMP @R6,R11
 0110	     2004	JNE $+10, goes to  011A
 0112	     972A	CMP @R7,R10
 0114	     2802	JNC $+6, goes to  011A
 0116	     872A	SUB @R7,R10
 0118	     762B	SUBC @R6,R11
 011A	     6808	ADDC R8,R8
 011C	     6909	ADDC R9,R9
 011E	     2BEE	JNC $-34, goes to  00FC
 0120	     B31C	BIT #1,R12
 0122	     2404	JEQ $+10, goes to  012C
 0124	     E338	XOR #-1,R8
 0126	     E339	XOR #-1,R9
 0128	     5318	ADD #1,R8
 012A	     6309	ADDC #0,R9
 012C	     B32C	BIT #2,R12
 012E	     2404	JEQ $+10, goes to  0138
 0130	     E33A	XOR #-1,R10
 0132	     E33B	XOR #-1,R11
 0134	     531A	ADD #1,R10
 0136	     630B	ADDC #0,R11
 0138	     4984	MOV R9,0(R4)
 013A	     0000
 013C	     4885	MOV R8,0(R5)
 013E	     0000
 0140	     4B86	MOV R11,0(R6)
 0142	     0000
 0144	     4A87	MOV R10,0(R7)
 0146	     0000
 0148	     4130	RET
 014A	     9306	CMP #0,R6
 014C	     2404	JEQ $+10, goes to  0156
 014E	     1124	RRA @R4
 0150	     1025	RRC @R5
 0152	     8316	SUB #1,R6
 0154	     3FFA	JMP $-10, goes to  014A
 0156	     4130	RET
 0158	     4130	RET

OMSPTool.DecSym MultiPrecisionArith.sms
decode MultiPrecisionArith.sms
MultiPrecisionArith E9142E2F  1
   1 mulu1632 [0  form = 10  size = 2 [^9] leaf UR 03F0( class = 3 R7 [^4] class = 3 R6 [^4] class = 2 R5 [^4] class = 2 R4 [^4])]       1
   1 SetLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       2
   1 SubLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       3
   1 AddLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       4
   1 LongNegate [0  form = 10  size = 2 [^9] leaf UR 0030( class = 3 R5 [^4] class = 3 R4 [^4])]       5
   1 MulLongInt [0  form = 10  size = 2 [^9] leaf UR 03F0( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       6
   1 DivLongLong [0  form = 10  size = 2 [^9] leaf UR 1FF0( class = 3 R7 [^4] class = 3 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       7
   1 ASRLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       8
