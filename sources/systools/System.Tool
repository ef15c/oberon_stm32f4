Net.Reset 110 OSCHO ~ Net.GetTime CS
System.Open ^  System.Recall  System.Watch  System.Collect System.Date
Edit.Open ^  Edit.Recall Edit.ChangeFont Oberon10.Scn.Fnt
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
Hilbert.Draw  Sierpinski.Draw  Blink.Run  Stars.Open

Tools.Recall  Tools.Clear
Tools.Inspect 0D0201000H Tools.Inspect 0E0042000H Tools.Inspect 0D02B9068H
Tools.Sector 0 Tools.ShowFile testRWNum.data

Edit.Open BuildM4.Tool Edit.Open BuildMSP.Tool

OM4P.Compile InputQwerty.Mod ~

Net.SendFiles CS LongDiv.Mod Kernel.Mod ~ testLongInt.Mod ~ LongInt.Mod ~
Net.ReceiveFiles CS  ~

StackTrace.ShowDump StackTrace.Calls
HeapTool.ShowFree Kernel.Coalesce
System.Free OMSPL OMSPP OMSPG OMSPTool OMSPD OMSPA OMSPB OMSPS ~ 
System.Free OM4P OM4G OM4B OM4A OM4S ~ System.Free OM4Tool OM4D ~
OM4P2.Compile ^ ~
OM4P2.Compile LongInt.Mod/s ~ System.Free LongInt ~ LongInt.run
