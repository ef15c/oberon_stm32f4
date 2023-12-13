MODULE QuickSort;
  TYPE
    Item* = POINTER TO ItemPayload;
    ItemPayload* = RECORD
    END;
    
    LT* = PROCEDURE(a, b: Item): BOOLEAN;
    
  PROCEDURE doSort(VAR a: ARRAY OF Item; L, R: INTEGER; cmp: LT);
    VAR i, j: INTEGER; w, x: Item;
  BEGIN
    i := L; j := R;
    x := a[(L+R) DIV 2];
    REPEAT
      WHILE cmp(a[i], x) DO i := i+1 END;
      WHILE cmp(x, a[j]) DO j := j-1 END;
      IF i <= j THEN
        w := a[i]; a[i] := a[j]; a[j] := w;
        i := i+1; j := j-1
      END
    UNTIL i > j;
    IF L < j THEN doSort(a, L, j, cmp) END;
    IF i < R THEN doSort(a, i, R, cmp) END
  END doSort;

  PROCEDURE Sort*(VAR a: ARRAY OF Item; cmp: LT);
  BEGIN
    doSort(a, 0, LEN(a)-1, cmp)
  END Sort;

END QuickSort.

(*


OM4Tool.DecObj QuickSort.m4c ~

decode QuickSort.m4c
QuickSort 6C618B42   1   392
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     0
strings

code
commands:
entries
   342     0   312
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =      342
   0	 F1BD0D10	SUBS SP SP #16
   4	     B41F	PUSH R0 R1 R2 R3 R4
   6	     B500	PUSH LR
   8	     9803	LDR R0 [SP + 12]
  10	     9006	STR R0 [SP + 24]
  12	     9804	LDR R0 [SP + 16]
  14	     9007	STR R0 [SP + 28]
  16	     9803	LDR R0 [SP + 12]
  18	     9904	LDR R1 [SP + 16]
  20	     1840	ADDS R0 R0 R1
  22	     1040	ASRS R0 R0 #1
  24	     9902	LDR R1 [SP + 8]
  26	     4288	CMP R0 R1
  28	     BF28	IT CS
  30	 EC002381	TrapCS 1 at pos 312
  34	     9901	LDR R1 [SP + 4]
  36	 EB110080	ADDS R0 R1 R0 LSL #2
  40	     6800	LDR R0 [ R0 + 0]
  42	     9009	STR R0 [SP + 36]
  44	     9806	LDR R0 [SP + 24]
  46	     9902	LDR R1 [SP + 8]
  48	     4288	CMP R0 R1
  50	     BF28	IT CS
  52	 EC0025B1	TrapCS 1 at pos 347
  56	     9901	LDR R1 [SP + 4]
  58	 EB110080	ADDS R0 R1 R0 LSL #2
  62	     6800	LDR R0 [ R0 + 0]
  64	     9909	LDR R1 [SP + 36]
  66	     9A05	LDR R2 [SP + 20]
  68	     2A00	CMP R2 #0
  70	     BF08	IT EQ
  72	 EC002625	TrapEQ 5 at pos 354
  76	     4790	BLX R2
  78	     2800	CMP R0 #0
  80	 F0008004	BEQ #8, goes to 92
  84	     9806	LDR R0 [SP + 24]
  86	     1C40	ADDS R0 R0 #1
  88	     9006	STR R0 [SP + 24]
  90	     E7E7	B #-50, goes to 44
  92	     9809	LDR R0 [SP + 36]
  94	     9907	LDR R1 [SP + 28]
  96	     9A02	LDR R2 [SP + 8]
  98	     4291	CMP R1 R2
 100	     BF28	IT CS
 102	 EC003091	TrapCS 1 at pos 393
 106	     9A01	LDR R2 [SP + 4]
 108	 EB120181	ADDS R1 R2 R1 LSL #2
 112	     6809	LDR R1 [ R1 + 0]
 114	     9A05	LDR R2 [SP + 20]
 116	     2A00	CMP R2 #0
 118	     BF08	IT EQ
 120	 EC0030D5	TrapEQ 5 at pos 397
 124	     4790	BLX R2
 126	     2800	CMP R0 #0
 128	 F0008004	BEQ #8, goes to 140
 132	     9807	LDR R0 [SP + 28]
 134	     1E40	SUBS R0 R0 #1
 136	     9007	STR R0 [SP + 28]
 138	     E7E7	B #-50, goes to 92
 140	     9806	LDR R0 [SP + 24]
 142	     9907	LDR R1 [SP + 28]
 144	     4288	CMP R0 R1
 146	 F3008030	BGT #96, goes to 246
 150	     9806	LDR R0 [SP + 24]
 152	     9902	LDR R1 [SP + 8]
 154	     4288	CMP R0 R1
 156	     BF28	IT CS
 158	 EC003441	TrapCS 1 at pos 452
 162	     9901	LDR R1 [SP + 4]
 164	 EB110080	ADDS R0 R1 R0 LSL #2
 168	     6800	LDR R0 [ R0 + 0]
 170	     9008	STR R0 [SP + 32]
 172	     9806	LDR R0 [SP + 24]
 174	     9902	LDR R1 [SP + 8]
 176	     4288	CMP R0 R1
 178	     BF28	IT CS
 180	 EC0034A1	TrapCS 1 at pos 458
 184	     9901	LDR R1 [SP + 4]
 186	 EB110080	ADDS R0 R1 R0 LSL #2
 190	     9907	LDR R1 [SP + 28]
 192	     9A02	LDR R2 [SP + 8]
 194	     4291	CMP R1 R2
 196	     BF28	IT CS
 198	 EC003521	TrapCS 1 at pos 466
 202	     9A01	LDR R2 [SP + 4]
 204	 EB120181	ADDS R1 R2 R1 LSL #2
 208	     6809	LDR R1 [ R1 + 0]
 210	     6001	STR R1 [ R0 + 0]
 212	     9807	LDR R0 [SP + 28]
 214	     9902	LDR R1 [SP + 8]
 216	     4288	CMP R0 R1
 218	     BF28	IT CS
 220	 EC003581	TrapCS 1 at pos 472
 224	     9901	LDR R1 [SP + 4]
 226	 EB110080	ADDS R0 R1 R0 LSL #2
 230	     9908	LDR R1 [SP + 32]
 232	     6001	STR R1 [ R0 + 0]
 234	     9806	LDR R0 [SP + 24]
 236	     1C40	ADDS R0 R0 #1
 238	     9006	STR R0 [SP + 24]
 240	     9807	LDR R0 [SP + 28]
 242	     1E40	SUBS R0 R0 #1
 244	     9007	STR R0 [SP + 28]
 246	     9806	LDR R0 [SP + 24]
 248	     9907	LDR R1 [SP + 28]
 250	     4288	CMP R0 R1
 252	     DD96	BLE #-212, goes to 44
 254	     9803	LDR R0 [SP + 12]
 256	     9907	LDR R1 [SP + 28]
 258	     4288	CMP R0 R1
 260	 F2808007	BGE #14, goes to 278
 264	     9801	LDR R0 [SP + 4]
 266	     9902	LDR R1 [SP + 8]
 268	     9A03	LDR R2 [SP + 12]
 270	     9B07	LDR R3 [SP + 28]
 272	     9C05	LDR R4 [SP + 20]
 274	 F7FFFF75	BL #-278, goes to 0
 278	     9806	LDR R0 [SP + 24]
 280	     9904	LDR R1 [SP + 16]
 282	     4288	CMP R0 R1
 284	 F2808007	BGE #14, goes to 302
 288	     9801	LDR R0 [SP + 4]
 290	     9902	LDR R1 [SP + 8]
 292	     9A06	LDR R2 [SP + 24]
 294	     9B04	LDR R3 [SP + 16]
 296	     9C05	LDR R4 [SP + 20]
 298	 F7FFFF69	BL #-302, goes to 0
 302	 F85DEB04	LDR LR [ SP ] + 4
 306	 F11D0D24	ADDS SP SP #36
 310	     4770	BX LR
 312	     B407	PUSH R0 R1 R2
 314	     B500	PUSH LR
 316	     9801	LDR R0 [SP + 4]
 318	     9902	LDR R1 [SP + 8]
 320	     2200	MOVS R2 #0
 322	     9B02	LDR R3 [SP + 8]
 324	     1E5B	SUBS R3 R3 #1
 326	     9C03	LDR R4 [SP + 12]
 328	 F7FFFF5A	BL #-332, goes to 0
 332	 F85DEB04	LDR LR [ SP ] + 4
 336	 F11D0D0C	ADDS SP SP #12
 340	     4770	BX LR
 342	     B500	PUSH LR
 344	 F85DEB04	LDR LR [ SP ] + 4
 348	     4770	BX LR

*)
