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
    VAR lim: INTEGER;
  BEGIN  
    (*start at boot block*)
    SYSTEM.LDREG(0, FSoffset + 4); SYSTEM.LDREG(1, VarORG0); SYSTEM.LDREG(2, 1); SYSTEM.SVC(2);
    SYSTEM.GET(VarORG0+16, lim);
    (*read remaining blocks*)
    SYSTEM.LDREG(0, FSoffset + 4 + 1); SYSTEM.LDREG(1, VarORG0+512); SYSTEM.LDREG(2, (lim+511) DIV 512 - 1); SYSTEM.SVC(2);
  END LoadFromDisk;

BEGIN
  LED(42H); LoadFromDisk;
  SYSTEM.PUT(VarORG0+12, MemLim); SYSTEM.PUT(VarORG0+24, stackOrg); LED(44H)
END BootLoadM4.

(*
OM4Tool.DecObj BootLoadM4.m4c ~
decode BootLoadM4.m4c
BootLoadM4 00000000   0   178
imports:
type descriptors

data     8
strings

code
commands:
entries
   104
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =      104
   0	 F000B832	B #100, goes to 104
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
  32	 F1BD0D04	SUBS SP SP #4
  36	     B500	PUSH LR
  38	     2004	MOVS R0 #4
  40	 F2C00008	MOVT R0 #8
  44	 F2410100	MOV R1 #4096
  48	 F2CD0120	MOVT R1 #53280
  52	     2201	MOVS R2 #1
  54	     DF02	SVC #2
  56	 F2410010	MOV R0 #4112
  60	 F2CD0020	MOVT R0 #53280
  64	     6800	LDR R0 [ R0 + 0]
  66	     9001	STR R0 [SP + 4]
  68	     2005	MOVS R0 #5
  70	 F2C00008	MOVT R0 #8
  74	 F2412100	MOV R1 #4608
  78	 F2CD0120	MOVT R1 #53280
  82	     9A01	LDR R2 [SP + 4]
  84	 F20212FF	ADD R2 R2 #511
  88	     1252	ASRS R2 R2 #9
  90	     1E52	SUBS R2 R2 #1
  92	     DF02	SVC #2
  94	 F85DEB04	LDR LR [ SP ] + 4
  98	 F11D0D04	ADDS SP SP #4
 102	     4770	BX LR
 104	     2042	MOVS R0 #66
 106	     DF01	SVC #1
 108	 F7FFFFD8	BL #-80, goes to 32
 112	 F241000C	MOV R0 #4108
 116	 F2CD0020	MOVT R0 #53280
 120	     2100	MOVS R1 #0
 122	 F2CD0180	MOVT R1 #53376
 126	     6001	STR R1 [ R0 + 0]
 128	 F2410018	MOV R0 #4120
 132	 F2CD0020	MOVT R0 #53280
 136	     2100	MOVS R1 #0
 138	 F2C10101	MOVT R1 #4097
 142	     6001	STR R1 [ R0 + 0]
 144	     2044	MOVS R0 #68
 146	     DF01	SVC #1
 148	 F2410000	MOV R0 #4096
 152	 F2CD0020	MOVT R0 #53280
 156	     4700	BX R0



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
