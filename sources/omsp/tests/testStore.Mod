MODULE testStore;
  TYPE string = ARRAY 10 OF CHAR; vector = ARRAY 5 OF INTEGER;

  VAR s,t: string; v,u: vector; i: INTEGER;

  PROCEDURE p*(a: ARRAY OF CHAR; c: string; VAR x:ARRAY OF CHAR; VAR z: string );
    VAR j: INTEGER;
  BEGIN j := j*3; z := c; z := s; s := z; x[j] := a[1]; x[j] := s[1]; z[j] := a[1]
  END p;

  PROCEDURE q*(b: ARRAY OF INTEGER; d: vector; VAR y: ARRAY OF INTEGER; VAR t: vector );
    VAR j: INTEGER;
  BEGIN t := d; t := v; v := t; y[j] := b[1]; y[j] := v[1]; t[j] := b[1]
  END q;

  PROCEDURE p0*(a: ARRAY OF CHAR*; c: string*; VAR x:ARRAY OF CHAR*; VAR z: string* );
    VAR j: INTEGER*;
  BEGIN j := j*3; z := c; z := s; s := z; x[j] := a[1]; x[j] := s[1]; z[j] := a[1]
  END p0;

  PROCEDURE q0*(b: ARRAY OF INTEGER*; d: vector*; VAR y: ARRAY OF INTEGER*; VAR t: vector* );
    VAR j: INTEGER*;
  BEGIN t := d; t := v; v := t; y[j] := b[1]; y[j] := v[1]; t[j] := b[1]
  END q0;

BEGIN i := i*3; s := t; s[i] := s[1]; u := v; v[i] := v[1]
END testStore.

OMSPP.Compile testStore.Mod/s~
OMSPTool.DecObj testStore.mpc

no traps:
decode testStore.mpc
testStore 0BDF80CE
imports:

section     0	r   10	s
fixups:

section     1	r   10	t
fixups:

section     2	r   10	v
fixups:

section     3	r   10	u
fixups:

section     4	r    2	i
fixups:

section     5	c  128	p
 0000	     8321	SUB #2,SP
 0002	     412F	MOV @SP,R15
 0004	     4F0E	MOV R15,R14
 0006	     5E0E	ADD R14,R14
 0008	     5E0F	ADD R14,R15
 000A	     4F81	MOV R15,0(SP)
 000C	     0000
 000E	     411F	MOV 10(SP),R15
 0010	     000A
 0012	     411E	MOV 4(SP),R14
 0014	     0004
 0016	     403D	MOV #5,R13
 0018	     0005
 001A	     4FBE	MOV @R15+,0(R14)
 001C	     0000
 001E	     532E	ADD #2,R14
 0020	     831D	SUB #1,R13
 0022	     23FB	JNE $-8, goes to  001A
 0024	     403F	MOV #0,R15
 0026	     0000
 0028	     411E	MOV 4(SP),R14
 002A	     0004
 002C	     403D	MOV #5,R13
 002E	     0005
 0030	     4FBE	MOV @R15+,0(R14)
 0032	     0000
 0034	     532E	ADD #2,R14
 0036	     831D	SUB #1,R13
 0038	     23FB	JNE $-8, goes to  0030
 003A	     411F	MOV 4(SP),R15
 003C	     0004
 003E	     403E	MOV #39,R14
 0040	     0027
 0042	     403D	MOV #5,R13
 0044	     0005
 0046	     4FBE	MOV @R15+,0(R14)
 0048	     0000
 004A	     532E	ADD #2,R14
 004C	     831D	SUB #1,R13
 004E	     23FB	JNE $-8, goes to  0046
 0050	     412F	MOV @SP,R15
 0052	     511F	ADD 6(SP),R15
 0054	     0006
 0056	     411E	MOV 12(SP),R14
 0058	     000C
 005A	     4EDF	MOV.B 1(R14),0(R15)
 005C	     0001
 005E	     0000
 0060	     412F	MOV @SP,R15
 0062	     511F	ADD 6(SP),R15
 0064	     0006
 0066	     42DF	MOV.B &0,0(R15)
 0068	     0000
 006A	     0000
 006C	     412F	MOV @SP,R15
 006E	     511F	ADD 4(SP),R15
 0070	     0004
 0072	     411E	MOV 12(SP),R14
 0074	     000C
 0076	     4EDF	MOV.B 1(R14),0(R15)
 0078	     0001
 007A	     0000
 007C	     5321	ADD #2,SP
 007E	     4130	RET
