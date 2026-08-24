MODULE Dhrystone;
  IMPORT SYSTEM, BSP, Texts, Oberon, Timer, D2 := Dhrystone2;

  CONST Too_Small_Time = 2*Timer.HERTZ; (*the test should run for a minimum of 2 seconds*)
    Mic_secs_Per_Second = 1000000.0;
    VAX_DHRYSTONE_VALUE = 1757.0;
    MEGA_HERTZ = 1000000;

  VAR (* Global Variables: *)
    Ptr_Glob, Next_Ptr_Glob: D2.Rec_Pointer;
    Bool_Glob: BOOLEAN;
    Ch_2_Glob: CHAR;
    Arr_1_Glob: D2.Arr_1_Dim;
    Arr_2_Glob: D2.Arr_2_Dim;

    Begin_Time, End_Time, User_Time: INTEGER;
    Microseconds, Dhrystones_Per_Second: REAL;

    W: Texts.Writer;

(******************)
(* executed once *)
(* Ptr_Ref_Par becomes Ptr_Glob *)
  PROCEDURE Proc_3 (VAR Ptr_Ref_Par: D2.Rec_Pointer);
  BEGIN
    IF Ptr_Glob # NIL THEN (* executed *) Ptr_Ref_Par := Ptr_Glob.Ptr_Comp END;
    D2.Proc_7 (10, D2.Int_Glob, Ptr_Glob.variant.var_1.Int_Comp)
  END Proc_3;

(******************)
(* executed once *)
  PROCEDURE Proc_1 ( Ptr_Val_Par: D2.Rec_Pointer);
    VAR Next_Record!: D2.Rec_Pointer;
  BEGIN Next_Record := Ptr_Val_Par.Ptr_Comp;
	(* == Ptr_Glob_Next *)
			(* Local variable, initialized with Ptr_Val_Par->Ptr_Comp,    *)
    (* corresponds to "rename" in Ada, "with" in Pascal           *)
	Ptr_Val_Par.Ptr_Comp^ := Ptr_Glob^;
	Ptr_Val_Par.variant.var_1.Int_Comp := 5;
	Next_Record.variant.var_1.Int_Comp := Ptr_Val_Par.variant.var_1.Int_Comp;
	Next_Record.Ptr_Comp := Ptr_Val_Par.Ptr_Comp;
	Proc_3 (Next_Record.Ptr_Comp);
	(* Ptr_Val_Par->Ptr_Comp->Ptr_Comp
                        == Ptr_Glob->Ptr_Comp *)
    IF Next_Record.Discr = D2.Ident_1 THEN (* executed *)
      Next_Record.variant.var_1.Int_Comp := 6;
      D2.Proc_6 (Ptr_Val_Par.variant.var_1.Enum_Comp, Next_Record.variant.var_1.Enum_Comp);
      Next_Record.Ptr_Comp := Ptr_Glob.Ptr_Comp;
  	D2.Proc_7 (Next_Record.variant.var_1.Int_Comp, 10, Next_Record.variant.var_1.Int_Comp);
    ELSE (* not executed *) Ptr_Val_Par^ := Ptr_Val_Par.Ptr_Comp^
    END
  END Proc_1;

(*******)
(* executed once *)
  PROCEDURE Proc_4; (* without parameters *)
    VAR Bool_Loc: BOOLEAN;
  BEGIN
	Bool_Loc := D2.Ch_1_Glob = "A";
	Bool_Glob := Bool_Loc OR Bool_Glob;
	Ch_2_Glob := "B"
  END Proc_4;

(*******)
(* executed once *)
  PROCEDURE Proc_5; (* without parameters *)
  BEGIN
    D2.SetCh_1_Glob("A");
	Bool_Glob := FALSE
  END Proc_5;

(******************)
(* executed once *)
(* *Int_Par_Ref == 1, becomes 4 *)
  PROCEDURE Proc_2 (VAR Int_Par_Ref: D2.One_Fifty);
    VAR Int_Loc: D2.One_Fifty; Enum_Loc: D2.Enumeration;
  BEGIN Int_Loc := Int_Par_Ref + 10;
    REPEAT (* executed once *)
      IF D2.Ch_1_Glob = "A" THEN (* executed *)
        DEC(Int_Loc, 1); Int_Par_Ref := Int_Loc - D2.Int_Glob; Enum_Loc := D2.Ident_1
      END (* if *)
    UNTIL Enum_Loc = D2.Ident_1 (* TRUE *)
  END Proc_2;

