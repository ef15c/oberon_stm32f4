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
    IF lh < 0 THEN XOR(negate, {0}); XOR(ll, -1); XOR(lh, -1); INC(ll); ADC(lh, 0) END;
    IF n < 0 THEN XOR(negate, {0}); XOR(n, -1); INC(n) END;
    th := lh; tl := ll; lh := 0; ll := 0;
    WHILE n # 0 DO CLRC; RRC(n); IF SYSTEM.COND(C) THEN INC(ll, tl); ADC(lh, th) END; INC(tl, tl); ADC(th, th) END;
    IF negate THEN XOR(ll, -1); XOR(lh, -1); INC(ll, 1); ADC(lh, 0) END
  END MulLongInt;

  PROCEDURE MulLongLong*(VAR lh, ll: INTEGER*; nh, nl: INTEGER*);
  (*Multiply long integer lh-ll by long integer value nh, nl*)
    VAR negate: BOOLEAN*; tl, th: INTEGER*;
  BEGIN negate := FALSE;
    IF lh < 0 THEN XOR(negate, {0}); XOR(ll, -1); XOR(lh, -1); INC(ll); ADC(lh, 0) END;
    IF nh < 0 THEN XOR(negate, {0}); XOR(nl, -1); XOR(nh, -1); INC(nl); ADC(nh, 0) END;
    th := lh; tl := ll; lh := 0; ll := 0;
    WHILE (nh # 0) OR (nl # 0) DO CLRC; RRC(nh); RRC(nl); IF SYSTEM.COND(C) THEN INC(ll, tl); ADC(lh, th) END; INC(tl, tl); ADC(th, th) END;
    IF negate THEN XOR(ll, -1); XOR(lh, -1); INC(ll, 1); ADC(lh, 0) END
  END MulLongLong;

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

  PROCEDURE AbsLong*(VAR lh, ll: INTEGER*);
  BEGIN
    IF lh < 0 THEN XOR(ll, -1); XOR(lh, -1); INC(ll); ADC(lh, 0) END
  END AbsLong;

  PROCEDURE SubLongLong*(VAR lh, ll: INTEGER*; nh, nl: INTEGER*);
  (*Subtract long integer nh-nl from long integer lh-ll*)
  BEGIN DEC(ll, nl); SBC(lh, nh)
  END SubLongLong;

  PROCEDURE CmpLongLong*(ah, al, bh, bl: INTEGER*): INTEGER;
    (*Compare long integer ah-al and long integer bh-bl*)
    VAR res: INTEGER*;
  BEGIN DEC(al, bl); SBC(ah, bh);
    IF SYSTEM.COND(6) THEN res := -1 ELSIF SYSTEM.COND(1) & (al = 0) THEN res := 0 ELSE res := 1 END

    RETURN res
  END CmpLongLong;


END MultiPrecisionArith.

OMSPP.Compile MultiPrecisionArith.Mod~
OMSPTool.DecSym MultiPrecisionArith.sms
decode MultiPrecisionArith.sms
MultiPrecisionArith 0E8B91C3  2
   9 mulu1632 [0  form = 10 [^9] leaf UR 03F0( class = 3 R7 [^4] class = 3 R6 [^4] class = 2 R5 [^4] class = 2 R4 [^4])]     1
   9 SetLongInt [0  form = 10 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]     2
   9 SubLongInt [0  form = 10 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]     3
   9 AddLongInt [0  form = 10 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]     4
   9 LongNegate [0  form = 10 [^9] leaf UR 0030( class = 3 R5 [^4] class = 3 R4 [^4])]     5
   9 MulLongInt [0  form = 10 [^9] leaf UR 03F0( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]     6
   9 MulLongLong [0  form = 10 [^9] leaf UR 07F0( class = 2 R7 [^4] class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]     7
   9 DivLongLong [0  form = 10 [^9] leaf UR 1FF0( class = 3 R7 [^4] class = 3 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]     8
   9 ASRLongInt [0  form = 10 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]     9
   9 AbsLong [0  form = 10 [^9] leaf UR 0030( class = 3 R5 [^4] class = 3 R4 [^4])]    10
   9 SubLongLong [0  form = 10 [^9] leaf UR 00F0( class = 2 R7 [^4] class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]    11
   9 CmpLongLong [0  form = 10 [^4] leaf UR 01F0( class = 2 R8 [^4] class = 2 R7 [^4] class = 2 R6 [^4] class = 2 R5 [^4])]    12

OMSPTool.DecObj MultiPrecisionArith.mpc
decode MultiPrecisionArith.mpc
MultiPrecisionArith 7965D39A
imports:

section     0	c   40	mulu1632
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
fixups:

section     1	c   20	SetLongInt
 0000	     4685	MOV R6,0(R5)
 0002	     0000
 0004	     9306	CMP #0,R6
 0006	     3403	JGE $+8, goes to  000E
 0008	     43B4	MOV #-1,0(R4)
 000A	     0000
 000C	     3C02	JMP $+6, goes to  0012
 000E	     4384	MOV #0,0(R4)
 0010	     0000
 0012	     4130	RET
fixups:

section     2	c   10	SubLongInt
 0000	     8685	SUB R6,0(R5)
 0002	     0000
 0004	     7384	SUBC #0,0(R4)
 0006	     0000
 0008	     4130	RET
fixups:

section     3	c   10	AddLongInt
 0000	     5685	ADD R6,0(R5)
 0002	     0000
 0004	     6384	ADDC #0,0(R4)
 0006	     0000
 0008	     4130	RET
fixups:

section     4	c   18	LongNegate
 0000	     E3B5	XOR #-1,0(R5)
 0002	     0000
 0004	     E3B4	XOR #-1,0(R4)
 0006	     0000
 0008	     5395	ADD #1,0(R5)
 000A	     0000
 000C	     6384	ADDC #0,0(R4)
 000E	     0000
 0010	     4130	RET
fixups:

section     5	c   94	MulLongInt
 0000	     4347	MOV.B #0,R7
 0002	     9384	CMP #0,0(R4)
 0004	     0000
 0006	     3409	JGE $+20, goes to  001A
 0008	     E357	XOR.B #1,R7
 000A	     E3B5	XOR #-1,0(R5)
 000C	     0000
 000E	     E3B4	XOR #-1,0(R4)
 0010	     0000
 0012	     5395	ADD #1,0(R5)
 0014	     0000
 0016	     6384	ADDC #0,0(R4)
 0018	     0000
 001A	     9306	CMP #0,R6
 001C	     3403	JGE $+8, goes to  0024
 001E	     E357	XOR.B #1,R7
 0020	     E336	XOR #-1,R6
 0022	     5316	ADD #1,R6
 0024	     4429	MOV @R4,R9
 0026	     4528	MOV @R5,R8
 0028	     4384	MOV #0,0(R4)
 002A	     0000
 002C	     4385	MOV #0,0(R5)
 002E	     0000
 0030	     9306	CMP #0,R6
 0032	     240A	JEQ $+22, goes to  0048
 0034	     C312	BIC #1,SR
 0036	     1006	RRC R6
 0038	     2804	JNC $+10, goes to  0042
 003A	     5885	ADD R8,0(R5)
 003C	     0000
 003E	     6984	ADDC R9,0(R4)
 0040	     0000
 0042	     5808	ADD R8,R8
 0044	     6909	ADDC R9,R9
 0046	     3FF4	JMP $-22, goes to  0030
 0048	     9347	CMP.B #0,R7
 004A	     2408	JEQ $+18, goes to  005C
 004C	     E3B5	XOR #-1,0(R5)
 004E	     0000
 0050	     E3B4	XOR #-1,0(R4)
 0052	     0000
 0054	     5395	ADD #1,0(R5)
 0056	     0000
 0058	     6384	ADDC #0,0(R4)
 005A	     0000
 005C	     4130	RET
fixups:

section     6	c  104	MulLongLong
 0000	     4348	MOV.B #0,R8
 0002	     9384	CMP #0,0(R4)
 0004	     0000
 0006	     3409	JGE $+20, goes to  001A
 0008	     E358	XOR.B #1,R8
 000A	     E3B5	XOR #-1,0(R5)
 000C	     0000
 000E	     E3B4	XOR #-1,0(R4)
 0010	     0000
 0012	     5395	ADD #1,0(R5)
 0014	     0000
 0016	     6384	ADDC #0,0(R4)
 0018	     0000
 001A	     9306	CMP #0,R6
 001C	     3405	JGE $+12, goes to  0028
 001E	     E358	XOR.B #1,R8
 0020	     E337	XOR #-1,R7
 0022	     E336	XOR #-1,R6
 0024	     5317	ADD #1,R7
 0026	     6306	ADDC #0,R6
 0028	     442A	MOV @R4,R10
 002A	     4529	MOV @R5,R9
 002C	     4384	MOV #0,0(R4)
 002E	     0000
 0030	     4385	MOV #0,0(R5)
 0032	     0000
 0034	     9306	CMP #0,R6
 0036	     240D	JEQ $+28, goes to  0052
 0038	     9307	CMP #0,R7
 003A	     240B	JEQ $+24, goes to  0052
 003C	     C312	BIC #1,SR
 003E	     1006	RRC R6
 0040	     1007	RRC R7
 0042	     2804	JNC $+10, goes to  004C
 0044	     5985	ADD R9,0(R5)
 0046	     0000
 0048	     6A84	ADDC R10,0(R4)
 004A	     0000
 004C	     5909	ADD R9,R9
 004E	     6A0A	ADDC R10,R10
 0050	     3FF1	JMP $-28, goes to  0034
 0052	     9348	CMP.B #0,R8
 0054	     2408	JEQ $+18, goes to  0066
 0056	     E3B5	XOR #-1,0(R5)
 0058	     0000
 005A	     E3B4	XOR #-1,0(R4)
 005C	     0000
 005E	     5395	ADD #1,0(R5)
 0060	     0000
 0062	     6384	ADDC #0,0(R4)
 0064	     0000
 0066	     4130	RET
fixups:

section     7	c  136	DivLongLong
 0000	     430C	MOV #0,R12
 0002	     9386	CMP #0,0(R6)
 0004	     0000
 0006	     3409	JGE $+20, goes to  001A
 0008	     E3B7	XOR #-1,0(R7)
 000A	     0000
 000C	     E3B6	XOR #-1,0(R6)
 000E	     0000
 0010	     5397	ADD #1,0(R7)
 0012	     0000
 0014	     6386	ADDC #0,0(R6)
 0016	     0000
 0018	     431C	MOV #1,R12
 001A	     9384	CMP #0,0(R4)
 001C	     0000
 001E	     3409	JGE $+20, goes to  0032
 0020	     E3B5	XOR #-1,0(R5)
 0022	     0000
 0024	     E3B4	XOR #-1,0(R4)
 0026	     0000
 0028	     5395	ADD #1,0(R5)
 002A	     0000
 002C	     6384	ADDC #0,0(R4)
 002E	     0000
 0030	     E33C	XOR #-1,R12
 0032	     430B	MOV #0,R11
 0034	     430A	MOV #0,R10
 0036	     4309	MOV #0,R9
 0038	     4318	MOV #1,R8
 003A	     55A5	ADD @R5,0(R5)
 003C	     0000
 003E	     64A4	ADDC @R4,0(R4)
 0040	     0000
 0042	     6A0A	ADDC R10,R10
 0044	     6B0B	ADDC R11,R11
 0046	     9B86	CMP R11,0(R6)
 0048	     0000
 004A	     3804	JL $+10, goes to  0054
 004C	     962B	CMP @R6,R11
 004E	     2004	JNE $+10, goes to  0058
 0050	     972A	CMP @R7,R10
 0052	     2802	JNC $+6, goes to  0058
 0054	     872A	SUB @R7,R10
 0056	     762B	SUBC @R6,R11
 0058	     6808	ADDC R8,R8
 005A	     6909	ADDC R9,R9
 005C	     2BEE	JNC $-34, goes to  003A
 005E	     B31C	BIT #1,R12
 0060	     2404	JEQ $+10, goes to  006A
 0062	     E338	XOR #-1,R8
 0064	     E339	XOR #-1,R9
 0066	     5318	ADD #1,R8
 0068	     6309	ADDC #0,R9
 006A	     B32C	BIT #2,R12
 006C	     2404	JEQ $+10, goes to  0076
 006E	     E33A	XOR #-1,R10
 0070	     E33B	XOR #-1,R11
 0072	     531A	ADD #1,R10
 0074	     630B	ADDC #0,R11
 0076	     4984	MOV R9,0(R4)
 0078	     0000
 007A	     4885	MOV R8,0(R5)
 007C	     0000
 007E	     4B86	MOV R11,0(R6)
 0080	     0000
 0082	     4A87	MOV R10,0(R7)
 0084	     0000
 0086	     4130	RET
fixups:

section     8	c   14	ASRLongInt
 0000	     9306	CMP #0,R6
 0002	     2404	JEQ $+10, goes to  000C
 0004	     1124	RRA @R4
 0006	     1025	RRC @R5
 0008	     8316	SUB #1,R6
 000A	     3FFA	JMP $-10, goes to  0000
 000C	     4130	RET
fixups:

section     9	c   24	AbsLong
 0000	     9384	CMP #0,0(R4)
 0002	     0000
 0004	     3408	JGE $+18, goes to  0016
 0006	     E3B5	XOR #-1,0(R5)
 0008	     0000
 000A	     E3B4	XOR #-1,0(R4)
 000C	     0000
 000E	     5395	ADD #1,0(R5)
 0010	     0000
 0012	     6384	ADDC #0,0(R4)
 0014	     0000
 0016	     4130	RET
fixups:

section    10	c   10	SubLongLong
 0000	     8785	SUB R7,0(R5)
 0002	     0000
 0004	     7684	SUBC R6,0(R4)
 0006	     0000
 0008	     4130	RET
fixups:

section    11	c   24	CmpLongLong
 0000	     8806	SUB R8,R6
 0002	     7705	SUBC R7,R5
 0004	     3402	JGE $+6, goes to  000A
 0006	     4334	MOV #-1,R4
 0008	     3C06	JMP $+14, goes to  0016
 000A	     2004	JNE $+10, goes to  0014
 000C	     9306	CMP #0,R6
 000E	     2002	JNE $+6, goes to  0014
 0010	     4304	MOV #0,R4
 0012	     3C01	JMP $+4, goes to  0016
 0014	     4314	MOV #1,R4
 0016	     4130	RET
fixups:

section    12	c    2	module body
 0000	     4130	RET
fixups:

section    13	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
   12    0    1    2    3    4    5    6    7    8
    9   10   11
