MODULE TestBYTE;
  IMPORT OM4S;
  
  VAR a: LONGINT;

BEGIN
  a := OM4S.ival
END TestBYTE.

(* TestBYTE.test
System.Free TestBYTE ~
ORTool.DecObj TestBYTE.rsc ~

TestBYTE B9C7BF96   1    60
imports:
	OM4S B9E0C970
	Texts ECBD67B7
type descriptors

data     4
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0 
   2	 80100002	LDR  R0  R1       2   mno=1 Next=0
   3	 80000001	LDR  R0  R0       1   vno=1
   4	 81000002	LDR  R1  R0       2   mno=0 Next=2
   5	 A0100000	STR   R0  R1       0  no fix
   6	 8FE00000	LDR LNK SP       0
   7	 4EE80004	ADD SP SP      4
   8	 C700000F	B LNK
commands:
entries
     0
pointer refs

fixP =        0
fixD =        4
fixT =        0
entry =        0


 *)
