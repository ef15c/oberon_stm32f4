MODULE testSVC;
	IMPORT SYSTEM;

PROCEDURE led(v: INTEGER);
BEGIN
	SYSTEM.LDREG(0, v);
	SYSTEM.SVC(1)
END led;

PROCEDURE ReadSD(src, dst: INTEGER);
BEGIN
	SYSTEM.LDREG(0, src);
	SYSTEM.LDREG(1, dst);
	SYSTEM.SVC(2)
END ReadSD;


END testSVC.

(*

OM4Tool.DecObj testSVC.m4c ~

decode testSVC.m4c
testSVC 74B6BBC8   1    58
imports:
type descriptors

data     0
strings

code
commands:
entries
    38
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       38
   0	     B401	PUSH R0
   2	     B500	PUSH LR
   4	     9801	LDR R0 [SP + 4]
   6	     DF01	SVC #1
   8	 F85DEB04	LDR LR [ SP ] + 4
  12	 F11D0D04	ADDS SP SP #4
  16	     4770	BX LR
  18	     B403	PUSH R0 R1
  20	     B500	PUSH LR
  22	     9801	LDR R0 [SP + 4]
  24	     9902	LDR R1 [SP + 8]
  26	     DF02	SVC #2
  28	 F85DEB04	LDR LR [ SP ] + 4
  32	 F11D0D08	ADDS SP SP #8
  36	     4770	BX LR
  38	     B500	PUSH LR
  40	 F85DEB04	LDR LR [ SP ] + 4
  44	     4770	BX LR

*)
