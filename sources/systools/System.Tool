System.Open ^  System.Recall  System.Watch  System.Collect System.Date
Edit.Open ^  Edit.Recall

Edit.CopyLooks Edit.ChangeFont Oberon8.Scn.Fnt Edit.ChangeOffset 2
Edit.ChangeFont Oberon10.Scn.Fnt Edit.ChangeFont Mono10.Scn.Fnt
Edit.ChangeFont Oberon10i.Scn.Fnt Edit.ChangeFont Oberon10b.Scn.Fnt
Edit.ChangeColor 0FFH Edit.ChangeColor 0FCH Edit.ChangeColor 0E3H Edit.ChangeColor 1FH
Edit.ChangeColor 1CH Edit.ChangeColor 5EH Edit.ChangeColor 0E0H Edit.ChangeColor 0E8H

System.Directory ^
  *.Mod  *.Bak  *.Tool  *.Text  *.Scn.Fnt  *.sm4  *.m4c

OM4P.Compile @  OM4P.Compile @/s  OM4P.Compile ^/s
OMSPP.Compile @/s OMSPP.Compile ^/s

System.Free ^ ~ System.Open Draw.Tool System.CopyFiles ~ System.RenameFiles ~
System.DeleteFiles ~

System.ShowModules  System.ShowCommands ^ 

PCLink1.Run testRS232.Mod testRS232.hello
Hilbert.Draw  Sierpinski.Draw  Blink.Run Blink.Stop Stars.Open

Tools.Recall  Tools.Clear Tools.UId Tools.MCUId
Tools.Inspect 40002850H Tools.Inspect 08001B80H Tools.Inspect 08004000H Tools.Inspect 40023C0CH
Tools.Sector 0 Tools.ShowFile

Edit.Open BuildM4.Tool Edit.Open BuildMSP.Tool

OM4P.Compile InputQwerty.Mod ~

Net.SendFiles CS sDiary.Mod sDiary.txt PosixTime.Mod ~

Net.ReceiveFiles CS findnextdsttime.c~ main.c main.h

StackTrace.Calls StackTrace.ShowDump HeapTool.ShowFree Kernel.Coalesce
System.Free OM4Tool ~ OM4D ~ System.Free OM4L
System.Free OMSPP OMSPL OMSPG~ OMSPTool OMSPD OMSPA OMSPB~
bugOMSP.Mod
Fermat.txt Image.ScreenShot
