MODULE testQuickSort;
  IMPORT QuickSort, Texts, Oberon;
  
  TYPE
    Person = POINTER TO PersonDesc;
    PersonDesc = RECORD(QuickSort.ItemPayload)
      name: ARRAY 10 OF CHAR;
      age: INTEGER
    END;
    
  VAR W: Texts.Writer;

  PROCEDURE ageCroissant(a, b: QuickSort.Item): BOOLEAN;
  BEGIN
    RETURN a(Person).age < b(Person).age
  END ageCroissant;
  
 PROCEDURE Sort*;
    VAR t!: ARRAY 4 OF QuickSort.Item;
      p!: Person;
      i: INTEGER;
  BEGIN
    NEW(p); p.name := "Nounours"; p.age := 62; t[0] := p;
    NEW(p); p.name := "Pupuce"; p.age := 63; t[1] := p;
    NEW(p); p.name := "Figaro"; p.age := 13; t[2] := p;
    NEW(p); p.name := "Baya"; p.age := 11; t[3] := p;
    
    QuickSort.Sort(t, ageCroissant);
    
    FOR i := 0 TO LEN(t)-1 DO
      p := t[i](Person);
      Texts.WriteString(W, p.name); Texts.WriteString(W, ", ");
      Texts.WriteInt(W, p.age, 1); Texts.WriteString(W, " ans.");
      Texts.WriteLn(W);
    END;
    Texts.Append(Oberon.Log, W.buf)
  END Sort;
BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Test QuickSort 13/12/2023");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
END testQuickSort.

testQuickSort.Sort
Test QuickSort 13/12/2023
Baya, 11 ans.
Figaro, 13 ans.
Nounours, 62 ans.
Pupuce, 63 ans.
