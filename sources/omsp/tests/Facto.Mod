MODULE Facto;
  IMPORT Arith;

  VAR res: INTEGER;

  PROCEDURE f*(n: INTEGER): INTEGER;
    VAR r: INTEGER;
  BEGIN
    IF n <= 0 THEN r := 1 ELSE r := n*f(n-1) END

    RETURN r
  END f;

BEGIN res := f(5)
END Facto.

OMSPTool.DecObj Facto.mpc
decode Facto.mpc
Facto BEC114C3 Flash    66
imports:
	Arith BDF2CFB8
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0032 0000
fixup procedures chains
 0038     0	 0000
 0026     1	 0001
fixup handlers chains
fixup data chains
 003E     0	 0000
fixup constants chains
fixup types chains
entry =  0032
code    66
 0000	     8321	SUB #2,SP
 0002	     430F	MOV #0,R15
 0004	     911F	CMP 4(SP),R15
 0006	     0004
 0008	     3803	JL #3, goes to  0010
 000A	     4391	MOV #1,0(SP)
 000C	     0000
 000E	     3C0E	JMP #14, goes to  002C
 0010	     411F	MOV 4(SP),R15
 0012	     0004
 0014	     831F	SUB #1,R15
 0016	     120F	PUSH R15
 0018	     12B0	CALL #0
 001A	     0000
 001C	     5321	ADD #2,SP
 001E	     4115	MOV 4(SP),R5
 0020	     0004
 0022	     4F06	MOV R15,R6
 0024	     12B0	CALL #0
 0026	     0000
 0028	     4481	MOV R4,0(SP)
 002A	     0000
 002C	     412F	MOV @SP,R15
 002E	     5321	ADD #2,SP
 0030	     4130	RET
 0032	     1230	PUSH #5
 0034	     0005
 0036	     12B0	CALL #26
 0038	     001A
 003A	     5321	ADD #2,SP
 003C	     4F82	MOV R15,&0
 003E	     0000
 0040	     4130	RET
