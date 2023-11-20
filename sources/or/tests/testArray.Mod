MODULE testArray;
  VAR s: ARRAY 10 OF CHAR;
    v: ARRAY 5 OF INTEGER;
    i: INTEGER;
BEGIN 
  s[i] := s[i+1];
  v[i] := v[i+1]
END testArray.

(*
ORTool.DecObj testArray.rsc ~

decode testArray.rsc
testArray D5E6D82E   1   196
imports:
type descriptors

data    36
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 80000002	LDR  R0  R0       2
   3	 80000020	LDR  R0  R0      32
   4	 4109000A	SUB  R1  R0     10
   5	 DA006A1C	BLHI  MT
   6	 81000004	LDR  R1  R0       4
   7	 00180000	ADD  R0  R1  R0
   8	 81000002	LDR  R1  R0       2
   9	 81100020	LDR  R1  R1      32
  10	 41180001	ADD  R1  R1      1
  11	 4219000A	SUB  R2  R1     10
  12	 DA00741C	BLHI  MT
  13	 82000005	LDR  R2  R0       5
  14	 01280001	ADD  R1  R2  R1
  15	 91100000	LDR  R1  R1       0
  16	 B1000000	STR   R1  R0       0
  17	 80000004	LDR  R0  R0       4
  18	 80000020	LDR  R0  R0      32
  19	 41090005	SUB  R1  R0      5
  20	 DA007D1C	BLHI  MT
  21	 40010002	LSL  R0  R0      2
  22	 81000005	LDR  R1  R0       5
  23	 00180000	ADD  R0  R1  R0
  24	 81000002	LDR  R1  R0       2
  25	 81100020	LDR  R1  R1      32
  26	 41180001	ADD  R1  R1      1
  27	 42190005	SUB  R2  R1      5
  28	 DA00871C	BLHI  MT
  29	 41110002	LSL  R1  R1      2
  30	 82000006	LDR  R2  R0       6
  31	 01280001	ADD  R1  R2  R1
  32	 8110000C	LDR  R1  R1      12
  33	 A100000C	STR   R1  R0      12
  34	 8FE00000	LDR LNK SP       0
  35	 4EE80004	ADD SP SP      4
  36	 C700000F	B LNK
commands:
entries
     0
pointer refs

fixP =        0
fixD =       30
fixT =        0
entry =        0

OM4Tool.DecObj testArray.m4c ~

decode testArray.m4c
testArray D5E6D82E   1   168
imports:
type descriptors

data    36
strings

code
commands:
entries
     0
pointer refs

fixP =        0
fixD =       98
fixT =        0
entry =        0
   0	     B500	PUSH LR
   2	 00000001	LDR R0 [ MT + Base(0) ]
   6	 F8D00020	LDR R0 [ R0 + 32 ]
  10	     280A	CMP R0 #10
  12	     BF28	IT CS
  14	 EC0006A1	TrapCS 1 at pos 106
  18	 10000008	LDR R1 [ MT + Base(0) ]
  22	     1808	ADDS R0 R1 R0
  24	 10000003	LDR R1 [ MT + Base(0) ]
  28	 F8D11020	LDR R1 [ R1 + 32 ]
  32	     1C49	ADDS R1 R1 #1
  34	     290A	CMP R1 #10
  36	     BF28	IT CS
  38	 EC000741	TrapCS 1 at pos 116
  42	 20000009	LDR R2 [ MT + Base(0) ]
  46	     1851	ADDS R1 R2 R1
  48	 F8911000	LDRB R1 [ R1 + 0 ]
  52	 F8801000	STRB R1 [ R0 + 0 ]
  56	 00000007	LDR R0 [ MT + Base(0) ]
  60	 F8D00020	LDR R0 [ R0 + 32 ]
  64	     2805	CMP R0 #5
  66	     BF28	IT CS
  68	 EC0007D1	TrapCS 1 at pos 125
  72	 10000008	LDR R1 [ MT + Base(0) ]
  76	 EB110080	ADDS R0 R1 R0 LSL #2
  80	 10000004	LDR R1 [ MT + Base(0) ]
  84	 F8D11020	LDR R1 [ R1 + 32 ]
  88	     1C49	ADDS R1 R1 #1
  90	     2905	CMP R1 #5
  92	     BF28	IT CS
  94	 EC001071	TrapCS 1 at pos 135
  98	 20000009	LDR R2 [ MT + Base(0) ]
 102	 EB120181	ADDS R1 R2 R1 LSL #2
 106	 F8D1100C	LDR R1 [ R1 + 12 ]
 110	 F8C0100C	STR R1 [ R0 + 12 ]
 114	 F85DEB04	LDR LR [ SP ] + 4
 118	     4770	BX LR

*)

