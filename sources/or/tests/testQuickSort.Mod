MODULE testQuickSort;
  IMPORT QuickSort, Texts, Oberon;
  
  TYPE
    Person = POINTER TO PersonDesc;
    PersonDesc = RECORD(QuickSort.ItemPayload)
      name: ARRAY 10 OF CHAR;
      age: INTEGER
    END;
    
  VAR W: Texts.Writer;

  PROCEDURE ageCroissant(a, b: QuickSort.Item): BOOLEAN;
  BEGIN
    RETURN a(Person).age < b(Person).age
  END ageCroissant;
    PROCEDURE Sort*;
    VAR t: ARRAY 4 OF QuickSort.Item;
      p: Person;
      i: INTEGER;
  BEGIN
    NEW(p); p.name := "Nounours"; p.age := 62; t[0] := p;
    NEW(p); p.name := "Pupuce"; p.age := 63; t[1] := p;
    NEW(p); p.name := "Figaro"; p.age := 13; t[2] := p;
    NEW(p); p.name := "Baya"; p.age := 11; t[3] := p;
    
    QuickSort.Sort(t, ageCroissant);
    
    FOR i := 0 TO LEN(t)-1 DO
      p := t[i](Person);
      Texts.WriteString(W, p.name); Texts.WriteString(W, ", ");
      Texts.WriteInt(W, p.age, 1); Texts.WriteString(W, " ans.");
      Texts.WriteLn(W);
    END;
    Texts.Append(Oberon.Log, W.buf)
  END Sort;
BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Test QuickSort 13/12/2023");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
END testQuickSort.

