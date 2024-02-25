# oberon_stm32f4
Portage of Oberon system to stm32f429i-disco board

Work in progress.

Software side:

Code generator for Cortex-M4F processor is done and tested.
Linker and export tool are done and tested.

Bootloader, inner, outer and net modules are done.

Stable: Bootloader, inner, outer modules

Usable: net module, but relaibility has to be inproved.

Next step: adapt graphic modules

Change in oberon 07 compiler:

This Oberon compiler allow declaration of unitialized pointers on stack.
Those pointer are not checked at runtime, so they are not safe until they are properly intialized.
I made a change in the compiler to allow detection of the declaration of local variables containing pointers.
The developer must check the code to be sure that no bad use is made with these variables.
For example, if a Files.Rider is declared as a local variable, no use of the file member before the rider (eg. via Files.Base) has been initialized with Files.Set.
When the developer has determined that the use of the local variable is safe, he or she must mark the variable with an exclamation mark (!) in its declaration.

Oberon runs now on the STM32F429I-DISCO base board:

![OberonRunning](https://github.com/ef15c/oberon_stm32f4/assets/8286839/77827576-acf8-4043-8afc-f022df2e06ab)

Hardware side:

Base board is tested:
SD Card, VGA, PS2 mouse and keyboard and nRF24L01+ interface are OK.

![equippedBaseBoard](https://github.com/ef15c/oberon_stm32f4/assets/8286839/a8bed1ea-580c-429d-b511-b619743729e1)

![populatedBaseBoard](https://github.com/ef15c/oberon_stm32f4/assets/8286839/60b433b5-c5a2-4ea3-9ac8-12d0c1df88bf)
