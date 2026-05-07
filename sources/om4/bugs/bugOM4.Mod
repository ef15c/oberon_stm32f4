MODULE bugOM4;
  IMPORT Def := USBHDef, IoReq := USBHIoReq;
  PROCEDURE p(phost: Def.Handle);
    VAR direction: SET;
  BEGIN
   direction := phost.Control.setup.bmRequestType*Def.REQ_DIR_MASK;
  END p;
END bugOM4.

OM4P.Compile bugOM4.Mod/s~
System.Free bugOM4~
bugOM4.p

OM4Tool.DecObj bugOM4.m4c
decode bugOM4.m4c
bugOM4 64868F7D   2     52
imports:
	USBHDef CD3B3652
	USBHIoReq AFE2AF74
type descriptors

strings

data     0
code
commands:
entries
 00000018
pointer refs

fixP =  00000000
fixV =  00000000
fixC =  00000000
fixT =  00000000
entry =  00000018
 00000000	     B081	SUB SP SP #4
 00000002	     B401	PUSH R0
 00000004	     B500	PUSH LR
 00000006	     9801	LDR R0 [ SP + 4 ]
 00000008	     7D00	LDRB R0 [ R0 + 20 ]
 0000000A	 F0100080	ANDS R0 R0 #128
 0000000E	     9002	STR R0 [ SP + 8 ]
 00000010	 F85DEB04	LDR LR [ SP ] + 4
 00000014	     B002	ADD SP SP #8
 00000016	     4770	BX LR
 00000018	     B500	PUSH LR
 0000001A	 F85DEB04	LDR LR [ SP ] + 4
 0000001E	     4770	BX LR
