MODULE testBug;

  VAR i: INTEGER; 

  PROCEDURE r; END r;

  PROCEDURE^4 p*(a: INTEGER; q: PROCEDURE);
  BEGIN q
  END p;

BEGIN p(0, r)
END testBug.

OMSPTool.DecObj testBug.mpc

OMSPTool.DecSym testBug.sms

OM4Tool.DecObj testBug.m4c
decode testBug.m4c
testBug 704DE6B3   1    72
imports:
type descriptors

data     4
strings

code
commands:
entries
 0000001E 00000008
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       30
 00000000	     B500	PUSH LR
 00000002	 F85DEB04	LDR LR [ SP ] + 4
 00000006	     4770	BX LR
 00000008	     B410	PUSH R4
 0000000A	     B403	PUSH R0 R1
 0000000C	     B500	PUSH LR
 0000000E	     9802	LDR R0 [SP + 8]
 00000010	     4780	BLX R0
 00000012	 F85DEB04	LDR LR [ SP ] + 4
 00000016	 F11D0D08	ADDS SP SP #8
 0000001A	     BC10	POP R4
 0000001C	     4770	BX LR
 0000001E	     B500	PUSH LR
 00000020	     2000	MOVS R0 #0
 00000022	 F000F800	BL #0, goes to  00000026
 00000026	 F1BE0126	SUBS R1 LR #38
 0000002A	 F7FFFFED	BL #-38, goes to  00000008
 0000002E	 F85DEB04	LDR LR [ SP ] + 4
 00000032	     4770	BX LR
