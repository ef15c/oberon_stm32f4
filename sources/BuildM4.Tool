Commands for generation of the bootloader
OM4P.Compile BootLoad.Mod ~
OM4X.WriteFile BootLoad.m4c BootLoad.hex 08000000H 1ACH 20030000H ~
Net.SendFiles CS BootLoad.hex ~
(*no more used: OM4X.WriteASM BootLoad.m4c BootLoad.s ~*)

Commands for generation of the boot file (inner core)
OM4P.Compile BSP.Mod SDCard.Mod ~
OM4P2.Compile LongDiv.Mod ~
OM4P.Compile Kernel.Mod FileDir.Mod Files.Mod Modules.Mod ~ 
OM4L.Link Modules ~
OM4L.Load Modules.bin ~

Commands for generation of outer core
OM4P.Compile PS2.Mod InputAzerty.Mod Display.Mod Viewers.Mod Fonts.Mod Texts.Mod
  Oberon.Mod MenuViewers.Mod TextFrames.Mod System.Mod Edit.Mod OnStartup.Mod ~

Commands for generation of the compiler
OM4P.Compile TextsEx.Mod CRC32.Mod FilesEx.Mod OM4S.Mod OM4B.Mod OM4A.Mod OM4G.Mod OM4P.Mod
  OM4X.Mod OM4L.Mod OM4D.Mod OM4Tool.Mod StackTrace.Mod ~

Commands for generation of net
OM4P.Compile SCC.Mod Net.Mod ~
OM4P.Compile RS232.Mod ~

Command for generation of tools
OM4P.Compile Tools.Mod HeapTool.Mod ~

Commands for generation of graphic system
OM4P.Compile Graphics.Mod GraphicFrames.Mod Draw.Mod Rectangles.Mod Curves.Mod
  MacroTool.Mod GraphTool.Mod ~

Command for generating programs
OM4P.Compile Hilbert.Mod Sierpinski.Mod Blink.Mod Stars.Mod ~

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

System.CopyFiles OM4S.Mod => OM4S2.Mod ~

LONGINT version

OM4P.Compile FilesEx2.Mod OM4S2.Mod/s OM4B2.Mod OM4A2.Mod/s OM4G2.Mod/s OM4P2.Mod ~
System.Free OM4P2 OM4G2 OM4A2 OM4B2 OM4S2 testRWNum FilesEx2 ~
OM4P2.Compile FilesEx2.Mod OM4S2.Mod OM4B2.Mod OM4A2.Mod OM4G2.Mod OM4P2.Mod ~
System.CopyFiles FilesEx2.Mod => FilesEx2.Mod.s2 OM4S2.m4c => OM4S2.m4c.s2 OM4B2.m4c => OM4B2.m4c.s2 OM4A2.m4c =>
  OM4A2.m4c.s2 OM4G2.m4c => OM4G2.m4c.s2 OM4P2.m4c => OM4P2.m4c.s2 ~

System.Free OM4P2 OM4G2 OM4A2 OM4B2 OM4S2 testRWNum FilesEx2 ~ System.Free OM4Tool OM4D ~
OM4P2.Compile FilesEx2.Mod OM4S2.Mod OM4B2.Mod OM4A2.Mod OM4G2.Mod OM4P2.Mod ~
System.CompareFiles FilesEx2.Mod = FilesEx2.Mod.s2 OM4S2.m4c = OM4S2.m4c.s2 OM4B2.m4c = OM4B2.m4c.s2
  OM4A2.m4c = OM4A2.m4c.s2 OM4G2.m4c = OM4G2.m4c.s2 OM4P2.m4c = OM4P2.m4c.s2 ~


OM4P2.Compile FilesEx2.Mod TextsEx2.Mod/s ~
System.Free OM4Tool OM4D ~

Net.SendFiles CS FilesEx2.Mod OM4S2.Mod OM4B2.Mod OM4A2.Mod OM4G2.Mod OM4P2.Mod ~

Kernel2.Mod ~
