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
testInc 1EDF1214 Flash   262
imports:
type descriptors

data     6
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0104
fixup procedures chains
fixup handlers chains
fixup data chains
 00CE     0	 0000
 00CC     0	 0002
 00E0     0	 0004
 00DE     0	 0005
fixup constants chains
fixup types chains
entry =  0104
code   262
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
 004C	     5391	ADD #1,0(SP)
 004E	     0000
 0050	     53A1	ADD #2,0(SP)
 0052	     0000
 0054	     83A1	SUB #2,0(SP)
 0056	     0000
 0058	     5191	ADD 2(SP),0(SP)
 005A	     0002
 005C	     0000
 005E	     53D1	ADD.B #1,4(SP)
 0060	     0004
 0062	     53E1	ADD.B #2,4(SP)
 0064	     0004
 0066	     83E1	SUB.B #2,4(SP)
 0068	     0004
 006A	     51D1	ADD.B 5(SP),4(SP)
 006C	     0005
 006E	     0004
 0070	     8391	SUB #1,0(SP)
 0072	     0000
 0074	     83A1	SUB #2,0(SP)
 0076	     0000
 0078	     53A1	ADD #2,0(SP)
 007A	     0000
 007C	     8191	SUB 2(SP),0(SP)
 007E	     0002
 0080	     0000
 0082	     83D1	SUB.B #1,4(SP)
 0084	     0004
 0086	     83E1	SUB.B #2,4(SP)
 0088	     0004
 008A	     53E1	ADD.B #2,4(SP)
 008C	     0004
 008E	     81D1	SUB.B 5(SP),4(SP)
 0090	     0005
 0092	     0004
 0094	     5031	ADD #6,SP
 0096	     0006
 0098	     4130	RET
 009A	     5392	ADD #1,&56
 009C	     0038
 009E	     53A2	ADD #2,&156
 00A0	     009C
 00A2	     83A2	SUB #2,&160
 00A4	     00A0
 00A6	     5292	ADD &54,&164
 00A8	     0036
 00AA	     00A4
 00AC	     53D2	ADD.B #1,&74
 00AE	     004A
 00B0	     53E2	ADD.B #2,&174
 00B2	     00AE
 00B4	     83E2	SUB.B #2,&178
 00B6	     00B2
 00B8	     52D2	ADD.B &72,&182
 00BA	     0048
 00BC	     00B6
 00BE	     8392	SUB #1,&170
 00C0	     00AA
 00C2	     83A2	SUB #2,&192
 00C4	     00C0
 00C6	     53A2	ADD #2,&196
 00C8	     00C4
 00CA	     8292	SUB &168,&200
 00CC	     00A8
 00CE	     00C8
 00D0	     83D2	SUB.B #1,&188
 00D2	     00BC
 00D4	     83E2	SUB.B #2,&210
 00D6	     00D2
 00D8	     53E2	ADD.B #2,&214
 00DA	     00D6
 00DC	     82D2	SUB.B &186,&218
 00DE	     00BA
 00E0	     00DA
 00E2	     5314	ADD #1,R4
 00E4	     5324	ADD #2,R4
 00E6	     8324	SUB #2,R4
 00E8	     5504	ADD R5,R4
 00EA	     5356	ADD.B #1,R6
 00EC	     5366	ADD.B #2,R6
 00EE	     8366	SUB.B #2,R6
 00F0	     5746	ADD.B R7,R6
 00F2	     8314	SUB #1,R4
 00F4	     8324	SUB #2,R4
 00F6	     5324	ADD #2,R4
 00F8	     8504	SUB R5,R4
 00FA	     8356	SUB.B #1,R6
 00FC	     8366	SUB.B #2,R6
 00FE	     5366	ADD.B #2,R6
 0100	     8746	SUB.B R7,R6
 0102	     4130	RET
 0104	     4130	RET
