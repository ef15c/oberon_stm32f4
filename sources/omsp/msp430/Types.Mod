MODULE Types;

  TYPE procedure* = PROCEDURE;
    PPROC* = RECORD p*: PROCEDURE END;

END Types.

OMSPTool.DecSym Types.sms
decode Types.sms
Types 03DB4129  1
   5 procedure [19  form = 10  size = 2 [^9] UR FFF0()]()
   5 PPROC [20  form = 13  size = 2 [^9]{  exno = 1  extlev = 0 { p [0  form = 10  size = 2 [^9] UR FFF0()]   0}]()
