MODULE testQuickSort2;
  IMPORT QuickSort;
  
  TYPE
    Person = POINTER TO PersonDesc;
    PersonDesc = RECORD(QuickSort.ItemPayload)
      name: ARRAY 10 OF CHAR;
      age: INTEGER
    END;
    
  PROCEDURE ageCroissant(a, b: QuickSort.Item): BOOLEAN;
  BEGIN
    RETURN a(Person).age < b(Person).age
  END ageCroissant;
    PROCEDURE Sort*;
    VAR t: ARRAY 4 OF QuickSort.Item;
      p: Person;
      i: INTEGER;
  BEGIN
    QuickSort.Sort(t, ageCroissant);
  END Sort;
END testQuickSort2.

(*

OM4Tool.DecObj testQuickSort2.m4c ~

decode testQuickSort2.m4ctestQuickSort2 C8BBB510   1   180imports:	QuickSort 6C618B42type descriptors 00000020 00000001 FFFFFFFF FFFFFFFF FFFFFFFFdata     0stringscodecommands:	Sort   78entries   112    78pointer refsfixP =       98fixD =       40fixT =        1entry =      112   0	     B403	PUSH R0 R1   2	     B500	PUSH LR   4	     9801	LDR R0 [SP + 4]   6	     D007	BEQ #14, goes to 24   8	 F8501C08	LDR R1 [ R0- 8 ]  12	     6849	LDR R1 [ R1 + 4]  14	 20000007	MOV R2 lower 16-bits base(0)  18	 00000000	MOVT R2 higher 16-bits base + 0  22	     428A	CMP R2 R1  24	     BF18	IT NE  26	 EC002282	TrapNE 2 at pos 296  30	     9902	LDR R1 [SP + 8]  32	     D007	BEQ #14, goes to 50  34	 F8512C08	LDR R2 [ R1- 8 ]  38	     6852	LDR R2 [ R2 + 4]  40	 3000000D	MOV R3 lower 16-bits base(0)  44	 00000000	MOVT R3 higher 16-bits base + 0  48	     4293	CMP R3 R2  50	     BF18	IT NE  52	 EC002382	TrapNE 2 at pos 312  56	     68C0	LDR R0 [ R0 + 12]  58	     68C9	LDR R1 [ R1 + 12]  60	     4288	CMP R0 R1  62	     BFB4	ITE LT  64	     2001	MOVLT R0 #1  66	     2000	MOVGE R0 #0  68	 F85DEB04	LDR LR [ SP ] + 4  72	 F11D0D08	ADDS SP SP #8  76	     4770	BX LR  78	 F1BD0D18	SUBS SP SP #24  82	     B500	PUSH LR  84	 F11D0004	ADDS R0 SP #4  88	     2104	MOVS R1 #4  90	 F000F800	BL #0, goes to 94  94	 F1BE025E	SUBS R2 LR #94  98	 10200031	BL Mod(  1) proc(2) 102	 F85DEB04	LDR LR [ SP ] + 4 106	 F11D0D18	ADDS SP SP #24 110	     4770	BX LR 112	     B500	PUSH LR 114	 F85DEB04	LDR LR [ SP ] + 4 118	     4770	BX LRtype descriptors* avant FIXUP 00000020 00000001 FFFFFFFF FFFFFFFF FFFFFFFF* après FIXUP 00000020 D0201248 FFFFFFFF FFFFFFFF FFFFFFFF
*)
