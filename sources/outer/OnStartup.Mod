MODULE OnStartup; (* C. Schoffit 25.10.2024. Allow user code to be executed at Oberon system satrup *)
  IMPORT Oberon, Net, System;

  VAR t: Oberon.Task;

  PROCEDURE getTime;
  BEGIN Net.doReset(110, "OSCHO"); Net.doGetTime("CS"); System.DisplayDate
  END getTime;

BEGIN t := Oberon.NewTask(getTime, 24*60*60*1000); (* date is got every day*) Oberon.Install(t)
END OnStartup.
