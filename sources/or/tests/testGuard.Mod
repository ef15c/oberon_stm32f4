MODULE testGuard;
  IMPORT Viewers;
  
  TYPE Viewer* = POINTER TO ViewerDesc;

    ViewerDesc* = RECORD (Viewers.ViewerDesc)
    END;

  PROCEDURE p;
    VAR V1: Viewers.Viewer;
  BEGIN
    CASE V1 OF
    Viewer:
    | Viewers.Viewer:
    END
  END p;
  
END testGuard.


(*
ORTool.DecObj testGuard.rsc ~



OM4Tool.DecObj testGuard.m4c ~



*)
