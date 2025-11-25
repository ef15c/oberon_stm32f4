MODULE testFor;

  PROCEDURE p;
    VAR i,j: INTEGER;
  BEGIN
    FOR i := 1 TO 10 DO j := 2*i END;
    FOR i := 10 TO 1 BY -2 DO END
  END p;

  PROCEDURE q;
    VAR i,j: INTEGER*;
  BEGIN
    FOR i := 1 TO 10 DO j := 2*i END;
    FOR i := 10 TO 1 BY -2 DO END
  END q;

BEGIN p; q
END testFor.

OMSPP.Compile testFor.Mod~
OMSPTool.DecObj testFor.mpc
decode testFor.mpc
testFor 1B9B8A7A
imports:

section     0	c   50	p
 0000	     8221	SUB #4,SP
 0002	     4391	MOV #1,0(SP)
 0004	     0000
 0006	     403F	MOV #10,R15
 0008	     000A
 000A	     912F	CMP @SP,R15
 000C	     3807	JL $+16, goes to  001C
 000E	     412F	MOV @SP,R15
 0010	     5F0F	ADD R15,R15
 0012	     4F81	MOV R15,2(SP)
 0014	     0002
 0016	     5391	ADD #1,0(SP)
 0018	     0000
 001A	     3FF5	JMP $-20, goes to  0006
 001C	     40B1	MOV #10,0(SP)
 001E	     000A
 0020	     0000
 0022	     9391	CMP #1,0(SP)
 0024	     0000
 0026	     3803	JL $+8, goes to  002E
 0028	     83A1	SUB #2,0(SP)
 002A	     0000
 002C	     3FFA	JMP $-10, goes to  0022
 002E	     5221	ADD #4,SP
 0030	     4130	RET
fixups:

section     1	c   34	q
 0000	     4314	MOV #1,R4
 0002	     4036	MOV #10,R6
 0004	     000A
 0006	     9406	CMP R4,R6
 0008	     3805	JL $+12, goes to  0014
 000A	     4406	MOV R4,R6
 000C	     5606	ADD R6,R6
 000E	     4605	MOV R6,R5
 0010	     5314	ADD #1,R4
 0012	     3FF7	JMP $-16, goes to  0002
 0014	     4034	MOV #10,R4
 0016	     000A
 0018	     9314	CMP #1,R4
 001A	     3802	JL $+6, goes to  0020
 001C	     8324	SUB #2,R4
 001E	     3FFC	JMP $-6, goes to  0018
 0020	     4130	RET
fixups:

section     2	c   10	module body
 0000	     12B0	CALL #0
 0002	     0000
 0004	     12B0	CALL #0
 0006	     0000
 0008	     4130	RET
fixups:
 0007	s0.1
 0003	s0.0

section     3	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    2
