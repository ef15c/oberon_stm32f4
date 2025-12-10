MODULE QuickSort;
  TYPE
    Array* = RECORD
      n*: INTEGER;
    END;

    Cmp = PROCEDURE(a: Array; i, j: INTEGER): BOOLEAN;
    Swap = PROCEDURE(VAR a: Array; i, j: INTEGER);
        
  PROCEDURE doSort(VAR a: Array; cmp: Cmp; swap: Swap; L, R: INTEGER);
    VAR i, j, x: INTEGER;
  BEGIN
    i := L; j := R;
    x := (L+R) DIV 2;
    REPEAT
      WHILE cmp(a, i, x) DO i := i+1 END;
      WHILE cmp(a, x, j) DO j := j-1 END;
      IF i <= j THEN swap(a, i, j);
        IF x = i THEN x := j ELSIF x = j THEN x := i END;
        i := i+1; j := j-1
      END
    UNTIL i > j;
    IF L < j THEN doSort(a, cmp, swap, L, j) END;
    IF i < R THEN doSort(a, cmp, swap, i, R) END
  END doSort;

  PROCEDURE Sort*(VAR a: Array; cmp: Cmp; swap: Swap);
  BEGIN
    IF a.n > 0 THEN doSort(a, cmp, swap, 0, a.n - 1) END
  END Sort;

END QuickSort.
