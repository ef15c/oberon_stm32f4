MODULE bugOMSP;
  IMPORT PT := PosixTime, Arith;

  CONST TIME=352249145+86400;
  VAR time: PT.TimeDesc; tm: PT.TmDesc;

BEGIN time.h := TIME DIV 10000H; time.l := TIME MOD 10000H;
PT.localtime(PTR(PT.Time, time), PTR(PT.Tm, tm))
END bugOMSP.

OMSPP.Compile bugOMSP.Mod/s~
OMSPL.Link 32 4000H 200H bugOMSP~

bugOMSP.txt bugOMSP.map

OMSPTool.DecSym bugOMSP.sms

OMSPTool.DecObj bugOMSP.mpc
