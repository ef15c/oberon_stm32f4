MODULE Types;

  TYPE procedure* = PROCEDURE;
    PPROC* = RECORD p*: PROCEDURE END;

END Types.

OMSPTool.DecObj Types.mpc
decode Types.mpc
Types 5D7B970E
imports:

section     0	d    8	PPROC
 02 00 FF FF FF FF FF FF
fixups:

section     1	c    2	module body
 0000	     4130	RET
fixups:

section     2	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    1    0

OMSPTool.DecSym Types.sms
decode Types.sms
Types 5D7B970E  3
   5 procedure [19  form = 7 [0  form = 10 [^9] UR FFF0()]]()
   5 PPROC [20  form = 13 [^9]{  exno = 1  extlev = 0  size = 2 { p [0  form = 7 [0  form = 10 [^9] UR FFF0()]]   0}]()
