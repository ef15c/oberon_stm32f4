MODULE testProc;

  PROCEDURE p*;
    PROCEDURE q;
    BEGIN q
    END q;
  BEGIN q; p
  END p;

BEGIN p
END testProc.

OMSPP.Compile testProc.Mod/s~

OMSPTool.DecSym testProc.sms
decode testProc.sms
testProc 28D01BD8  2
   9 p [0  form = 10 [^9] UR 0000()]     1

OMSPTool.DecObj testProc.mpc
decode testProc.mpc
testProc 75AC3E14
imports:

section     0	c    6	q
 0000	     12B0	CALL #0
 0002	     0000
 0004	     4130	RET
fixups:
 0003	s0.0

section     1	c   10	p
 0000	     12B0	CALL #0
 0002	     0000
 0004	     12B0	CALL #0
 0006	     0000
 0008	     4130	RET
fixups:
 0007	s0.1
 0003	s0.0

section     2	c    6	module body
 0000	     12B0	CALL #0
 0002	     0000
 0004	     4130	RET
fixups:
 0003	s0.1

section     3	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    2

MODULE testProc;
  PROCEDURE p;
    PROCEDURE q;
    BEGIN p
    END q;
  END p;
END testProc.

OMSPP.Compile @/
