MODULE testCond;

  PROCEDURE p(v: INTEGER);
    VAR b: BOOLEAN;
  BEGIN b := (v>-1) & (v<1) OR (v>9) & (v<11)
  END p;

BEGIN p(40)
END testCond.


OM4Tool.DecObj testCond.m4c ~

decode testCond.m4c
testCond D8E1D5B7   1    86
imports:
type descriptors

data     0
strings

code
commands:
entries
    60
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       60
   0	 F1BD0D04	SUBS SP SP #4
   4	     B401	PUSH R0
   6	     B500	PUSH LR
   8	     9801	LDR R0 [SP + 4]
  10	 F1B03FFF	CMP R0 #-1
  14	 F3408004	BLE #8
  18	     9801	LDR R0 [SP + 4]
  20	     2801	CMP R0 #1
  22	 F2C08007	BLT #14
  26	     9801	LDR R0 [SP + 4]
  28	     2809	CMP R0 #9
  30	 F3408005	BLE #10
  34	     9801	LDR R0 [SP + 4]
  36	     280B	CMP R0 #11
  38	     DA01	BGE #2
  40	     2001	MOVS R0 #1
  42	     E000	B #0
  44	     2000	MOVS R0 #0
  46	 F88D0008	STRB R0 [ SP + 8 ]
  50	 F85DEB04	LDR LR [ SP ] + 4
  54	 F11D0D08	ADDS SP SP #8
  58	     4770	BX LR
  60	     B500	PUSH LR
  62	     2028	MOVS R0 #40
  64	 F7FFFFDE	BL #-68
  68	 F85DEB04	LDR LR [ SP ] + 4
  72	     4770	BX LR

OMSPTool.DecObj testCond.mpc
decode testCond.mpc
testCond D8E1D5B7    66
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 0030
pointer refs

fixup procedures chains
 0036     0	 0000
fixup handlers chains
fixup data chains
fixup type chains
entry =  0030
code    60
 0000	     8321	SUB #2,SP
 0002	     433F	MOV #-1,R15
 0004	     911F	CMP 4(SP),R15
 0006	     0004
 0008	     3403	JGE #3, goes to  0010
 000A	     9391	CMP #1,4(SP)
 000C	     0004
 000E	     3809	JL #9, goes to  0022
 0010	     403F	MOV #9,R15
 0012	     0009
 0014	     911F	CMP 4(SP),R15
 0016	     0004
 0018	     3406	JGE #6, goes to  0026
 001A	     90B1	CMP #11,4(SP)
 001C	     000B
 001E	     0004
 0020	     3402	JGE #2, goes to  0026
 0022	     431F	MOV #1,R15
 0024	     3C01	JMP #1, goes to  0028
 0026	     430F	MOV #0,R15
 0028	     4FC1	MOV.B R15,0(SP)
 002A	     0000
 002C	     5321	ADD #2,SP
 002E	     4130	RET
 0030	     1230	PUSH #40
 0032	     0028
 0034	     12B0	CALL #0
 0036	     0000
 0038	     5321	ADD #2,SP
 003A	     4130	RET