fixups:
 0069	s0.0+1
 0041	s0.0

section     6	c  122	q
 0000	     8321	SUB #2,SP
 0002	     411F	MOV 10(SP),R15
 0004	     000A
 0006	     411E	MOV 4(SP),R14
 0008	     0004
 000A	     403D	MOV #5,R13
 000C	     0005
 000E	     4FBE	MOV @R15+,0(R14)
 0010	     0000
 0012	     532E	ADD #2,R14
 0014	     831D	SUB #1,R13
 0016	     23FB	JNE $-8, goes to  000E
 0018	     403F	MOV #0,R15
 001A	     0000
 001C	     411E	MOV 4(SP),R14
 001E	     0004
 0020	     403D	MOV #5,R13
 0022	     0005
 0024	     4FBE	MOV @R15+,0(R14)
 0026	     0000
 0028	     532E	ADD #2,R14
 002A	     831D	SUB #1,R13
 002C	     23FB	JNE $-8, goes to  0024
 002E	     411F	MOV 4(SP),R15
 0030	     0004
 0032	     403E	MOV #27,R14
 0034	     001B
 0036	     403D	MOV #5,R13
 0038	     0005
 003A	     4FBE	MOV @R15+,0(R14)
 003C	     0000
 003E	     532E	ADD #2,R14
 0040	     831D	SUB #1,R13
 0042	     23FB	JNE $-8, goes to  003A
 0044	     412F	MOV @SP,R15
 0046	     5F0F	ADD R15,R15
 0048	     511F	ADD 6(SP),R15
 004A	     0006
 004C	     411E	MOV 12(SP),R14
 004E	     000C
 0050	     4E9F	MOV 2(R14),0(R15)
 0052	     0002
 0054	     0000
 0056	     412F	MOV @SP,R15
 0058	     5F0F	ADD R15,R15
 005A	     511F	ADD 6(SP),R15
 005C	     0006
 005E	     429F	MOV &0,0(R15)
 0060	     0000
 0062	     0000
 0064	     412F	MOV @SP,R15
 0066	     5F0F	ADD R15,R15
 0068	     511F	ADD 4(SP),R15
 006A	     0004
 006C	     411E	MOV 12(SP),R14
 006E	     000C
 0070	     4E9F	MOV 2(R14),0(R15)
 0072	     0002
 0074	     0000
 0076	     5321	ADD #2,SP
 0078	     4130	RET
fixups:
 0061	s0.2+2
 0035	s0.2

section     7	c  100	p0
 0000	     4A0B	MOV R10,R11
 0002	     4B0C	MOV R11,R12
 0004	     5C0C	ADD R12,R12
 0006	     5C0B	ADD R12,R11
 0008	     4B0A	MOV R11,R10
 000A	     460B	MOV R6,R11
 000C	     490C	MOV R9,R12
 000E	     403D	MOV #5,R13
 0010	     0005
 0012	     4BBC	MOV @R11+,0(R12)
 0014	     0000
 0016	     532C	ADD #2,R12
 0018	     831D	SUB #1,R13
 001A	     23FB	JNE $-8, goes to  0012
 001C	     403B	MOV #0,R11
 001E	     0000
 0020	     490C	MOV R9,R12
 0022	     403D	MOV #5,R13
 0024	     0005
 0026	     4BBC	MOV @R11+,0(R12)
 0028	     0000
 002A	     532C	ADD #2,R12
 002C	     831D	SUB #1,R13
 002E	     23FB	JNE $-8, goes to  0026
 0030	     490B	MOV R9,R11
 0032	     403C	MOV #31,R12
 0034	     001F
 0036	     403D	MOV #5,R13
 0038	     0005
 003A	     4BBC	MOV @R11+,0(R12)
 003C	     0000
 003E	     532C	ADD #2,R12
 0040	     831D	SUB #1,R13
 0042	     23FB	JNE $-8, goes to  003A
 0044	     4A0B	MOV R10,R11
 0046	     570B	ADD R7,R11
 0048	     44DB	MOV.B 1(R4),0(R11)
 004A	     0001
 004C	     0000
 004E	     4A0B	MOV R10,R11
 0050	     570B	ADD R7,R11
 0052	     42DB	MOV.B &0,0(R11)
 0054	     0000
 0056	     0000
 0058	     4A0B	MOV R10,R11
 005A	     590B	ADD R9,R11
 005C	     44DB	MOV.B 1(R4),0(R11)
 005E	     0001
 0060	     0000
 0062	     4130	RET
