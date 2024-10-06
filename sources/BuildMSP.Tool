Commands for generation of the MSP430 target compiler
OM4P.Compile OMSPS.Mod/s OMSPB.Mod/s OMSPA.Mod/s OMSPG.Mod/s OMSPP.Mod/s
 OMSPD.Mod/s OMSPTool.Mod/s OMSPL.Mod/s ~

MSP430 specific code
OMSPP.Compile msp430g2553.Mod/s Traps.Mod/s Arith.Mod/s MultiPrecisionArith.Mod/s ~

Test programs
OMSPP.Compile testFunc.Mod testFor.Mod testDeRef.Mod testCond.Mod testAssert.Mod testIntRelat.Mod testIntArith.Mod testInEx.Mod testInc.Mod testIfThen.Mod
 testLoadAdr.Mod testNeg.Mod testParam.Mod testProc.Mod testRecord.Mod testSet.Mod testStore.Mod testString.Mod/s testImportString.Mod testStringRelat.Mod
 testTypTag.Mod testSFuncs.Mod testSFuncs2.Mod/s testSFuncs3.Mod testSProcs.Mod testArray.Mod testExport.Mod/s testImport.Mod testRepeat.Mod testSelector.Mod
 testVector.Mod Facto.Mod testPRU.Mod/s testFunc2.Mod testFrame.Mod testVarParam.Mod testSProcs2.Mod testRecStr.Mod ISRTrap.Mod testInit.Mod testInitImp.Mod
 testRAMcode.Mod ~

OMSPL.Link 32 4000H 200H testFrame ~ OMSPL.Link 32 4000H 200H testTypTag ~ OMSPL.Link 32 4000H 200H testString ~
OMSPL.Link 32 4000H 200H testImportString ~ OMSPL.Link 32 4000H 200H testInitImp ~ OMSPL.Link 32 4000H 200H testRAMcode ~

Texas Instruments examples
Compilation
OMSPP.Compile msp430g2x13ca01.Mod msp430g2x13ca02.Mod msp430g2x13ca03.Mod ~

OMSPP.Compile msp430g2x33adc1001.Mod msp430g2x33adc1002.Mod msp430g2x33adc1003.Mod msp430g2x33adc1004.Mod  msp430g2x33adc1005.Mod msp430g2x33adc1006.Mod
 msp430g2x33adc1007.Mod msp430g2x33adc1008.Mod msp430g2x33adc1009.Mod msp430g2x33adc1010.Mod msp430g2x33adc1011.Mod msp430g2x33adc1012.Mod
 msp430g2x33adc1013.Mod msp430g2x33adc1014.Mod msp430g2x33adc1016.Mod msp430g2x33adc10temp.Mod ~

OMSPP.Compile msp430g2xx31.Mod msp430g2xx31vlo.Mod msp430g2xx3clks.Mod msp430g2xx3dcocalib.Mod msp430g2xx3dcoflashcal.Mod msp430g2xx3flashwrite01.Mod
 msp430g2xx3LFxtalnmi.Mod msp430g2xx3lpm3.Mod msp430g2xx3lpm3vlo.Mod msp430g2xx3nmi.Mod ~

OMSPP.Compile msp430g2xx3P101.Mod msp430g2xx3P102.Mod msp430g2xx3P103.Mod msp430g2xx3P104.Mod ~

OMSPP.Compile msp430g2xx3ta01.Mod msp430g2xx3ta02.Mod msp430g2xx3ta03.Mod msp430g2xx3ta04.Mod msp430g2xx3ta05.Mod msp430g2xx3ta06.Mod
 msp430g2xx3ta07.Mod msp430g2xx3ta08.Mod msp430g2xx3ta10.Mod msp430g2xx3ta11.Mod msp430g2xx3ta13.Mod msp430g2xx3ta14.Mod
 msp430g2xx3ta16.Mod msp430g2xx3ta17.Mod msp430g2xx3ta19.Mod msp430g2xx3ta20.Mod  msp430g2xx3ta21.Mod msp430g2xx3tauart2400.Mod
msp430g2xx3tauart9600.Mod ~

OMSPP.Compile msp430g2xx3uscia0irda01.Mod msp430g2xx3uscia0spi09.Mod msp430g2xx3uscia0spi10.Mod ~

