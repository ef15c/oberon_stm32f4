MODULE bugOMSP;
  CONST SET_X_ADDRESS* = {7};

  PROCEDURE send*(d: BYTESET*);
  BEGIN INC(ORD(d))
  END send;

  PROCEDURE p(xAddr: BYTE);
  BEGIN send(SET_X_ADDRESS + TOSET(xAddr))
  END p;

BEGIN p(2)
END bugOMSP.

OMSPP.Compile bugOMSP.Mod/s~
OMSPL.Link 32 4000H 200H bugOMSP~

bugOMSP.txt bugOMSP.map

OMSPTool.DecSym bugOMSP.sms

OMSPTool.DecObj bugOMSP.mpc
decode bugOMSP.mpc
bugOMSP 2A9B4FA6
imports:

section     0	c    4	send
 0000	     5354	ADD.B #1,R4
 0002	     4130	RET
fixups:

section     1	c   18	p
 0000	     4154	MOV.B 2(SP),R4
 0002	     0002
 0004	     4035	MOV #128,R5
 0006	     0080
 0008	     D405	BIS R4,R5
 000A	     4504	MOV R5,R4
 000C	     12B0	CALL #0
 000E	     0000
 0010	     4130	RET
fixups:
 000F	s0.0

section     2	c   10	module body
 0000	     1223	PUSH #2
 0002	     12B0	CALL #0
 0004	     0000
 0006	     5321	ADD #2,SP
 0008	     4130	RET
fixups:
 0005	s0.1

section     3	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    2    0
