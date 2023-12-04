MODULE testFor;

  PROCEDURE p;
    VAR i,j: INTEGER;
  BEGIN
    FOR i := 1 TO 10 DO j := 2*i END;
    FOR i := 10 TO 1 BY -2 DO END
  END p;
  
END testFor.


(*
ORTool.DecObj testFor.rsc ~

decode testFor.rsc
testFor 74E5D4BB   1   120
imports:
type descriptors

data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 40000001	MOV  R0  R0      1
   3	 4109000A	SUB  R1  R0     10
   4	 EE000007	BGT        7
   5	 A0E00004	STR   R0 SP       4
   6	 80E00004	LDR  R0 SP       4
   7	 40010001	LSL  R0  R0      1
   8	 A0E00008	STR   R0 SP       8
   9	 80E00004	LDR  R0 SP       4
  10	 40080001	ADD  R0  R0      1
  11	 E7FFFFF7	B      -9
  12	 4000000A	MOV  R0  R0     10
  13	 41090001	SUB  R1  R0      1
  14	 E5000004	BLT        4
  15	 A0E00004	STR   R0 SP       4
  16	 80E00004	LDR  R0 SP       4
  17	 5008FFFE	ADD  R0  R0     -2
  18	 E7FFFFFA	B      -6
  19	 8FE00000	LDR LNK SP       0
  20	 4EE8000C	ADD SP SP     12
  21	 C700000F	B LNK
  22	 4EE90004	SUB SP SP      4
  23	 AFE00000	STR  LNK SP       0
  24	 8FE00000	LDR LNK SP       0
  25	 4EE80004	ADD SP SP      4
  26	 C700000F	B LNK
commands:
entries
    88
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       88


OM4Tool.DecObj testFor.m4c ~

decode testFor.m4c
testFor 74E5D4BB   1    80
imports:
type descriptors

data     0
strings

code
commands:
entries
    60
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       60
   0	 F1BD0D08	SUBS SP SP #8
   4	     B500	PUSH LR
   6	     2001	MOVS R0 #1
   8	     210A	MOVS R1 #10
  10	     4288	CMP R0 R1
  12	 F3008007	BGT #14, goes to 30
  16	     9001	STR R0 [SP + 4]
  18	     9801	LDR R0 [SP + 4]
  20	     0040	LSLS R0 R0 #1
  22	     9002	STR R0 [SP + 8]
  24	     9801	LDR R0 [SP + 4]
  26	     1C40	ADDS R0 R0 #1
  28	     E7F4	B #-24, goes to 8
  30	     200A	MOVS R0 #10
  32	     2101	MOVS R1 #1
  34	     4288	CMP R0 R1
  36	 F2C08005	BLT #10, goes to 50
  40	     9001	STR R0 [SP + 4]
  42	     9801	LDR R0 [SP + 4]
  44	 F1B00002	SUBS R0 R0 #2
  48	     E7F6	B #-20, goes to 32
  50	 F85DEB04	LDR LR [ SP ] + 4
  54	 F11D0D08	ADDS SP SP #8
  58	     4770	BX LR
  60	     B500	PUSH LR
  62	 F85DEB04	LDR LR [ SP ] + 4
  66	     4770	BX LR


*)