fixups:
 0055	s0.0+1
 0035	s0.0

section     8	c   96	q0
 0000	     460B	MOV R6,R11
 0002	     490C	MOV R9,R12
 0004	     403D	MOV #5,R13
 0006	     0005
 0008	     4BBC	MOV @R11+,0(R12)
 000A	     0000
 000C	     532C	ADD #2,R12
 000E	     831D	SUB #1,R13
 0010	     23FB	JNE $-8, goes to  0008
 0012	     403B	MOV #0,R11
 0014	     0000
 0016	     490C	MOV R9,R12
 0018	     403D	MOV #5,R13
 001A	     0005
 001C	     4BBC	MOV @R11+,0(R12)
 001E	     0000
 0020	     532C	ADD #2,R12
 0022	     831D	SUB #1,R13
 0024	     23FB	JNE $-8, goes to  001C
 0026	     490B	MOV R9,R11
 0028	     403C	MOV #21,R12
 002A	     0015
 002C	     403D	MOV #5,R13
 002E	     0005
 0030	     4BBC	MOV @R11+,0(R12)
 0032	     0000
 0034	     532C	ADD #2,R12
 0036	     831D	SUB #1,R13
 0038	     23FB	JNE $-8, goes to  0030
 003A	     4A0B	MOV R10,R11
 003C	     5B0B	ADD R11,R11
 003E	     570B	ADD R7,R11
 0040	     449B	MOV 2(R4),0(R11)
 0042	     0002
 0044	     0000
 0046	     4A0B	MOV R10,R11
 0048	     5B0B	ADD R11,R11
 004A	     570B	ADD R7,R11
 004C	     429B	MOV &0,0(R11)
 004E	     0000
 0050	     0000
 0052	     4A0B	MOV R10,R11
 0054	     5B0B	ADD R11,R11
 0056	     590B	ADD R9,R11
 0058	     449B	MOV 2(R4),0(R11)
 005A	     0002
 005C	     0000
 005E	     4130	RET
fixups:
 004F	s0.2+2
 002B	s0.2

section     9	c   70	module body
 0000	     421F	MOV &0,R15
 0002	     0000
 0004	     4F0E	MOV R15,R14
 0006	     5E0E	ADD R14,R14
 0008	     5E0F	ADD R14,R15
 000A	     4F82	MOV R15,&3
 000C	     0003
 000E	     403F	MOV #0,R15
 0010	     0000
 0012	     403E	MOV #5,R14
 0014	     0005
 0016	     4FBF	MOV @R15+,0(R15)
 0018	     0000
 001A	     831E	SUB #1,R14
 001C	     23FC	JNE $-6, goes to  0016
 001E	     421F	MOV &13,R15
 0020	     000D
 0022	     42DF	MOV.B &0,0(R15)
 0024	     0000
 0026	     0000
 0028	     403F	MOV #0,R15
 002A	     0000
 002C	     403E	MOV #5,R14
 002E	     0005
 0030	     4FBF	MOV @R15+,0(R15)
 0032	     0000
 0034	     831E	SUB #1,R14
 0036	     23FC	JNE $-6, goes to  0030
 0038	     421F	MOV &33,R15
 003A	     0021
 003C	     5F0F	ADD R15,R15
 003E	     429F	MOV &0,43(R15)
 0040	     0000
 0042	     002B
 0044	     4130	RET
fixups:
 0041	s0.2+2
 0033	s0.3-2-s0.2
 0043	s0.2
 0027	s0.0
 0025	s0.0+1
 0019	s0.0-2-s0.1
 0011	s0.1
 003B	s0.4

section    10	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    9    5    6    7    8

