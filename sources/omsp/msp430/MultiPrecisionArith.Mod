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
    WHILE (nh # 0) & (nl # 0) DO CLRC; RRC(nh); RRC(nl); IF SYSTEM.COND(C) THEN INC(ll, tl); ADC(lh, th) END; INC(tl, tl); ADC(th, th) END;
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
MultiPrecisionArith F94936B3  1
   1 mulu1632 [0  form = 10  size = 2 [^9] leaf UR 03F0( class = 3 R7 [^4] class = 3 R6 [^4] class = 2 R5 [^4] class = 2 R4 [^4])]       1
   1 SetLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       2
   1 SubLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       3
   1 AddLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       4
   1 LongNegate [0  form = 10  size = 2 [^9] leaf UR 0030( class = 3 R5 [^4] class = 3 R4 [^4])]       5
   1 MulLongInt [0  form = 10  size = 2 [^9] leaf UR 03F0( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       6
   1 MulLongLong [0  form = 10  size = 2 [^9] leaf UR 07F0( class = 2 R7 [^4] class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       7
   1 DivLongLong [0  form = 10  size = 2 [^9] leaf UR 1FF0( class = 3 R7 [^4] class = 3 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       8
   1 ASRLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       9
   1 AbsLong [0  form = 10  size = 2 [^9] leaf UR 0030( class = 3 R5 [^4] class = 3 R4 [^4])]      10
   1 SubLongLong [0  form = 10  size = 2 [^9] leaf UR 00F0( class = 2 R7 [^4] class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]      11
   1 CmpLongLong [0  form = 10  size = 2 [^4] leaf UR 01F0( class = 2 R8 [^4] class = 2 R7 [^4] class = 2 R6 [^4] class = 2 R5 [^4])]      12

OMSPTool.DecObj MultiPrecisionArith.mpc
decode MultiPrecisionArith.mpc
MultiPrecisionArith F94936B3 Flash   506
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 01F8 c 0000 c 0028 c 003C c 0046 c 0050 c 0062 c 00C0 c 0128 c 01B0 c 01BE c 01D6 c 01E0
fixup procedures in code space chains
fixup handlers in vector space chains
fixup data in code space chains
fixup constants in code space chains
fixup variables in constant space chains
fixup constants in constant space chains
entry =  01F8
code   506
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
 006A	     E357	XOR.B #1,R7
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
 0080	     E357	XOR.B #1,R7
 0082	     E336	XOR #-1,R6
 0084	     5316	ADD #1,R6
 0086	     4429	MOV @R4,R9
 0088	     4528	MOV @R5,R8
 008A	     4384	MOV #0,0(R4)
 008C	     0000
 008E	     4385	MOV #0,0(R5)
 0090	     0000
 0092	     9306	CMP #0,R6
 0094	     240A	JEQ $+22, goes to  00AA
 0096	     C312	BIC #1,SR
 0098	     1006	RRC R6
 009A	     2804	JNC $+10, goes to  00A4
 009C	     5885	ADD R8,0(R5)
 009E	     0000
 00A0	     6984	ADDC R9,0(R4)
 00A2	     0000
 00A4	     5808	ADD R8,R8
 00A6	     6909	ADDC R9,R9
 00A8	     3FF4	JMP $-22, goes to  0092
 00AA	     9347	CMP.B #0,R7
 00AC	     2408	JEQ $+18, goes to  00BE
 00AE	     E3B5	XOR #-1,0(R5)
 00B0	     0000
 00B2	     E3B4	XOR #-1,0(R4)
 00B4	     0000
 00B6	     5395	ADD #1,0(R5)
 00B8	     0000
 00BA	     6384	ADDC #0,0(R4)
 00BC	     0000
 00BE	     4130	RET
 00C0	     4348	MOV.B #0,R8
 00C2	     9384	CMP #0,0(R4)
 00C4	     0000
 00C6	     3409	JGE $+20, goes to  00DA
 00C8	     E358	XOR.B #1,R8
 00CA	     E3B5	XOR #-1,0(R5)
 00CC	     0000
 00CE	     E3B4	XOR #-1,0(R4)
 00D0	     0000
 00D2	     5395	ADD #1,0(R5)
 00D4	     0000
 00D6	     6384	ADDC #0,0(R4)
 00D8	     0000
 00DA	     9306	CMP #0,R6
 00DC	     3405	JGE $+12, goes to  00E8
 00DE	     E358	XOR.B #1,R8
 00E0	     E337	XOR #-1,R7
 00E2	     E336	XOR #-1,R6
 00E4	     5317	ADD #1,R7
 00E6	     6306	ADDC #0,R6
 00E8	     442A	MOV @R4,R10
 00EA	     4529	MOV @R5,R9
 00EC	     4384	MOV #0,0(R4)
 00EE	     0000
 00F0	     4385	MOV #0,0(R5)
 00F2	     0000
 00F4	     9306	CMP #0,R6
 00F6	     240D	JEQ $+28, goes to  0112
 00F8	     9307	CMP #0,R7
 00FA	     240B	JEQ $+24, goes to  0112
 00FC	     C312	BIC #1,SR
 00FE	     1006	RRC R6
 0100	     1007	RRC R7
 0102	     2804	JNC $+10, goes to  010C
 0104	     5985	ADD R9,0(R5)
 0106	     0000
 0108	     6A84	ADDC R10,0(R4)
 010A	     0000
 010C	     5909	ADD R9,R9
 010E	     6A0A	ADDC R10,R10
 0110	     3FF1	JMP $-28, goes to  00F4
 0112	     9348	CMP.B #0,R8
 0114	     2408	JEQ $+18, goes to  0126
 0116	     E3B5	XOR #-1,0(R5)
 0118	     0000
 011A	     E3B4	XOR #-1,0(R4)
 011C	     0000
 011E	     5395	ADD #1,0(R5)
 0120	     0000
 0122	     6384	ADDC #0,0(R4)
 0124	     0000
 0126	     4130	RET
 0128	     430C	MOV #0,R12
 012A	     9386	CMP #0,0(R6)
 012C	     0000
 012E	     3409	JGE $+20, goes to  0142
 0130	     E3B7	XOR #-1,0(R7)
 0132	     0000
 0134	     E3B6	XOR #-1,0(R6)
 0136	     0000
 0138	     5397	ADD #1,0(R7)
 013A	     0000
 013C	     6386	ADDC #0,0(R6)
 013E	     0000
 0140	     431C	MOV #1,R12
 0142	     9384	CMP #0,0(R4)
 0144	     0000
 0146	     3409	JGE $+20, goes to  015A
 0148	     E3B5	XOR #-1,0(R5)
 014A	     0000
 014C	     E3B4	XOR #-1,0(R4)
 014E	     0000
 0150	     5395	ADD #1,0(R5)
 0152	     0000
 0154	     6384	ADDC #0,0(R4)
 0156	     0000
 0158	     E33C	XOR #-1,R12
 015A	     430B	MOV #0,R11
 015C	     430A	MOV #0,R10
 015E	     4309	MOV #0,R9
 0160	     4318	MOV #1,R8
 0162	     55A5	ADD @R5,0(R5)
 0164	     0000
 0166	     64A4	ADDC @R4,0(R4)
 0168	     0000
 016A	     6A0A	ADDC R10,R10
 016C	     6B0B	ADDC R11,R11
 016E	     9B86	CMP R11,0(R6)
 0170	     0000
 0172	     3804	JL $+10, goes to  017C
 0174	     962B	CMP @R6,R11
 0176	     2004	JNE $+10, goes to  0180
 0178	     972A	CMP @R7,R10
 017A	     2802	JNC $+6, goes to  0180
 017C	     872A	SUB @R7,R10
 017E	     762B	SUBC @R6,R11
 0180	     6808	ADDC R8,R8
 0182	     6909	ADDC R9,R9
 0184	     2BEE	JNC $-34, goes to  0162
 0186	     B31C	BIT #1,R12
 0188	     2404	JEQ $+10, goes to  0192
 018A	     E338	XOR #-1,R8
 018C	     E339	XOR #-1,R9
 018E	     5318	ADD #1,R8
 0190	     6309	ADDC #0,R9
 0192	     B32C	BIT #2,R12
 0194	     2404	JEQ $+10, goes to  019E
 0196	     E33A	XOR #-1,R10
 0198	     E33B	XOR #-1,R11
 019A	     531A	ADD #1,R10
 019C	     630B	ADDC #0,R11
 019E	     4984	MOV R9,0(R4)
 01A0	     0000
 01A2	     4885	MOV R8,0(R5)
 01A4	     0000
 01A6	     4B86	MOV R11,0(R6)
 01A8	     0000
 01AA	     4A87	MOV R10,0(R7)
 01AC	     0000
 01AE	     4130	RET
 01B0	     9306	CMP #0,R6
 01B2	     2404	JEQ $+10, goes to  01BC
 01B4	     1124	RRA @R4
 01B6	     1025	RRC @R5
 01B8	     8316	SUB #1,R6
 01BA	     3FFA	JMP $-10, goes to  01B0
 01BC	     4130	RET
 01BE	     9384	CMP #0,0(R4)
 01C0	     0000
 01C2	     3408	JGE $+18, goes to  01D4
 01C4	     E3B5	XOR #-1,0(R5)
 01C6	     0000
 01C8	     E3B4	XOR #-1,0(R4)
 01CA	     0000
 01CC	     5395	ADD #1,0(R5)
 01CE	     0000
 01D0	     6384	ADDC #0,0(R4)
 01D2	     0000
 01D4	     4130	RET
 01D6	     8785	SUB R7,0(R5)
 01D8	     0000
 01DA	     7684	SUBC R6,0(R4)
 01DC	     0000
 01DE	     4130	RET
 01E0	     8806	SUB R8,R6
 01E2	     7705	SUBC R7,R5
 01E4	     3402	JGE $+6, goes to  01EA
 01E6	     4334	MOV #-1,R4
 01E8	     3C06	JMP $+14, goes to  01F6
 01EA	     2004	JNE $+10, goes to  01F4
 01EC	     9306	CMP #0,R6
 01EE	     2002	JNE $+6, goes to  01F4
 01F0	     4304	MOV #0,R4
 01F2	     3C01	JMP $+4, goes to  01F6
 01F4	     4314	MOV #1,R4
 01F6	     4130	RET
 01F8	     4130	RET
