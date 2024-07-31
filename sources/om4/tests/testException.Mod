MODULE testException;
  PROCEDURE* Handler(frame: LONGINT);
  BEGIN
  END Handler;
END testException.


(*
ORTool.DecObj testException.rsc ~

decode testException.rsc
testException 49415297   1    68
imports:
type descriptors

data     0
strings

code
   0	 4EE90010	SUB SP SP     16
   1	 A0E00000	STR   R0 SP       0
   2	 A1E00004	STR   R1 SP       4
   3	 A2E00008	STR   R2 SP       8
   4	 82E00008	LDR  R2 SP       8
   5	 81E00004	LDR  R1 SP       4
   6	 80E00000	LDR  R0 SP       0
   7	 4EE80010	ADD SP SP     16
   8	 C7000010	B  R0
   9	 4EE90004	SUB SP SP      4
  10	 AFE00000	STR  LNK SP       0
  11	 8FE00000	LDR LNK SP       0
  12	 4EE80004	ADD SP SP      4
  13	 C700000F	B LNK
commands:
entries
    36
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       36


OM4Tool.DecObj testException.m4c ~

decode testException.m4c
testException 49415297   1    48
imports:
type descriptors

data     0
strings

code
commands:
entries
    28
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       28
   0	 F01E0F04	TST LR #4
   4	     BF0C	ITE EQ
   6	 F3EF8008	MRSEQ R0 MSP
  10	 F3EF8009	MRSNE R0 PSP
  14	     B401	PUSH R0
  16	     B500	PUSH LR
  18	 F85DEB04	LDR LR [ SP ] + 4
  22	 F11D0D04	ADDS SP SP #4
  26	     4770	BX LR
  28	     B500	PUSH LR
  30	 F85DEB04	LDR LR [ SP ] + 4
  34	     4770	BX LR

*)
