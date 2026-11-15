MODULE AOC2017Day18;
  IMPORT Texts, Oberon, U := AOCUtils, Log := SystemLog;

  CONST NB_PROGS = 2;

  TYPE 
    Argument = RECORD type: CHAR; r: BYTE; n: INTEGER END; (*type = "r" for register, "n" for number*)
    Instruction = RECORD op: CHAR; na: BYTE; a: ARRAY 2 OF Argument END;

  VAR W: Texts.Writer;
    MQ: ARRAY NB_PROGS, 100 OF LONGINT; head, tail: ARRAY NB_PROGS OF INTEGER;

  PROCEDURE parse(VAR p: ARRAY OF Instruction; VAR l: INTEGER);
    VAR S!: Texts.Scanner; ln: INTEGER; i: INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); ln := S.line; l := 0;
    REPEAT Texts.Scan(S) UNTIL ln # S.line; ASSERT(S.class = Texts.Name);
    REPEAT ln := S.line;  (*opcode*)
      IF S.s = "set" THEN p[l].op := "s"; p[l].na := 2
      ELSIF S.s = "add" THEN p[l].op := "+"; p[l].na := 2
      ELSIF S.s = "mul" THEN p[l].op := "*"; p[l].na := 2
      ELSIF S.s = "mod" THEN p[l].op := "M"; p[l].na := 2
      ELSIF S.s = "snd" THEN p[l].op := "S"; p[l].na := 1
      ELSIF S.s = "rcv" THEN p[l].op := "r"; p[l].na := 1
      ELSIF S.s = "jgz" THEN p[l].op := "j"; p[l].na := 2
      ELSE Log.DebugString("op", S.s); ASSERT(FALSE)
      END;
      FOR i := 0 TO p[l].na - 1 DO Texts.Scan(S); (*arguments*)
        IF S.class = Texts.Name THEN p[l].a[i].type := "r"; p[l].a[i].r := ORD(S.s[0]) - ORD("a")
        ELSE ASSERT(S.class = Texts.Int); p[l].a[i].type := "n"; p[l].a[i].n := S.i
        END
      END; INC(l);
      REPEAT Texts.Scan(S) UNTIL ln # S.line
    UNTIL S.class # Texts.Name
  END parse;

  PROCEDURE val(a: Argument; r: ARRAY OF LONGINT): LONGINT;
    VAR v: LONGINT;
  BEGIN
    IF a.type = "r" THEN v := r[a.r] ELSE v := a.n END
    RETURN v
  END val;

  PROCEDURE exec1(p: ARRAY OF Instruction; l: INTEGER; VAR r: ARRAY OF LONGINT; VAR pc, f, sf: INTEGER);
    VAR op: CHAR; a0, a1: Argument;
  BEGIN op := p[pc].op; a0 := p[pc].a[0]; a1 := p[pc].a[1];
    IF op = "s" THEN ASSERT(p[pc].a[0].type = "r"); r[a0.r] := val(a1, r); INC(pc)
    ELSIF op = "+" THEN ASSERT(p[pc].a[0].type = "r"); INC(r[a0.r], val(a1, r)); INC(pc)
    ELSIF op = "*" THEN ASSERT(p[pc].a[0].type = "r"); r[a0.r] := r[a0.r] * val(a1, r); INC(pc)
    ELSIF op = "M" THEN ASSERT(p[pc].a[0].type = "r"); r[a0.r] := r[a0.r] MOD val(a1, r); INC(pc)
    ELSIF op = "S" THEN sf := val(a0, r); INC(pc)
    ELSIF op = "r" THEN IF val(a0, r) # 0 THEN ASSERT(sf # -1); f := sf END; INC(pc)
    ELSIF op = "j" THEN IF val(a0, r) > 0 THEN INC(pc, val(a1, r)) ELSE INC(pc) END
    ELSE Log.DebugChar("op", op); ASSERT(FALSE)
    END
  END exec1;

  PROCEDURE execUntilRcv(p: ARRAY OF Instruction; l: INTEGER; VAR r: ARRAY OF LONGINT): INTEGER;
    VAR pc, f, sf: INTEGER;
  BEGIN f := -1; sf := -1; pc := 0;
    WHILE (f < 0) & (pc >= 0) & (pc < l) DO exec1(p,l, r, pc, f, sf) END
    RETURN f
  END execUntilRcv;

  PROCEDURE part1*;
    VAR prog: ARRAY 100 OF Instruction; nbi: INTEGER; regs: ARRAY 26 OF LONGINT;
  BEGIN parse(prog, nbi); CLEAR(regs);
    Texts.WriteString(W, "Partie 1: frequency = "); Texts.WriteInt(W, execUntilRcv(prog, nbi, regs), 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part1;

  PROCEDURE snd(id: INTEGER; val: LONGINT): BOOLEAN;
    VAR r: BOOLEAN;
  BEGIN r := U.QSend(MQ[id], head[id], tail[id], val);
    RETURN r
  END snd;

  PROCEDURE rcv(id: INTEGER; VAR val: LONGINT): BOOLEAN;
    VAR r: BOOLEAN;
  BEGIN r := U.QReceive(MQ[NB_PROGS-1 - id], head[NB_PROGS-1 - id], tail[NB_PROGS-1 - id], val);
    RETURN r
  END rcv;

  PROCEDURE exec2(p: ARRAY OF Instruction; l: INTEGER; VAR r: ARRAY OF LONGINT;
      VAR pc, s: INTEGER; id: INTEGER);
    VAR op: CHAR; a0, a1: Argument;
  BEGIN op := p[pc].op; a0 := p[pc].a[0]; a1 := p[pc].a[1];
    IF op = "s" THEN ASSERT(p[pc].a[0].type = "r"); r[a0.r] := val(a1, r); INC(pc)
    ELSIF op = "+" THEN ASSERT(p[pc].a[0].type = "r"); INC(r[a0.r], val(a1, r)); INC(pc)
    ELSIF op = "*" THEN ASSERT(p[pc].a[0].type = "r"); r[a0.r] := r[a0.r] * val(a1, r); INC(pc)
    ELSIF op = "M" THEN ASSERT(p[pc].a[0].type = "r"); r[a0.r] := r[a0.r] MOD val(a1, r); INC(pc)
    ELSIF op = "S" THEN IF snd(id, val(a0, r)) THEN INC(pc); INC(s) END
    ELSIF op = "r" THEN ASSERT(p[pc].a[0].type = "r"); IF rcv(id, r[a0.r]) THEN INC(pc) END
    ELSIF op = "j" THEN IF val(a0, r) > 0 THEN INC(pc, val(a1, r)) ELSE INC(pc) END
    ELSE Log.DebugChar("op", op); ASSERT(FALSE)
    END
  END exec2;

  PROCEDURE part2*;
    VAR prog: ARRAY 100 OF Instruction; nbi: INTEGER; regs0, regs1: ARRAY 26 OF LONGINT;
      pc0, pc1, opc0, opc1, s0, s1: INTEGER;
  BEGIN parse(prog, nbi); CLEAR(regs0); CLEAR(regs1); regs1[ORD("p") - ORD("a")] := 1;
    pc0 := 0; pc1 := 0; s0 := 0; s1 := 0; CLEAR(head); CLEAR(tail);
    REPEAT opc0 := pc0; opc1 := pc1;
      exec2(prog, nbi, regs0, pc0, s0, 0); exec2(prog, nbi, regs1, pc1, s1, 1)
    UNTIL (pc0 = opc0) & (pc1 = opc1) OR (pc0 < 0) OR (pc0 >= nbi) OR (pc1 < 0) OR (pc1 >= nbi);
    ASSERT ((pc0 < 0) OR (pc0 >= nbi) OR (prog[pc0].op = "r"));
    ASSERT ((pc1 < 0) OR (pc1 >= nbi) OR (prog[pc1].op = "r"));
    Texts.WriteString(W, "Partie 2: number of program 1 sends = "); Texts.WriteInt(W, s1, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part2;

BEGIN Texts.OpenWriter(W)
END AOC2017Day18.

Oberon.Batch
  OM4P.Compile AOC2017Day18.Mod/s~
  System.Free AOC2017Day18 AOCUtils~
~

Partie 1: frequency = 4
AOC2017Day18.part1
set a 1
add a 2
mul a a
mod a 5
snd a
set a 0
rcv a
jgz a -1
set a 1
jgz a -2
~

Partie 2: number of program 1 sends = 3
AOC2017Day18.part2
snd 1
snd 2
snd p
rcv a
rcv b
rcv c
rcv d
~

Partie 1: frequency = 3423
AOC2017Day18.part1
Partie 2: number of program 1 sends = 7493
AOC2017Day18.part2
set i 31
set a 1
mul p 17
jgz p p
mul a 2
add i -1
jgz i -2
add a -1
set i 127
set p 618
mul p 8505
mod p a
mul p 129749
add p 12345
mod p a
set b p
mod b 10000
snd b
add i -1
jgz i -9
jgz a 3
rcv b
jgz b -1
set f 0
set i 126
rcv a
rcv b
set p a
mul p -1
add p b
jgz p 4
snd a
set a b
jgz 1 3
snd b
set f 1
add i -1
jgz i -11
snd a
jgz f -16
jgz a -19
~

OM4L.LinkEF System AOC2017Day17~
OM4X.LoadEF AOC2017Day17.efb OM4L.CompareEF AOC2017Day17.efb
