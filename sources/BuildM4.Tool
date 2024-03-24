Commands for generation of the bootloader
OM4P.Compile BootLoadM4.Mod ~
OM4X.WriteASM BootLoadM4.m4c BootLoadM4.s ~

Commands for generation of the boot file (inner core)
OM4P.Compile BSP.Mod/s KernelM4.Mod/s FileDir.Mod/s Files.Mod/s ModulesM4.Mod/s ~ 
OM4L.Link Modules ~
OM4L.Load Modules.bin ~

OM4Tool.DecBin Modules.bin ~

Commands for generation of outer core
OM4P.Compile PS2.Mod/s ~
OM4P.Compile InputM4.Mod/s DisplayM4.Mod/s Viewers.Mod/s FontsM4.Mod/s Texts.Mod/s 
  OberonM4.Mod/s MenuViewers.Mod/s TextFrames.Mod/s SystemM4.Mod/s Edit.Mod/s ~

Commands for generation of graphic system
OM4P.Compile Graphics.Mod/s GraphicFramesM4.Mod/s Draw.Mod Rectangles.Mod/s Curves.Mod/s
  MacroTool.Mod GraphTool.Mod ~

Commands for generation of the compiler
OM4P.Compile TextsEx.Mod/s OM4S.Mod/s OM4B.Mod/s OM4A.Mod/s OM4G.Mod/s OM4P.Mod/s
  OM4X.Mod/s OM4L.Mod/s OM4D.Mod/s ~

Command for generation of tools
OM4P.Compile OM4Tool.Mod/s Tools.Mod/s ~

Commands for generation of net
OM4P.Compile SCCM4.Mod/s NetM4.Mod/s ~

Command for generating programs
OM4P.Compile Hilbert.Mod/s Sierpinski.Mod/s Blink.Mod/s Stars.Mod/s ~

System.Directory *.m4c ~ System.Directory *.sm4 ~
