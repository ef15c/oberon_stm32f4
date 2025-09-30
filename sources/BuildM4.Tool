Commands for generation of the bootloader
OM4P.Compile BootLoad.Mod ~
OM4X.WriteFile BootLoad.m4c BootLoad.hex 08000000H 1ACH 20030000H ~
Net.SendFiles CS BootLoad.hex ~
OM4X.Load BootLoad.hex
(*no more used: OM4X.WriteASM BootLoad.m4c BootLoad.s ~*)

Commands for generation of the boot file (inner core)
OM4P.Compile BSP.Mod SDCard.Mod LongDiv.Mod Kernel.Mod FileDir.Mod Files.Mod Modules.Mod ~
OM4L.Link Modules ~
OM4L.Load Modules.bin ~
 ** or/and **
OM4L.LinkEF Modules ~
OM4L.LoadEF Modules.efb OM4L.CompareEF Modules.efb

Commands for generation of outer core
OM4P.Compile PS2.Mod InputAzerty.Mod Display.Mod Viewers.Mod Fonts.Mod Texts.Mod
  Oberon.Mod MenuViewers.Mod TextFrames.Mod System.Mod Edit.Mod OnStartup.Mod ~
** optional **
OM4L.LinkEF System ~
OM4L.LoadEF System.efb OM4L.CompareEF System.efb

Commands for generation of net
OM4P.Compile TextsEx.Mod SCC.Mod Net.Mod ~
OM4P.Compile RS232.Mod ~

Commands for generation of the compiler
OM4P.Compile CRC32.Mod FilesEx.Mod OM4S.Mod OM4B.Mod OM4A.Mod OM4G.Mod OM4P.Mod
  OM4X.Mod FLASH.Mod OM4L.Mod OM4D.Mod OM4Tool.Mod StackTrace.Mod ~
** optional **
OM4L.LinkEF Modules System Edit OnStartup OM4L OM4P ~
OM4L.LoadEF OM4P.efb OM4L.CompareEF OM4P.efb

Command for generation of tools
OM4P.Compile Tools.Mod HeapTool.Mod SystemLog.Mod BMP.Mod Image.Mod ~

Commands for generation of graphic system
OM4P.Compile Graphics.Mod GraphicFrames.Mod Draw.Mod Rectangles.Mod Curves.Mod
  MacroTool.Mod GraphTool.Mod ~

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
