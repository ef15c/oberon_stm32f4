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

OMSPTool.DecObj testArray.mpc
decode testArray.mpc
testArray D5E6D82E Flash   118
imports:
type descriptors
 0006 FFFF FFFF FFFF
data    70
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0000
fixup procedures chains
fixup handlers chains
fixup data chains
 004C     0	 0044
 0012     0	 0000
 0030     0	 000A
 005A     0	 0014
fixup constants chains
fixup types chains
entry =  0000
code   110
 0000	     421F	MOV &0,R15
 0002	     0000
 0004	     403E	MOV #0,R14
 0006	     0000
 0008	     5E0F	ADD R14,R15
 000A	     421E	MOV &2,R14
 000C	     0002
 000E	     531E	ADD #1,R14
 0010	     403D	MOV #6,R13
 0012	     0006
 0014	     5D0E	ADD R13,R14
 0016	     4EEF	MOV.B @R14,0(R15)
 0018	     0000
 001A	     421F	MOV &12,R15
 001C	     000C
 001E	     5F0F	ADD R15,R15
 0020	     403E	MOV #0,R14
 0022	     0000
 0024	     5E0F	ADD R14,R15
 0026	     421E	MOV &28,R14
 0028	     001C
 002A	     531E	ADD #1,R14
 002C	     5E0E	ADD R14,R14
 002E	     403D	MOV #34,R13
 0030	     0022
 0032	     5D0E	ADD R13,R14
 0034	     4EAF	MOV @R14,0(R15)
 0036	     0000
 0038	     421F	MOV &40,R15
 003A	     0028
 003C	     5F0F	ADD R15,R15
 003E	     4F0E	MOV R15,R14
 0040	     5E0E	ADD R14,R14
 0042	     5E0F	ADD R14,R15
 0044	     403E	MOV #0,R14
 0046	     0000
 0048	     5E0F	ADD R14,R15
 004A	     421E	MOV &58,R14
 004C	     003A
 004E	     531E	ADD #1,R14
 0050	     5E0E	ADD R14,R14
 0052	     4E0D	MOV R14,R13
 0054	     5D0D	ADD R13,R13
 0056	     5D0E	ADD R13,R14
 0058	     403D	MOV #70,R13
 005A	     0046
 005C	     5D0E	ADD R13,R14
 005E	     403D	MOV #3,R13
 0060	     0003
 0062	     4EBF	MOV @R14+,0(R15)
 0064	     0000
 0066	     532F	ADD #2,R15
 0068	     831D	SUB #1,R13
 006A	     23FB	JNE #-5, goes to  0062
 006C	     4130	RET
