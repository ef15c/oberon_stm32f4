(*C. Schoffit 15.09.24 *)

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
  (*Multiply long integer lh-ll with by integer value n*)
    VAR negate: BOOLEAN*; tl, th: INTEGER*;
  BEGIN negate := FALSE;
    IF lh < 0 THEN XOR(negate, -1); XOR(ll, -1); XOR(lh, -1); INC(ll, 1); ADC(lh, 0) END;
    IF n < 0 THEN XOR(negate, -1); XOR(n, -1); INC(n) END;
    th := lh; tl := ll; lh := 0; ll := 0;
    WHILE n # 0 DO IF ODD(n) THEN INC(ll, tl); ADC(lh, th) END; INC(tl, tl); ADC(th, th); CLRC; RRC(n) END;
    IF negate THEN XOR(ll, -1); XOR(lh, -1); INC(ll, 1); ADC(lh, 0) END
  END MulLongInt;

  PROCEDURE ASRLongInt*(VAR lh, ll: INTEGER*; n: INTEGER*);
  BEGIN WHILE n # 0 DO RRA(lh, 1); RRC(ll); DEC(n) END
  END ASRLongInt;

END MultiPrecisionArith.

OMSPTool.DecObj MultiPrecisionArith.mpc
decode MultiPrecisionArith.mpc
MultiPrecisionArith A6EFC8D6 Flash   210
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 00D0 0000 0028 003C 0046 0050 0062 00C2
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  00D0
code   210
 0000	     4386	MOV #0,0(R6)
 0002	     0000
 0004	     4387	MOV #0,0(R7)
 0006	     0000
 0008	     4508	MOV R5,R8
 000A	     4309	MOV #0,R9
 000C	     9304	CMP #0,R4
 000E	     240B	JEQ #11, goes to  0026
 0010	     B314	BIT #1,R4
 0012	     2404	JEQ #4, goes to  001C
 0014	     5886	ADD R8,0(R6)
 0016	     0000
 0018	     6987	ADDC R9,0(R7)
 001A	     0000
 001C	     5808	ADD R8,R8
 001E	     6909	ADDC R9,R9
 0020	     C312	BIC #1,SR
 0022	     1004	RRC R4
 0024	     3FF3	JMP #-13, goes to  000C
 0026	     4130	RET
 0028	     4685	MOV R6,0(R5)
 002A	     0000
 002C	     9306	CMP #0,R6
 002E	     3403	JGE #3, goes to  0036
 0030	     43B4	MOV #-1,0(R4)
 0032	     0000
 0034	     3C02	JMP #2, goes to  003A
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
 0068	     3409	JGE #9, goes to  007C
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
 007E	     3403	JGE #3, goes to  0086
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
 0094	     240B	JEQ #11, goes to  00AC
 0096	     B316	BIT #1,R6
 0098	     2404	JEQ #4, goes to  00A2
 009A	     5885	ADD R8,0(R5)
 009C	     0000
 009E	     6984	ADDC R9,0(R4)
 00A0	     0000
 00A2	     5808	ADD R8,R8
 00A4	     6909	ADDC R9,R9
 00A6	     C312	BIC #1,SR
 00A8	     1006	RRC R6
 00AA	     3FF3	JMP #-13, goes to  0092
 00AC	     9347	CMP.B #0,R7
 00AE	     2408	JEQ #8, goes to  00C0
 00B0	     E3B5	XOR #-1,0(R5)
 00B2	     0000
 00B4	     E3B4	XOR #-1,0(R4)
 00B6	     0000
 00B8	     5395	ADD #1,0(R5)
 00BA	     0000
 00BC	     6384	ADDC #0,0(R4)
 00BE	     0000
 00C0	     4130	RET
 00C2	     9306	CMP #0,R6
 00C4	     2404	JEQ #4, goes to  00CE
 00C6	     1124	RRA @R4
 00C8	     1025	RRC @R5
 00CA	     8316	SUB #1,R6
 00CC	     3FFA	JMP #-6, goes to  00C2
 00CE	     4130	RET
 00D0	     4130	RET

OMSPTool.DecSym MultiPrecisionArith.sms
decode MultiPrecisionArith.sms
MultiPrecisionArith A6EFC8D6  1
   1 mulu1632 [0  form = 10  size = 2 [^9] leaf UR 03F0( class = 3 R7 [^4] class = 3 R6 [^4] class = 2 R5 [^4] class = 2 R4 [^4])]       1
   1 SetLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       2
   1 SubLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       3
   1 AddLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       4
   1 LongNegate [0  form = 10  size = 2 [^9] leaf UR 0030( class = 3 R5 [^4] class = 3 R4 [^4])]       5
   1 MulLongInt [0  form = 10  size = 2 [^9] leaf UR 03F0( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       6
   1 ASRLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       7
