Net.Reset 110 OSCHO ~ Net.GetTime CS
System.Open ^  System.Recall  System.Watch  System.Collect System.Date
Edit.Open ^  Edit.Recall
Edit.ChangeFont Oberon10i.Scn.Fnt Edit.ChangeFont Oberon10b.Scn.Fnt
Edit.ChangeColor 0FFH Edit.ChangeColor 0FCH Edit.ChangeColor 0E3H Edit.ChangeColor 1FH
Edit.ChangeColor 01CH Edit.ChangeColor 0E0H

System.Directory ^
  *.Mod  *.Bak  *.Tool  *.Text  *.Scn.Fnt  *.sm4  *.m4c

OM4P.Compile @  OM4P.Compile @/s  OM4P.Compile ^/s

System.Free ~ System.Open Draw.Tool System.CopyFiles ~ System.RenameFiles ~
System.DeleteFiles ~

System.ShowModules  System.ShowCommands ^ 

PCLink1.Run
Hilbert.Draw  Sierpinski.Draw  Blink.Run  Stars.Open

Tools.Inspect 0D0201000H Tools.Inspect 0E000ED00H Tools.Inspect 20000000H

Tools.Sector 0
Tools.ShowFile 
Tools.Recall  Tools.Clear

Edit.Open BuildM4.Tool

Net.SendFiles CS BootLoadM4.Mod BootLoadM4.s ~
Net.ReceiveFiles CS BSP.Mod ~

testForever.Mod testForever.loop testForever.ovfl System.Free testForever
RS232.Mod System.Free RS232 ~
System.Free Net SCC ~
testRS232.Mod testRS232.hello System.Free testRS232 ~
Net.SendFiles CS BSP.Mod ~
