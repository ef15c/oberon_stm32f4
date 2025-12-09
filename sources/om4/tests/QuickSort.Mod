MODULE QuickSort;
  TYPE
    Item* = POINTER TO ItemPayload;
    ItemPayload* = RECORD END;
    
    LT* = PROCEDURE(a, b: Item): BOOLEAN;
    
  PROCEDURE doSort(VAR a: ARRAY OF Item; L, R: INTEGER; cmp: LT);
    VAR i, j: INTEGER; w!, x!: Item;
  BEGIN
    i := L; j := R;
    x := a[(L+R) DIV 2];
    REPEAT
      WHILE cmp(a[i], x) DO i := i+1 END;
      WHILE cmp(x, a[j]) DO j := j-1 END;
      IF i <= j THEN
        w := a[i]; a[i] := a[j]; a[j] := w;
        i := i+1; j := j-1
      END
    UNTIL i > j;
    IF L < j THEN doSort(a, L, j, cmp) END;
    IF i < R THEN doSort(a, i, R, cmp) END
  END doSort;

  PROCEDURE Sort*(VAR a: ARRAY OF Item; cmp: LT);
  BEGIN
    doSort(a, 0, LEN(a)-1, cmp)
  END Sort;

END QuickSort.