MODULE testStore;
  IMPORT Traps;

  TYPE string = ARRAY 10 OF CHAR; vector = ARRAY 5 OF INTEGER;

  VAR s,t: string; v,u: vector; i: INTEGER;

  PROCEDURE p*(a: ARRAY OF CHAR; c: string; VAR x:ARRAY OF CHAR; VAR z: string );
    VAR j: INTEGER;
  BEGIN j := j*3; z := c; z := s; s := z; x[j] := a[1]; x[j] := s[1]; z[j] := a[1]
  END p;

  PROCEDURE q*(b: ARRAY OF INTEGER; d: vector; VAR y: ARRAY OF INTEGER; VAR t: vector );
    VAR j: INTEGER;
  BEGIN t := d; t := v; v := t; y[j] := b[1]; y[j] := v[1]; t[j] := b[1]
  END q;

  PROCEDURE p0*(a: ARRAY OF CHAR*; c: string*; VAR x:ARRAY OF CHAR*; VAR z: string* );
    VAR j: INTEGER*;
  BEGIN j := j*3; z := c; z := s; s := z; x[j] := a[1]; x[j] := s[1]; z[j] := a[1]
  END p0;

  PROCEDURE q0*(b: ARRAY OF INTEGER*; d: vector*; VAR y: ARRAY OF INTEGER*; VAR t: vector* );
    VAR j: INTEGER*;
  BEGIN t := d; t := v; v := t; y[j] := b[1]; y[j] := v[1]; t[j] := b[1]
  END q0;

BEGIN i := i*3; s := t; s[i] := s[1]; u := v; v[i] := v[1]
END testStore.

OMSPP.Compile @/s
OMSPTool.DecObj testStore.mpc

with traps:
decode testStore.mpc
testStore 0BDF80CE
imports:
	Traps CE0C2A28

section     0	r   10	s
fixups:

section     1	r   10	t
fixups:

section     2	r   10	v
fixups:

section     3	r   10	u
fixups:

section     4	r    2	i
fixups:

section     5	c  184	p
 0000	     8321	SUB #2,SP
 0002	     412F	MOV @SP,R15
 0004	     4F0E	MOV R15,R14
 0006	     5E0E	ADD R14,R14
 0008	     5E0F	ADD R14,R15
 000A	     4F81	MOV R15,0(SP)
 000C	     0000
 000E	     411F	MOV 10(SP),R15
 0010	     000A
 0012	     411E	MOV 4(SP),R14
 0014	     0004
 0016	     403D	MOV #5,R13
 0018	     0005
 001A	     4FBE	MOV @R15+,0(R14)
 001C	     0000
 001E	     532E	ADD #2,R14
 0020	     831D	SUB #1,R13
 0022	     23FB	JNE $-8, goes to  001A
 0024	     403F	MOV #0,R15
 0026	     0000
 0028	     411E	MOV 4(SP),R14
 002A	     0004
 002C	     403D	MOV #5,R13
 002E	     0005
 0030	     4FBE	MOV @R15+,0(R14)
 0032	     0000
 0034	     532E	ADD #2,R14
 0036	     831D	SUB #1,R13
 0038	     23FB	JNE $-8, goes to  0030
 003A	     411F	MOV 4(SP),R15
 003C	     0004
 003E	     403E	MOV #39,R14
 0040	     0027
 0042	     403D	MOV #5,R13
 0044	     0005
 0046	     4FBE	MOV @R15+,0(R14)
 0048	     0000
 004A	     532E	ADD #2,R14
 004C	     831D	SUB #1,R13
 004E	     23FB	JNE $-8, goes to  0046
 0050	     9191	CMP 8(SP),0(SP)
 0052	     0008
 0054	     0000
 0056	     2802	JNC $+6, goes to  005C
 0058	     12B0	CALL #0
 005A	     0000
 005C	     412F	MOV @SP,R15
 005E	     511F	ADD 6(SP),R15
 0060	     0006
 0062	     431E	MOV #1,R14
 0064	     911E	CMP 14(SP),R14
 0066	     000E
 0068	     2802	JNC $+6, goes to  006E
 006A	     12B0	CALL #91
 006C	     005B
 006E	     511E	ADD 12(SP),R14
 0070	     000C
 0072	     4EEF	MOV.B @R14,0(R15)
 0074	     0000
 0076	     9191	CMP 8(SP),0(SP)
 0078	     0008
 007A	     0000
 007C	     2802	JNC $+6, goes to  0082
 007E	     12B0	CALL #109
 0080	     006D
 0082	     412F	MOV @SP,R15
 0084	     511F	ADD 6(SP),R15
 0086	     0006
 0088	     42DF	MOV.B &0,0(R15)
 008A	     0000
 008C	     0000
 008E	     90B1	CMP #10,0(SP)
 0090	     000A
 0092	     0000
 0094	     2802	JNC $+6, goes to  009A
 0096	     12B0	CALL #129
 0098	     0081
 009A	     412F	MOV @SP,R15
 009C	     511F	ADD 4(SP),R15
 009E	     0004
 00A0	     431E	MOV #1,R14
 00A2	     911E	CMP 14(SP),R14
 00A4	     000E
 00A6	     2802	JNC $+6, goes to  00AC
 00A8	     12B0	CALL #153
 00AA	     0099
 00AC	     511E	ADD 12(SP),R14
 00AE	     000C
 00B0	     4EEF	MOV.B @R14,0(R15)
 00B2	     0000
 00B4	     5321	ADD #2,SP
 00B6	     4130	RET
