Net.Reset 110 OSCHO ~ Net.GetTime CS
System.Open ^  System.Recall  System.Watch  System.Collect System.Date
Edit.Open ^  Edit.Recall
Edit.ChangeFont Oberon10i.Scn.Fnt Edit.ChangeFont Oberon10b.Scn.Fnt
Edit.ChangeColor 0FFH Edit.ChangeColor 0FCH Edit.ChangeColor 0E3H Edit.ChangeColor 1FH
Edit.ChangeColor 01CH Edit.ChangeColor 0E0H

System.Directory ^
  *.Mod  *.Bak  *.Tool  *.Text  *.Scn.Fnt  *.sm4  *.m4c

OM4P.Compile @  OM4P.Compile @/s  OM4P.Compile ^/s
OMSPP.Compile ^/s

System.Free ~ System.Open Draw.Tool System.CopyFiles ~ System.RenameFiles ~
System.DeleteFiles ~

System.ShowModules  System.ShowCommands ^ 

PCLink1.Run
Hilbert.Draw  Sierpinski.Draw  Blink.Run  Stars.Open

Tools.Recall  Tools.Clear
Tools.Inspect 0D0201000H Tools.Inspect 0E0042000H Tools.Inspect 20000600H
Tools.Sector 0 Tools.ShowFile testString.sm4

Edit.Open BuildM4.Tool
Edit.Open BuildMSP.Tool

OM4P.Compile InputM4Qwerty.Mod ~

Net.SendFiles CS OMSPG.Mod testTypTag.Mod ~
Net.ReceiveFiles CS testTypTag.Mod ~

testRS232.Mod testRS232.hello
StackTrace.ShowDump StackTrace.Calls
System.CopyFiles OM4D.Mod => OMSPD.Mod ~
HeapTool.ShowFree Kernel.Coalesce
System.Free OMSPTool OMSPD ~ System.Free OMSPP OMSPG ~ OMSPA OMSPB OMSPS ~
