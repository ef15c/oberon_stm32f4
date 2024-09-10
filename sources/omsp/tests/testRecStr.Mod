MODULE testRecStr;

  TYPE rec = RECORD a: INTEGER END;

  VAR s: ARRAY 10 OF CHAR; r: rec;

BEGIN s := "bonjour"
END testRecStr.

OMSPTool.DecObj testRecStr.mpc
decode testRecStr.mpc
testRecStr B957349F Flash    38
imports:
type descriptors
 0002 FFFF FFFF FFFF
data    12
strings
bonjour|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0010
fixup procedures chains
fixup handlers chains
fixup data chains
 0002( 0012)     0	 0000
fixup constants chains
 0006( 0016)     0	 0008
fixup types chains
entry =  0010
code    22
 0000( 0010)	     403F	MOV #0,R15
 0002( 0012)	     0000
 0004( 0014)	     403E	MOV #0,R14
 0006( 0016)	     0000
 0008( 0018)	     4EBF	MOV @R14+,0(R15)
 000A( 001A)	     0000
 000C( 001C)	     532F	ADD #2,R15
 000E( 001E)	     93CE	CMP.B #0,-1(R14)
 0010( 0020)	     FFFF
 0012( 0022)	     23FA	JNE #-6, goes to  0008
 0014( 0024)	     4130	RET
