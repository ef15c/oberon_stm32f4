# oberon_stm32f4
Portage of Oberon system to stm32f429i-disco board

<b>Version 2 released!</b><br>
![OberonRunningR2](https://github.com/ef15c/oberon_stm32f4/assets/8286839/87f5d58e-1d84-4705-a15d-ad8de9eb8cd8)

Improved SD card write reliability<br>
Improved VGA signals<br>
Improved keyboard support
PS/2, RTC, nRF24L01+ (CRC + SPI) drivers ported form C to Oberon<br>
Minor bugs correction<br>

<b>Changes in oberon 07 compiler:</b>

<b>Registers usage control in procedures</b><br>
Cortex M4 microcontrollers save automatically a set of registers on stack when servicing an interruption.
If an Oberon exception handler contains too complicated expressions, there is a risk that a non saved register is used.
To prevent that case to happen, I have introduce a new notation ^n after the PROCEDURE keyword:<br><br>
PROCEDURE^3 handler;<br>
BEGIN ....<br>
END handler;<br><br>
With this information, the compiler can check  that no more than n register are used. The save/restoration instructions are automatically generated according to the declared number of used registers.<br>

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
