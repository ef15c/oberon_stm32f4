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
testStringRelat 43ACA2A2 Flash   612
imports:
type descriptors

data     0
strings
1.||2.||3.||-1.|-2.|-3.|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 024A
fixup procedures chains
fixup handlers chains
fixup data chains
fixup types and strings chains
 00C6     0	 0000
 00E6     0	 0004
 0106     0	 0008
 0126     0	 000C
 0146     0	 0010
 0166     0	 0014
entry =  024A
code   588
 0000	     8031	SUB #22,SP
 0002	     0016
 0004	     410F	MOV SP,R15
 0006	     503F	ADD #12,R15
 0008	     000C
 000A	     403E	MOV #0,R14
 000C	     0000
 000E	     4E7D	MOV.B @R14+,R13
 0010	     9F7D	CMP.B @R15+,R13
 0012	     2002	JNE #2, goes to  0018
 0014	     934D	CMP.B #0,R13
 0016	     23FB	JNE #-5, goes to  000E
 0018	     2C02	JC #2, goes to  001E
 001A	     431F	MOV #1,R15
 001C	     3C01	JMP #1, goes to  0020
 001E	     430F	MOV #0,R15
 0020	     4FC1	MOV.B R15,1(SP)
 0022	     0001
 0024	     410F	MOV SP,R15
 0026	     503F	ADD #12,R15
 0028	     000C
 002A	     403E	MOV #0,R14
 002C	     0000
 002E	     4F7D	MOV.B @R15+,R13
 0030	     9E7D	CMP.B @R14+,R13
 0032	     2002	JNE #2, goes to  0038
 0034	     934D	CMP.B #0,R13
 0036	     23FB	JNE #-5, goes to  002E
 0038	     2802	JNC #2, goes to  003E
 003A	     431F	MOV #1,R15
 003C	     3C01	JMP #1, goes to  0040
 003E	     430F	MOV #0,R15
 0040	     4FC1	MOV.B R15,1(SP)
 0042	     0001
 0044	     410F	MOV SP,R15
 0046	     503F	ADD #12,R15
 0048	     000C
 004A	     403E	MOV #0,R14
 004C	     0000
 004E	     4F7D	MOV.B @R15+,R13
 0050	     9E7D	CMP.B @R14+,R13
 0052	     2002	JNE #2, goes to  0058
 0054	     934D	CMP.B #0,R13
 0056	     23FB	JNE #-5, goes to  004E
 0058	     2002	JNE #2, goes to  005E
 005A	     431F	MOV #1,R15
 005C	     3C01	JMP #1, goes to  0060
 005E	     430F	MOV #0,R15
 0060	     4FC1	MOV.B R15,1(SP)
 0062	     0001
 0064	     410F	MOV SP,R15
 0066	     503F	ADD #12,R15
 0068	     000C
 006A	     403E	MOV #0,R14
 006C	     0000
 006E	     4F7D	MOV.B @R15+,R13
 0070	     9E7D	CMP.B @R14+,R13
 0072	     2002	JNE #2, goes to  0078
 0074	     934D	CMP.B #0,R13
 0076	     23FB	JNE #-5, goes to  006E
 0078	     2C02	JC #2, goes to  007E
 007A	     431F	MOV #1,R15
 007C	     3C01	JMP #1, goes to  0080
 007E	     430F	MOV #0,R15
 0080	     4FC1	MOV.B R15,1(SP)
 0082	     0001
 0084	     410F	MOV SP,R15
 0086	     503F	ADD #12,R15
 0088	     000C
 008A	     403E	MOV #0,R14
 008C	     0000
 008E	     4E7D	MOV.B @R14+,R13
 0090	     9F7D	CMP.B @R15+,R13
 0092	     2002	JNE #2, goes to  0098
 0094	     934D	CMP.B #0,R13
 0096	     23FB	JNE #-5, goes to  008E
 0098	     2802	JNC #2, goes to  009E
 009A	     431F	MOV #1,R15
 009C	     3C01	JMP #1, goes to  00A0
 009E	     430F	MOV #0,R15
 00A0	     4FC1	MOV.B R15,1(SP)
 00A2	     0001
 00A4	     410F	MOV SP,R15
 00A6	     503F	ADD #12,R15
 00A8	     000C
 00AA	     403E	MOV #0,R14
 00AC	     0000
 00AE	     4F7D	MOV.B @R15+,R13
 00B0	     9E7D	CMP.B @R14+,R13
 00B2	     2002	JNE #2, goes to  00B8
 00B4	     934D	CMP.B #0,R13
 00B6	     23FB	JNE #-5, goes to  00AE
 00B8	     2402	JEQ #2, goes to  00BE
 00BA	     431F	MOV #1,R15
 00BC	     3C01	JMP #1, goes to  00C0
 00BE	     430F	MOV #0,R15
 00C0	     4FC1	MOV.B R15,1(SP)
 00C2	     0001
 00C4	     403F	MOV #12,R15
 00C6	     000C
 00C8	     410E	MOV SP,R14
 00CA	     503E	ADD #12,R14
 00CC	     000C
 00CE	     4E7D	MOV.B @R14+,R13
 00D0	     9F7D	CMP.B @R15+,R13
 00D2	     2002	JNE #2, goes to  00D8
 00D4	     934D	CMP.B #0,R13
 00D6	     23FB	JNE #-5, goes to  00CE
 00D8	     2C02	JC #2, goes to  00DE
 00DA	     431F	MOV #1,R15
 00DC	     3C01	JMP #1, goes to  00E0
 00DE	     430F	MOV #0,R15
 00E0	     4FC1	MOV.B R15,1(SP)
 00E2	     0001
 00E4	     403F	MOV #44,R15
 00E6	     002C
 00E8	     410E	MOV SP,R14
 00EA	     503E	ADD #12,R14
 00EC	     000C
 00EE	     4F7D	MOV.B @R15+,R13
 00F0	     9E7D	CMP.B @R14+,R13
 00F2	     2002	JNE #2, goes to  00F8
 00F4	     934D	CMP.B #0,R13
 00F6	     23FB	JNE #-5, goes to  00EE
 00F8	     2802	JNC #2, goes to  00FE
 00FA	     431F	MOV #1,R15
 00FC	     3C01	JMP #1, goes to  0100
 00FE	     430F	MOV #0,R15
 0100	     4FC1	MOV.B R15,1(SP)
 0102	     0001
 0104	     403F	MOV #76,R15
 0106	     004C
 0108	     410E	MOV SP,R14
 010A	     503E	ADD #12,R14
 010C	     000C
 010E	     4F7D	MOV.B @R15+,R13
 0110	     9E7D	CMP.B @R14+,R13
 0112	     2002	JNE #2, goes to  0118
 0114	     934D	CMP.B #0,R13
 0116	     23FB	JNE #-5, goes to  010E
 0118	     2002	JNE #2, goes to  011E
 011A	     431F	MOV #1,R15
 011C	     3C01	JMP #1, goes to  0120
 011E	     430F	MOV #0,R15
 0120	     4FC1	MOV.B R15,1(SP)
 0122	     0001
 0124	     403F	MOV #108,R15
 0126	     006C
 0128	     410E	MOV SP,R14
 012A	     503E	ADD #12,R14
 012C	     000C
 012E	     4F7D	MOV.B @R15+,R13
 0130	     9E7D	CMP.B @R14+,R13
 0132	     2002	JNE #2, goes to  0138
 0134	     934D	CMP.B #0,R13
 0136	     23FB	JNE #-5, goes to  012E
 0138	     2C02	JC #2, goes to  013E
 013A	     431F	MOV #1,R15
 013C	     3C01	JMP #1, goes to  0140
 013E	     430F	MOV #0,R15
 0140	     4FC1	MOV.B R15,1(SP)
 0142	     0001
 0144	     403F	MOV #140,R15
 0146	     008C
 0148	     410E	MOV SP,R14
 014A	     503E	ADD #12,R14
 014C	     000C
 014E	     4E7D	MOV.B @R14+,R13
 0150	     9F7D	CMP.B @R15+,R13
 0152	     2002	JNE #2, goes to  0158
 0154	     934D	CMP.B #0,R13
 0156	     23FB	JNE #-5, goes to  014E
 0158	     2802	JNC #2, goes to  015E
 015A	     431F	MOV #1,R15
 015C	     3C01	JMP #1, goes to  0160
 015E	     430F	MOV #0,R15
 0160	     4FC1	MOV.B R15,1(SP)
 0162	     0001
 0164	     403F	MOV #172,R15
 0166	     00AC
 0168	     410E	MOV SP,R14
 016A	     503E	ADD #12,R14
 016C	     000C
 016E	     4F7D	MOV.B @R15+,R13
 0170	     9E7D	CMP.B @R14+,R13
 0172	     2002	JNE #2, goes to  0178
 0174	     934D	CMP.B #0,R13
 0176	     23FB	JNE #-5, goes to  016E
 0178	     2402	JEQ #2, goes to  017E
 017A	     431F	MOV #1,R15
 017C	     3C01	JMP #1, goes to  0180
 017E	     430F	MOV #0,R15
 0180	     4FC1	MOV.B R15,1(SP)
 0182	     0001
 0184	     410F	MOV SP,R15
 0186	     503F	ADD #12,R15
 0188	     000C
 018A	     410E	MOV SP,R14
 018C	     532E	ADD #2,R14
 018E	     4E7D	MOV.B @R14+,R13
 0190	     9F7D	CMP.B @R15+,R13
 0192	     2002	JNE #2, goes to  0198
 0194	     934D	CMP.B #0,R13
 0196	     23FB	JNE #-5, goes to  018E
 0198	     2C02	JC #2, goes to  019E
 019A	     431F	MOV #1,R15
 019C	     3C01	JMP #1, goes to  01A0
 019E	     430F	MOV #0,R15
 01A0	     4FC1	MOV.B R15,1(SP)
 01A2	     0001
 01A4	     410F	MOV SP,R15
 01A6	     503F	ADD #12,R15
 01A8	     000C
 01AA	     410E	MOV SP,R14
 01AC	     532E	ADD #2,R14
 01AE	     4F7D	MOV.B @R15+,R13
 01B0	     9E7D	CMP.B @R14+,R13
 01B2	     2002	JNE #2, goes to  01B8
 01B4	     934D	CMP.B #0,R13
 01B6	     23FB	JNE #-5, goes to  01AE
 01B8	     2802	JNC #2, goes to  01BE
 01BA	     431F	MOV #1,R15
 01BC	     3C01	JMP #1, goes to  01C0
 01BE	     430F	MOV #0,R15
 01C0	     4FC1	MOV.B R15,1(SP)
 01C2	     0001
 01C4	     410F	MOV SP,R15
 01C6	     503F	ADD #12,R15
 01C8	     000C
 01CA	     410E	MOV SP,R14
 01CC	     532E	ADD #2,R14
 01CE	     4F7D	MOV.B @R15+,R13
 01D0	     9E7D	CMP.B @R14+,R13
 01D2	     2002	JNE #2, goes to  01D8
 01D4	     934D	CMP.B #0,R13
 01D6	     23FB	JNE #-5, goes to  01CE
 01D8	     2002	JNE #2, goes to  01DE
 01DA	     431F	MOV #1,R15
 01DC	     3C01	JMP #1, goes to  01E0
 01DE	     430F	MOV #0,R15
 01E0	     4FC1	MOV.B R15,1(SP)
 01E2	     0001
 01E4	     410F	MOV SP,R15
 01E6	     503F	ADD #12,R15
 01E8	     000C
 01EA	     410E	MOV SP,R14
 01EC	     532E	ADD #2,R14
 01EE	     4F7D	MOV.B @R15+,R13
 01F0	     9E7D	CMP.B @R14+,R13
 01F2	     2002	JNE #2, goes to  01F8
 01F4	     934D	CMP.B #0,R13
 01F6	     23FB	JNE #-5, goes to  01EE
 01F8	     2C02	JC #2, goes to  01FE
 01FA	     431F	MOV #1,R15
 01FC	     3C01	JMP #1, goes to  0200
 01FE	     430F	MOV #0,R15
 0200	     4FC1	MOV.B R15,1(SP)
 0202	     0001
 0204	     410F	MOV SP,R15
 0206	     503F	ADD #12,R15
 0208	     000C
 020A	     410E	MOV SP,R14
 020C	     532E	ADD #2,R14
 020E	     4E7D	MOV.B @R14+,R13
 0210	     9F7D	CMP.B @R15+,R13
 0212	     2002	JNE #2, goes to  0218
 0214	     934D	CMP.B #0,R13
 0216	     23FB	JNE #-5, goes to  020E
 0218	     2802	JNC #2, goes to  021E
 021A	     431F	MOV #1,R15
 021C	     3C01	JMP #1, goes to  0220
 021E	     430F	MOV #0,R15
 0220	     4FC1	MOV.B R15,1(SP)
 0222	     0001
 0224	     410F	MOV SP,R15
 0226	     503F	ADD #12,R15
 0228	     000C
 022A	     410E	MOV SP,R14
 022C	     532E	ADD #2,R14
 022E	     4F7D	MOV.B @R15+,R13
 0230	     9E7D	CMP.B @R14+,R13
 0232	     2002	JNE #2, goes to  0238
 0234	     934D	CMP.B #0,R13
 0236	     23FB	JNE #-5, goes to  022E
 0238	     2402	JEQ #2, goes to  023E
 023A	     431F	MOV #1,R15
 023C	     3C01	JMP #1, goes to  0240
 023E	     430F	MOV #0,R15
 0240	     4FC1	MOV.B R15,1(SP)
 0242	     0001
 0244	     5031	ADD #22,SP
 0246	     0016
 0248	     4130	RET
 024A	     4130	RET
