MODULE testFor;

  PROCEDURE p;
    VAR i,j: INTEGER;
  BEGIN
    FOR i := 1 TO 10 DO j := 2*i END;
    FOR i := 10 TO 1 BY -2 DO END
  END p;

END testFor.

OMSPTool.DecObj testFor.mpc

not leaf:
decode testFor.mpc
testFor 74E5D4BB    60
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0036
fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0036
code    56
 0000	     8221	SUB #4,SP
 0002	     4391	MOV #1,2(SP)
 0004	     0002
 0006	     403F	MOV #10,R15
 0008	     000A
 000A	     911F	CMP 2(SP),R15
 000C	     0002
 000E	     3808	JL #8, goes to  0020
 0010	     411F	MOV 2(SP),R15
 0012	     0002
 0014	     5F0F	ADD R15,R15
 0016	     4F81	MOV R15,0(SP)
 0018	     0000
 001A	     5391	ADD #1,2(SP)
 001C	     0002
 001E	     3FF3	JMP #-13, goes to  0006
 0020	     40B1	MOV #10,2(SP)
 0022	     000A
 0024	     0002
 0026	     9391	CMP #1,2(SP)
 0028	     0002
 002A	     3803	JL #3, goes to  0032
 002C	     83A1	SUB #2,2(SP)
 002E	     0002
 0030	     3FFA	JMP #-6, goes to  0026
 0032	     5221	ADD #4,SP
 0034	     4130	RET
 0036	     4130	RET

leaf:
decode testFor.mpc
testFor 74E5D4BB    40
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0022
fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0022
code    36
 0000	     4314	MOV #1,R4
 0002	     4036	MOV #10,R6
 0004	     000A
 0006	     9406	CMP R4,R6
 0008	     3805	JL #5, goes to  0014
 000A	     4406	MOV R4,R6
 000C	     5606	ADD R6,R6
 000E	     4605	MOV R6,R5
 0010	     5314	ADD #1,R4
 0012	     3FF7	JMP #-9, goes to  0002
 0014	     4034	MOV #10,R4
 0016	     000A
 0018	     9314	CMP #1,R4
 001A	     3802	JL #2, goes to  0020
 001C	     8324	SUB #2,R4
 001E	     3FFC	JMP #-4, goes to  0018
 0020	     4130	RET
 0022	     4130	RET
