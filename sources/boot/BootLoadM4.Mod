OM4P.Compile @  
OM4X.WriteASM BootLoadM4.m4c BootLoadM4.s ~
OM4X.WriteFile BootLoadM4.m4c BootLoadM4.hex 0F000000H ~

MODULE* BootLoadM4;  (*NW 20.10.2013 / PR 4.2.2014 / CS 09/12/2023; boot from SDHC disk only*)
  IMPORT SYSTEM;
  CONST SP = 13; LR = 14; PC = 15; (*dedicated registers*)
    VarORG0 = 0D0201000H; MemLim = 0D0800000H; stackOrg = 10010000H;
    FSoffset = 80000H;   (*block offset*)

(* ---------- disk ------------*)

  PROCEDURE LoadFromDisk;
    VAR r, lim: INTEGER;
  BEGIN  
    (*start at boot block*)
    SYSTEM.LDREG(0, FSoffset + 4); SYSTEM.LDREG(1, VarORG0); SYSTEM.LDREG(2, 1); r := SYSTEM.SVC(2);
    SYSTEM.GET(VarORG0+16, lim);
    (*read remaining blocks*)
    SYSTEM.LDREG(0, FSoffset + 4 + 1); SYSTEM.LDREG(1, VarORG0+512); SYSTEM.LDREG(2, (lim+511) DIV 512 - 1); 
    r := SYSTEM.SVC(2);
  END LoadFromDisk;

BEGIN
  LED(42H); LoadFromDisk;
  SYSTEM.PUT(VarORG0+12, MemLim); SYSTEM.PUT(VarORG0+24, stackOrg); LED(44H)
END BootLoadM4.

(*
OM4Tool.DecObj BootLoadM4.m4c ~

decode BootLoadM4.m4c
BootLoadM4 00000000   0   156
imports:
type descriptors

data     8
strings

code
commands:
entries
    80
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       80
   0	 F000B826	B #76, goes to 80
   4	 F1BD0D08	SUBS SP SP #8
   8	     B500	PUSH LR
  10	     2004	MOVS R0 #4
  12	 F2C00008	MOVT R0 #8
  16	 F2410100	MOV R1 #4096
  20	 F2CD0120	MOVT R1 #53280
  24	     2201	MOVS R2 #1
  26	     DF02	SVC #2
  28	     9001	STR R0 [SP + 4]
  30	 F2410010	MOV R0 #4112
  34	 F2CD0020	MOVT R0 #53280
  38	     6800	LDR R0 [ R0 + 0]
  40	     9002	STR R0 [SP + 8]
  42	     2005	MOVS R0 #5
  44	 F2C00008	MOVT R0 #8
  48	 F2412100	MOV R1 #4608
  52	 F2CD0120	MOVT R1 #53280
  56	     9A02	LDR R2 [SP + 8]
  58	 F20212FF	ADD R2 R2 #511
  62	     1252	ASRS R2 R2 #9
  64	     1E52	SUBS R2 R2 #1
  66	     DF02	SVC #2
  68	     9001	STR R0 [SP + 4]
  70	 F85DEB04	LDR LR [ SP ] + 4
  74	 F11D0D08	ADDS SP SP #8
  78	     4770	BX LR
  80	     2042	MOVS R0 #66
  82	     DF01	SVC #1
  84	 F7FFFFD6	BL #-84, goes to 4
  88	 F241000C	MOV R0 #4108
  92	 F2CD0020	MOVT R0 #53280
  96	     2100	MOVS R1 #0
  98	 F2CD0180	MOVT R1 #53376
 102	     6001	STR R1 [ R0 + 0]
 104	 F2410018	MOV R0 #4120
 108	 F2CD0020	MOVT R0 #53280
 112	     2100	MOVS R1 #0
 114	 F2C10101	MOVT R1 #4097
 118	     6001	STR R1 [ R0 + 0]
 120	     2044	MOVS R0 #68
 122	     DF01	SVC #1
 124	 F2410000	MOV R0 #4096
 128	 F2CD0020	MOVT R0 #53280
 132	     4700	BX R0


*)

OM4P.Compile @  ORG.Decode
OM4X.WriteASM Counter.m4c Counter.s ~
OM4X.WriteASM Shifter.m4c Shifter.s ~

MODULE* Counter;
  PROCEDURE count;
    VAR x, y, z: INTEGER;
  BEGIN LED(1); z := 0;
    REPEAT LED(z); x := 1000;
      REPEAT y := 1000;
        REPEAT y := y-1 UNTIL y = 0;
          x := x-1
        UNTIL x = 0;
      z := z+1
    UNTIL FALSE
  END count;
BEGIN count;
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
