MODULE LongInt;
  IMPORT SYSTEM, Texts, Oberon;

  VAR a, b: LONGINT; c: INTEGER;
    W: Texts.Writer;

  PROCEDURE Write(l: LONGINT);
    VAR low: INTEGER;
  BEGIN low := l; l := LSR(l, 32);
    Texts.WriteHex(W, l); Texts.WriteHex(W, low); Texts.WriteLn(W);

    Texts.Append(Oberon.Log, W.buf)
  END Write;
(*
  PROCEDURE DivL(VAR D, S: LONGINT);
    (* Divides 2 64bit integers. D is divident, S is divisor
        at exit D becomes D MOD S and S becomes D DIV S *)
    VAR clzd, clzs, coef, coef2: INTEGER; neg: BOOLEAN; q, rd: LONGINT;
  BEGIN (* Int64 division *) neg := FALSE;
    IF D < 0 THEN neg := TRUE; D := -D END;
    clzd := CLZ(D); clzs :=  CLZ(S);
    IF (clzd >= 32) & (clzs >= 32) THEN (*both D and S fit in INTEGER, we can use 32bit division*)
      clzd := SYSTEM.VAL(INTEGER, D) DIV SYSTEM.VAL(INTEGER, S); 
      DEC(SYSTEM.VAL(INTEGER, D), clzd*SYSTEM.VAL(INTEGER, S)); S := clzd
    ELSE (*64bit division is required*) coef := clzs - clzd;
      IF coef < 0 THEN S := 0
      ELSE q := 0; rd := S; IF coef > 0 THEN rd := LSL(rd, coef) END;
        WHILE D > S DO
          IF D < rd THEN rd := LSR(rd, 1); q := LSL(q, 1); DEC(coef) END;
          DEC(D, rd); INC(q);
          clzd := CLZ(D); clzs := CLZ(rd); coef2 := clzs - clzd;
          ASSERT(coef2 > 0); q := LSL(q, coef2); rd := LSR(rd, coef2); DEC(coef, coef2)
        END;
        q := LSL(q, coef); D := rd; S := q
      END
    END; IF neg THEN D := -D; S := -S END
  END DivL;
*)
  PROCEDURE run*;
  BEGIN a := 1234567890; a := a*10000000; INC(a, 1234567); Write(a);
    Texts.WriteHex(W, SYSTEM.ADR(a)); Texts.WriteLn(W);
    b := 10; Write(b);
  (*  DivL(a, b);
    Texts.WriteInt(W, SYSTEM.VAL(INTEGER, a), 1); Texts.WriteLn(W);
    Texts.WriteInt(W, SYSTEM.VAL(INTEGER, b), 1); Texts.WriteLn(W);
*)
    Texts.Append(Oberon.Log, W.buf)
  END run;

BEGIN Texts.OpenWriter(W)
END LongInt.

OM4Tool.DecObj LongInt.m4c
decode LongInt.m4c
LongInt FC1279C7   1   540
imports:
	Texts AFCB7538
	Fonts AA480AE7
	Files 1482C9F6
	Oberon DB3EE95B
	Display 15E666AA
	Viewers E54B088A
	PS2 FA464427
type descriptors

data    60
strings

code
commands:
	run  122
entries
 00000160 0000007A
pointer refs
    56    44    24    20