Link
OMSPL.Link 32 4000H 200H msp430g2x13ca01 ~ OMSPL.Link 32 4000H 200H msp430g2x13ca02 ~
OMSPL.Link 32 4000H 200H msp430g2x13ca03 ~

OMSPL.Link 32 4000H 200H msp430g2x33adc1001 ~ OMSPL.Link 32 4000H 200H msp430g2x33adc1002 ~ OMSPL.Link 32 4000H 200H msp430g2x33adc1003 ~
OMSPL.Link 32 4000H 200H msp430g2x33adc1004 ~ OMSPL.Link 32 4000H 200H msp430g2x33adc1005 ~ OMSPL.Link 32 4000H 200H msp430g2x33adc1006 ~
OMSPL.Link 32 4000H 200H msp430g2x33adc1007 ~ OMSPL.Link 32 4000H 200H msp430g2x33adc1008 ~ OMSPL.Link 32 4000H 200H msp430g2x33adc1009 ~
OMSPL.Link 32 4000H 200H msp430g2x33adc1010 ~ OMSPL.Link 32 4000H 200H msp430g2x33adc1011 ~ OMSPL.Link 32 4000H 200H msp430g2x33adc1012 ~
OMSPL.Link 32 4000H 200H msp430g2x33adc1013 ~ OMSPL.Link 32 4000H 200H msp430g2x33adc1014 ~ OMSPL.Link 32 4000H 200H msp430g2x33adc1016 ~
OMSPL.Link 32 4000H 200H msp430g2x33adc10temp ~

OMSPL.Link 32 4000H 200H msp430g2xx31 ~ OMSPL.Link 32 4000H 200H msp430g2xx31vlo ~ OMSPL.Link 32 4000H 200H msp430g2xx3clks ~
OMSPL.Link 32 4000H 200H msp430g2xx3dcocalib ~ OMSPL.Link 32 4000H 200H msp430g2xx3dcoflashcal ~ OMSPL.Link 32 4000H 200H msp430g2xx3flashwrite01 ~
OMSPL.Link 32 4000H 200H msp430g2xx3LFxtalnmi ~ OMSPL.Link 32 4000H 200H msp430g2xx3lpm3 ~ OMSPL.Link 32 4000H 200H msp430g2xx3lpm3vlo ~
OMSPL.Link 32 4000H 200H msp430g2xx3nmi ~

OMSPL.Link 32 4000H 200H msp430g2xx3P101 ~ OMSPL.Link 32 4000H 200H msp430g2xx3P102 ~ OMSPL.Link 32 4000H 200H msp430g2xx3P103 ~
OMSPL.Link 32 4000H 200H msp430g2xx3P104 ~

OMSPL.Link 32 4000H 200H msp430g2xx3ta01 ~ OMSPL.Link 32 4000H 200H msp430g2xx3ta02 ~ OMSPL.Link 32 4000H 200H msp430g2xx3ta03 ~
OMSPL.Link 32 4000H 200H msp430g2xx3ta04 ~ OMSPL.Link 32 4000H 200H msp430g2xx3ta05 ~ OMSPL.Link 32 4000H 200H msp430g2xx3ta06 ~
OMSPL.Link 32 4000H 200H msp430g2xx3ta07 ~ OMSPL.Link 32 4000H 200H msp430g2xx3ta08 ~ OMSPL.Link 32 4000H 200H msp430g2xx3ta10 ~
OMSPL.Link 32 4000H 200H msp430g2xx3ta11 ~ OMSPL.Link 32 4000H 200H msp430g2xx3ta13 ~ OMSPL.Link 32 4000H 200H msp430g2xx3ta14 ~
OMSPL.Link 32 4000H 200H msp430g2xx3ta16 ~ OMSPL.Link 32 4000H 200H msp430g2xx3ta17 ~ OMSPL.Link 32 4000H 200H msp430g2xx3ta19 ~
OMSPL.Link 32 4000H 200H msp430g2xx3ta20 ~ OMSPL.Link 32 4000H 200H msp430g2xx3ta21 ~ OMSPL.Link 32 4000H 200H msp430g2xx3tauart2400 ~
OMSPL.Link 32 4000H 200H msp430g2xx3tauart9600 ~

OMSPL.Link 32 4000H 200H msp430g2xx3uscia0irda01 ~ OMSPL.Link 32 4000H 200H msp430g2xx3uscia0spi09 ~ OMSPL.Link 32 4000H 200H msp430g2xx3uscia0spi10 ~
