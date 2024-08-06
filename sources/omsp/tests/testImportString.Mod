MODULE testImportString;
  IMPORT Texts, Oberon, testString;

  VAR W: Texts.Writer;

  PROCEDURE run*;
  BEGIN Texts.WriteString(W, "---"); Texts.WriteString(W, testString.st); Texts.WriteString(W, "+++");
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END run;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OM4Tool 04.08.24"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END testImportString.

OMSPTool.DecObj testImportString.mpc
decode testImportString.mpc
testImportString BFA5B1A1 Flash    22
imports:
	testString DF726B2B
type descriptors

data    10
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0000
fixup procedures chains
fixup handlers chains
fixup data chains
 0002     0	 0000
fixup types and strings chains
entry =  0000
code    22
 0000	     403F	MOV #0,R15
 0002	     0000
 0004	     403E	MOV #56,R14
 0006	     0038
 0008	     4EBF	MOV @R14+,0(R15)
 000A	     0000
 000C	     532F	ADD #2,R15
 000E	     93CE	CMP.B #0,65535(R14)
 0010	     FFFF
 0012	     23FA	JNE #-6, goes to  0008
 0014	     4130	RET

OM4Tool.DecObj testImportString.m4c
decode testImportString.m4c
testImportString BFA5B1A1   1    64
imports:
	testString DF5AB52B
type descriptors

data    12
strings

code
commands:
entries
     0
pointer refs

fixP =        0
fixD =       10
fixT =        0
entry =        0
 00000000	     B500	PUSH LR
 00000002	 00000001	MOV R0 lower 16-bits base(0)
 00000006	 00000000	MOVT R0 higher 16-bits base + 0
 0000000A	 10000004	MOV R1 lower 16-bits base(0)
 0000000E	 0000000C	MOVT R1 higher 16-bits base + 12
 00000012	 F8512B04	LDR R2 [ R1 ] + 4
 00000016	 F8402B04	STR R2 [ R0 ] + 4
 0000001A	     1612	ASRS R2 R2 #24
 0000001C	     D1F9	BNE #-14, goes to  00000012
 0000001E	 F85DEB04	LDR LR [ SP ] + 4
 00000022	     4770	BX LR
