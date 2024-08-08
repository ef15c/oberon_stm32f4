MODULE testStringRelat;

  PROCEDURE p;
    VAR a, b: ARRAY 10 OF CHAR;
      t: BOOLEAN;
  BEGIN
    t := a>"1.";
    t := a>="2.";
    t := a="3.";
    t := a<"-1.";
    t := a<="-2.";
    t := a#"-3.";
    t := "1.">a;
    t := "2.">=a;
    t := "3."=a;
    t := "-1."<a;
    t := "-2."<=a;
    t := "-3."#a;
    t := a>b;
    t := a>=b;
    t := a=b;
    t := a<b;
    t := a<=b;
    t := a#b
  END p;

END testStringRelat.

OMSPTool.DecObj testStringRelat.mpc
decode testStringRelat.mpc
testStringRelat 43ACA2A2 Flash   684
imports:
type descriptors

data     0
strings
1.||2.||3.||-1.|-2.|-3.|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0292
fixup procedures chains
fixup handlers chains
fixup data chains
fixup types and strings chains
 00DE     0	 0000
 0102     0	 0004
 0126     0	 0008
 014A     0	 000C
 016E     0	 0010
 0192     0	 0014
entry =  0292
code   660
 0000	     8031	SUB #22,SP
 0002	     0016
 0004	     410F	MOV SP,R15
 0006	     503F	ADD #12,R15
 0008	     000C
 000A	     403E	MOV #0,R14
 000C	     0000
 000E	     531E	ADD #1,R14
 0010	     9FFE	CMP.B @R15+,-1(R14)
 0012	     FFFF
 0014	     2003	JNE #3, goes to  001C
 0016	     93CE	CMP.B #0,-1(R14)
 0018	     FFFF
 001A	     23F9	JNE #-7, goes to  000E
 001C	     2C02	JC #2, goes to  0022
 001E	     431F	MOV #1,R15
 0020	     3C01	JMP #1, goes to  0024
 0022	     430F	MOV #0,R15
 0024	     4FC1	MOV.B R15,1(SP)
 0026	     0001
 0028	     410F	MOV SP,R15
 002A	     503F	ADD #12,R15
 002C	     000C
 002E	     403E	MOV #0,R14
 0030	     0000
 0032	     531F	ADD #1,R15
 0034	     9EFF	CMP.B @R14+,-1(R15)
 0036	     FFFF
 0038	     2003	JNE #3, goes to  0040
 003A	     93CF	CMP.B #0,-1(R15)
 003C	     FFFF
 003E	     23F9	JNE #-7, goes to  0032
 0040	     2802	JNC #2, goes to  0046
 0042	     431F	MOV #1,R15
 0044	     3C01	JMP #1, goes to  0048
 0046	     430F	MOV #0,R15
 0048	     4FC1	MOV.B R15,1(SP)
 004A	     0001
 004C	     410F	MOV SP,R15
 004E	     503F	ADD #12,R15
 0050	     000C
 0052	     403E	MOV #0,R14
 0054	     0000
 0056	     531F	ADD #1,R15
 0058	     9EFF	CMP.B @R14+,-1(R15)
 005A	     FFFF
 005C	     2003	JNE #3, goes to  0064
 005E	     93CF	CMP.B #0,-1(R15)
 0060	     FFFF
 0062	     23F9	JNE #-7, goes to  0056
 0064	     2002	JNE #2, goes to  006A
 0066	     431F	MOV #1,R15
 0068	     3C01	JMP #1, goes to  006C
 006A	     430F	MOV #0,R15
 006C	     4FC1	MOV.B R15,1(SP)
 006E	     0001
 0070	     410F	MOV SP,R15
 0072	     503F	ADD #12,R15
 0074	     000C
 0076	     403E	MOV #0,R14
 0078	     0000
 007A	     531F	ADD #1,R15
 007C	     9EFF	CMP.B @R14+,-1(R15)
 007E	     FFFF
 0080	     2003	JNE #3, goes to  0088
 0082	     93CF	CMP.B #0,-1(R15)
 0084	     FFFF
 0086	     23F9	JNE #-7, goes to  007A
 0088	     2C02	JC #2, goes to  008E
 008A	     431F	MOV #1,R15
 008C	     3C01	JMP #1, goes to  0090
 008E	     430F	MOV #0,R15
 0090	     4FC1	MOV.B R15,1(SP)
 0092	     0001
 0094	     410F	MOV SP,R15
 0096	     503F	ADD #12,R15
 0098	     000C
 009A	     403E	MOV #0,R14
 009C	     0000
 009E	     531E	ADD #1,R14
 00A0	     9FFE	CMP.B @R15+,-1(R14)
 00A2	     FFFF
 00A4	     2003	JNE #3, goes to  00AC
 00A6	     93CE	CMP.B #0,-1(R14)
 00A8	     FFFF
 00AA	     23F9	JNE #-7, goes to  009E
 00AC	     2802	JNC #2, goes to  00B2
 00AE	     431F	MOV #1,R15
 00B0	     3C01	JMP #1, goes to  00B4
 00B2	     430F	MOV #0,R15
 00B4	     4FC1	MOV.B R15,1(SP)
 00B6	     0001
 00B8	     410F	MOV SP,R15
 00BA	     503F	ADD #12,R15
 00BC	     000C
 00BE	     403E	MOV #0,R14
 00C0	     0000
 00C2	     531F	ADD #1,R15
 00C4	     9EFF	CMP.B @R14+,-1(R15)
 00C6	     FFFF
 00C8	     2003	JNE #3, goes to  00D0
 00CA	     93CF	CMP.B #0,-1(R15)
 00CC	     FFFF
 00CE	     23F9	JNE #-7, goes to  00C2
 00D0	     2402	JEQ #2, goes to  00D6
 00D2	     431F	MOV #1,R15
 00D4	     3C01	JMP #1, goes to  00D8
 00D6	     430F	MOV #0,R15
 00D8	     4FC1	MOV.B R15,1(SP)
 00DA	     0001
 00DC	     403F	MOV #12,R15
 00DE	     000C
 00E0	     410E	MOV SP,R14
 00E2	     503E	ADD #12,R14
 00E4	     000C
 00E6	     531E	ADD #1,R14
 00E8	     9FFE	CMP.B @R15+,-1(R14)
 00EA	     FFFF
 00EC	     2003	JNE #3, goes to  00F4
 00EE	     93CE	CMP.B #0,-1(R14)
 00F0	     FFFF
 00F2	     23F9	JNE #-7, goes to  00E6
 00F4	     2C02	JC #2, goes to  00FA
 00F6	     431F	MOV #1,R15
 00F8	     3C01	JMP #1, goes to  00FC
 00FA	     430F	MOV #0,R15
 00FC	     4FC1	MOV.B R15,1(SP)
 00FE	     0001
 0100	     403F	MOV #48,R15
 0102	     0030
 0104	     410E	MOV SP,R14
 0106	     503E	ADD #12,R14
 0108	     000C
 010A	     531F	ADD #1,R15
 010C	     9EFF	CMP.B @R14+,-1(R15)
 010E	     FFFF
 0110	     2003	JNE #3, goes to  0118
 0112	     93CF	CMP.B #0,-1(R15)
 0114	     FFFF
 0116	     23F9	JNE #-7, goes to  010A
 0118	     2802	JNC #2, goes to  011E
 011A	     431F	MOV #1,R15
 011C	     3C01	JMP #1, goes to  0120
 011E	     430F	MOV #0,R15
 0120	     4FC1	MOV.B R15,1(SP)
 0122	     0001
 0124	     403F	MOV #84,R15
 0126	     0054
 0128	     410E	MOV SP,R14
 012A	     503E	ADD #12,R14
 012C	     000C
 012E	     531F	ADD #1,R15
 0130	     9EFF	CMP.B @R14+,-1(R15)
 0132	     FFFF
 0134	     2003	JNE #3, goes to  013C
 0136	     93CF	CMP.B #0,-1(R15)
 0138	     FFFF
 013A	     23F9	JNE #-7, goes to  012E
 013C	     2002	JNE #2, goes to  0142
 013E	     431F	MOV #1,R15
 0140	     3C01	JMP #1, goes to  0144
 0142	     430F	MOV #0,R15
 0144	     4FC1	MOV.B R15,1(SP)
 0146	     0001
 0148	     403F	MOV #120,R15
 014A	     0078
 014C	     410E	MOV SP,R14
 014E	     503E	ADD #12,R14
 0150	     000C
 0152	     531F	ADD #1,R15
 0154	     9EFF	CMP.B @R14+,-1(R15)
 0156	     FFFF
 0158	     2003	JNE #3, goes to  0160
 015A	     93CF	CMP.B #0,-1(R15)
 015C	     FFFF
 015E	     23F9	JNE #-7, goes to  0152
 0160	     2C02	JC #2, goes to  0166
 0162	     431F	MOV #1,R15
 0164	     3C01	JMP #1, goes to  0168
 0166	     430F	MOV #0,R15
 0168	     4FC1	MOV.B R15,1(SP)
 016A	     0001
 016C	     403F	MOV #156,R15
 016E	     009C
 0170	     410E	MOV SP,R14
 0172	     503E	ADD #12,R14
 0174	     000C
 0176	     531E	ADD #1,R14
 0178	     9FFE	CMP.B @R15+,-1(R14)
 017A	     FFFF
 017C	     2003	JNE #3, goes to  0184
 017E	     93CE	CMP.B #0,-1(R14)
 0180	     FFFF
 0182	     23F9	JNE #-7, goes to  0176
 0184	     2802	JNC #2, goes to  018A
 0186	     431F	MOV #1,R15
 0188	     3C01	JMP #1, goes to  018C
 018A	     430F	MOV #0,R15
 018C	     4FC1	MOV.B R15,1(SP)
 018E	     0001
 0190	     403F	MOV #192,R15
 0192	     00C0
 0194	     410E	MOV SP,R14
 0196	     503E	ADD #12,R14
 0198	     000C
 019A	     531F	ADD #1,R15
 019C	     9EFF	CMP.B @R14+,-1(R15)
 019E	     FFFF
 01A0	     2003	JNE #3, goes to  01A8
 01A2	     93CF	CMP.B #0,-1(R15)
 01A4	     FFFF
 01A6	     23F9	JNE #-7, goes to  019A
 01A8	     2402	JEQ #2, goes to  01AE
 01AA	     431F	MOV #1,R15
 01AC	     3C01	JMP #1, goes to  01B0
 01AE	     430F	MOV #0,R15
 01B0	     4FC1	MOV.B R15,1(SP)
 01B2	     0001
 01B4	     410F	MOV SP,R15
 01B6	     503F	ADD #12,R15
 01B8	     000C
 01BA	     410E	MOV SP,R14
 01BC	     532E	ADD #2,R14
 01BE	     531E	ADD #1,R14
 01C0	     9FFE	CMP.B @R15+,-1(R14)
 01C2	     FFFF
 01C4	     2003	JNE #3, goes to  01CC
 01C6	     93CE	CMP.B #0,-1(R14)
 01C8	     FFFF
 01CA	     23F9	JNE #-7, goes to  01BE
 01CC	     2C02	JC #2, goes to  01D2
 01CE	     431F	MOV #1,R15
 01D0	     3C01	JMP #1, goes to  01D4
 01D2	     430F	MOV #0,R15
 01D4	     4FC1	MOV.B R15,1(SP)
 01D6	     0001
 01D8	     410F	MOV SP,R15
 01DA	     503F	ADD #12,R15
 01DC	     000C
 01DE	     410E	MOV SP,R14
 01E0	     532E	ADD #2,R14
 01E2	     531F	ADD #1,R15
 01E4	     9EFF	CMP.B @R14+,-1(R15)
 01E6	     FFFF
 01E8	     2003	JNE #3, goes to  01F0
 01EA	     93CF	CMP.B #0,-1(R15)
 01EC	     FFFF
 01EE	     23F9	JNE #-7, goes to  01E2
 01F0	     2802	JNC #2, goes to  01F6
 01F2	     431F	MOV #1,R15
 01F4	     3C01	JMP #1, goes to  01F8
 01F6	     430F	MOV #0,R15
 01F8	     4FC1	MOV.B R15,1(SP)
 01FA	     0001
 01FC	     410F	MOV SP,R15
 01FE	     503F	ADD #12,R15
 0200	     000C
 0202	     410E	MOV SP,R14
 0204	     532E	ADD #2,R14
 0206	     531F	ADD #1,R15
 0208	     9EFF	CMP.B @R14+,-1(R15)
 020A	     FFFF
 020C	     2003	JNE #3, goes to  0214
 020E	     93CF	CMP.B #0,-1(R15)
 0210	     FFFF
 0212	     23F9	JNE #-7, goes to  0206
 0214	     2002	JNE #2, goes to  021A
 0216	     431F	MOV #1,R15
 0218	     3C01	JMP #1, goes to  021C
 021A	     430F	MOV #0,R15
 021C	     4FC1	MOV.B R15,1(SP)
 021E	     0001
 0220	     410F	MOV SP,R15
 0222	     503F	ADD #12,R15
 0224	     000C
 0226	     410E	MOV SP,R14
 0228	     532E	ADD #2,R14
 022A	     531F	ADD #1,R15
 022C	     9EFF	CMP.B @R14+,-1(R15)
 022E	     FFFF
 0230	     2003	JNE #3, goes to  0238
 0232	     93CF	CMP.B #0,-1(R15)
 0234	     FFFF
 0236	     23F9	JNE #-7, goes to  022A
 0238	     2C02	JC #2, goes to  023E
 023A	     431F	MOV #1,R15
 023C	     3C01	JMP #1, goes to  0240
 023E	     430F	MOV #0,R15
 0240	     4FC1	MOV.B R15,1(SP)
 0242	     0001
 0244	     410F	MOV SP,R15
 0246	     503F	ADD #12,R15
 0248	     000C
 024A	     410E	MOV SP,R14
 024C	     532E	ADD #2,R14
 024E	     531E	ADD #1,R14
 0250	     9FFE	CMP.B @R15+,-1(R14)
 0252	     FFFF
 0254	     2003	JNE #3, goes to  025C
 0256	     93CE	CMP.B #0,-1(R14)
 0258	     FFFF
 025A	     23F9	JNE #-7, goes to  024E
 025C	     2802	JNC #2, goes to  0262
 025E	     431F	MOV #1,R15
 0260	     3C01	JMP #1, goes to  0264
 0262	     430F	MOV #0,R15
 0264	     4FC1	MOV.B R15,1(SP)
 0266	     0001
 0268	     410F	MOV SP,R15
 026A	     503F	ADD #12,R15
 026C	     000C
 026E	     410E	MOV SP,R14
 0270	     532E	ADD #2,R14
 0272	     531F	ADD #1,R15
 0274	     9EFF	CMP.B @R14+,-1(R15)
 0276	     FFFF
 0278	     2003	JNE #3, goes to  0280
 027A	     93CF	CMP.B #0,-1(R15)
 027C	     FFFF
 027E	     23F9	JNE #-7, goes to  0272
 0280	     2402	JEQ #2, goes to  0286
 0282	     431F	MOV #1,R15
 0284	     3C01	JMP #1, goes to  0288
 0286	     430F	MOV #0,R15
 0288	     4FC1	MOV.B R15,1(SP)
 028A	     0001
 028C	     5031	ADD #22,SP
 028E	     0016
 0290	     4130	RET
 0292	     4130	RET
