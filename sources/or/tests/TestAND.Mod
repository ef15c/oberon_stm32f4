MODULE TestAND;

PROCEDURE and*;
VAR res, a, b, c : BOOLEAN;
BEGIN
  res := a & b & c;
END and;

END TestAND.

(*
imports:
type descriptors

data     0
strings

code
   0	 4EE90008	SUB  SP  SP      8
   1	 AFE00000	STR  LNK SP      0
   2	 90E00005	LDR  R0 SP       5
   3	 E1000006	BEQ     6
   4	 90E00006	LDR  R0 SP       6
   5	 E1000004	BEQ     4
   6	 90E00007	LDR  R0 SP       7
   7	 E1000002	BEQ     2
   8	 40000001	MOV  R0  R0      1
   9	 E7000001	B       1
  10	 40000000	MOV  R0  R0      0
  11	 B0E00004	STR  R0 SP       4
  12	 8FE00000	LDR LNK SP       0
  13	 4EE80008	ADD SP SP        8
  14	 C700000F	B LNK
  15	 4EE90004	SUB SP SP        4
  16	 AFE00000	STR  LNK SP      0
  17	 8FE00000	LDR LNK SP       0
  18	 4EE80004	ADD SP SP        4
  19	 C700000F	B LNK
commands:
	and    0
entries
    60     0
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =      60
*)
