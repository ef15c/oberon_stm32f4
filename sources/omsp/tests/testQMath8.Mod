MODULE testQMath8;
  IMPORT Q := QMath8;

  VAR q: Q.q;

BEGIN q := Q.atoQ("0.5"); q := Q.atoQ("100")
END testQMath8.

OMSPL.Link 32 4000H 200H testQMath8 ~
