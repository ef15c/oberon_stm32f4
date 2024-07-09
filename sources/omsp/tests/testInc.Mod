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

OMSPTool.DecObj testInc.mpc

not leaf:
decode testInc.mpc
testInc 74D6D3BE   164
imports:
type descriptors

data     6
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 0096
pointer refs

fixup procedures chains
fixup handlers chains
fixup data chains
 0038     0	 0000
 0036     0	 0002
 004A     0	 0004
 0048     0	 0005
fixup type chains
entry =  0096
code   152
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
 0096	     4130	RET

leaf:
decode testInc.mpc
testInc 74D6D3BE   120
imports:
type descriptors

data     6
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 006A
pointer refs

fixup procedures chains
fixup handlers chains
fixup data chains
 0034     0	 0000
 0032     0	 0002
 0046     0	 0004
 0044     0	 0005
fixup type chains
entry =  006A
code   108
 0000	     5392	ADD #1,&0
 0002	     0000
 0004	     53A2	ADD #2,&2
 0006	     0002
 0008	     83A2	SUB #2,&6
 000A	     0006
 000C	     5292	ADD &0,&10
 000E	     0000
 0010	     000A
 0012	     53D2	ADD.B #1,&0
 0014	     0000
 0016	     53E2	ADD.B #2,&20
 0018	     0014
 001A	     83E2	SUB.B #2,&24
 001C	     0018
 001E	     52D2	ADD.B &0,&28
 0020	     0000
 0022	     001C
 0024	     8392	SUB #1,&16
 0026	     0010
 0028	     83A2	SUB #2,&38
 002A	     0026
 002C	     53A2	ADD #2,&42
 002E	     002A
 0030	     8292	SUB &14,&46
 0032	     000E
 0034	     002E
 0036	     83D2	SUB.B #1,&34
 0038	     0022
 003A	     83E2	SUB.B #2,&56
 003C	     0038
 003E	     53E2	ADD.B #2,&60
 0040	     003C
 0042	     82D2	SUB.B &32,&64
 0044	     0020
 0046	     0040
 0048	     5314	ADD #1,R4
 004A	     5324	ADD #2,R4
 004C	     8324	SUB #2,R4
 004E	     5504	ADD R5,R4
 0050	     5356	ADD.B #1,R6
 0052	     5366	ADD.B #2,R6
 0054	     8366	SUB.B #2,R6
 0056	     5746	ADD.B R7,R6
 0058	     8314	SUB #1,R4
 005A	     8324	SUB #2,R4
 005C	     5324	ADD #2,R4
 005E	     8504	SUB R5,R4
 0060	     8356	SUB.B #1,R6
 0062	     8366	SUB.B #2,R6
 0064	     5366	ADD.B #2,R6
 0066	     8746	SUB.B R7,R6
 0068	     4130	RET
 006A	     4130	RET
