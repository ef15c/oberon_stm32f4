MODULE testSFuncs;
  IMPORT SYSTEM;
  PROCEDURE p;
    VAR a, v: LONGINT;
      r, s: REAL;
      b: BOOLEAN;
  BEGIN
    a := ABS(v);
    s := ABS(r);
    s := SQRT(r);
    b := ODD(a);
    v := FLOOR(r);
    r := FLT(v);
    v := ORD(b);
  END p;
BEGIN
END testSFuncs.


(*
ORTool.DecObj testSFuncs.rsc ~

decode testSFuncs.rsctestSFuncs 74DACAC7   1   144imports:type descriptorsdata     0stringscode   0	 4EE90018	SUB SP SP     24   1	 AFE00000	STR  LNK SP       0   2	 80E00008	LDR  R0 SP       8   3	 40090000	SUB  R0  R0      0   4	 ED000002	BGE        2   5	 41000000	MOV  R1  R0      0   6	 00190000	SUB  R0  R1  R0   7	 A0E00004	STR   R0 SP       4   8	 80E0000C	LDR  R0 SP      12   9	 40010001	LSL  R0  R0      1  10	 40030001	ROR  R0  R0      1  11	 A0E00010	STR   R0 SP      16  12	 80E00004	LDR  R0 SP       4  13	 40040001	AND  R0  R0      1  14	 E1000002	BEQ        2  15	 40000001	MOV  R0  R0      1  16	 E7000001	B       1  17	 40000000	MOV  R0  R0      0  18	 B0E00014	STR   R0 SP      20  19	 80E00008	LDR  R0 SP       8  20	 61004B00	MOV'  R1  R0  19200  21	 200C0001	FAD'  R0  R0  R1  22	 A0E0000C	STR   R0 SP      12  23	 90E00014	LDR  R0 SP      20  24	 A0E00008	STR   R0 SP       8  25	 8FE00000	LDR LNK SP       0  26	 4EE80018	ADD SP SP     24  27	 C700000F	B LNK  28	 4EE90004	SUB SP SP      4  29	 AFE00000	STR  LNK SP       0  30	 8FE00000	LDR LNK SP       0  31	 4EE80004	ADD SP SP      4  32	 C700000F	B LNKcommands:entries   112pointer refsfixP =        0fixD =        0fixT =        0entry =      112

OM4Tool.DecObj testSFuncs.m4c ~
decode testSFuncs.m4ctestSFuncs E3E91F2A   1   122imports:type descriptorsdata     0stringscodecommands:entries   102pointer refsfixP =        0fixD =        0fixT =        0entry =      102   0	 F1BD0D14	SUBS SP SP #20   4	     B500	PUSH LR   6	     9802	LDR R0 [SP + 8]   8	     2800	CMP R0 #0  10	     BFBC	ITT LT  12	     2100	MOVLT R1 #0  14	     1A08	SUBLT R0 R1 R0  16	     9001	STR R0 [SP + 4]  18	 ED9D0A03	VLDR S0 [ SP + 12 ]  22	 EEB00AC0	VABS S0 S0  26	 ED8D0A04	VSTR S0 [ SP + 16 ]  30	 ED9D0A03	VLDR S0 [ SP + 12 ]  34	 EEB10AC0	VSQRT S0 S0  38	 ED8D0A04	VSTR S0 [ SP + 16 ]  42	     9801	LDR R0 [SP + 4]  44	 EA5F0070	RORS R0 R0 #1  48	     BF4C	ITE MI  50	     2001	MOVMI R0 #1  52	     2000	MOVPL R0 #0  54	 F88D0014	STRB R0 [ SP + 20 ]  58	 ED9D0A03	VLDR S0 [ SP + 12 ]  62	 EEBD0A40	VCVTR.S32.F32 S0 S0  66	 EE100A10	VMOV R0 S0  70	     9002	STR R0 [SP + 8]  72	     9802	LDR R0 [SP + 8]  74	 EE000A10	VMOV S0 R0  78	 EEB80AC0	VCVT.F32.S32. S0 S0  82	 ED8D0A03	VSTR S0 [ SP + 12 ]  86	 F89D0014	LDRB R0 [ SP + 20 ]  90	     9002	STR R0 [SP + 8]  92	 F85DEB04	LDR LR [ SP ] + 4  96	 F11D0D14	ADDS SP SP #20 100	     4770	BX LR 102	     B500	PUSH LR 104	 F85DEB04	LDR LR [ SP ] + 4 108	     4770	BX LR
*)
