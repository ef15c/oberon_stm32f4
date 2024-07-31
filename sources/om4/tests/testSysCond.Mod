MODULE testSysCond;
  IMPORT SYSTEM;  
  CONST MI = 4;
  VAR i: INTEGER;
    b: BOOLEAN;
BEGIN
  SYSTEM.CMP(i, 0);
  b := SYSTEM.COND(MI)
END testSysCond.

(*
OM4Tool.DecObj testSysCond.m4c ~

decode testSysCond.m4c
testSysCond B84B4D37   1    56
imports:
type descriptors

data     8
strings

code
commands:
entries
     0
pointer refs

fixP =        0
fixD =       20
fixT =        0
entry =        0
 00000000	     B500	PUSH LR
 00000002	 00000001	MOV R0 lower 16-bits base(0)
 00000006	 00000000	MOVT R0 higher 16-bits base + 0
 0000000A	     6800	LDR R0 [ R0 + 0]
 0000000C	     2800	CMP R0 #0
 0000000E	     BF4C	ITE MI
 00000010	     2001	MOVMI R0 #1
 00000012	     2000	MOVPL R0 #0
 00000014	 10000009	MOV R1 lower 16-bits base(0)
 00000018	 00000004	MOVT R1 higher 16-bits base + 4
 0000001C	     7008	STRB R0 [ R1 + 0]
 0000001E	 F85DEB04	LDR LR [ SP ] + 4
 00000022	     4770	BX LR

*)
