# Oberon STM32F4
Portage of Oberon system to stm32f429i-disco board<br><br>
**Version 13 released!**
## Oberon System
A rudimentary image manipulation module has been added. It allows to display 8bpp indexed colors BMP and can take screenshots.
  
![Screenshot](https://raw.githubusercontent.com/ef15c/oberon_stm32f4/refs/heads/main/sources/graph/screenshot7C99C356.png)
  
**The 12th release contains a major improvement:** the modules code and strings can be hosted
 in the flash memory of the microcontroller and be executed in place.
The global data can also be placed is SRAM.  
Previously, the modules had too be loaded in the SDRAM to be executed.  
There are a lot of advantages doing this:  

* The code executes 8 times faster, by avoiding the competition between CPU and VGA system for SDRAM access.  
* More SDRAM is available for modules that remains in SDRAM and for the heap.
* If the Oberon system and the compiler are both placed in embedded flash memory,
 the system is guaranteed to boot and compile even if incoherent recompilation has been done on vital modules.
 
 To put modules in embedded flash, follow this procedure:
 
 * Prelink the modules using the command **OM4L.LinkEF**. Example: `OM4L.LinkEF Modules System Edit OM4P ~`  
This will produce a .efb file that will be later placed in the embedded flash memory.
 * Reboot the station in legacy SDRAM mode by pressing the SW1 button on the base board and the reset button on the SMT429I-DISCO board.
  This is mandatory because it is not safe to modify the embedded flash memory while executing it.
 * Install the .efb file using the command **OM4L.LoadEF**. Example: `OM4L.LoadEF OM4P.efb`  
The installation can be verified by comparing the .efb file and the content of the embedded flash,
 using the command **OM4L.CompareEF**. Example: `OM4L.CompareEF OM4P.efb`  
The installation is successful if the output of this command ends with the word "same".
 * Reboot the station without pressing SW1 button. The station should now execute the Oberon system and the compiler from embedded flash.
 This can be checked with the command **System.ShowModules**. In the window that appears,
  all lines refering a module stored in embedded flash will end with the number -1. Example: `OM4P	 0802E7B4 0802F1F4  -1`

  
Reminder: starting wiht the release 9, it is now easy to launch user actions immediately after system startup.
Put your code in the initialization section of the OnStartup module and compile it.

![OberonMSP430compiler](https://github.com/user-attachments/assets/6926baf1-dc6c-406c-8f0f-f2973136a3e1)

<br>
QWERTY keyboard can be activated by middle clicking on the text "OM4P.Compile InputQwerty.Mod ~"<br>
displayed in yellow in the middle of the System.Tool window. Restart the system to load the updated Input module.<br>
<br>

![System_Tool](https://github.com/ef15c/oberon_stm32f4/assets/8286839/867c913a-35e0-49ab-a81b-0c658132c971)

![OberonRunningR3](https://github.com/ef15c/oberon_stm32f4/assets/8286839/32ec5160-54e4-4188-9445-5ce0f7f4f413)

![OberonRunningR2](https://github.com/ef15c/oberon_stm32f4/assets/8286839/87f5d58e-1d84-4705-a15d-ad8de9eb8cd8)

<b>Changes in oberon 07 compiler:</b>

<b>Registers usage control in procedures</b><br>
Cortex M4 microcontrollers save automatically a set of registers on stack when servicing an interruption.
If an Oberon exception handler contains too complicated expressions, there is a risk that a non saved register is used.
To prevent that case to happen, I introduced a new notation ^n after the PROCEDURE keyword:<br><br>
PROCEDURE^3 handler;<br>
BEGIN ....<br>
END handler;<br><br>
With this information, the compiler can check  that no more than n registers are used. The save/restoration instructions are automatically generated according to the declared number of used registers.<br>

<b>Unsafe local variables marking</b><br>
This Oberon compiler allow allocation of unitialized pointers on stack.
Those pointers are not checked at runtime, so they are not safe until they are properly intialized.

I made a change in the compiler to allow detection of the declaration of local variables containing pointers.
The developer must check the code to be sure that no bad use is made with these variables.

For example, assume that a Files.Rider is declared as a local variable. Using of the "file" member (eg. via Files.Base) is unsafe until the rider has been initialized with Files.Set.

When the developer has determined that the code usage of the local variable is safe, he or she must mark the variable with an exclamation mark (!) in its declaration.


Oberon runs now on the STM32F429I-DISCO base board:

![OberonRunning](https://github.com/ef15c/oberon_stm32f4/assets/8286839/77827576-acf8-4043-8afc-f022df2e06ab)

Hardware side:

![equippedBaseBoard](https://github.com/ef15c/oberon_stm32f4/assets/8286839/a8bed1ea-580c-429d-b511-b619743729e1)

![populatedBaseBoard](https://github.com/ef15c/oberon_stm32f4/assets/8286839/60b433b5-c5a2-4ea3-9ac8-12d0c1df88bf)
