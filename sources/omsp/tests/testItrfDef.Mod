MODULE testItrfDef;

  (*{4..15} requires that those registers, excluding the return regiser must be saved by callee*)
  TYPE Callback* = PROCEDURE {4..15} (): BOOLEAN;

  VAR cbk: Callback;

  PROCEDURE* (0) {15} handler;
  BEGIN IF cbk() THEN END
  END handler;

  PROCEDURE setCallback*(c: Callback);
  BEGIN cbk := c
  END setCallback;

END testItrfDef.

OMSPTool.DecObj testItrfDef.mpc
decode testItrfDef.mpc
testItrfDef BC3350CA Flash    24
imports:
type descriptors

data     2
strings

vector table
 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0016 c 000E
fixup procedures chains
fixup handlers chains
 0100     0	 0000
fixup data chains
 0012     0	 0000
fixup constants chains
fixup types chains
entry =  0016
code    24
 0000	     120F	PUSH R15
 0002	     1292	CALL &0
 0004	     0000
 0006	     934F	CMP.B #0,R15
 0008	     2400	JEQ $+2, goes to  000A
 000A	     413F	POP R15
 000C	     1300	RETI
 000E	     4192	MOV 2(SP),&4
 0010	     0002
 0012	     0004
 0014	     4130	RET
 0016	     4130	RET

OMSPTool.DecSym testItrfDef.sms
decode testItrfDef.sms
testItrfDef BC3350CA  1
   5 Callback [19  form = 10  size = 2 [^2] UR 8000()]()
   1 setCallback [0  form = 10  size = 2 [^9] UR 0000( class = 2 [^19])]       1
