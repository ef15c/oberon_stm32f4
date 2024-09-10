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
testStringRelat 0ECA6633 Flash   552
imports:
type descriptors

data     0
strings
1.||2.||3.||-1.|-2.|-3.|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0226
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
 00AE( 00C6)     0	 0000
 00CA( 00E2)     0	 0004
 00E6( 00FE)     0	 0008
 0102( 011A)     0	 000C
 011E( 0136)     0	 0010
 013A( 0152)     0	 0014
fixup types chains
entry =  0226
code   528
 0000( 0018)	     8031	SUB #22,SP
 0002( 001A)	     0016
 0004( 001C)	     410F	MOV SP,R15
 0006( 001E)	     403E	MOV #0,R14
 0008( 0020)	     0000
 000A( 0022)	     4E7D	MOV.B @R14+,R13
 000C( 0024)	     9F7D	CMP.B @R15+,R13
 000E( 0026)	     2002	JNE #2, goes to  0014
 0010( 0028)	     934D	CMP.B #0,R13
 0012( 002A)	     23FB	JNE #-5, goes to  000A
 0014( 002C)	     2C02	JC #2, goes to  001A
 0016( 002E)	     431F	MOV #1,R15
 0018( 0030)	     3C01	JMP #1, goes to  001C
 001A( 0032)	     430F	MOV #0,R15
 001C( 0034)	     4FC1	MOV.B R15,20(SP)
 001E( 0036)	     0014
 0020( 0038)	     410F	MOV SP,R15
 0022( 003A)	     403E	MOV #0,R14
 0024( 003C)	     0000
 0026( 003E)	     4F7D	MOV.B @R15+,R13
 0028( 0040)	     9E7D	CMP.B @R14+,R13
 002A( 0042)	     2002	JNE #2, goes to  0030
 002C( 0044)	     934D	CMP.B #0,R13
 002E( 0046)	     23FB	JNE #-5, goes to  0026
 0030( 0048)	     2802	JNC #2, goes to  0036
 0032( 004A)	     431F	MOV #1,R15
 0034( 004C)	     3C01	JMP #1, goes to  0038
 0036( 004E)	     430F	MOV #0,R15
 0038( 0050)	     4FC1	MOV.B R15,20(SP)
 003A( 0052)	     0014
 003C( 0054)	     410F	MOV SP,R15
 003E( 0056)	     403E	MOV #0,R14
 0040( 0058)	     0000
 0042( 005A)	     4F7D	MOV.B @R15+,R13
 0044( 005C)	     9E7D	CMP.B @R14+,R13
 0046( 005E)	     2002	JNE #2, goes to  004C
 0048( 0060)	     934D	CMP.B #0,R13
 004A( 0062)	     23FB	JNE #-5, goes to  0042
 004C( 0064)	     2002	JNE #2, goes to  0052
 004E( 0066)	     431F	MOV #1,R15
 0050( 0068)	     3C01	JMP #1, goes to  0054
 0052( 006A)	     430F	MOV #0,R15
 0054( 006C)	     4FC1	MOV.B R15,20(SP)
 0056( 006E)	     0014
 0058( 0070)	     410F	MOV SP,R15
 005A( 0072)	     403E	MOV #0,R14
 005C( 0074)	     0000
 005E( 0076)	     4F7D	MOV.B @R15+,R13
 0060( 0078)	     9E7D	CMP.B @R14+,R13
 0062( 007A)	     2002	JNE #2, goes to  0068
 0064( 007C)	     934D	CMP.B #0,R13
 0066( 007E)	     23FB	JNE #-5, goes to  005E
 0068( 0080)	     2C02	JC #2, goes to  006E
 006A( 0082)	     431F	MOV #1,R15
 006C( 0084)	     3C01	JMP #1, goes to  0070
 006E( 0086)	     430F	MOV #0,R15
 0070( 0088)	     4FC1	MOV.B R15,20(SP)
 0072( 008A)	     0014
 0074( 008C)	     410F	MOV SP,R15
 0076( 008E)	     403E	MOV #0,R14
 0078( 0090)	     0000
 007A( 0092)	     4E7D	MOV.B @R14+,R13
 007C( 0094)	     9F7D	CMP.B @R15+,R13
 007E( 0096)	     2002	JNE #2, goes to  0084
 0080( 0098)	     934D	CMP.B #0,R13
 0082( 009A)	     23FB	JNE #-5, goes to  007A
 0084( 009C)	     2802	JNC #2, goes to  008A
 0086( 009E)	     431F	MOV #1,R15
 0088( 00A0)	     3C01	JMP #1, goes to  008C
 008A( 00A2)	     430F	MOV #0,R15
 008C( 00A4)	     4FC1	MOV.B R15,20(SP)
 008E( 00A6)	     0014
 0090( 00A8)	     410F	MOV SP,R15
 0092( 00AA)	     403E	MOV #0,R14
 0094( 00AC)	     0000
 0096( 00AE)	     4F7D	MOV.B @R15+,R13
 0098( 00B0)	     9E7D	CMP.B @R14+,R13
 009A( 00B2)	     2002	JNE #2, goes to  00A0
 009C( 00B4)	     934D	CMP.B #0,R13
 009E( 00B6)	     23FB	JNE #-5, goes to  0096
 00A0( 00B8)	     2402	JEQ #2, goes to  00A6
 00A2( 00BA)	     431F	MOV #1,R15
 00A4( 00BC)	     3C01	JMP #1, goes to  00A8
 00A6( 00BE)	     430F	MOV #0,R15
 00A8( 00C0)	     4FC1	MOV.B R15,20(SP)
 00AA( 00C2)	     0014
 00AC( 00C4)	     403F	MOV #8,R15
 00AE( 00C6)	     0008
 00B0( 00C8)	     410E	MOV SP,R14
 00B2( 00CA)	     4E7D	MOV.B @R14+,R13
 00B4( 00CC)	     9F7D	CMP.B @R15+,R13
 00B6( 00CE)	     2002	JNE #2, goes to  00BC
 00B8( 00D0)	     934D	CMP.B #0,R13
 00BA( 00D2)	     23FB	JNE #-5, goes to  00B2
 00BC( 00D4)	     2C02	JC #2, goes to  00C2
 00BE( 00D6)	     431F	MOV #1,R15
 00C0( 00D8)	     3C01	JMP #1, goes to  00C4
 00C2( 00DA)	     430F	MOV #0,R15
 00C4( 00DC)	     4FC1	MOV.B R15,20(SP)
 00C6( 00DE)	     0014
 00C8( 00E0)	     403F	MOV #36,R15
 00CA( 00E2)	     0024
 00CC( 00E4)	     410E	MOV SP,R14
 00CE( 00E6)	     4F7D	MOV.B @R15+,R13
 00D0( 00E8)	     9E7D	CMP.B @R14+,R13
 00D2( 00EA)	     2002	JNE #2, goes to  00D8
 00D4( 00EC)	     934D	CMP.B #0,R13
 00D6( 00EE)	     23FB	JNE #-5, goes to  00CE
 00D8( 00F0)	     2802	JNC #2, goes to  00DE
 00DA( 00F2)	     431F	MOV #1,R15
 00DC( 00F4)	     3C01	JMP #1, goes to  00E0
 00DE( 00F6)	     430F	MOV #0,R15
 00E0( 00F8)	     4FC1	MOV.B R15,20(SP)
 00E2( 00FA)	     0014
 00E4( 00FC)	     403F	MOV #64,R15
 00E6( 00FE)	     0040
 00E8( 0100)	     410E	MOV SP,R14
 00EA( 0102)	     4F7D	MOV.B @R15+,R13
 00EC( 0104)	     9E7D	CMP.B @R14+,R13
 00EE( 0106)	     2002	JNE #2, goes to  00F4
 00F0( 0108)	     934D	CMP.B #0,R13
 00F2( 010A)	     23FB	JNE #-5, goes to  00EA
 00F4( 010C)	     2002	JNE #2, goes to  00FA
 00F6( 010E)	     431F	MOV #1,R15
 00F8( 0110)	     3C01	JMP #1, goes to  00FC
 00FA( 0112)	     430F	MOV #0,R15
 00FC( 0114)	     4FC1	MOV.B R15,20(SP)
 00FE( 0116)	     0014
 0100( 0118)	     403F	MOV #92,R15
 0102( 011A)	     005C
 0104( 011C)	     410E	MOV SP,R14
 0106( 011E)	     4F7D	MOV.B @R15+,R13
 0108( 0120)	     9E7D	CMP.B @R14+,R13
 010A( 0122)	     2002	JNE #2, goes to  0110
 010C( 0124)	     934D	CMP.B #0,R13
 010E( 0126)	     23FB	JNE #-5, goes to  0106
 0110( 0128)	     2C02	JC #2, goes to  0116
 0112( 012A)	     431F	MOV #1,R15
 0114( 012C)	     3C01	JMP #1, goes to  0118
 0116( 012E)	     430F	MOV #0,R15
 0118( 0130)	     4FC1	MOV.B R15,20(SP)
 011A( 0132)	     0014
 011C( 0134)	     403F	MOV #120,R15
 011E( 0136)	     0078
 0120( 0138)	     410E	MOV SP,R14
 0122( 013A)	     4E7D	MOV.B @R14+,R13
 0124( 013C)	     9F7D	CMP.B @R15+,R13
 0126( 013E)	     2002	JNE #2, goes to  012C
 0128( 0140)	     934D	CMP.B #0,R13
 012A( 0142)	     23FB	JNE #-5, goes to  0122
 012C( 0144)	     2802	JNC #2, goes to  0132
 012E( 0146)	     431F	MOV #1,R15
 0130( 0148)	     3C01	JMP #1, goes to  0134
 0132( 014A)	     430F	MOV #0,R15
 0134( 014C)	     4FC1	MOV.B R15,20(SP)
 0136( 014E)	     0014
 0138( 0150)	     403F	MOV #148,R15
 013A( 0152)	     0094
 013C( 0154)	     410E	MOV SP,R14
 013E( 0156)	     4F7D	MOV.B @R15+,R13
 0140( 0158)	     9E7D	CMP.B @R14+,R13
 0142( 015A)	     2002	JNE #2, goes to  0148
 0144( 015C)	     934D	CMP.B #0,R13
 0146( 015E)	     23FB	JNE #-5, goes to  013E
 0148( 0160)	     2402	JEQ #2, goes to  014E
 014A( 0162)	     431F	MOV #1,R15
 014C( 0164)	     3C01	JMP #1, goes to  0150
 014E( 0166)	     430F	MOV #0,R15
 0150( 0168)	     4FC1	MOV.B R15,20(SP)
 0152( 016A)	     0014
 0154( 016C)	     410F	MOV SP,R15
 0156( 016E)	     410E	MOV SP,R14
 0158( 0170)	     503E	ADD #10,R14
 015A( 0172)	     000A
 015C( 0174)	     4E7D	MOV.B @R14+,R13
 015E( 0176)	     9F7D	CMP.B @R15+,R13
 0160( 0178)	     2002	JNE #2, goes to  0166
 0162( 017A)	     934D	CMP.B #0,R13
 0164( 017C)	     23FB	JNE #-5, goes to  015C
 0166( 017E)	     2C02	JC #2, goes to  016C
 0168( 0180)	     431F	MOV #1,R15
 016A( 0182)	     3C01	JMP #1, goes to  016E
 016C( 0184)	     430F	MOV #0,R15
 016E( 0186)	     4FC1	MOV.B R15,20(SP)
 0170( 0188)	     0014
 0172( 018A)	     410F	MOV SP,R15
 0174( 018C)	     410E	MOV SP,R14
 0176( 018E)	     503E	ADD #10,R14
 0178( 0190)	     000A
 017A( 0192)	     4F7D	MOV.B @R15+,R13
 017C( 0194)	     9E7D	CMP.B @R14+,R13
 017E( 0196)	     2002	JNE #2, goes to  0184
 0180( 0198)	     934D	CMP.B #0,R13
 0182( 019A)	     23FB	JNE #-5, goes to  017A
 0184( 019C)	     2802	JNC #2, goes to  018A
 0186( 019E)	     431F	MOV #1,R15
 0188( 01A0)	     3C01	JMP #1, goes to  018C
 018A( 01A2)	     430F	MOV #0,R15
 018C( 01A4)	     4FC1	MOV.B R15,20(SP)
 018E( 01A6)	     0014
 0190( 01A8)	     410F	MOV SP,R15
 0192( 01AA)	     410E	MOV SP,R14
 0194( 01AC)	     503E	ADD #10,R14
 0196( 01AE)	     000A
 0198( 01B0)	     4F7D	MOV.B @R15+,R13
 019A( 01B2)	     9E7D	CMP.B @R14+,R13
 019C( 01B4)	     2002	JNE #2, goes to  01A2
 019E( 01B6)	     934D	CMP.B #0,R13
 01A0( 01B8)	     23FB	JNE #-5, goes to  0198
 01A2( 01BA)	     2002	JNE #2, goes to  01A8
 01A4( 01BC)	     431F	MOV #1,R15
 01A6( 01BE)	     3C01	JMP #1, goes to  01AA
 01A8( 01C0)	     430F	MOV #0,R15
 01AA( 01C2)	     4FC1	MOV.B R15,20(SP)
 01AC( 01C4)	     0014
 01AE( 01C6)	     410F	MOV SP,R15
 01B0( 01C8)	     410E	MOV SP,R14
 01B2( 01CA)	     503E	ADD #10,R14
 01B4( 01CC)	     000A
 01B6( 01CE)	     4F7D	MOV.B @R15+,R13
 01B8( 01D0)	     9E7D	CMP.B @R14+,R13
 01BA( 01D2)	     2002	JNE #2, goes to  01C0
 01BC( 01D4)	     934D	CMP.B #0,R13
 01BE( 01D6)	     23FB	JNE #-5, goes to  01B6
 01C0( 01D8)	     2C02	JC #2, goes to  01C6
 01C2( 01DA)	     431F	MOV #1,R15
 01C4( 01DC)	     3C01	JMP #1, goes to  01C8
 01C6( 01DE)	     430F	MOV #0,R15
 01C8( 01E0)	     4FC1	MOV.B R15,20(SP)
 01CA( 01E2)	     0014
 01CC( 01E4)	     410F	MOV SP,R15
 01CE( 01E6)	     410E	MOV SP,R14
 01D0( 01E8)	     503E	ADD #10,R14
 01D2( 01EA)	     000A
 01D4( 01EC)	     4E7D	MOV.B @R14+,R13
 01D6( 01EE)	     9F7D	CMP.B @R15+,R13
 01D8( 01F0)	     2002	JNE #2, goes to  01DE
 01DA( 01F2)	     934D	CMP.B #0,R13
 01DC( 01F4)	     23FB	JNE #-5, goes to  01D4
 01DE( 01F6)	     2802	JNC #2, goes to  01E4
 01E0( 01F8)	     431F	MOV #1,R15
 01E2( 01FA)	     3C01	JMP #1, goes to  01E6
 01E4( 01FC)	     430F	MOV #0,R15
 01E6( 01FE)	     4FC1	MOV.B R15,20(SP)
 01E8( 0200)	     0014
 01EA( 0202)	     410F	MOV SP,R15
 01EC( 0204)	     410E	MOV SP,R14
 01EE( 0206)	     503E	ADD #10,R14
 01F0( 0208)	     000A
 01F2( 020A)	     4F7D	MOV.B @R15+,R13
 01F4( 020C)	     9E7D	CMP.B @R14+,R13
 01F6( 020E)	     2002	JNE #2, goes to  01FC
 01F8( 0210)	     934D	CMP.B #0,R13
 01FA( 0212)	     23FB	JNE #-5, goes to  01F2
 01FC( 0214)	     2402	JEQ #2, goes to  0202
 01FE( 0216)	     431F	MOV #1,R15
 0200( 0218)	     3C01	JMP #1, goes to  0204
 0202( 021A)	     430F	MOV #0,R15
 0204( 021C)	     4FC1	MOV.B R15,20(SP)
 0206( 021E)	     0014
 0208( 0220)	     5031	ADD #22,SP
 020A( 0222)	     0016
 020C( 0224)	     4130	RET
 020E( 0226)	     4130	RET
