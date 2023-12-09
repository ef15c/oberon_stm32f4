OM4P.Compile @  
OM4X.WriteFile BootLoadM4.m4c 512 "D:/Verilog/RISC5/prom.mem"~

MODULE* BootLoadM4;  (*NW 20.10.2013 / PR 4.2.2014 / CS 09/12/2023; boot from SDHC disk only*)
  IMPORT SYSTEM;
  CONST SP = 13; LR = 14; PC = 15; (*dedicated registers*)
    VarORG0 = 0D0201000H;
    MTOrg = VarORG0+20H; MemLim = 0D0800000H; stackOrg = 10010000H;
    FSoffset = 80000H;   (*block offset*)

(* ---------- disk ------------*)

  PROCEDURE LoadFromDisk;
    VAR src, dst, lim: INTEGER;
  BEGIN src := FSoffset + 4;   (*start at boot block*)
    SYSTEM.LDREG(0, src); SYSTEM.LDREG(1, VarORG0); SYSTEM.SVC(2);
    SYSTEM.GET(VarORG0+16, lim);
    INC(src); dst := VarORG0+512;
    WHILE dst < lim DO 
      SYSTEM.LDREG(0, src); SYSTEM.LDREG(1, dst); SYSTEM.SVC(2);
      INC(src); INC(dst, 512)
    END
  END LoadFromDisk;

BEGIN
  LED(42H); LoadFromDisk;
  SYSTEM.PUT(VarORG0+12, MemLim); SYSTEM.PUT(VarORG0+24, stackOrg); LED(44H)
END BootLoadM4.

(*
OM4Tool.DecObj BootLoadM4.m4c ~

decode BootLoadM4.m4c
BootLoadM4 00000000   0   202
imports:
type descriptors

data     8
strings

code
commands:
entries
   128
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =      128
   0	 F000B83E	B #124, goes to 128
   4	     0000	LSLS R0 R0 #0
   6	     0000	LSLS R0 R0 #0
   8	     0000	LSLS R0 R0 #0
  10	     0000	LSLS R0 R0 #0
  12	     0000	LSLS R0 R0 #0
  14	     0000	LSLS R0 R0 #0
  16	     0000	LSLS R0 R0 #0
  18	     0000	LSLS R0 R0 #0
  20	     0000	LSLS R0 R0 #0
  22	     0000	LSLS R0 R0 #0
  24	     0000	LSLS R0 R0 #0
  26	     0000	LSLS R0 R0 #0
  28	     0000	LSLS R0 R0 #0
  30	     0000	LSLS R0 R0 #0
  32	 F1BD0D0C	SUBS SP SP #12
  36	     B500	PUSH LR
  38	     2004	MOVS R0 #4
  40	 F2C00008	MOVT R0 #8
  44	     9001	STR R0 [SP + 4]
  46	     9801	LDR R0 [SP + 4]
  48	 F2410100	MOV R1 #4096
  52	 F2CD0120	MOVT R1 #53280
  56	     DF02	SVC #2
  58	 F2410010	MOV R0 #4112
  62	 F2CD0020	MOVT R0 #53280
  66	     6800	LDR R0 [ R0 + 0]
  68	     9003	STR R0 [SP + 12]
  70	     9801	LDR R0 [SP + 4]
  72	     1C40	ADDS R0 R0 #1
  74	     9001	STR R0 [SP + 4]
  76	 F2412000	MOV R0 #4608
  80	 F2CD0020	MOVT R0 #53280
  84	     9002	STR R0 [SP + 8]
  86	     9802	LDR R0 [SP + 8]
  88	     9903	LDR R1 [SP + 12]
  90	     4288	CMP R0 R1
  92	 F280800B	BGE #22, goes to 118
  96	     9801	LDR R0 [SP + 4]
  98	     9902	LDR R1 [SP + 8]
 100	     DF02	SVC #2
 102	     9801	LDR R0 [SP + 4]
 104	     1C40	ADDS R0 R0 #1
 106	     9001	STR R0 [SP + 4]
 108	     9802	LDR R0 [SP + 8]
 110	 F2002000	ADD R0 R0 #512
 114	     9002	STR R0 [SP + 8]
 116	     E7EF	B #-34, goes to 86
 118	 F85DEB04	LDR LR [ SP ] + 4
 122	 F11D0D0C	ADDS SP SP #12
 126	     4770	BX LR
 128	     2042	MOVS R0 #66
 130	     DF01	SVC #1
 132	 F7FFFFCC	BL #-104, goes to 32
 136	 F241000C	MOV R0 #4108
 140	 F2CD0020	MOVT R0 #53280
 144	     2100	MOVS R1 #0
 146	 F2CD0180	MOVT R1 #53376
 150	     6001	STR R1 [ R0 + 0]
 152	 F2410018	MOV R0 #4120
 156	 F2CD0020	MOVT R0 #53280
 160	     2100	MOVS R1 #0
 162	 F2C10101	MOVT R1 #4097
 166	     6001	STR R1 [ R0 + 0]
 168	     2044	MOVS R0 #68
 170	     DF01	SVC #1
 172	 F2410000	MOV R0 #4096
 176	 F2CD0020	MOVT R0 #53280
 180	     4700	BX R0

*)

OM4P.Compile @  ORG.Decode
OM4X.WriteFile Counter.m4c 2048 "D:/Verilog/RISC/prom.mem"~
OM4X.WriteFile Shifter.m4c 2048 "D:/Verilog/RISC/prom.mem"~

MODULE* Counter;
  VAR x, y, z: INTEGER;
BEGIN LED(1); z := 0;
  REPEAT LED(z); x := 1000;
     REPEAT y := 1000;
       REPEAT y := y-1 UNTIL y = 0;
       x := x-1
     UNTIL x = 0;
     z := z+1
   UNTIL FALSE
END Counter.

MODULE* Shifter;
  VAR x, y, z, d: INTEGER;
BEGIN  z := 1; d := 1;
  REPEAT LED(z); x := 1000;
     REPEAT y := 1000;
       REPEAT y := y-1 UNTIL y = 0;
       x := x-1
     UNTIL x = 0;
     IF z = 128 THEN d := -1 ELSIF z = 1 THEN d := 1 END ;
     IF d = 1 THEN z := LSL(z, 1) ELSE z := ASR(z, 1) END
   UNTIL FALSE
END Shifter.
