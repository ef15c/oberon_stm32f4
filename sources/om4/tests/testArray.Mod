MODULE testArray;
  TYPE rt = RECORD
    a, b, c: INTEGER
  END;
  
  VAR s: ARRAY 10 OF CHAR;
    v: ARRAY 5 OF INTEGER;
    r: ARRAY 8 OF rt;
    i: INTEGER;
BEGIN 
  s[i] := s[i+1];
  v[i] := v[i+1];
  r[i] := r[i+1]
END testArray.

(*
ORTool.DecObj testArray.rsc ~

decode testArray.rsc
testArray D5E6D82E   1   408
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data   132
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 80000002	LDR  R0  R0       2
   3	 80000094	LDR  R0  R0     148
   4	 4109000A	SUB  R1  R0     10
   5	 DA00B71C	BLHI  MT
   6	 81000004	LDR  R1  R0       4
   7	 00180000	ADD  R0  R1  R0
   8	 81000002	LDR  R1  R0       2
   9	 81100094	LDR  R1  R1     148
  10	 41180001	ADD  R1  R1      1
  11	 4219000A	SUB  R2  R1     10
  12	 DA00C11C	BLHI  MT
  13	 82000005	LDR  R2  R0       5
  14	 01280001	ADD  R1  R2  R1
  15	 91100014	LDR  R1  R1      20
  16	 B1000014	STR   R1  R0      20
  17	 80000004	LDR  R0  R0       4
  18	 80000094	LDR  R0  R0     148
  19	 41090005	SUB  R1  R0      5
  20	 DA00CA1C	BLHI  MT
  21	 40010002	LSL  R0  R0      2
  22	 81000005	LDR  R1  R0       5
  23	 00180000	ADD  R0  R1  R0
  24	 81000002	LDR  R1  R0       2
  25	 81100094	LDR  R1  R1     148
  26	 41180001	ADD  R1  R1      1
  27	 42190005	SUB  R2  R1      5
  28	 DA00D41C	BLHI  MT
  29	 41110002	LSL  R1  R1      2
  30	 82000006	LDR  R2  R0       6
  31	 01280001	ADD  R1  R2  R1
  32	 81100020	LDR  R1  R1      32
  33	 A1000020	STR   R1  R0      32
  34	 80000004	LDR  R0  R0       4
  35	 80000094	LDR  R0  R0     148
  36	 41090008	SUB  R1  R0      8
  37	 DA00DD1C	BLHI  MT
  38	 400A000C	MUL  R0  R0     12
  39	 81000005	LDR  R1  R0       5
  40	 00180000	ADD  R0  R1  R0
  41	 81000002	LDR  R1  R0       2
  42	 81100094	LDR  R1  R1     148
  43	 41180001	ADD  R1  R1      1
  44	 42190008	SUB  R2  R1      8
  45	 DA00E71C	BLHI  MT
  46	 411A000C	MUL  R1  R1     12
  47	 82000006	LDR  R2  R0       6
  48	 01280001	ADD  R1  R2  R1
  49	 40080034	ADD  R0  R0     52
  50	 41180034	ADD  R1  R1     52
  51	 42000003	MOV  R2  R0      3
  52	 83100000	LDR  R3  R1       0
  53	 41180004	ADD  R1  R1      4
  54	 A3000000	STR   R3  R0       0
  55	 40080004	ADD  R0  R0      4
  56	 42290001	SUB  R2  R2      1
  57	 E9FFFFFA	BNE       -6
  58	 8FE00000	LDR LNK SP       0
  59	 4EE80004	ADD SP SP      4
  60	 C700000F	B LNK
commands:
entries
     0
pointer refs

fixP =        0
fixD =       47
fixT =        0
entry =        0

OM4Tool.DecObj testArray.m4c ~

decode testArray.m4c
testArray D5E6D82E   1   380
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data   132
strings

code
commands:
entries
     0
pointer refs

fixP =        0
fixD =      186
fixT =        0
entry =        0
   0	     B500	PUSH LR
   2	 00000001	MOV R0 lower 16-bits base(0)
   6	 00000094	MOVT R0 higher 16-bits base + 148
  10	     6800	LDR R0 [ R0 + 0]
  12	     280A	CMP R0 #10
  14	     BF28	IT CS
  16	 EC001371	TrapCS 1 at pos 183
  20	 10000009	MOV R1 lower 16-bits base(0)
  24	 00000014	MOVT R1 higher 16-bits base + 20
  28	     1808	ADDS R0 R1 R0
  30	 10000005	MOV R1 lower 16-bits base(0)
  34	 00000094	MOVT R1 higher 16-bits base + 148
  38	     6809	LDR R1 [ R1 + 0]
  40	     1C49	ADDS R1 R1 #1
  42	     290A	CMP R1 #10
  44	     BF28	IT CS
  46	 EC001411	TrapCS 1 at pos 193
  50	 2000000A	MOV R2 lower 16-bits base(0)
  54	 00000014	MOVT R2 higher 16-bits base + 20
  58	     1851	ADDS R1 R2 R1
  60	     7809	LDRB R1 [ R1 + 0]
  62	     7001	STRB R1 [ R0 + 0]
  64	 00000007	MOV R0 lower 16-bits base(0)
  68	 00000094	MOVT R0 higher 16-bits base + 148
  72	     6800	LDR R0 [ R0 + 0]
  74	     2805	CMP R0 #5
  76	     BF28	IT CS
  78	 EC0014A1	TrapCS 1 at pos 202
  82	 10000009	MOV R1 lower 16-bits base(0)
  86	 00000020	MOVT R1 higher 16-bits base + 32
  90	 EB110080	ADDS R0 R1 R0 LSL #2
  94	 10000006	MOV R1 lower 16-bits base(0)
  98	 00000094	MOVT R1 higher 16-bits base + 148
 102	     6809	LDR R1 [ R1 + 0]
 104	     1C49	ADDS R1 R1 #1
 106	     2905	CMP R1 #5
 108	     BF28	IT CS
 110	 EC001541	TrapCS 1 at pos 212
 114	 2000000A	MOV R2 lower 16-bits base(0)
 118	 00000020	MOVT R2 higher 16-bits base + 32
 122	 EB120181	ADDS R1 R2 R1 LSL #2
 126	     6809	LDR R1 [ R1 + 0]
 128	     6001	STR R1 [ R0 + 0]
 130	 00000008	MOV R0 lower 16-bits base(0)
 134	 00000094	MOVT R0 higher 16-bits base + 148
 138	     6800	LDR R0 [ R0 + 0]
 140	     2808	CMP R0 #8
 142	     BF28	IT CS
 144	 EC0015D1	TrapCS 1 at pos 221
 148	     210C	MOVS R1 #12
 150	     4348	MULS R0 R1 R0
 152	 1000000B	MOV R1 lower 16-bits base(0)
 156	 00000034	MOVT R1 higher 16-bits base + 52
 160	     1808	ADDS R0 R1 R0
 162	 10000005	MOV R1 lower 16-bits base(0)
 166	 00000094	MOVT R1 higher 16-bits base + 148
 170	     6809	LDR R1 [ R1 + 0]
 172	     1C49	ADDS R1 R1 #1
 174	     2908	CMP R1 #8
 176	     BF28	IT CS
 178	 EC001671	TrapCS 1 at pos 231
 182	     220C	MOVS R2 #12
 184	     4351	MULS R1 R2 R1
 186	 2000000C	MOV R2 lower 16-bits base(0)
 190	 00000034	MOVT R2 higher 16-bits base + 52
 194	     1851	ADDS R1 R2 R1
 196	     2203	MOVS R2 #3
 198	 F8513B04	LDR R3 [ R1 ] + 4
 202	 F8403B04	STR R3 [ R0 ] + 4
 206	     1E52	SUBS R2 R2 #1
 208	     D1F9	BNE #-14, goes to 198
 210	 F85DEB04	LDR LR [ SP ] + 4
 214	     4770	BX LR

*)