(* main program, corresponds to procedures        *)
(* Main and Proc_0 in the Ada version             *)
  PROCEDURE StartTest*;
  (* main program, corresponds to procedures        *)
  (* Main and Proc_0 in the Ada version             *)
    VAR Int_1_Loc,  Int_2_Loc, Int_3_Loc: D2.One_Fifty;
	Ch_Index: BYTE;
    Enum_Loc: D2.Enumeration;
    Str_1_Loc, Str_2_Loc: D2.Str_30;
    Run_Index, Number_Of_Runs: INTEGER;
	temp: ARRAY 100 OF CHAR;

    S!: Texts.Scanner;
    Next_Glob!, Glob!: D2.Rec_Type;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    Int_1_Loc := 0; Int_2_Loc := 0;
    (* Initializations *)
	Next_Ptr_Glob := SYSTEM.VAL(D2.Rec_Pointer, SYSTEM.ADR(Next_Glob));
	Ptr_Glob := SYSTEM.VAL(D2.Rec_Pointer, SYSTEM.ADR(Glob));;

	Ptr_Glob.Ptr_Comp := Next_Ptr_Glob;
	Ptr_Glob.Discr := D2.Ident_1;
	Ptr_Glob.variant.var_1.Enum_Comp := D2.Ident_3;
	Ptr_Glob.variant.var_1.Int_Comp := 40;
	Ptr_Glob.variant.var_1.Str_Comp := "DHRYSTONE PROGRAM, SOME STRING";
	Str_1_Loc :=  "DHRYSTONE PROGRAM, 1'ST STRING";

	Arr_2_Glob [8][7] := 10;
	(* Was missing in published program. Without this statement,    *)
	(* Arr_2_Glob [8][7] would have an undefined value.             *)
	(* Warning: With 16-Bit processors and Number_Of_Runs > 32000,  *)
	(* overflow may occur for this array element.                   *)
	Texts.WriteLn(W); Texts.WriteString(W, "Dhrystone Benchmark, Version 2.1 (Language: Oberon)");
    Texts.WriteLn(W);  Texts.WriteLn(W);
    Texts.Scan(S);
    IF S.class # Texts.Int THEN
      Texts.WriteString(W, "Please give the number of runs through the benchmark: ");
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
	ELSE Number_Of_Runs := S.i;
      Texts.WriteString(W, "Execution starts, "); Texts.WriteInt(W, Number_Of_Runs, 1); 
      Texts.WriteString(W, " runs through Dhrystone"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
      (***************)
      (* Start timer *)
      (***************)
      Begin_Time := Timer.startTimer();
      FOR Run_Index := 1 TO Number_Of_Runs DO
        Proc_5;
        Proc_4;
        (* Ch_1_Glob == 'A', Ch_2_Glob == 'B', Bool_Glob == true *)
        Int_1_Loc := 2;
        Int_2_Loc := 3;
        Str_2_Loc := "DHRYSTONE PROGRAM, 2'ND STRING";
        Enum_Loc := D2.Ident_2;
        Bool_Glob := ~ D2.Func_2 (Str_1_Loc, Str_2_Loc);
        (* Bool_Glob = TRUE *)
        WHILE Int_1_Loc < Int_2_Loc DO (* loop body executed once *)
          Int_3_Loc := 5 * Int_1_Loc - Int_2_Loc;
          (* Int_3_Loc == 7 *)
          D2.Proc_7 (Int_1_Loc, Int_2_Loc, Int_3_Loc);
          (* Int_3_Loc == 7 *)
          INC(Int_1_Loc)
        END; (* while *)
        (* Int_1_Loc == 3, Int_2_Loc == 3, Int_3_Loc == 7 *)
        D2.Proc_8 (Arr_1_Glob, Arr_2_Glob, Int_1_Loc, Int_3_Loc);
        (* Int_Glob == 5 *)
        Proc_1 (Ptr_Glob);
        FOR Ch_Index := ORD("A") TO ORD(Ch_2_Glob) DO
          (* loop body executed twice *)
          IF Enum_Loc = D2.Func_1 (CHR(Ch_Index), "C") THEN (* not executed *)
            D2.Proc_6 (D2.Ident_1, Enum_Loc);
            Str_2_Loc := "DHRYSTONE PROGRAM, 3'RD STRING";
            Int_2_Loc := Run_Index;
            D2.SetInt_Glob(Run_Index)
          END
        END;
        (* Int_1_Loc == 3, Int_2_Loc == 3, Int_3_Loc == 7 *)
        Int_2_Loc := Int_2_Loc * Int_1_Loc;
        Int_1_Loc := Int_2_Loc DIV Int_3_Loc;
        Int_2_Loc := 7 * (Int_2_Loc - Int_3_Loc) - Int_1_Loc;
        (* Int_1_Loc == 1, Int_2_Loc == 13, Int_3_Loc == 7 *)
        Proc_2 (Int_1_Loc);
        (* Int_1_Loc == 5 *)
      END; (* loop "for Run_Index" *)
      (**************)
      (* Stop timer *)
      (**************)
      End_Time := Timer.stopTimer();
      Texts.WriteString(W, "Execution ends"); Texts.WriteLn(W); Texts.WriteLn(W);
      Texts.WriteString(W, "Final values of the variables used in the benchmark:"); Texts.WriteLn(W); Texts.WriteLn(W);
      Texts.WriteString(W, "Int_Glob:            "); Texts.WriteInt(W, D2.Int_Glob, 1); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   5"); Texts.WriteLn(W);
      Texts.WriteString(W, "Bool_Glob:           "); Texts.WriteInt(W, ORD(Bool_Glob), 1); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   1"); Texts.WriteLn(W);
      Texts.WriteString(W, "Ch_1_Glob:           "); Texts.Write(W, D2.Ch_1_Glob); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   A"); Texts.WriteLn(W);
      Texts.WriteString(W, "Ch_2_Glob:           "); Texts.Write(W, Ch_2_Glob); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   B"); Texts.WriteLn(W);
      Texts.WriteString(W, "Arr_1_Glob[8]:       "); Texts.WriteInt(W, Arr_1_Glob[8], 1); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   7"); Texts.WriteLn(W);
      Texts.WriteString(W, "Arr_2_Glob[8][7]:    "); Texts.WriteInt(W, Arr_2_Glob[8][7], 1); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   Number_Of_Runs + 10"); Texts.WriteLn(W);
      Texts.WriteString(W, "Ptr_Glob."); Texts.WriteLn(W);
      Texts.WriteString(W, "  Ptr_Comp:          "); Texts.WriteHex(W, ORD(Ptr_Glob.Ptr_Comp)); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   (implementation-dependent)"); Texts.WriteLn(W);
      Texts.WriteString(W, "  Discr:             "); Texts.WriteInt(W, Ptr_Glob.Discr, 1); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   0"); Texts.WriteLn(W);
      Texts.WriteString(W, "  Enum_Comp:         "); Texts.WriteInt(W, Ptr_Glob.variant.var_1.Enum_Comp, 1); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   2"); Texts.WriteLn(W);
      Texts.WriteString(W, "  Int_Comp:          "); Texts.WriteInt(W, Ptr_Glob.variant.var_1.Int_Comp, 1); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   17"); Texts.WriteLn(W);
      Texts.WriteString(W, "  Str_Comp:          ");Texts.WriteString(W, Ptr_Glob.variant.var_1.Str_Comp); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   DHRYSTONE PROGRAM, SOME STRING"); Texts.WriteLn(W);
      Texts.WriteString(W, "Next_Ptr_Glob."); Texts.WriteLn(W);
      Texts.WriteString(W, "  Ptr_Comp:          "); Texts.WriteHex(W, ORD(Next_Ptr_Glob.Ptr_Comp)); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   (implementation-dependent), same as above"); Texts.WriteLn(W);
      Texts.WriteString(W, "  Discr:             "); Texts.WriteInt(W, Next_Ptr_Glob.Discr, 1); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   0"); Texts.WriteLn(W);
      Texts.WriteString(W, "  Enum_Comp:         "); Texts.WriteInt(W, Next_Ptr_Glob.variant.var_1.Enum_Comp, 1); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   1"); Texts.WriteLn(W);
      Texts.WriteString(W, "  Int_Comp:          "); Texts.WriteInt(W, Next_Ptr_Glob.variant.var_1.Int_Comp, 1); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:    18"); Texts.WriteLn(W);
      Texts.WriteString(W, " Str_Comp:          "); Texts.WriteString(W, Next_Ptr_Glob.variant.var_1.Str_Comp); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   DHRYSTONE PROGRAM, SOME STRING"); Texts.WriteLn(W);
      Texts.WriteString(W, "Int_1_Loc:           "); Texts.WriteInt(W, Int_1_Loc, 1); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   5"); Texts.WriteLn(W);
      Texts.WriteString(W, "Int_2_Loc:           "); Texts.WriteInt(W, Int_2_Loc, 1); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   13"); Texts.WriteLn(W);
      Texts.WriteString(W, "Int_3_Loc:           "); Texts.WriteInt(W, Int_3_Loc, 1); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:    7"); Texts.WriteLn(W);
      Texts.WriteString(W, "Enum_Loc:            "); Texts.WriteInt(W, Enum_Loc, 1); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   1"); Texts.WriteLn(W);
      Texts.WriteString(W, "Str_1_Loc:           "); Texts.WriteString(W, Str_1_Loc); Texts.WriteLn(W);
      Texts.WriteString(W, "       should be:   DHRYSTONE PROGRAM, 1'ST STRING"); Texts.WriteLn(W);
      Texts.WriteString(W, "Str_2_Loc:           "); Texts.WriteString(W, Str_2_Loc); Texts.WriteLn(W);
      Texts.WriteString(W, "        should be:   DHRYSTONE PROGRAM, 2'ND STRING"); Texts.WriteLn(W); Texts.WriteLn(W);
      User_Time := End_Time - Begin_Time;
      IF User_Time < Too_Small_Time THEN
    	Texts.WriteString(W, "Measured time too small to obtain meaningful results"); Texts.WriteLn(W);
        Texts.WriteString(W, "Please increase number of runs"); Texts.WriteLn(W)
      ELSE Microseconds := FLT(User_Time) * Mic_secs_Per_Second / (FLT(Timer.HERTZ) *  FLT(Number_Of_Runs));
        Dhrystones_Per_Second := FLT(Timer.HERTZ) * FLT(Number_Of_Runs) / FLT(User_Time);
        Texts.WriteString(W, "CPU freq: "); Texts.WriteInt(W, BSP.HCLKFreq*MEGA_HERTZ, 1); Texts.WriteLn(W);
        Texts.WriteString(W, "Oberon 07 compiler version: 18.08.26"); Texts.WriteLn(W);
        Texts.WriteString(W, "Microseconds for one run through Dhrystone: "); Texts.WriteRealFix(W, Microseconds, 6, 1); Texts.WriteLn(W);
        Texts.WriteString(W, "Dhrystones per Second:                      "); Texts.WriteRealFix(W, Dhrystones_Per_Second, 6, 1); Texts.WriteLn(W);
        Texts.WriteString(W, "DMIPS:                      "); Texts.WriteRealFix(W, Dhrystones_Per_Second/VAX_DHRYSTONE_VALUE, 6, 1); Texts.WriteLn(W);
        Texts.WriteString(W, "DMIPS/MHz:                      "); 
        Texts.WriteRealFix(W, (Dhrystones_Per_Second/VAX_DHRYSTONE_VALUE)/FLT(BSP.HCLKFreq), 6, 1);
        Texts.WriteLn(W);
      END
    END;
    Texts.Append(Oberon.Log, W.buf);
    Next_Ptr_Glob := NIL;
    Ptr_Glob := NIL
  END StartTest;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Dhrystone 2.1 CS 23.08.26");
  Texts.Append(Oberon.Log, W.buf)
END Dhrystone.

OM4P.Compile Timer.Mod/s Dhrystone2.Mod/s Dhrystone.Mod/s~
System.Free Dhrystone Dhrystone2 Timer~

Dhrystone.StartTest 30000

Execution in SDRAM:
Dhrystone 2.1 CS 23.08.26
Dhrystone Benchmark, Version 2.1 (Language: Oberon)

Execution starts, 30000 runs through Dhrystone
Execution ends

Final values of the variables used in the benchmark:

Int_Glob:            5
        should be:   5
Bool_Glob:           1
        should be:   1
Ch_1_Glob:           A
        should be:   A
Ch_2_Glob:           B
        should be:   B
Arr_1_Glob[8]:       7
        should be:   7
Arr_2_Glob[8][7]:    30010
        should be:   Number_Of_Runs + 10
Ptr_Glob.
  Ptr_Comp:           1000FDC8
        should be:   (implementation-dependent)
  Discr:             0
        should be:   0
  Enum_Comp:         2
        should be:   2
  Int_Comp:          17
        should be:   17
  Str_Comp:          DHRYSTONE PROGRAM, SOME STRING
        should be:   DHRYSTONE PROGRAM, SOME STRING
Next_Ptr_Glob.
  Ptr_Comp:           1000FDC8
        should be:   (implementation-dependent), same as above
  Discr:             0
        should be:   0
  Enum_Comp:         1
        should be:   1
  Int_Comp:          18
        should be:    18
 Str_Comp:          DHRYSTONE PROGRAM, SOME STRING
        should be:   DHRYSTONE PROGRAM, SOME STRING
Int_1_Loc:           5
        should be:   5
Int_2_Loc:           13
        should be:   13
Int_3_Loc:           7
        should be:    7
Enum_Loc:            1
        should be:   1
Str_1_Loc:           DHRYSTONE PROGRAM, 1'ST STRING
       should be:   DHRYSTONE PROGRAM, 1'ST STRING
Str_2_Loc:           DHRYSTONE PROGRAM, 2'ND STRING
        should be:   DHRYSTONE PROGRAM, 2'ND STRING

CPU freq: 168000000
Oberon 07 compiler version: 18.08.26
Microseconds for one run through Dhrystone:   80.1
Dhrystones per Second:                        12489.6
DMIPS:                         7.2
DMIPS/MHz:                          .1

OM4L.LinkEF Modules System Edit OnStartup Image OM4L Dhrystone OM4P ~
OM4L.LoadEF OM4P.efb OM4L.CompareEF OM4P.efb

Dhrystone.StartTest 300000

Execution in Flash:
Dhrystone 2.1 CS 23.08.26 Client set as OSCHO on channel 110
setting time done
System.Clock 24.08.26 15:33:14

Dhrystone Benchmark, Version 2.1 (Language: Oberon)

Execution starts, 300000 runs through Dhrystone
Execution ends

Final values of the variables used in the benchmark:

Int_Glob:            5
        should be:   5
Bool_Glob:           1
        should be:   1
Ch_1_Glob:           A
        should be:   A
Ch_2_Glob:           B
        should be:   B
Arr_1_Glob[8]:       7
        should be:   7
Arr_2_Glob[8][7]:    300010
        should be:   Number_Of_Runs + 10
Ptr_Glob.
  Ptr_Comp:           1000FDC8
        should be:   (implementation-dependent)
  Discr:             0
        should be:   0
  Enum_Comp:         2
        should be:   2
  Int_Comp:          17
        should be:   17
  Str_Comp:          DHRYSTONE PROGRAM, SOME STRING
        should be:   DHRYSTONE PROGRAM, SOME STRING
Next_Ptr_Glob.
  Ptr_Comp:           1000FDC8
        should be:   (implementation-dependent), same as above
  Discr:             0
        should be:   0
  Enum_Comp:         1
        should be:   1
  Int_Comp:          18
        should be:    18
 Str_Comp:          DHRYSTONE PROGRAM, SOME STRING
        should be:   DHRYSTONE PROGRAM, SOME STRING
Int_1_Loc:           5
        should be:   5
Int_2_Loc:           13
        should be:   13
Int_3_Loc:           7
        should be:    7
Enum_Loc:            1
        should be:   1
Str_1_Loc:           DHRYSTONE PROGRAM, 1'ST STRING
       should be:   DHRYSTONE PROGRAM, 1'ST STRING
Str_2_Loc:           DHRYSTONE PROGRAM, 2'ND STRING
        should be:   DHRYSTONE PROGRAM, 2'ND STRING

CPU freq: 168000000
Oberon 07 compiler version: 18.08.26
Microseconds for one run through Dhrystone:    8.4
Dhrystones per Second:                        119665.0
DMIPS:                        68.2
DMIPS/MHz:                          .5
