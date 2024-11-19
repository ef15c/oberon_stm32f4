MODULE testItrfUse;
  IMPORT testItrfDef;

  PROCEDURE callback*(): BOOLEAN;
    VAR x: INTEGER;
  BEGIN x := 0
    RETURN FALSE
  END callback;

BEGIN testItrfDef.setCallback(callback)
END testItrfUse.

OMSPTool.DecObj testItrfUse.mpc
decode testItrfUse.mpc
testItrfUse 7A15DBD6 Flash    24
imports:
	testItrfDef BC3350CA
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 000C c 0000
fixup procedures chains
 000E     0	 0000
 0012     1	 0001
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  000C
code    24
 0000	     8321	SUB #2,SP
 0002	     4381	MOV #0,0(SP)
 0004	     0000
 0006	     430F	MOV #0,R15
 0008	     5321	ADD #2,SP
 000A	     4130	RET
 000C	     1230	PUSH #0
 000E	     0000
 0010	     12B0	CALL #0
 0012	     0000
 0014	     5321	ADD #2,SP
 0016	     4130	RET

OMSPTool.DecSym testItrfUse.sms
decode testItrfUse.sms
testItrfUse 7A15DBD6  1
   1 callback [0  form = 10  size = 2 [^2] UR 8000()]       1