fixups:
 008B	s0.0+1
 00AB	s1.1
 0041	s0.0

section     6	c  182	q
 0000	     8321	SUB #2,SP
 0002	     411F	MOV 10(SP),R15
 0004	     000A
 0006	     411E	MOV 4(SP),R14
 0008	     0004
 000A	     403D	MOV #5,R13
 000C	     0005
 000E	     4FBE	MOV @R15+,0(R14)
 0010	     0000
 0012	     532E	ADD #2,R14
 0014	     831D	SUB #1,R13
 0016	     23FB	JNE $-8, goes to  000E
 0018	     403F	MOV #0,R15
 001A	     0000
 001C	     411E	MOV 4(SP),R14
 001E	     0004
 0020	     403D	MOV #5,R13
 0022	     0005
 0024	     4FBE	MOV @R15+,0(R14)
 0026	     0000
 0028	     532E	ADD #2,R14
 002A	     831D	SUB #1,R13
 002C	     23FB	JNE $-8, goes to  0024
 002E	     411F	MOV 4(SP),R15
 0030	     0004
 0032	     403E	MOV #27,R14
 0034	     001B
 0036	     403D	MOV #5,R13
 0038	     0005
 003A	     4FBE	MOV @R15+,0(R14)
 003C	     0000
 003E	     532E	ADD #2,R14
 0040	     831D	SUB #1,R13
 0042	     23FB	JNE $-8, goes to  003A
 0044	     9191	CMP 8(SP),0(SP)
 0046	     0008
 0048	     0000
 004A	     2802	JNC $+6, goes to  0050
 004C	     12B0	CALL #0
 004E	     0000
 0050	     412F	MOV @SP,R15
 0052	     5F0F	ADD R15,R15
 0054	     511F	ADD 6(SP),R15
 0056	     0006
 0058	     431E	MOV #1,R14
 005A	     911E	CMP 14(SP),R14
 005C	     000E
 005E	     2802	JNC $+6, goes to  0064
 0060	     12B0	CALL #79
 0062	     004F
 0064	     5E0E	ADD R14,R14
 0066	     511E	ADD 12(SP),R14
 0068	     000C
 006A	     4EAF	MOV @R14,0(R15)
 006C	     0000
 006E	     9191	CMP 8(SP),0(SP)
 0070	     0008
 0072	     0000
 0074	     2802	JNC $+6, goes to  007A
 0076	     12B0	CALL #99
 0078	     0063
 007A	     412F	MOV @SP,R15
 007C	     5F0F	ADD R15,R15
 007E	     511F	ADD 6(SP),R15
 0080	     0006
 0082	     429F	MOV &0,0(R15)
 0084	     0000
 0086	     0000
 0088	     90B1	CMP #5,0(SP)
 008A	     0005
 008C	     0000
 008E	     2802	JNC $+6, goes to  0094
 0090	     12B0	CALL #121
 0092	     0079
 0094	     412F	MOV @SP,R15
 0096	     5F0F	ADD R15,R15
 0098	     511F	ADD 4(SP),R15
 009A	     0004
 009C	     431E	MOV #1,R14
 009E	     911E	CMP 14(SP),R14
 00A0	     000E
 00A2	     2802	JNC $+6, goes to  00A8
 00A4	     12B0	CALL #147
 00A6	     0093
 00A8	     5E0E	ADD R14,R14
 00AA	     511E	ADD 12(SP),R14
 00AC	     000C
 00AE	     4EAF	MOV @R14,0(R15)
 00B0	     0000
 00B2	     5321	ADD #2,SP
 00B4	     4130	RET
