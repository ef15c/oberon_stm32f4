MODULE testMBI;
  IMPORT SYSTEM;
  
  PROCEDURE p;
  BEGIN
    SYSTEM.MBI(1);
    SYSTEM.MBI(2);
    SYSTEM.MBI(3)
  END p;
  
END testMBI.


(*
OM4Tool.DecObj testMBI.m4c ~

decode testMBI.m4c
testMBI 74BCA7C2   1    40
imports:
type descriptors

data     0
strings

code
commands:
entries
    20
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       20
 00000000	     B500	PUSH LR
 00000002	 F3BF8F5F	DMB
 00000006	 F3BF8F4F	DSB
 0000000A	 F3BF8F6F	ISB
 0000000E	 F85DEB04	LDR LR [ SP ] + 4
 00000012	     4770	BX LR
 00000014	     B500	PUSH LR
 00000016	 F85DEB04	LDR LR [ SP ] + 4
 0000001A	     4770	BX LR



*)
