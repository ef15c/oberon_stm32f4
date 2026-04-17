Commands for generation of the bootloader
OM4P.Compile BootLoad.Mod ~
OM4X.WriteFile BootLoad.m4c BootLoad.hex 08000000H 1ACH 20030000H ~
Net.SendFiles CS BootLoad.hex ~
OM4X.Load BootLoad.hex
(*no more used: OM4X.WriteASM BootLoad.m4c BootLoad.s ~*)

Commands for generation of the boot file (inner core)
OM4P.Compile BSP.Mod/s SDCard.Mod/s LongDiv.Mod/s Kernel.Mod/s FileDir.Mod/s Files.Mod/s Modules.Mod/s ~
OM4L.Link Modules ~
OM4L.Load Modules.bin ~
 ** or/and **
OM4L.LinkEF Modules ~
OM4L.LoadEF Modules.efb OM4L.CompareEF Modules.efb

Commands for generation of outer core
OM4P.Compile PS2.Mod/s InputAzerty.Mod/s Display.Mod/s Viewers.Mod/s Fonts.Mod/s Texts.Mod/s
  Oberon.Mod/s MenuViewers.Mod/s TextFrames.Mod/s System.Mod/s Edit.Mod/s
  CRC32.Mod/s SCC.Mod/s Net.Mod/s OnStartup.Mod/s ~
** optional **
OM4L.LinkEF System ~
OM4L.LoadEF System.efb OM4L.CompareEF System.efb

Commands for generation of UART
OM4P.Compile RS232.Mod/s ~

Command for generation of tools
OM4P.Compile Tools.Mod/s HeapTool.Mod/s SystemLog.Mod/s BMP.Mod/s Image.Mod/s FilesEx.Mod/s ~

Commands for generation of the compiler
OM4P.Compile FLASH.Mod/s OM4S.Mod/s OM4B.Mod/s OM4A.Mod/s OM4G.Mod/s OM4P.Mod/s
  OM4X.Mod/s OM4L.Mod/s OM4D.Mod/s OM4Tool.Mod/s StackTrace.Mod/s ~
** optional **
OM4L.LinkEF Modules System Edit OnStartup Image OM4L OM4P ~
OM4L.LoadEF OM4P.efb OM4L.CompareEF OM4P.efb

Commands for generation of graphic system
OM4P.Compile Graphics.Mod/s GraphicFrames.Mod/s Draw.Mod/s Rectangles.Mod/s Curves.Mod/s
  MacroTool.Mod/s GraphTool.Mod/s ~

Command for generating programs
OM4P.Compile Hilbert.Mod Sierpinski.Mod Blink.Mod Stars.Mod ~

OM4Tool.DecBin Modules.bin ~

Tool for compiler debugging
BugsCompile.Tool

Staging Compiler for heavy evolution. BE VERY CAUTIOUS
System.CopyFiles OM4B.Mod=>OM4B2.Mod OM4A.Mod=>OM4A2.Mod OM4G.Mod=>OM4G2.Mod OM4P.Mod=>OM4P2.Mod ~
<<rename modules and make changes on sources>>
Net.SendFiles CS OM4B2.Mod OM4A2.Mod OM4G2.Mod OM4P2.Mod ~
OM4P.Compile OM4A2.Mod OM4B2.Mod OM4G2.Mod OM4P2.Mod ~
OM4P2.Compile OM4A2.Mod/s OM4B2.Mod OM4G2.Mod OM4P2.Mod ~
System.Free OM4P2 OM4G2 OM4Tool OM4D OM4A2 ~
OM4P2.Compile testBug2.Mod ~
Install new compiler
System.CopyFiles OM4B2.Mod=>OM4B.Mod OM4A2.Mod=>OM4A.Mod OM4G2.Mod=>OM4G.Mod OM4P2.Mod=>OM4P.Mod ~
Net.SendFiles CS OM4B.Mod OM4A.Mod OM4G.Mod OM4P.Mod ~
<<rename modules with original names>>
OM4P2.Compile OM4B.Mod OM4G.Mod OM4P.Mod ~

System.CopyFiles OM4S.Mod => OM4S2.Mod ~