fixP =      370
fixD =      362
fixT =        0
entry =      352
 00000000	 F1BD0D04	SUBS SP SP #4
 00000004	     B403	PUSH R0 R1
 00000006	     B500	PUSH LR
 00000008	     9801	LDR R0 [SP + 4]
 0000000A	     9003	STR R0 [SP + 12]
 0000000C	 E9DD0101	LDRD R0 R1 [ SP+ 4 ]
 00000010	     4608	MOV R0 R1
 00000012	     2100	MOVS R1 #0
 00000014	 E9CD0101	STRD R0 R1 [ SP+ 4 ]
 00000018	 0000000C	MOV R0 lower 16-bits base(0)
 0000001C	 00000014	MOVT R0 higher 16-bits base + 20
 00000020	 11000004	MOV R1 lower 16-bits base(1)
 00000024	 00000005	MOVT R1 higher 16-bits var(5)
 00000028	     9A01	LDR R2 [SP + 4]
 0000002A	 11F00015	BL Mod(  1) proc(31)
 0000002E	 00000007	MOV R0 lower 16-bits base(0)
 00000032	 00000014	MOVT R0 higher 16-bits base + 20
 00000036	 11000004	MOV R1 lower 16-bits base(1)
 0000003A	 00000005	MOVT R1 higher 16-bits var(5)
 0000003E	     9A03	LDR R2 [SP + 12]
 00000040	 11F0000B	BL Mod(  1) proc(31)
 00000044	 00000007	MOV R0 lower 16-bits base(0)
 00000048	 00000014	MOVT R0 higher 16-bits base + 20
 0000004C	 11000004	MOV R1 lower 16-bits base(1)
 00000050	 00000005	MOVT R1 higher 16-bits var(5)
 00000054	 11C0000A	BL Mod(  1) proc(28)
 00000058	 04000006	MOV R0 lower 16-bits base(4)
 0000005C	 0000000D	MOVT R0 higher 16-bits var(13)
 00000060	     6800	LDR R0 [ R0 + 0]
 00000062	 10000005	MOV R1 lower 16-bits base(0)
 00000066	 00000014	MOVT R1 higher 16-bits base + 20
 0000006A	     6809	LDR R1 [ R1 + 0]
 0000006C	 10E0000C	BL Mod(  1) proc(14)
 00000070	 F85DEB04	LDR LR [ SP ] + 4
 00000074	 F11D0D0C	ADDS SP SP #12
 00000078	     4770	BX LR
 0000007A	     B500	PUSH LR
 0000007C	 F24020D2	MOV R0 #722
 00000080	 F6C41096	MOVT R0 #18838
 00000084	     2100	MOVS R1 #0
 00000086	 20000012	MOV R2 lower 16-bits base(0)
 0000008A	 00000000	MOVT R2 higher 16-bits base + 0
 0000008E	 E9C20100	STRD R0 R1 [ R2+ 0 ]
 00000092	 F2496080	MOV R0 #38528
 00000096	 F2C00098	MOVT R0 #152
 0000009A	     2100	MOVS R1 #0
 0000009C	 2000000B	MOV R2 lower 16-bits base(0)
 000000A0	 00000000	MOVT R2 higher 16-bits base + 0
 000000A4	 E9D22300	LDRD R2 R3 [ R2+ 0 ]
 000000A8	 FB02F401	MUL R4 R2 R1
 000000AC	 FB03F500	MUL R5 R3 R0
 000000B0	     1964	ADDS R4 R4 R5
 000000B2	 FBA20100	UMULL R0 R1 R2 R0
 000000B6	     1909	ADDS R1 R1 R4
 000000B8	 2000000E	MOV R2 lower 16-bits base(0)
 000000BC	 00000000	MOVT R2 higher 16-bits base + 0
 000000C0	 E9C20100	STRD R0 R1 [ R2+ 0 ]
 000000C4	 F24D6087	MOV R0 #54919
 000000C8	 F2C00012	MOVT R0 #18
 000000CC	     2100	MOVS R1 #0
 000000CE	 2000000B	MOV R2 lower 16-bits base(0)
 000000D2	 00000000	MOVT R2 higher 16-bits base + 0
 000000D6	 E9D23400	LDRD R3 R4 [ R2+ 0 ]
 000000DA	     181B	ADDS R3 R3 R0
 000000DC	     414C	ADCS R4 R4 R1
 000000DE	 E9C23400	STRD R3 R4 [ R2+ 0 ]
 000000E2	 0000000A	MOV R0 lower 16-bits base(0)
 000000E6	 00000000	MOVT R0 higher 16-bits base + 0
 000000EA	 E9D00100	LDRD R0 R1 [ R0+ 0 ]
 000000EE	 F7FFFF87	BL #-242, goes to  00000000
 000000F2	 00000008	MOV R0 lower 16-bits base(0)
 000000F6	 00000014	MOVT R0 higher 16-bits base + 20
 000000FA	 11000004	MOV R1 lower 16-bits base(1)
 000000FE	 00000005	MOVT R1 higher 16-bits var(5)
 00000102	 20000004	MOV R2 lower 16-bits base(0)
 00000106	 00000000	MOVT R2 higher 16-bits base + 0
 0000010A	 11F0004F	BL Mod(  1) proc(31)
 0000010E	 00000006	MOV R0 lower 16-bits base(0)
 00000112	 00000014	MOVT R0 higher 16-bits base + 20
 00000116	 11000004	MOV R1 lower 16-bits base(1)
 0000011A	 00000005	MOVT R1 higher 16-bits var(5)
 0000011E	 11C0000A	BL Mod(  1) proc(28)
 00000122	     200A	MOVS R0 #10
 00000124	     2100	MOVS R1 #0
 00000126	 20000008	MOV R2 lower 16-bits base(0)
 0000012A	 00000008	MOVT R2 higher 16-bits base + 8
 0000012E	 E9C20100	STRD R0 R1 [ R2+ 0 ]
 00000132	 00000006	MOV R0 lower 16-bits base(0)
 00000136	 00000008	MOVT R0 higher 16-bits base + 8
 0000013A	 E9D00100	LDRD R0 R1 [ R0+ 0 ]
 0000013E	 F7FFFF5F	BL #-322, goes to  00000000
 00000142	 04000008	MOV R0 lower 16-bits base(4)
 00000146	 0000000D	MOVT R0 higher 16-bits var(13)
 0000014A	     6800	LDR R0 [ R0 + 0]
 0000014C	 10000005	MOV R1 lower 16-bits base(0)
 00000150	 00000014	MOVT R1 higher 16-bits base + 20
 00000154	     6809	LDR R1 [ R1 + 0]
 00000156	 10E0001C	BL Mod(  1) proc(14)
 0000015A	 F85DEB04	LDR LR [ SP ] + 4
 0000015E	     4770	BX LR
 00000160	     B500	PUSH LR
 00000162	 0000000B	MOV R0 lower 16-bits base(0)
 00000166	 00000014	MOVT R0 higher 16-bits base + 20
 0000016A	 11000004	MOV R1 lower 16-bits base(1)
 0000016E	 00000005	MOVT R1 higher 16-bits var(5)
 00000172	 1170000E	BL Mod(  1) proc(23)
 00000176	 F85DEB04	LDR LR [ SP ] + 4
 0000017A	     4770	BX LR
