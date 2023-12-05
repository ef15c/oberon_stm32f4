MODULE testInc;
  VAR a, b: INTEGER;
    c, d: BYTE;
  PROCEDURE p;
    VAR i, j: INTEGER;
    k, l: BYTE;
  BEGIN
    INC(a); INC(a, 2); INC(a, -2); INC(a, b);
    INC(c); INC(c, 2); INC(c, -2); INC(c, d);
    DEC(a); DEC(a, 2); DEC(a, -2); DEC(a, b);
    DEC(c); DEC(c, 2); DEC(c, -2); DEC(c, d);
    
    INC(i); INC(i, 2); INC(i, -2); INC(i, j);
    INC(k); INC(k, 2); INC(k, -2); INC(k, l);
    DEC(i); DEC(i, 2); DEC(i, -2); DEC(i, j);
    DEC(k); DEC(k, 2); DEC(k, -2); DEC(k, l);
  END p;
  
END testInc.


(*
ORTool.DecObj testInc.rsc ~

decode testInc.rsc
testInc 74D6D3BE   1   624
imports:
type descriptors

data    12
strings

code
   0	 4EE90010	SUB SP SP     16
   1	 AFE00000	STR  LNK SP       0
   2	 80000002	LDR  R0  R0       2
   3	 40080000	ADD  R0  R0      0
   4	 81000000	LDR  R1  R0       0
   5	 41180001	ADD  R1  R1      1
   6	 A1000000	STR   R1  R0       0
   7	 80000005	LDR  R0  R0       5
   8	 40080000	ADD  R0  R0      0
   9	 81000000	LDR  R1  R0       0
  10	 41180002	ADD  R1  R1      2
  11	 A1000000	STR   R1  R0       0
  12	 80000005	LDR  R0  R0       5
  13	 40080000	ADD  R0  R0      0
  14	 81000000	LDR  R1  R0       0
  15	 5118FFFE	ADD  R1  R1     -2
  16	 A1000000	STR   R1  R0       0
  17	 80000005	LDR  R0  R0       5
  18	 40080000	ADD  R0  R0      0
  19	 81000000	LDR  R1  R0       0
  20	 82000003	LDR  R2  R0       3
  21	 82200004	LDR  R2  R2       4
  22	 01180002	ADD  R1  R1  R2
  23	 A1000000	STR   R1  R0       0
  24	 80000004	LDR  R0  R0       4
  25	 40080008	ADD  R0  R0      8
  26	 91000000	LDR  R1  R0       0
  27	 41180001	ADD  R1  R1      1
  28	 B1000000	STR   R1  R0       0
  29	 80000005	LDR  R0  R0       5
  30	 40080008	ADD  R0  R0      8
  31	 91000000	LDR  R1  R0       0
  32	 41180002	ADD  R1  R1      2
  33	 B1000000	STR   R1  R0       0
  34	 80000005	LDR  R0  R0       5
  35	 40080008	ADD  R0  R0      8
  36	 91000000	LDR  R1  R0       0
  37	 5118FFFE	ADD  R1  R1     -2
  38	 B1000000	STR   R1  R0       0
  39	 80000005	LDR  R0  R0       5
  40	 40080008	ADD  R0  R0      8
  41	 91000000	LDR  R1  R0       0
  42	 82000003	LDR  R2  R0       3
  43	 92200009	LDR  R2  R2       9
  44	 01180002	ADD  R1  R1  R2
  45	 B1000000	STR   R1  R0       0
  46	 80000004	LDR  R0  R0       4
  47	 40080000	ADD  R0  R0      0
  48	 81000000	LDR  R1  R0       0
  49	 41190001	SUB  R1  R1      1
  50	 A1000000	STR   R1  R0       0
  51	 80000005	LDR  R0  R0       5
  52	 40080000	ADD  R0  R0      0
  53	 81000000	LDR  R1  R0       0
  54	 41190002	SUB  R1  R1      2
  55	 A1000000	STR   R1  R0       0
  56	 80000005	LDR  R0  R0       5
  57	 40080000	ADD  R0  R0      0
  58	 81000000	LDR  R1  R0       0
  59	 5119FFFE	SUB  R1  R1     -2
  60	 A1000000	STR   R1  R0       0
  61	 80000005	LDR  R0  R0       5
  62	 40080000	ADD  R0  R0      0
  63	 81000000	LDR  R1  R0       0
  64	 82000003	LDR  R2  R0       3
  65	 82200004	LDR  R2  R2       4
  66	 01190002	SUB  R1  R1  R2
  67	 A1000000	STR   R1  R0       0
  68	 80000004	LDR  R0  R0       4
  69	 40080008	ADD  R0  R0      8
  70	 91000000	LDR  R1  R0       0
  71	 41190001	SUB  R1  R1      1
  72	 B1000000	STR   R1  R0       0
  73	 80000005	LDR  R0  R0       5
  74	 40080008	ADD  R0  R0      8
  75	 91000000	LDR  R1  R0       0
  76	 41190002	SUB  R1  R1      2
  77	 B1000000	STR   R1  R0       0
  78	 80000005	LDR  R0  R0       5
  79	 40080008	ADD  R0  R0      8
  80	 91000000	LDR  R1  R0       0
  81	 5119FFFE	SUB  R1  R1     -2
  82	 B1000000	STR   R1  R0       0
  83	 80000005	LDR  R0  R0       5
  84	 40080008	ADD  R0  R0      8
  85	 91000000	LDR  R1  R0       0
  86	 82000003	LDR  R2  R0       3
  87	 92200009	LDR  R2  R2       9
  88	 01190002	SUB  R1  R1  R2
  89	 B1000000	STR   R1  R0       0
  90	 80E00004	LDR  R0 SP       4
  91	 40080001	ADD  R0  R0      1
  92	 A0E00004	STR   R0 SP       4
  93	 80E00004	LDR  R0 SP       4
  94	 40080002	ADD  R0  R0      2
  95	 A0E00004	STR   R0 SP       4
  96	 80E00004	LDR  R0 SP       4
  97	 5008FFFE	ADD  R0  R0     -2
  98	 A0E00004	STR   R0 SP       4
  99	 80E00004	LDR  R0 SP       4
 100	 81E00008	LDR  R1 SP       8
 101	 00080001	ADD  R0  R0  R1
 102	 A0E00004	STR   R0 SP       4
 103	 90E0000C	LDR  R0 SP      12
 104	 40080001	ADD  R0  R0      1
 105	 B0E0000C	STR   R0 SP      12
 106	 90E0000C	LDR  R0 SP      12
 107	 40080002	ADD  R0  R0      2
 108	 B0E0000C	STR   R0 SP      12
 109	 90E0000C	LDR  R0 SP      12
 110	 5008FFFE	ADD  R0  R0     -2
 111	 B0E0000C	STR   R0 SP      12
 112	 90E0000C	LDR  R0 SP      12
 113	 91E0000D	LDR  R1 SP      13
 114	 00080001	ADD  R0  R0  R1
 115	 B0E0000C	STR   R0 SP      12
 116	 80E00004	LDR  R0 SP       4
 117	 40090001	SUB  R0  R0      1
 118	 A0E00004	STR   R0 SP       4
 119	 80E00004	LDR  R0 SP       4
 120	 40090002	SUB  R0  R0      2
 121	 A0E00004	STR   R0 SP       4
 122	 80E00004	LDR  R0 SP       4
 123	 5009FFFE	SUB  R0  R0     -2
 124	 A0E00004	STR   R0 SP       4
 125	 80E00004	LDR  R0 SP       4
 126	 81E00008	LDR  R1 SP       8
 127	 00090001	SUB  R0  R0  R1
 128	 A0E00004	STR   R0 SP       4
 129	 90E0000C	LDR  R0 SP      12
 130	 40090001	SUB  R0  R0      1
 131	 B0E0000C	STR   R0 SP      12
 132	 90E0000C	LDR  R0 SP      12
 133	 40090002	SUB  R0  R0      2
 134	 B0E0000C	STR   R0 SP      12
 135	 90E0000C	LDR  R0 SP      12
 136	 5009FFFE	SUB  R0  R0     -2
 137	 B0E0000C	STR   R0 SP      12
 138	 90E0000C	LDR  R0 SP      12
 139	 91E0000D	LDR  R1 SP      13
 140	 00090001	SUB  R0  R0  R1
 141	 B0E0000C	STR   R0 SP      12
 142	 8FE00000	LDR LNK SP       0
 143	 4EE80010	ADD SP SP     16
 144	 C700000F	B LNK
 145	 4EE90004	SUB SP SP      4
 146	 AFE00000	STR  LNK SP       0
 147	 8FE00000	LDR LNK SP       0
 148	 4EE80004	ADD SP SP      4
 149	 C700000F	B LNK
commands:
entries
   580
pointer refs

fixP =        0
fixD =       86
fixT =        0
entry =      580


OM4Tool.DecObj testInc.m4c ~

decode testInc.m4c
testInc 74D6D3BE   1   468
imports:
type descriptors

data    12
strings

code
commands:
entries
   436
pointer refs

fixP =        0
fixD =      264
fixT =        0
entry =      436
   0	 F1BD0D0C	SUBS SP SP #12
   4	     B500	PUSH LR
   6	 00000003	MOV R0 lower 16-bits base(0)
  10	 0000D414	MOVT R0 higher 16-bits var(0)
  14	     6801	LDR R1 [ R0 + 0]
  16	     1C49	ADDS R1 R1 #1
  18	     6001	STR R1 [ R0 + 0]
  20	 00000007	MOV R0 lower 16-bits base(0)
  24	 0000D414	MOVT R0 higher 16-bits var(0)
  28	     6801	LDR R1 [ R0 + 0]
  30	     1C89	ADDS R1 R1 #2
  32	     6001	STR R1 [ R0 + 0]
  34	 00000007	MOV R0 lower 16-bits base(0)
  38	 0000D414	MOVT R0 higher 16-bits var(0)
  42	     6801	LDR R1 [ R0 + 0]
  44	 F1B10102	SUBS R1 R1 #2
  48	     6001	STR R1 [ R0 + 0]
  50	 00000008	MOV R0 lower 16-bits base(0)
  54	 0000D414	MOVT R0 higher 16-bits var(0)
  58	     6801	LDR R1 [ R0 + 0]
  60	 20000005	MOV R2 lower 16-bits base(0)
  64	 0000D414	MOVT R2 higher 16-bits var(4)
  68	     6812	LDR R2 [ R2 + 0]
  70	     1889	ADDS R1 R1 R2
  72	     6001	STR R1 [ R0 + 0]
  74	 00000007	MOV R0 lower 16-bits base(0)
  78	 0000D414	MOVT R0 higher 16-bits var(8)
  82	     7801	LDRB R1 [ R0 + 0]
  84	     1C49	ADDS R1 R1 #1
  86	     7001	STRB R1 [ R0 + 0]
  88	 00000007	MOV R0 lower 16-bits base(0)
  92	 0000D414	MOVT R0 higher 16-bits var(8)
  96	     7801	LDRB R1 [ R0 + 0]
  98	     1C89	ADDS R1 R1 #2
 100	     7001	STRB R1 [ R0 + 0]
 102	 00000007	MOV R0 lower 16-bits base(0)
 106	 0000D414	MOVT R0 higher 16-bits var(8)
 110	     7801	LDRB R1 [ R0 + 0]
 112	 F1B10102	SUBS R1 R1 #2
 116	     7001	STRB R1 [ R0 + 0]
 118	 00000008	MOV R0 lower 16-bits base(0)
 122	 0000D414	MOVT R0 higher 16-bits var(8)
 126	     7801	LDRB R1 [ R0 + 0]
 128	 20000005	MOV R2 lower 16-bits base(0)
 132	 0000D414	MOVT R2 higher 16-bits var(9)
 136	     7812	LDRB R2 [ R2 + 0]
 138	     1889	ADDS R1 R1 R2
 140	     7001	STRB R1 [ R0 + 0]
 142	 00000007	MOV R0 lower 16-bits base(0)
 146	 0000D414	MOVT R0 higher 16-bits var(0)
 150	     6801	LDR R1 [ R0 + 0]
 152	     1E49	SUBS R1 R1 #1
 154	     6001	STR R1 [ R0 + 0]
 156	 00000007	MOV R0 lower 16-bits base(0)
 160	 0000D414	MOVT R0 higher 16-bits var(0)
 164	     6801	LDR R1 [ R0 + 0]
 166	     1E89	SUBS R1 R1 #2
 168	     6001	STR R1 [ R0 + 0]
 170	 00000007	MOV R0 lower 16-bits base(0)
 174	 0000D414	MOVT R0 higher 16-bits var(0)
 178	     6801	LDR R1 [ R0 + 0]
 180	 F1110102	ADDS R1 R1 #2
 184	     6001	STR R1 [ R0 + 0]
 186	 00000008	MOV R0 lower 16-bits base(0)
 190	 0000D414	MOVT R0 higher 16-bits var(0)
 194	     6801	LDR R1 [ R0 + 0]
 196	 20000005	MOV R2 lower 16-bits base(0)
 200	 0000D414	MOVT R2 higher 16-bits var(4)
 204	     6812	LDR R2 [ R2 + 0]
 206	     1A89	SUBS R1 R1 R2
 208	     6001	STR R1 [ R0 + 0]
 210	 00000007	MOV R0 lower 16-bits base(0)
 214	 0000D414	MOVT R0 higher 16-bits var(8)
 218	     7801	LDRB R1 [ R0 + 0]
 220	     1E49	SUBS R1 R1 #1
 222	     7001	STRB R1 [ R0 + 0]
 224	 00000007	MOV R0 lower 16-bits base(0)
 228	 0000D414	MOVT R0 higher 16-bits var(8)
 232	     7801	LDRB R1 [ R0 + 0]
 234	     1E89	SUBS R1 R1 #2
 236	     7001	STRB R1 [ R0 + 0]
 238	 00000007	MOV R0 lower 16-bits base(0)
 242	 0000D414	MOVT R0 higher 16-bits var(8)
 246	     7801	LDRB R1 [ R0 + 0]
 248	 F1110102	ADDS R1 R1 #2
 252	     7001	STRB R1 [ R0 + 0]
 254	 00000008	MOV R0 lower 16-bits base(0)
 258	 0000D414	MOVT R0 higher 16-bits var(8)
 262	     7801	LDRB R1 [ R0 + 0]
 264	 20000005	MOV R2 lower 16-bits base(0)
 268	 0000D414	MOVT R2 higher 16-bits var(9)
 272	     7812	LDRB R2 [ R2 + 0]
 274	     1A89	SUBS R1 R1 R2
 276	     7001	STRB R1 [ R0 + 0]
 278	     9801	LDR R0 [SP + 4]
 280	     1C40	ADDS R0 R0 #1
 282	     9001	STR R0 [SP + 4]
 284	     9801	LDR R0 [SP + 4]
 286	     1C80	ADDS R0 R0 #2
 288	     9001	STR R0 [SP + 4]
 290	     9801	LDR R0 [SP + 4]
 292	 F1B00002	SUBS R0 R0 #2
 296	     9001	STR R0 [SP + 4]
 298	     9801	LDR R0 [SP + 4]
 300	     9902	LDR R1 [SP + 8]
 302	     1840	ADDS R0 R0 R1
 304	     9001	STR R0 [SP + 4]
 306	 F89D000C	LDRB R0 [ SP + 12 ]
 310	     1C40	ADDS R0 R0 #1
 312	 F88D000C	STRB R0 [ SP + 12 ]
 316	 F89D000C	LDRB R0 [ SP + 12 ]
 320	     1C80	ADDS R0 R0 #2
 322	 F88D000C	STRB R0 [ SP + 12 ]
 326	 F89D000C	LDRB R0 [ SP + 12 ]
 330	 F1B00002	SUBS R0 R0 #2
 334	 F88D000C	STRB R0 [ SP + 12 ]
 338	 F89D000C	LDRB R0 [ SP + 12 ]
 342	 F89D100D	LDRB R1 [ SP + 13 ]
 346	     1840	ADDS R0 R0 R1
 348	 F88D000C	STRB R0 [ SP + 12 ]
 352	     9801	LDR R0 [SP + 4]
 354	     1E40	SUBS R0 R0 #1
 356	     9001	STR R0 [SP + 4]
 358	     9801	LDR R0 [SP + 4]
 360	     1E80	SUBS R0 R0 #2
 362	     9001	STR R0 [SP + 4]
 364	     9801	LDR R0 [SP + 4]
 366	 F1100002	ADDS R0 R0 #2
 370	     9001	STR R0 [SP + 4]
 372	     9801	LDR R0 [SP + 4]
 374	     9902	LDR R1 [SP + 8]
 376	     1A40	SUBS R0 R0 R1
 378	     9001	STR R0 [SP + 4]
 380	 F89D000C	LDRB R0 [ SP + 12 ]
 384	     1E40	SUBS R0 R0 #1
 386	 F88D000C	STRB R0 [ SP + 12 ]
 390	 F89D000C	LDRB R0 [ SP + 12 ]
 394	     1E80	SUBS R0 R0 #2
 396	 F88D000C	STRB R0 [ SP + 12 ]
 400	 F89D000C	LDRB R0 [ SP + 12 ]
 404	 F1100002	ADDS R0 R0 #2
 408	 F88D000C	STRB R0 [ SP + 12 ]
 412	 F89D000C	LDRB R0 [ SP + 12 ]
 416	 F89D100D	LDRB R1 [ SP + 13 ]
 420	     1A40	SUBS R0 R0 R1
 422	 F88D000C	STRB R0 [ SP + 12 ]
 426	 F85DEB04	LDR LR [ SP ] + 4
 430	 F11D0D0C	ADDS SP SP #12
 434	     4770	BX LR
 436	     B500	PUSH LR
 438	 F85DEB04	LDR LR [ SP ] + 4
 442	     4770	BX LR


*)