(*

OM4Tool.DecObj testQuickSort.m4c ~

decode testQuickSort.m4c
testQuickSort B6CA9DF7   1   956
imports:
	QuickSort 6C618B42
	Texts ECBD67B7
	Fonts F4C9F557
	Files 73F5D686
	Oberon 28C4E6AF
	Display 4C08D3EA
	Viewers 9177B0AD
type descriptors
 00000020 00000001 FFFFFFFF FFFFFFFF FFFFFFFF
data    40
strings
Nounours||||Pupuce||Figaro||Baya||||, || ans.|||Test QuickSort 13/12/2023|||
code
commands:
	Sort   78
entries
   598    78
pointer refs
    56    44    24    20
fixP =      690
fixD =      680
fixT =        1
entry =      598
   0	     B403	PUSH R0 R1
   2	     B500	PUSH LR
   4	     9801	LDR R0 [SP + 4]
   6	     D007	BEQ #14, goes to 24
   8	 F8501C08	LDR R1 [ R0- 8 ]
  12	     6849	LDR R1 [ R1 + 4]
  14	 20000007	MOV R2 lower 16-bits base(0)
  18	 00000000	MOVT R2 higher 16-bits base + 0
  22	     428A	CMP R2 R1
  24	     BF18	IT NE
  26	 EC002502	TrapNE 2 at pos 336
  30	     9902	LDR R1 [SP + 8]
  32	     D007	BEQ #14, goes to 50
  34	 F8512C08	LDR R2 [ R1- 8 ]
  38	     6852	LDR R2 [ R2 + 4]
  40	 3000000D	MOV R3 lower 16-bits base(0)
  44	 00000000	MOVT R3 higher 16-bits base + 0
  48	     4293	CMP R3 R2
  50	     BF18	IT NE
  52	 EC002602	TrapNE 2 at pos 352
  56	     68C0	LDR R0 [ R0 + 12]
  58	     68C9	LDR R1 [ R1 + 12]
  60	     4288	CMP R0 R1
  62	     BFB4	ITE LT
  64	     2001	MOVLT R0 #1
  66	     2000	MOVGE R0 #0
  68	 F85DEB04	LDR LR [ SP ] + 4
  72	 F11D0D08	ADDS SP SP #8
  76	     4770	BX LR
  78	 F1BD0D18	SUBS SP SP #24
  82	     B500	PUSH LR
  84	 F11D0014	ADDS R0 SP #20
  88	 10000018	MOV R1 lower 16-bits base(0)
  92	 00000000	MOVT R1 higher 16-bits base + 0
  96	 EC003720	Trap 0 at pos 498
 100	     9805	LDR R0 [SP + 20]
 102	     2800	CMP R0 #0
 104	     BF08	IT EQ
 106	 EC003794	TrapEQ 4 at pos 505
 110	 1000000B	MOV R1 lower 16-bits base(0)
 114	 0000003C	MOVT R1 higher 16-bits base + 60
 118	 F8512B04	LDR R2 [ R1 ] + 4
 122	 F8402B04	STR R2 [ R0 ] + 4
 126	     1612	ASRS R2 R2 #24
 128	     D1F9	BNE #-14, goes to 118
 130	     9805	LDR R0 [SP + 20]
 132	     2800	CMP R0 #0
 134	     BF08	IT EQ
 136	 EC0040E4	TrapEQ 4 at pos 526
 140	     213E	MOVS R1 #62
 142	     60C1	STR R1 [ R0 + 12]
 144	     9805	LDR R0 [SP + 20]
 146	     9001	STR R0 [SP + 4]
 148	 F11D0014	ADDS R0 SP #20
 152	 10000015	MOV R1 lower 16-bits base(0)
 156	 00000000	MOVT R1 higher 16-bits base + 0
 160	 EC0042D0	Trap 0 at pos 557
 164	     9805	LDR R0 [SP + 20]
 166	     2800	CMP R0 #0
 168	     BF08	IT EQ
 170	 EC004344	TrapEQ 4 at pos 564
 174	 1000000B	MOV R1 lower 16-bits base(0)
 178	 00000048	MOVT R1 higher 16-bits base + 72
 182	 F8512B04	LDR R2 [ R1 ] + 4
 186	 F8402B04	STR R2 [ R0 ] + 4
 190	     1612	ASRS R2 R2 #24
 192	     D1F9	BNE #-14, goes to 182
 194	     9805	LDR R0 [SP + 20]
 196	     2800	CMP R0 #0
 198	     BF08	IT EQ
 200	 EC004474	TrapEQ 4 at pos 583
 204	     213F	MOVS R1 #63
 206	     60C1	STR R1 [ R0 + 12]
 208	     9805	LDR R0 [SP + 20]
 210	     9002	STR R0 [SP + 8]
 212	 F11D0014	ADDS R0 SP #20
 216	 10000015	MOV R1 lower 16-bits base(0)
 220	 00000000	MOVT R1 higher 16-bits base + 0
 224	 EC004660	Trap 0 at pos 614
 228	     9805	LDR R0 [SP + 20]
 230	     2800	CMP R0 #0
 232	     BF08	IT EQ
 234	 EC0046D4	TrapEQ 4 at pos 621
 238	 1000000B	MOV R1 lower 16-bits base(0)
 242	 00000050	MOVT R1 higher 16-bits base + 80
 246	 F8512B04	LDR R2 [ R1 ] + 4
 250	 F8402B04	STR R2 [ R0 ] + 4
 254	     1612	ASRS R2 R2 #24
 256	     D1F9	BNE #-14, goes to 246
 258	     9805	LDR R0 [SP + 20]
 260	     2800	CMP R0 #0
 262	     BF08	IT EQ
 264	 EC005004	TrapEQ 4 at pos 640
 268	     210D	MOVS R1 #13
 270	     60C1	STR R1 [ R0 + 12]
 272	     9805	LDR R0 [SP + 20]
 274	     9003	STR R0 [SP + 12]
 276	 F11D0014	ADDS R0 SP #20
 280	 10000015	MOV R1 lower 16-bits base(0)
 284	 00000000	MOVT R1 higher 16-bits base + 0
 288	 EC0051F0	Trap 0 at pos 671
 292	     9805	LDR R0 [SP + 20]
 294	     2800	CMP R0 #0
 296	     BF08	IT EQ
 298	 EC005264	TrapEQ 4 at pos 678
 302	 1000000B	MOV R1 lower 16-bits base(0)
 306	 00000058	MOVT R1 higher 16-bits base + 88
 310	 F8512B04	LDR R2 [ R1 ] + 4
 314	 F8402B04	STR R2 [ R0 ] + 4
 318	     1612	ASRS R2 R2 #24
 320	     D1F9	BNE #-14, goes to 310
 322	     9805	LDR R0 [SP + 20]
 324	     2800	CMP R0 #0
 326	     BF08	IT EQ
 328	 EC005374	TrapEQ 4 at pos 695
 332	     210B	MOVS R1 #11
 334	     60C1	STR R1 [ R0 + 12]
 336	     9805	LDR R0 [SP + 20]
 338	     9004	STR R0 [SP + 16]
 340	 F11D0004	ADDS R0 SP #4
 344	     2104	MOVS R1 #4
 346	 F000F800	BL #0, goes to 350
 350	 F2AE125E	SUB R2 LR #350
 354	 102000B1	BL Mod(  1) proc(2)
 358	     2000	MOVS R0 #0
 360	     2103	MOVS R1 #3
 362	     4288	CMP R0 R1
 364	 F3008062	BGT #196, goes to 564
 368	     9006	STR R0 [SP + 24]
 370	     9806	LDR R0 [SP + 24]
 372	     2804	CMP R0 #4
 374	     BF28	IT CS
 376	 EC0062B1	TrapCS 1 at pos 811
 380	 EB1D0080	ADDS R0 SP R0 LSL #2
 384	     6840	LDR R0 [ R0 + 4]
 386	     D007	BEQ #14, goes to 404
 388	 F8501C08	LDR R1 [ R0- 8 ]
 392	     6849	LDR R1 [ R1 + 4]
 394	 2000002E	MOV R2 lower 16-bits base(0)
 398	 00000000	MOVT R2 higher 16-bits base + 0
 402	     428A	CMP R2 R1
 404	     BF18	IT NE
 406	 EC006332	TrapNE 2 at pos 819
 410	     9005	STR R0 [SP + 20]
 412	 00000009	MOV R0 lower 16-bits base(0)
 416	 00000014	MOVT R0 higher 16-bits base + 20
 420	 12000004	MOV R1 lower 16-bits base(2)
 424	 00000005	MOVT R1 higher 16-bits var(5)
 428	     9A05	LDR R2 [SP + 20]
 430	     2A00	CMP R2 #0
 432	     BF08	IT EQ
 434	 EC006574	TrapEQ 4 at pos 855
 438	     230A	MOVS R3 #10
 440	 21D0002B	BL Mod(  2) proc(29)
 444	 0000000C	MOV R0 lower 16-bits base(0)
 448	 00000014	MOVT R0 higher 16-bits base + 20
 452	 12000004	MOV R1 lower 16-bits base(2)
 456	 00000005	MOVT R1 higher 16-bits var(5)
 460	 20000004	MOV R2 lower 16-bits base(0)
 464	 00000060	MOVT R2 higher 16-bits base + 96
 468	     2303	MOVS R3 #3
 470	 21D0000F	BL Mod(  2) proc(29)
 474	 00000007	MOV R0 lower 16-bits base(0)
 478	 00000014	MOVT R0 higher 16-bits base + 20
 482	 12000004	MOV R1 lower 16-bits base(2)
 486	 00000005	MOVT R1 higher 16-bits var(5)
 490	     9A05	LDR R2 [SP + 20]
 492	     2A00	CMP R2 #0
 494	     BF08	IT EQ
 496	 EC007144	TrapEQ 4 at pos 916
 500	     68D2	LDR R2 [ R2 + 12]
 502	     2301	MOVS R3 #1
 504	 21E00011	BL Mod(  2) proc(30)
 508	 0000000D	MOV R0 lower 16-bits base(0)
 512	 00000014	MOVT R0 higher 16-bits base + 20
 516	 12000004	MOV R1 lower 16-bits base(2)
 520	 00000005	MOVT R1 higher 16-bits var(5)
 524	 20000004	MOV R2 lower 16-bits base(0)
 528	 00000064	MOVT R2 higher 16-bits base + 100
 532	     2306	MOVS R3 #6
 534	 21D0000F	BL Mod(  2) proc(29)
 538	 00000007	MOV R0 lower 16-bits base(0)
 542	 00000014	MOVT R0 higher 16-bits base + 20
 546	 12000004	MOV R1 lower 16-bits base(2)
 550	 00000005	MOVT R1 higher 16-bits var(5)
 554	 21C0000A	BL Mod(  2) proc(28)
 558	     9806	LDR R0 [SP + 24]
 560	     1C40	ADDS R0 R0 #1
 562	     E799	B #-206, goes to 360
 564	 05000009	MOV R0 lower 16-bits base(5)
 568	 0000000D	MOVT R0 higher 16-bits var(13)
 572	     6800	LDR R0 [ R0 + 0]
 574	 10000005	MOV R1 lower 16-bits base(0)
 578	 00000014	MOVT R1 higher 16-bits base + 20
 582	     6809	LDR R1 [ R1 + 0]
 584	 20E0000F	BL Mod(  2) proc(14)
 588	 F85DEB04	LDR LR [ SP ] + 4
 592	 F11D0D18	ADDS SP SP #24
 596	     4770	BX LR
 598	     B500	PUSH LR
 600	 0000000D	MOV R0 lower 16-bits base(0)
 604	 00000014	MOVT R0 higher 16-bits base + 20
 608	 12000004	MOV R1 lower 16-bits base(2)
 612	 00000005	MOVT R1 higher 16-bits var(5)
 616	 21700010	BL Mod(  2) proc(23)
 620	 00000006	MOV R0 lower 16-bits base(0)
 624	 00000014	MOVT R0 higher 16-bits base + 20
 628	 12000004	MOV R1 lower 16-bits base(2)
 632	 00000005	MOVT R1 higher 16-bits var(5)
 636	 20000004	MOV R2 lower 16-bits base(0)
 640	 0000006C	MOVT R2 higher 16-bits base + 108
 644	     231A	MOVS R3 #26
 646	 21D0000F	BL Mod(  2) proc(29)
 650	 00000007	MOV R0 lower 16-bits base(0)
 654	 00000014	MOVT R0 higher 16-bits base + 20
 658	 12000004	MOV R1 lower 16-bits base(2)
 662	 00000005	MOVT R1 higher 16-bits var(5)
 666	 21C0000A	BL Mod(  2) proc(28)
 670	 05000006	MOV R0 lower 16-bits base(5)
 674	 0000000D	MOVT R0 higher 16-bits var(13)
 678	     6800	LDR R0 [ R0 + 0]
 680	 10000005	MOV R1 lower 16-bits base(0)
 684	 00000014	MOVT R1 higher 16-bits base + 20
 688	     6809	LDR R1 [ R1 + 0]
 690	 20E0000C	BL Mod(  2) proc(14)
 694	 F85DEB04	LDR LR [ SP ] + 4
 698	     4770	BX LR

*)
