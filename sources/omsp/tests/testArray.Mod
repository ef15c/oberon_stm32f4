MODULE testArray;
  TYPE rt = RECORD
    a, b, c: INTEGER
  END;
  
  VAR s: ARRAY 10 OF CHAR; (*0*)
    v: ARRAY 5 OF INTEGER; (*0AH*)
    r: ARRAY 8 OF rt; (*14H*)
    i: INTEGER; (*44H*)
BEGIN 
  s[i] := s[i+1];
  v[i] := v[i+1];
  r[i] := r[i+1]
END testArray.

OMSPTool.DecObj testArray.mpc
decode testArray.mpc
testArray 88E768A9 Flash    94
imports:
type descriptors
 0006 FFFF FFFF FFFF
data    70
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0000
fixup procedures in code space chains
fixup handlers in vector space chains
fixup data in code space chains
 0044     0	 0014
 0022     0	 000A
 000E     0	 0000
 0032     0	 0044
fixup constants in code space chains
fixup variables in constant space chains
fixup constants in constant space chains
entry =  0000
code    86
 0000	     421F	MOV &0,R15
 0002	     0000 @i
 0004	     421E	MOV &2,R14
 0006	     0002 @i
 0008	     531E	ADD #1,R14
 000A	     4EDF	MOV.B 0(R14),12(R15)
 000C	     0000 @s
 000E	     000C @s
 0010	     421F	MOV &6,R15
 0012	     0006 @i
 0014	     5F0F	ADD R15,R15
 0016	     421E	MOV &18,R14
 0018	     0012 @i
 001A	     531E	ADD #1,R14
 001C	     5E0E	ADD R14,R14
 001E	     4E9F	MOV 0(R14),32(R15)
 0020	     0000 @v
 0022	     0020 @v
 0024	     421F	MOV &24,R15
 0026	     0018 @i
 0028	     5F0F	ADD R15,R15; 2i
 002A	     4F0E	MOV R15,R14; 2i
 002C	     5E0E	ADD R14,R14; 4i
 002E	     5E0F	ADD R14,R15; 6i
 0030	     421E	MOV &38,R14
 0032	     0026 @i
 0034	     531E	ADD #1,R14
 0036	     5E0E	ADD R14,R14
 0038	     4E0D	MOV R14,R13
 003A	     5D0D	ADD R13,R13
 003C	     5D0E	ADD R13,R14
 003E	     503E	ADD #0,R14
 0040	     0000 (@r)
 0042	     503F	ADD #64,R15
 0044	     0040 (@r)
 0046	     403D	MOV #3,R13
 0048	     0003
 004A	     4EBF	MOV @R14+,0(R15)
 004C	     0000
 004E	     532F	ADD #2,R15
 0050	     831D	SUB #1,R13
 0052	     23FB	JNE $-8, goes to  004A
 0054	     4130	RET
