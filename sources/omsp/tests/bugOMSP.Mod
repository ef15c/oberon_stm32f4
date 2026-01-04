MODULE bugOMSP;

  VAR address: PBYTE;

  PROCEDURE serialOutChar(c: CHAR*);
  END serialOutChar;

  PROCEDURE toHexa(v: BYTE*): CHAR;
    VAR r: BYTE*;
  BEGIN IF v < 10 THEN r := ORD("0") ELSE r := ORD("A") - 10 END;
    INC(r, v)

    RETURN CHR(r)
  END toHexa;

BEGIN serialOutChar(toHexa(address^ DIV 10H))
END bugOMSP.

OMSPP.Compile bugOMSP.Mod/s~
OMSPL.Link 32 4000H 200H bugOMSP~

bugOMSP.txt bugOMSP.map

OMSPTool.DecSym bugOMSP.sms

OMSPTool.DecObj bugOMSP.mpc
decode bugOMSP.mpc
bugOMSP 5563A616
imports:

section     0	r    2	address
fixups:

section     1	c    2	serialOutChar
 0000	     4130	RET
fixups:

section     2	c   20	toHexa
 0000	     9075	CMP.B #10,R5
 0002	     000A
 0004	     2C03	JC $+8, goes to  000C
 0006	     4074	MOV.B #48,R4
 0008	     0030
 000A	     3C02	JMP $+6, goes to  0010
 000C	     4074	MOV.B #55,R4
 000E	     0037
 0010	     5544	ADD.B R5,R4
 0012	     4130	RET
fixups:

section     3	c   26	module body
 0000	     4214	MOV &0,R4
 0002	     0000
 0004	     4464	MOV.B @R4,R4
 0006	     1144	RRA.B R4
 0008	     1144	RRA.B R4
 000A	     1144	RRA.B R4
 000C	     1144	RRA.B R4
 000E	     4445	MOV.B R4,R5
 0010	     12B0	CALL #0
 0012	     0000
 0014	     12B0	CALL #0
 0016	     0000
 0018	     4130	RET
fixups:
 0017	s0.1
 0013	s0.2
 0003	s0.0

section     4	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    3
