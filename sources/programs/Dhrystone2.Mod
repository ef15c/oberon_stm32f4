MODULE Dhrystone2;

  CONST
    Ident_1*=  0;
    Ident_2* = 1;
    Ident_3* = 2;
    Ident_4* = 3;
    Ident_5* = 4;

  TYPE
    Enumeration* = INTEGER;
    One_Thirty* = INTEGER;
    One_Fifty* = INTEGER;
    Capital_Letter* = CHAR;
    Str_30* = ARRAY 31 OF CHAR;
    Arr_1_Dim* = ARRAY 50 OF INTEGER;
    Arr_2_Dim* = ARRAY 50, 50 OF INTEGER;

    VAR_1* = RECORD Enum_Comp*: Enumeration; Int_Comp*: INTEGER; Str_Comp*: ARRAY 31 OF CHAR END;
    VARIANT* = RECORD  var_1*: VAR_1 END;
    Rec_Pointer* = POINTER TO Rec_Type;
    Rec_Type* = RECORD
      Ptr_Comp*: Rec_Pointer;
      Discr*: Enumeration;
     variant*: VARIANT
    END;

  VAR Ch_1_Glob*: CHAR; Int_Glob*: INTEGER;

(*************************************************)
(* executed three times                                         *)
(* first call:      Ch_1_Par_Val == 'H', Ch_2_Par_Val == 'R'    *)
(* second call:     Ch_1_Par_Val == 'A', Ch_2_Par_Val == 'C'    *)
(* third call:      Ch_1_Par_Val == 'B', Ch_2_Par_Val == 'C'    *)
  PROCEDURE Func_1* (Ch_1_Par_Val, Ch_2_Par_Val: Capital_Letter): Enumeration;
    VAR ret: Enumeration; Ch_1_Loc, Ch_2_Loc: Capital_Letter;
  BEGIN
    Ch_1_Loc := Ch_1_Par_Val;
    Ch_2_Loc := Ch_1_Loc;
    IF Ch_2_Loc # Ch_2_Par_Val THEN (* executed *) ret := Ident_1
    ELSE (* not executed *) Ch_1_Glob := Ch_1_Loc; ret := Ident_2
    END

    RETURN ret
  END Func_1;

(*************************************************)
(* executed once *)
(* Str_1_Par_Ref == "DHRYSTONE PROGRAM, 1'ST STRING" *)
(* Str_2_Par_Ref == "DHRYSTONE PROGRAM, 2'ND STRING" *)
  PROCEDURE Func_2* (Str_1_Par_Ref, Str_2_Par_Ref: ARRAY OF CHAR): BOOLEAN;
    VAR ret: BOOLEAN;
	  Int_Loc: One_Thirty;
      Ch_Loc: Capital_Letter;
  BEGIN
	Int_Loc := 2;
	WHILE Int_Loc <= 2 DO (* loop body executed once *)
      IF Func_1 (Str_1_Par_Ref[Int_Loc], Str_2_Par_Ref[Int_Loc+1]) = Ident_1 THEN
        Ch_Loc := "A"; INC(Int_Loc)
      END
    END;
	IF (Ch_Loc >= "W") & (Ch_Loc < "Z") THEN (* not executed *) Int_Loc := 7 END;
	IF Ch_Loc = "R" THEN (* not executed *) ret := TRUE
    ELSE (* executed *)
      IF Str_1_Par_Ref >  Str_2_Par_Ref THEN (* not executed *)
        INC(Int_Loc, 7); Int_Glob := Int_Loc; ret := TRUE
      ELSE (* executed *) ret := FALSE
      END
	END (* if Ch_Loc *)

    RETURN ret
  END Func_2;

(***************************)
(* executed once        *)
(* Enum_Par_Val == Ident_3 *)
  PROCEDURE Func_3 (Enum_Par_Val: Enumeration): BOOLEAN;
    VAR Enum_Loc: Enumeration;
  BEGIN Enum_Loc := Enum_Par_Val;

    RETURN Enum_Loc = Ident_3
  END Func_3;

(**********************************************)
(* executed three times                                      *)
(* first call:      Int_1_Par_Val == 2, Int_2_Par_Val == 3,  *)
(*                  Int_Par_Ref becomes 7                    *)
(* second call:     Int_1_Par_Val == 10, Int_2_Par_Val == 5, *)
(*                  Int_Par_Ref becomes 17                   *)
(* third call:      Int_1_Par_Val == 6, Int_2_Par_Val == 10, *)
(*                  Int_Par_Ref becomes 18                   *)
  PROCEDURE Proc_7* (Int_1_Par_Val, Int_2_Par_Val: One_Fifty; VAR Int_Par_Ref: One_Fifty);
    VAR Int_Loc: One_Fifty;
  BEGIN Int_Loc := Int_1_Par_Val + 2; Int_Par_Ref := Int_2_Par_Val + Int_Loc
  END Proc_7;

(*********************************************************************)
(* executed once      *)
(* Int_Par_Val_1 == 3 *)
(* Int_Par_Val_2 == 7 *)
  PROCEDURE Proc_8* (VAR Arr_1_Par_Ref: Arr_1_Dim; VAR Arr_2_Par_Ref: Arr_2_Dim; Int_1_Par_Val, Int_2_Par_Val: INTEGER);
    VAR  Int_Index, Int_Loc: One_Fifty;
  BEGIN
    Int_Loc := Int_1_Par_Val + 5;
    Arr_1_Par_Ref [Int_Loc] := Int_2_Par_Val;
    Arr_1_Par_Ref [Int_Loc+1] := Arr_1_Par_Ref [Int_Loc];
    Arr_1_Par_Ref [Int_Loc+30] := Int_Loc;
    FOR Int_Index := Int_Loc TO Int_Loc+1 DO Arr_2_Par_Ref [Int_Loc] [Int_Index] := Int_Loc END;
    INC(Arr_2_Par_Ref [Int_Loc] [Int_Loc-1]);
    Arr_2_Par_Ref [Int_Loc+20] [Int_Loc] := Arr_1_Par_Ref [Int_Loc];
    Int_Glob := 5
  END Proc_8;

(*********************************)
(* executed once *)
(* Enum_Val_Par == Ident_3, Enum_Ref_Par becomes Ident_2 *)
  PROCEDURE Proc_6* (Enum_Val_Par: Enumeration; VAR Enum_Ref_Par: Enumeration);
  BEGIN Enum_Ref_Par := Enum_Val_Par;
    IF ~ Func_3 (Enum_Val_Par) THEN (* not executed *) Enum_Ref_Par := Ident_4 END;
	IF Enum_Val_Par = Ident_1 THEN Enum_Ref_Par := Ident_1
    ELSIF Enum_Val_Par = Ident_2 THEN
      IF Int_Glob > 100 THEN Enum_Ref_Par := Ident_1 ELSE Enum_Ref_Par := Ident_4 END
    ELSIF Enum_Val_Par =  Ident_3 THEN (* executed *) Enum_Ref_Par := Ident_2
    ELSIF Enum_Val_Par = Ident_4 THEN (*break*)
    ELSIF Enum_Val_Par = Ident_5 THEN Enum_Ref_Par := Ident_3
	END
  END Proc_6;

  PROCEDURE SetCh_1_Glob*(v: CHAR);
  BEGIN Ch_1_Glob := v
  END SetCh_1_Glob;

  PROCEDURE SetInt_Glob*(v: INTEGER);
  BEGIN Int_Glob := v
  END SetInt_Glob;

END Dhrystone2.
