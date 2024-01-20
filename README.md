# oberon_stm32f4
Portage of Oberon system to stm32f429i-disco board


Work in progress.

Software side:

Code generator for Cortex-M4F processor is done and tested.
Linker and export tool are done and tested.

Bootloader, inner and outer modules are done.

Preliminary tests of modules Kernel, FileDir, Files and Fonts are OK.
Outer core modules are OK.

Oberon runs now on the STM32F429I-DISCO base board:

![OberonRunning](https://github.com/ef15c/oberon_stm32f4/assets/8286839/77827576-acf8-4043-8afc-f022df2e06ab)

Hardware side:

Base board is tested:
SD Card, VGA, PS2 mouse and keyboard and nRF24L01+ interface are OK.

![equippedBaseBoard](https://github.com/ef15c/oberon_stm32f4/assets/8286839/a8bed1ea-580c-429d-b511-b619743729e1)

![populatedBaseBoard](https://github.com/ef15c/oberon_stm32f4/assets/8286839/60b433b5-c5a2-4ea3-9ac8-12d0c1df88bf)
