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

END testFor.

OMSPTool.DecObj testFor.mpc
decode testFor.mpc
testFor 16D8ACA3 Flash    86
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0054
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0054
code    86
 0000	     8221	SUB #4,SP
 0002	     4391	MOV #1,0(SP)
 0004	     0000
 0006	     403F	MOV #10,R15
 0008	     000A
 000A	     912F	CMP @SP,R15
 000C	     3807	JL #7, goes to  001C
 000E	     412F	MOV @SP,R15
 0010	     5F0F	ADD R15,R15
 0012	     4F81	MOV R15,2(SP)
 0014	     0002
 0016	     5391	ADD #1,0(SP)
 0018	     0000
 001A	     3FF5	JMP #-11, goes to  0006
 001C	     40B1	MOV #10,0(SP)
 001E	     000A
 0020	     0000
 0022	     9391	CMP #1,0(SP)
 0024	     0000
 0026	     3803	JL #3, goes to  002E
 0028	     83A1	SUB #2,0(SP)
 002A	     0000
 002C	     3FFA	JMP #-6, goes to  0022
 002E	     5221	ADD #4,SP
 0030	     4130	RET
 0032	     4314	MOV #1,R4
 0034	     4036	MOV #10,R6
 0036	     000A
 0038	     9406	CMP R4,R6
 003A	     3805	JL #5, goes to  0046
 003C	     4406	MOV R4,R6
 003E	     5606	ADD R6,R6
 0040	     4605	MOV R6,R5
 0042	     5314	ADD #1,R4
 0044	     3FF7	JMP #-9, goes to  0034
 0046	     4034	MOV #10,R4
 0048	     000A
 004A	     9314	CMP #1,R4
 004C	     3802	JL #2, goes to  0052
 004E	     8324	SUB #2,R4
 0050	     3FFC	JMP #-4, goes to  004A
 0052	     4130	RET
 0054	     4130	RET
