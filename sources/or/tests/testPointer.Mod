MODULE testPointer;
  TYPE node* = POINTER TO rec;
    rec* = RECORD
      l*, r*: node;
    END;

  VAR n*: node;

END testPointer.

(*
ORTool.DecObj testPointer.rsc ~

decode testPointer.rsc
testPointer C7962A70   1    76
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF 00000004 00000000 FFFFFFFF
data     4
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 8FE00000	LDR LNK SP       0
   3	 4EE80004	ADD SP SP      4
   4	 C700000F	B LNK
commands:
entries
     0     0    28
pointer refs
    28
fixP =        0
fixD =        0
fixT =        0
entry =        0



OM4Tool.DecObj testPointer.m4c ~

decode testPointer.m4c
testPointer C7962A70   1    64
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF 00000004 00000000 FFFFFFFF
data     4
strings

code
commands:
entries
     0     0    28
pointer refs
    28
fixP =        0
fixD =        0
fixT =        0
entry =        0
 00000000	     B500	PUSH LR
 00000002	 F85DEB04	LDR LR [ SP ] + 4
 00000006	     4770	BX LR


*)
