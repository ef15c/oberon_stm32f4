MODULE TestCM4;
  IMPORT Texts, Oberon;

  CONST BW = 0F0009000H;
   (* Powers of two *)
    C27=8000000H; C26=4000000H; C24=1000000H; C23=800000H; C22=400000H; 
    C21=200000H; C20=100000H; C16=10000H; C13=2000H; C12=1000H; C11=800H;     C10=400H; C8=100H;
    C7=80H; C4=10H; C1=2;

  VAR W: Texts.Writer;
    
PROCEDURE encB(disp: LONGINT): LONGINT;
  (* Encode B.W <label>
     1 1 1 1 0 S imm10 1 0 J1 1 J2 imm11
     I1 = NOT(J1 EOR S); I2 = NOT(J2 EOR S); imm32 = SignExtend(S:I1:I2:imm10:imm11:'0', 32);
     if InITBlock() && !LastInITBlock() then UNPREDICTABLE;
  *) 
  VAR res: LONGINT;
    S, J1, J2: BYTE;
    imm10, imm11: LONGINT;
  BEGIN
    ASSERT(~ODD(disp));
    ASSERT(disp >= -16777216);
    ASSERT(disp < 16777216);
    disp := disp DIV 2;
    S := disp DIV C23 MOD C1;
    disp := disp MOD C23;
    (*J1 = NOT(I1) EOR S
     J2 = NOT(I2) EOR S*)
    J1 := disp DIV C22 MOD C1;
    disp := disp MOD C22;
    J2 := disp DIV C21 MOD C1;
    disp := disp MOD C21;
    IF S=0 THEN
      J1 := 1-J1;
      J2 := 1-J2;
    END;
    imm10 := disp DIV C11 MOD C10;    imm11 := disp MOD C11; 
    RETURN BW + S*C26 + imm10*C16+J1*C13+J2*C11 + imm11
  END encB;
  
  PROCEDURE runTest(disp: LONGINT);
  BEGIN
    Texts.WriteString(W,"disp "); Texts.WriteHex(W, disp);
    Texts.WriteString(W," is encoded as "); Texts.WriteHex(W, encB(disp));
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END runTest;
  
  PROCEDURE Encode*;
  BEGIN
    runTest(8000014);
    runTest(4000008);
(*    runTest(0A0000000H); *)
    runTest(-20);
    runTest(2)
  END Encode;
BEGIN
  Texts.OpenWriter(W)
END TestCM4.
(*disp  007A120E is encoded as  F3A1B107disp  003D0908 is encoded as  F3D0BC84disp  FFFFFFF6 is encoded as  EFFFBFFBdisp  00000002 is encoded as  F000B801*)
