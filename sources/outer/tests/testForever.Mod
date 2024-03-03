MODULE testForever;
	PROCEDURE loop*;
	BEGIN REPEAT UNTIL FALSE
	END loop;

	PROCEDURE ovfl*;
	BEGIN ovfl
	END ovfl;
END testForever.

OM4Tool.DecObj testForever.m4c

testForever C036071D   1    76
imports:
type descriptors

data     0
strings

code
commands:
	loop    0
	ovfl   10
entries
    22     0    10
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       22
 00000000	     B500	PUSH LR
 00000002	     E7FE	B #-4, goes to  00000002
 00000004	 F85DEB04	LDR LR [ SP ] + 4
 00000008	     4770	BX LR
 0000000A	     B500	PUSH LR
 0000000C	 F7FFFFFD	BL #-6, goes to  0000000A
 00000010	 F85DEB04	LDR LR [ SP ] + 4
 00000014	     4770	BX LR
 00000016	     B500	PUSH LR
 00000018	 F85DEB04	LDR LR [ SP ] + 4
 0000001C	     4770	BX LR
