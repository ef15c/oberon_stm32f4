Commands for generation of the bootloader
OM4P.Compile BootLoadM4.Mod ~
OM4X.WriteASM BootLoadM4.m4c BootLoadM4.s ~


Commands for generation of the boot file (inner core)
OM4P.Compile KernelM4.Mod/s ~ 
OM4P.Compile  FileDir.Mod/s ~
OM4P.Compile Files.Mod/s ~
OM4P.Compile ModulesM4.Mod/s ~ 
OM4L.Link Modules ~
OM4L.Load Modules.bin ~

OM4Tool.DecBin Modules.bin ~

Commands for generaion of outer core
OM4P.Compile InputM4.Mod/s ~
OM4P.Compile DisplayM4.Mod/s ~
OM4P.Compile Viewers.Mod/s ~
OM4P.Compile FontsM4.Mod/s ~
OM4P.Compile Texts.Mod/s ~
OM4P.Compile OberonM4.Mod/s ~
OM4P.Compile MenuViewers.Mod/s ~
OM4P.Compile TextFrames.Mod/s ~
OM4P.Compile SystemM4.Mod/s ~
OM4P.Compile Edit.Mod/s ~

Commands for generation of graphic system
OM4P.Compile Graphics.Mod ~
OM4P.Compile GraphicFramesM4.Mod ~
OM4P.Compile Draw.Mod ~
OM4P.Compile Rectangles.Mod ~
OM4P.Compile Curves.Mod ~
OM4P.Compile MacroTool.Mod ~
OM4P.Compile GraphTool.Mod ~

Commands for generation of the compiler
OM4P.Compile TextsEx.Mod/s ~
OM4P.Compile OM4S.Mod/s ~
OM4P.Compile OM4B.Mod/s ~
OM4P.Compile OM4A.Mod/s ~
OM4P.Compile OM4G.Mod/s ~
OM4P.Compile OM4P.Mod/s ~
OM4P.Compile OM4X.Mod/s ~
OM4P.Compile OM4L.Mod/s ~
OM4P.Compile OM4D.Mod/s ~

Command for generation of tools
OM4P.Compile OM4Tool.Mod/s ~
OM4P.Compile Tools.Mod/s ~

Commands for generation of net
OM4P.Compile SCCM4.Mod/s ~
OM4P.Compile NetM4.Mod/s ~


System.Directory *.m4c ~ System.Directory *.sm4 ~
