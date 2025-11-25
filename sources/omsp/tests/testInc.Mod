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

BEGIN p; q
END testInc.

OMSPP.Compile testInc.Mod~
OMSPTool.DecObj testInc.mpc
decode testInc.mpc
testInc 139C34CD
imports:

section     0	r    2	a
fixups:

section     1	r    2	b
fixups:

section     2	r    1	c
fixups:

section     3	r    1	d
fixups:

section     4	c  154	p
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     5392	ADD #1,&0
 0006	     0000
 0008	     53A2	ADD #2,&7
 000A	     0007
 000C	     83A2	SUB #2,&11
 000E	     000B
 0010	     5292	ADD &0,&15
 0012	     0000
 0014	     000F
 0016	     53D2	ADD.B #1,&0
 0018	     0000
 001A	     53E2	ADD.B #2,&25
 001C	     0019
 001E	     83E2	SUB.B #2,&29
 0020	     001D
 0022	     52D2	ADD.B &0,&33
 0024	     0000
 0026	     0021
 0028	     8392	SUB #1,&21
 002A	     0015
 002C	     83A2	SUB #2,&43
 002E	     002B
 0030	     53A2	ADD #2,&47
 0032	     002F
 0034	     8292	SUB &19,&51
 0036	     0013
 0038	     0033
 003A	     83D2	SUB.B #1,&39
 003C	     0027
 003E	     83E2	SUB.B #2,&61
 0040	     003D
 0042	     53E2	ADD.B #2,&65
 0044	     0041
 0046	     82D2	SUB.B &37,&69
 0048	     0025
 004A	     0045
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
fixups:
 0049	s0.3
 004B	s0.2
 0037	s0.1
 0039	s0.0

section     5	c  106	q
 0000	     5392	ADD #1,&0
 0002	     0000
 0004	     53A2	ADD #2,&3
 0006	     0003
 0008	     83A2	SUB #2,&7
 000A	     0007
 000C	     5292	ADD &0,&11
 000E	     0000
 0010	     000B
 0012	     53D2	ADD.B #1,&0
 0014	     0000
 0016	     53E2	ADD.B #2,&21
 0018	     0015
 001A	     83E2	SUB.B #2,&25
 001C	     0019
 001E	     52D2	ADD.B &0,&29
 0020	     0000
 0022	     001D
 0024	     8392	SUB #1,&17
 0026	     0011
 0028	     83A2	SUB #2,&39
 002A	     0027
 002C	     53A2	ADD #2,&43
 002E	     002B
 0030	     8292	SUB &15,&47
 0032	     000F
 0034	     002F
 0036	     83D2	SUB.B #1,&35
 0038	     0023
 003A	     83E2	SUB.B #2,&57
 003C	     0039
 003E	     53E2	ADD.B #2,&61
 0040	     003D
 0042	     82D2	SUB.B &33,&65
 0044	     0021
 0046	     0041
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
fixups:
 0045	s0.3
 0047	s0.2
 0033	s0.1
 0035	s0.0

section     6	c   10	module body
 0000	     12B0	CALL #0
 0002	     0000
 0004	     12B0	CALL #0
 0006	     0000
 0008	     4130	RET
fixups:
 0007	s0.5
 0003	s0.4

section     7	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    6
