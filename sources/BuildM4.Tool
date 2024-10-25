Commands for generation of the bootloader
OM4P.Compile BootLoad.Mod ~
OM4X.WriteFile BootLoad.m4c BootLoad.hex 08000000H 1ACH 20030000H ~
Net.SendFiles CS BootLoad.hex ~
(*no more used: OM4X.WriteASM BootLoad.m4c BootLoad.s ~*)

Commands for generation of the boot file (inner core)
OM4P.Compile BSP.Mod/s SDCard.Mod/s Kernel.Mod/s FileDir.Mod/s Files.Mod/s Modules.Mod/s ~ 
OM4L.Link Modules ~
OM4L.Load Modules.bin ~

Commands for generation of outer core
OM4P.Compile PS2.Mod/s InputAzerty.Mod/s Display.Mod/s Viewers.Mod/s Fonts.Mod/s Texts.Mod/s 
  Oberon.Mod/s MenuViewers.Mod/s TextFrames.Mod/s System.Mod/s Edit.Mod/s OnStartup.Mod ~

Commands for generation of the compiler
OM4P.Compile TextsEx.Mod/s CRC32.Mod/s FilesEx.Mod/s OM4S.Mod/s OM4B.Mod/s OM4A.Mod/s OM4G.Mod/s OM4P.Mod/s
  OM4X.Mod/s OM4L.Mod/s OM4D.Mod/s OM4Tool.Mod/s StackTrace.Mod/s ~

Commands for generation of net
OM4P.Compile SCC.Mod/s Net.Mod/s ~
OM4P.Compile RS232.Mod/s ~

Command for generation of tools
OM4P.Compile Tools.Mod/s HeapTool.Mod ~

Commands for generation of graphic system
OM4P.Compile Graphics.Mod/s GraphicFrames.Mod/s Draw.Mod Rectangles.Mod/s Curves.Mod/s
  MacroTool.Mod/s GraphTool.Mod/s ~

Command for generating programs
OM4P.Compile Hilbert.Mod/s Sierpinski.Mod/s Blink.Mod/s Stars.Mod/s ~

OM4Tool.DecBin Modules.bin ~

Tool for compiler debugging
BugsCompile.Tool

Staging Compiler for heavy evolution. BE VERY CAUTIOUS
System.CopyFiles OM4B.Mod=>OM4B2.Mod OM4G.Mod=>OM4G2.Mod OM4P.Mod=>OM4P2.Mod ~
<<rename modules and make changes on sources>>
Net.SendFiles CS OM4B2.Mod OM4G2.Mod OM4P2.Mod ~
OM4P.Compile OM4B2.Mod OM4G2.Mod OM4P2.Mod ~
OM4P2.Compile OM4B2.Mod OM4G2.Mod OM4P2.Mod ~
System.Free OM4P2 OM4G2 OM4Tool OM4D OM4A OM4B2 ~
OM4P2.Compile testBug2.Mod ~
Install new compiler
System.CopyFiles OM4B2.Mod=>OM4B.Mod OM4G2.Mod=>OM4G.Mod OM4P2.Mod=>OM4P.Mod ~
Net.SendFiles CS OM4B.Mod OM4G.Mod OM4P.Mod ~
<<rename modules with original names>>
OM4P2.Compile OM4B.Mod OM4G.Mod OM4P.Mod ~
