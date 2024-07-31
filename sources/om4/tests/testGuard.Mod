MODULE testGuard;
  
  TYPE R0 = POINTER TO  R0D;
    R0D = RECORD END;
    R1 = POINTER TO R1D;
    R1D = RECORD (R0D) END;

  PROCEDURE p;
    VAR V1: R0;
  BEGIN
    CASE V1 OF
    R0:
    END
  END p;
  
END testGuard.


(*
ORTool.DecObj testGuard.rsc ~

decode testGuard.rsc
testGuard E6D5DB1F   1    96
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000020 00014006 FFFFFFFF FFFFFFFF FFFFFFFF
data     0
strings

code
   0	 4EE90008	SUB SP SP      8
   1	 AFE00000	STR  LNK SP       0
   2	 EF000000	BNO        0
   3	 8FE00000	LDR LNK SP       0
   4	 4EE80008	ADD SP SP      8
   5	 C700000F	B LNK
   6	 4EE90004	SUB SP SP      4
   7	 AFE00000	STR  LNK SP       0
   8	 8FE00000	LDR LNK SP       0
   9	 4EE80004	ADD SP SP      4
  10	 C700000F	B LNK
commands:
entries
    24
pointer refs

fixP =        0
fixD =        0
fixT =        6
entry =       24



OM4Tool.DecObj testGuard.m4c ~

decode testGuard.m4c
testGuard E6D5DB1F   1    80
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000020 00014006 FFFFFFFF FFFFFFFF FFFFFFFF
data     0
strings

code
commands:
entries
    20
pointer refs

fixP =        0
fixD =        0
fixT =        6
entry =       20
 00000000	 F1BD0D04	SUBS SP SP #4
 00000004	     B500	PUSH LR
 00000006	 F3AF8000	NOP
 0000000A	 F85DEB04	LDR LR [ SP ] + 4
 0000000E	 F11D0D04	ADDS SP SP #4
 00000012	     4770	BX LR
 00000014	     B500	PUSH LR
 00000016	 F85DEB04	LDR LR [ SP ] + 4
 0000001A	     4770	BX LR


*)
