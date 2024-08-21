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

  PROCEDURE q;
    VAR i, j: INTEGER*;
    k, l: BYTE*;
  BEGIN
    INC(a); INC(a, 2); INC(a, -2); INC(a, b);
    INC(c); INC(c, 2); INC(c, -2); INC(c, d);
    DEC(a); DEC(a, 2); DEC(a, -2); DEC(a, b);
    DEC(c); DEC(c, 2); DEC(c, -2); DEC(c, d);
    
    INC(i); INC(i, 2); INC(i, -2); INC(i, j);
    INC(k); INC(k, 2); INC(k, -2); INC(k, l);
    DEC(i); DEC(i, 2); DEC(i, -2); DEC(i, j);
    DEC(k); DEC(k, 2); DEC(k, -2); DEC(k, l);
  END q;

END testInc.

OMSPTool.DecObj testInc.mpc
decode testInc.mpc
testInc 74D6D3BE Flash   258
imports:
type descriptors

data     6
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0100
fixup procedures chains
fixup handlers chains
fixup data chains
 00CA     0	 0000
 00C8     0	 0002
 00DC     0	 0004
 00DA     0	 0005
fixup constants chains
fixup types chains
entry =  0100
code   258
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     5392	ADD #1,&0
 0006	     0000
 0008	     53A2	ADD #2,&6
 000A	     0006
 000C	     83A2	SUB #2,&10
 000E	     000A
 0010	     5292	ADD &0,&14
 0012	     0000
 0014	     000E
 0016	     53D2	ADD.B #1,&0
 0018	     0000
 001A	     53E2	ADD.B #2,&24
 001C	     0018
 001E	     83E2	SUB.B #2,&28
 0020	     001C
 0022	     52D2	ADD.B &0,&32
 0024	     0000
 0026	     0020
 0028	     8392	SUB #1,&20
 002A	     0014
 002C	     83A2	SUB #2,&42
 002E	     002A
 0030	     53A2	ADD #2,&46
 0032	     002E
 0034	     8292	SUB &18,&50
 0036	     0012
 0038	     0032
 003A	     83D2	SUB.B #1,&38
 003C	     0026
 003E	     83E2	SUB.B #2,&60
 0040	     003C
 0042	     53E2	ADD.B #2,&64
 0044	     0040
 0046	     82D2	SUB.B &36,&68
 0048	     0024
 004A	     0044
 004C	     5391	ADD #1,4(SP)
 004E	     0004
 0050	     53A1	ADD #2,4(SP)
 0052	     0004
 0054	     83A1	SUB #2,4(SP)
 0056	     0004
 0058	     5191	ADD 2(SP),4(SP)
 005A	     0002
 005C	     0004
 005E	     53D1	ADD.B #1,1(SP)
 0060	     0001
 0062	     53E1	ADD.B #2,1(SP)
 0064	     0001
 0066	     83E1	SUB.B #2,1(SP)
 0068	     0001
 006A	     51E1	ADD.B @SP,1(SP)
 006C	     0001
 006E	     8391	SUB #1,4(SP)
 0070	     0004
 0072	     83A1	SUB #2,4(SP)
 0074	     0004
 0076	     53A1	ADD #2,4(SP)
 0078	     0004
 007A	     8191	SUB 2(SP),4(SP)
 007C	     0002
 007E	     0004
 0080	     83D1	SUB.B #1,1(SP)
 0082	     0001
 0084	     83E1	SUB.B #2,1(SP)
 0086	     0001
 0088	     53E1	ADD.B #2,1(SP)
 008A	     0001
 008C	     81E1	SUB.B @SP,1(SP)
 008E	     0001
 0090	     5031	ADD #6,SP
 0092	     0006
 0094	     4130	RET
 0096	     5392	ADD #1,&56
 0098	     0038
 009A	     53A2	ADD #2,&152
 009C	     0098
 009E	     83A2	SUB #2,&156
 00A0	     009C
 00A2	     5292	ADD &54,&160
 00A4	     0036
 00A6	     00A0
 00A8	     53D2	ADD.B #1,&74
 00AA	     004A
 00AC	     53E2	ADD.B #2,&170
 00AE	     00AA
 00B0	     83E2	SUB.B #2,&174
 00B2	     00AE
 00B4	     52D2	ADD.B &72,&178
 00B6	     0048
 00B8	     00B2
 00BA	     8392	SUB #1,&166
 00BC	     00A6
 00BE	     83A2	SUB #2,&188
 00C0	     00BC
 00C2	     53A2	ADD #2,&192
 00C4	     00C0
 00C6	     8292	SUB &164,&196
 00C8	     00A4
 00CA	     00C4
 00CC	     83D2	SUB.B #1,&184
 00CE	     00B8
 00D0	     83E2	SUB.B #2,&206
 00D2	     00CE
 00D4	     53E2	ADD.B #2,&210
 00D6	     00D2
 00D8	     82D2	SUB.B &182,&214
 00DA	     00B6
 00DC	     00D6
 00DE	     5314	ADD #1,R4
 00E0	     5324	ADD #2,R4
 00E2	     8324	SUB #2,R4
 00E4	     5504	ADD R5,R4
 00E6	     5356	ADD.B #1,R6
 00E8	     5366	ADD.B #2,R6
 00EA	     8366	SUB.B #2,R6
 00EC	     5746	ADD.B R7,R6
 00EE	     8314	SUB #1,R4
 00F0	     8324	SUB #2,R4
 00F2	     5324	ADD #2,R4
 00F4	     8504	SUB R5,R4
 00F6	     8356	SUB.B #1,R6
 00F8	     8366	SUB.B #2,R6
 00FA	     5366	ADD.B #2,R6
 00FC	     8746	SUB.B R7,R6
 00FE	     4130	RET
 0100	     4130	RET
