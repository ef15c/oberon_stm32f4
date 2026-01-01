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

OMSPL.Link 32 4000H 200H Facto ~
  linking Arith Facto
    flash  102, data    2, stack  510 bytes

OMSPTool.DecSym Facto.sms
   9 f [0  form = 10 [^4] UR 8070( class = 2 [^4])]     1

OMSPTool.DecObj Facto.mpc
decode Facto.mpc
Facto 309DBBD6
imports:
	Arith CA33A8B5

section     0	r    2	res
fixups:

section     1	c   50	f
 0000	     8321	SUB #2,SP
 0002	     430F	MOV #0,R15
 0004	     911F	CMP 4(SP),R15
 0006	     0004
 0008	     3803	JL $+8, goes to  0010
 000A	     4391	MOV #1,0(SP)
 000C	     0000
 000E	     3C0E	JMP $+30, goes to  002C
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
fixups:
 0027	s1.1
 001B	s0.1

section     2	c   16	module body
 0000	     1230	PUSH #5
 0002	     0005
 0004	     12B0	CALL #0
 0006	     0000
 0008	     5321	ADD #2,SP
 000A	     4F82	MOV R15,&0
 000C	     0000
 000E	     4130	RET
fixups:
 000D	s0.0
 0007	s0.1

section     3	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    2    1
