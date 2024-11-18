MODULE QMath8;
  IMPORT Arith;

  TYPE q* = INTEGER;

  PROCEDURE atoQPL*(string: ARRAY OF CHAR; pos, len: INTEGER): q;
    VAR r, div: INTEGER; neg: BOOLEAN;
  BEGIN r := 0; IF string[pos] = "-" THEN neg := TRUE; INC(pos); DEC(len) ELSE neg := FALSE END;
    WHILE (len > 0) & (string[pos] >= "0") & (string[pos] <= "9") DO r := r*10; INC(r, ORD(string[pos]) - ORD("0")); INC(pos); DEC(len) END; SWPB(r);
    IF len > 0 THEN
      IF string[pos] = "." THEN INC(pos); DEC(len); div := 10;
        WHILE (len > 0) & (string[pos] >= "0") & (string[pos] <= "9") DO
          IF div < 100H*10 THEN
            INC(r, (ORD(string[pos]) - ORD("0")) * 100H DIV div); div := div*10
          END;
          INC(pos); DEC(len)
        END;
        IF len > 0 THEN r := 0 END
      ELSE r := 0 (*invalid character*)
      END
    END;
    IF neg THEN XOR(r, -1); INC(r) END
    RETURN r
  END atoQPL;

  PROCEDURE atoQ*(string: ARRAY OF CHAR): q;
    VAR r, len: INTEGER;
  BEGIN len := 0; WHILE string[len] # 0X DO INC(len) END;
    r := atoQPL(string, 0, len)

    RETURN r
  END atoQ;

END QMath8.

OMSPTool.DecObj QMath8.mpc
