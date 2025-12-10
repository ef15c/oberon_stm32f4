MODULE testQuickSort;
  IMPORT Q := QuickSort, Texts, Oberon;
  
  TYPE
    Person = RECORD
      name: ARRAY 10 OF CHAR;
      age: INTEGER
    END;
    Array = RECORD(Q.Array) person: ARRAY 4 OF Person END;
  VAR W: Texts.Writer;

  PROCEDURE ageCroissant(a: Q.Array; i, j: INTEGER): BOOLEAN;
  BEGIN
    RETURN a(Array).person[i].age < a(Array).person[j].age
  END ageCroissant;

  PROCEDURE swap(VAR a: Q.Array; i, j: INTEGER);
    VAR t: Person;
  BEGIN t := a(Array).person[i]; a(Array).person[i] := a(Array).person[j]; a(Array).person[j] := t
  END swap;

  PROCEDURE print(a: Array);
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO a.n -1 DO
      Texts.WriteString(W, a.person[i].name); Texts.WriteString(W, ", ");
      Texts.WriteInt(W, a.person[i].age, 1); Texts.WriteString(W, " ans.");
      Texts.WriteLn(W);
    END;
    Texts.WriteString(W, "---"); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END print;

 PROCEDURE Sort*;
    VAR a: Array; p: Person;
  BEGIN
    a.person[0].name := "Nounours"; a.person[0].age := 62;
    a.person[1].name := "Pupuce"; a.person[1].age := 63;
    a.person[2].name := "Figaro"; a.person[2].age := 13;
    a.person[3].name := "Baya"; a.person[3].age := 11;
    a.n := 4;

    print(a);
    Q.Sort(a, ageCroissant, swap);
    print(a);
  END Sort;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Test QuickSort 10/12/2025");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
END testQuickSort.

OM4P.Compile testQuickSort.Mod~
System.Free testQuickSort QuickSort~

testQuickSort.Sort
Test QuickSort 10/12/2025
Nounours, 62 ans.
Pupuce, 63 ans.
Figaro, 13 ans.
Baya, 11 ans.
---
Baya, 11 ans.
Figaro, 13 ans.
Nounours, 62 ans.
Pupuce, 63 ans.
---
