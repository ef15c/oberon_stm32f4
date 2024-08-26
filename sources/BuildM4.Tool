Commands for generation of the bootloader
OM4P.Compile BootLoadM4.Mod ~
OM4X.WriteFile BootLoadM4.m4c BootLoadM4.hex 08000000H 1ACH 20030000H ~
Net.SendFiles CS BootLoadM4.hex ~
(*no more used: OM4X.WriteASM BootLoadM4.m4c BootLoadM4.s ~*)

Commands for generation of the boot file (inner core)
OM4P.Compile BSP.Mod/s SDCard.Mod/s KernelM4.Mod/s FileDir.Mod/s Files.Mod/s ModulesM4.Mod/s ~ 
OM4L.Link Modules ~
OM4L.Load Modules.bin ~

Commands for generation of outer core
OM4P.Compile PS2.Mod/s InputM4Azerty.Mod/s DisplayM4.Mod/s Viewers.Mod/s FontsM4.Mod/s Texts.Mod/s 
  OberonM4.Mod/s MenuViewers.Mod/s TextFrames.Mod/s SystemM4.Mod/s Edit.Mod/s ~

Commands for generation of the compiler
OM4P.Compile TextsEx.Mod/s OM4S.Mod/s OM4B.Mod/s OM4A.Mod/s OM4G.Mod/s OM4P.Mod/s
  OM4X.Mod/s OM4L.Mod/s OM4D.Mod/s OM4Tool.Mod/s ~

Commands for generation of net
OM4P.Compile SCCM4.Mod/s NetM4.Mod/s ~
OM4P.Compile RS232.Mod ~

Command for generation of tools
OM4P.Compile Tools.Mod/s ~

Commands for generation of graphic system
OM4P.Compile Graphics.Mod/s GraphicFramesM4.Mod/s Draw.Mod Rectangles.Mod/s Curves.Mod/s
  MacroTool.Mod GraphTool.Mod ~

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
