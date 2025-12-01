MODULE testArray;
  TYPE rt = RECORD
    a, b, c: INTEGER
  END;
  
  VAR s: ARRAY 10 OF CHAR;
    v: ARRAY 5 OF INTEGER;
    r: ARRAY 8 OF rt;
    i: INTEGER;
BEGIN 
  s[i] := s[i+1];
  v[i] := v[i+1];
  r[i] := r[i+1]
END testArray.

OMSPP.Compile testArray.Mod/s ~
OMSPTool.DecObj testArray.mpc
decode testArray.mpc
testArray 8B5631A7
imports:

section     0	d    8	rt
 06 00 FF FF FF FF FF FF
fixups:

section     1	r   10	s
fixups:

section     2	r   10	v
fixups:

section     3	r   48	r
fixups:

section     4	r    2	i
fixups:

section     5	c   86	module body
 0000	     421F	MOV &0,R15
 0002	     0000
 0004	     421E	MOV &3,R14
 0006	     0003
 0008	     531E	ADD #1,R14
 000A	     4EDF	MOV.B 0(R14),13(R15)
 000C	     0000
 000E	     000D
 0010	     421F	MOV &7,R15
 0012	     0007
 0014	     5F0F	ADD R15,R15
 0016	     421E	MOV &19,R14
 0018	     0013
 001A	     531E	ADD #1,R14
 001C	     5E0E	ADD R14,R14
 001E	     4E9F	MOV 0(R14),33(R15)
 0020	     0000
 0022	     0021
 0024	     421F	MOV &25,R15
 0026	     0019
 0028	     5F0F	ADD R15,R15
 002A	     4F0E	MOV R15,R14
 002C	     5E0E	ADD R14,R14
 002E	     5E0F	ADD R14,R15
 0030	     421E	MOV &39,R14
 0032	     0027
 0034	     531E	ADD #1,R14
 0036	     5E0E	ADD R14,R14
 0038	     4E0D	MOV R14,R13
 003A	     5D0D	ADD R13,R13
 003C	     5D0E	ADD R13,R14
 003E	     503E	ADD #0,R14
 0040	     0000
 0042	     503F	ADD #65,R15
 0044	     0041
 0046	     403D	MOV #3,R13
 0048	     0003
 004A	     4EBF	MOV @R14+,0(R15)
 004C	     0000
 004E	     532F	ADD #2,R15
 0050	     831D	SUB #1,R13
 0052	     23FB	JNE $-8, goes to  004A
 0054	     4130	RET
fixups:
 0045	s0.3
 0023	s0.2
 000F	s0.1
 0033	s0.4

section     6	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    5