fixups:
 0085	s0.2+2
 00A7	s1.1
 0035	s0.2

section     7	c  146	p0
 0000	     4A0B	MOV R10,R11
 0002	     4B0C	MOV R11,R12
 0004	     5C0C	ADD R12,R12
 0006	     5C0B	ADD R12,R11
 0008	     4B0A	MOV R11,R10
 000A	     460B	MOV R6,R11
 000C	     490C	MOV R9,R12
 000E	     403D	MOV #5,R13
 0010	     0005
 0012	     4BBC	MOV @R11+,0(R12)
 0014	     0000
 0016	     532C	ADD #2,R12
 0018	     831D	SUB #1,R13
 001A	     23FB	JNE $-8, goes to  0012
 001C	     403B	MOV #0,R11
 001E	     0000
 0020	     490C	MOV R9,R12
 0022	     403D	MOV #5,R13
 0024	     0005
 0026	     4BBC	MOV @R11+,0(R12)
 0028	     0000
 002A	     532C	ADD #2,R12
 002C	     831D	SUB #1,R13
 002E	     23FB	JNE $-8, goes to  0026
 0030	     490B	MOV R9,R11
 0032	     403C	MOV #31,R12
 0034	     001F
 0036	     403D	MOV #5,R13
 0038	     0005
 003A	     4BBC	MOV @R11+,0(R12)
 003C	     0000
 003E	     532C	ADD #2,R12
 0040	     831D	SUB #1,R13
 0042	     23FB	JNE $-8, goes to  003A
 0044	     980A	CMP R8,R10
 0046	     2802	JNC $+6, goes to  004C
 0048	     12B0	CALL #0
 004A	     0000
 004C	     4A0B	MOV R10,R11
 004E	     570B	ADD R7,R11
 0050	     431C	MOV #1,R12
 0052	     950C	CMP R5,R12
 0054	     2802	JNC $+6, goes to  005A
 0056	     12B0	CALL #75
 0058	     004B
 005A	     540C	ADD R4,R12
 005C	     4CEB	MOV.B @R12,0(R11)
 005E	     0000
 0060	     980A	CMP R8,R10
 0062	     2802	JNC $+6, goes to  0068
 0064	     12B0	CALL #89
 0066	     0059
 0068	     4A0B	MOV R10,R11
 006A	     570B	ADD R7,R11
 006C	     42DB	MOV.B &0,0(R11)
 006E	     0000
 0070	     0000
 0072	     903A	CMP #10,R10
 0074	     000A
 0076	     2802	JNC $+6, goes to  007C
 0078	     12B0	CALL #103
 007A	     0067
 007C	     4A0B	MOV R10,R11
 007E	     590B	ADD R9,R11
 0080	     431C	MOV #1,R12
 0082	     950C	CMP R5,R12
 0084	     2802	JNC $+6, goes to  008A
 0086	     12B0	CALL #123
 0088	     007B
 008A	     540C	ADD R4,R12
 008C	     4CEB	MOV.B @R12,0(R11)
 008E	     0000
 0090	     4130	RET
fixups:
 006F	s0.0+1
 0089	s1.1
 0035	s0.0

