Commands for generation of the MSP430 target compiler
OM4P.Compile OMSPS.Mod/s OMSPB.Mod/s OMSPA.Mod/s OMSPG.Mod/s OMSPP.Mod/s
 OMSPD.Mod/s OMSPTool.Mod/s OMSPL.Mod/s ~

MSP430 specific code
OMSPP.Compile msp430g2553.Mod/s Traps.Mod/s Arith.Mod/s ~

Test programs
OMSPP.Compile testFunc.Mod testFor.Mod testDeRef.Mod testCond.Mod testAssert.Mod
testIntRelat.Mod testIntArith.Mod testInEx.Mod testInc.Mod testIfThen.Mod testLoadAdr.Mod testNeg.Mod
testParam.Mod testProc.Mod testRecord.Mod testSet.Mod testStore.Mod testString.Mod/s testImportString.Mod
testStringRelat.Mod testTypTag.Mod testSFuncs.Mod testSFuncs2.Mod/s testSFuncs3.Mod testSProcs.Mod testArray.Mod
testExport.Mod/s testImport.Mod testRepeat.Mod testSelector.Mod testVector.Mod Facto.Mod testPRU.Mod/s
testFunc2.Mod testFrame.Mod testVarParam.Mod testSProcs2.Mod testRecStr.Mod ISRTrap.Mod testInit.Mod
testInitImp.Mod ~

OMSPL.Link 32 4000H 200H testFrame ~ Edit.Open testFrame.txt
OMSPL.Link 32 4000H 200H testTypTag ~ Edit.Open testTypTag.txt
OMSPL.Link 32 4000H 200H testString ~ Edit.Open testString.txt
OMSPL.Link 32 4000H 200H testImportString ~ Edit.Open testImportString.txt
OMSPL.Link 32 4000H 200H testInitImp ~ Edit.Open testInitImp.txt

Texas Instruments examples
OMSPP.Compile msp430g2x13ca01.Mod msp430g2x13ca02.Mod msp430g2x13ca03.Mod
 msp430g2x33adc1001.Mod msp430g2x33adc1002.Mod msp430g2x33adc1003.Mod msp430g2x33adc1004.Mod
 msp430g2x33adc1005.Mod
 msp430g2xx3ta01.Mod msp430g2xx3lpm3vlo.Mod ~

OMSPL.Link 32 4000H 200H msp430g2x13ca01 ~
OMSPL.Link 32 4000H 200H msp430g2x13ca02 ~
OMSPL.Link 32 4000H 200H msp430g2x13ca03 ~

OMSPL.Link 32 4000H 200H msp430g2x33adc1001 ~
OMSPL.Link 32 4000H 200H msp430g2x33adc1002 ~
OMSPL.Link 32 4000H 200H msp430g2x33adc1003 ~
OMSPL.Link 32 4000H 200H msp430g2x33adc1004 ~
OMSPL.Link 32 4000H 200H msp430g2x33adc1005 ~

OMSPL.Link 32 4000H 200H msp430g2xx3ta01 ~
OMSPL.Link 32 4000H 200H msp430g2xx3lpm3vlo ~
