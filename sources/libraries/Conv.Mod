MODULE Conv;

  PROCEDURE toHexa*(val: BYTE*): CHAR;
    VAR res: CHAR*;
  BEGIN
    IF val<10 THEN res := CHR(val + ORD("0"))
    ELSIF val<16 THEN res := CHR(val+(ORD("A")-10))
    ELSE res := "?"
	END

    RETURN res
  END toHexa;

END Conv.

OMSPTool.DecObj Conv.mpc
decode Conv.mpc
Conv B4CBC65B Flash    40
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0026 c 0000
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0026
code    40
 0000	     9075	CMP.B #10,R5
 0002	     000A
 0004	     2C05	JC $+12, goes to  0010
 0006	     4506	MOV R5,R6
 0008	     5076	ADD.B #48,R6
 000A	     0030
 000C	     4644	MOV.B R6,R4
 000E	     3C0A	JMP $+22, goes to  0024
 0010	     9075	CMP.B #16,R5
 0012	     0010
 0014	     2C05	JC $+12, goes to  0020
 0016	     4506	MOV R5,R6
 0018	     5076	ADD.B #55,R6
 001A	     0037
 001C	     4644	MOV.B R6,R4
 001E	     3C02	JMP $+6, goes to  0024
 0020	     4074	MOV.B #63,R4
 0022	     003F
 0024	     4130	RET
 0026	     4130	RET