section     8	c  146	q0
 0000	     460B	MOV R6,R11
 0002	     490C	MOV R9,R12
 0004	     403D	MOV #5,R13
 0006	     0005
 0008	     4BBC	MOV @R11+,0(R12)
 000A	     0000
 000C	     532C	ADD #2,R12
 000E	     831D	SUB #1,R13
 0010	     23FB	JNE $-8, goes to  0008
 0012	     403B	MOV #0,R11
 0014	     0000
 0016	     490C	MOV R9,R12
 0018	     403D	MOV #5,R13
 001A	     0005
 001C	     4BBC	MOV @R11+,0(R12)
 001E	     0000
 0020	     532C	ADD #2,R12
 0022	     831D	SUB #1,R13
 0024	     23FB	JNE $-8, goes to  001C
 0026	     490B	MOV R9,R11
 0028	     403C	MOV #21,R12
 002A	     0015
 002C	     403D	MOV #5,R13
 002E	     0005
 0030	     4BBC	MOV @R11+,0(R12)
 0032	     0000
 0034	     532C	ADD #2,R12
 0036	     831D	SUB #1,R13
 0038	     23FB	JNE $-8, goes to  0030
 003A	     980A	CMP R8,R10
 003C	     2802	JNC $+6, goes to  0042
 003E	     12B0	CALL #0
 0040	     0000
 0042	     4A0B	MOV R10,R11
 0044	     5B0B	ADD R11,R11
 0046	     570B	ADD R7,R11
 0048	     431C	MOV #1,R12
 004A	     950C	CMP R5,R12
 004C	     2802	JNC $+6, goes to  0052
 004E	     12B0	CALL #65
 0050	     0041
 0052	     5C0C	ADD R12,R12
 0054	     540C	ADD R4,R12
 0056	     4CAB	MOV @R12,0(R11)
 0058	     0000
 005A	     980A	CMP R8,R10
 005C	     2802	JNC $+6, goes to  0062
 005E	     12B0	CALL #81
 0060	     0051
 0062	     4A0B	MOV R10,R11
 0064	     5B0B	ADD R11,R11
 0066	     570B	ADD R7,R11
 0068	     429B	MOV &0,0(R11)
 006A	     0000
 006C	     0000
 006E	     903A	CMP #5,R10
 0070	     0005
 0072	     2802	JNC $+6, goes to  0078
 0074	     12B0	CALL #97
 0076	     0061
 0078	     4A0B	MOV R10,R11
 007A	     5B0B	ADD R11,R11
 007C	     590B	ADD R9,R11
 007E	     431C	MOV #1,R12
 0080	     950C	CMP R5,R12
 0082	     2802	JNC $+6, goes to  0088
 0084	     12B0	CALL #119
 0086	     0077
 0088	     5C0C	ADD R12,R12
 008A	     540C	ADD R4,R12
 008C	     4CAB	MOV @R12,0(R11)
 008E	     0000
 0090	     4130	RET
fixups:
 006B	s0.2+2
 0087	s1.1
 002B	s0.2

section     9	c   94	module body
 0000	     421F	MOV &0,R15
 0002	     0000
 0004	     4F0E	MOV R15,R14
 0006	     5E0E	ADD R14,R14
 0008	     5E0F	ADD R14,R15
 000A	     4F82	MOV R15,&3
 000C	     0003
 000E	     403F	MOV #0,R15
 0010	     0000
 0012	     403E	MOV #5,R14
 0014	     0005
 0016	     4FBF	MOV @R15+,0(R15)
 0018	     0000
 001A	     831E	SUB #1,R14
 001C	     23FC	JNE $-6, goes to  0016
 001E	     90B2	CMP #10,&13
 0020	     000A
 0022	     000D
 0024	     2802	JNC $+6, goes to  002A
 0026	     12B0	CALL #0
 0028	     0000
 002A	     421F	MOV &35,R15
 002C	     0023
 002E	     42DF	MOV.B &0,0(R15)
 0030	     0000
 0032	     0000
 0034	     403F	MOV #0,R15
 0036	     0000
 0038	     403E	MOV #5,R14
 003A	     0005
 003C	     4FBF	MOV @R15+,0(R15)
 003E	     0000
 0040	     831E	SUB #1,R14
 0042	     23FC	JNE $-6, goes to  003C
 0044	     90B2	CMP #5,&45
 0046	     0005
 0048	     002D
 004A	     2802	JNC $+6, goes to  0050
 004C	     12B0	CALL #41
 004E	     0029
 0050	     421F	MOV &73,R15
 0052	     0049
 0054	     5F0F	ADD R15,R15
 0056	     429F	MOV &0,55(R15)
 0058	     0000
 005A	     0037
 005C	     4130	RET
fixups:
 0059	s0.2+2
 003F	s0.3-2-s0.2
 005B	s0.2
 0033	s0.0
 0031	s0.0+1
 004F	s1.1
 0019	s0.0-2-s0.1
 0011	s0.1
 0053	s0.4

section    10	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    9    5    6    7    8
