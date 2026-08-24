MODULE Timer;
  IMPORT Kernel;

  CONST HERTZ* = 1000;

  PROCEDURE startTimer*(): INTEGER;

    RETURN Kernel.Time()
  END startTimer;

  PROCEDURE stopTimer*(): INTEGER;

    RETURN Kernel.Time()
  END stopTimer;

END Timer.
