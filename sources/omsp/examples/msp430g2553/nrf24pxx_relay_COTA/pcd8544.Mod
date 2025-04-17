MODULE pcd8544;
  IMPORT M := msp430g2553, MP := MultiPrecisionArith, Delay := msp430delay;
  (*
   *
   *  Created on: 24 avr. 2013
   *      Author: C. Schoffit
   09.04.25: Oberon portage

   Copyright (c) 2013 Christian Schoffit sphpn@free.fr

    pcd8544 module is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    pcd8544 module is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with pcd8544 module; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)

  CONST PO_NCE = M.P2OUT; NCE = {5}; (*LCD selection pin*)
    (*P2.5*) PO_DC = M.P2OUT; DC = {6}; (*P2.6*)
    PO_NRST* = M.P2OUT; NRST* = {7}; (*P2.7*) PO_NLIGHT* = M.P1OUT; NLIGHT* = {0}; (*P1.0*)

    HPIXELS =  84; VBANKS =  6; (*screen size*)

    (*Instruction flags*)
    DATA = 8; (*specify data instead of command*) INVERT = {0..8};

    (*instructions available in all modes*)
    NOp = {}; NOP_MASK = {0..8}; FUNCTION_SET = {5}; FUNCTION_SET_MASK = {3..8}; H = 0; V = 1; PD = 2; (*function flags*)

    (*instructions available in basic mode*)
    DISPLAY_CONTROL = {3}; DISPLAY_CONTROL_MASK = {1, 3..8}; D = 2; E = 0;
    SET_Y_ADDRESS = {6}; SET_Y_ADDRESS_MASK = {3..8};
    SET_X_ADDRESS = {7}; SET_X_ADDRESS_MASK = {7..8};

    (*instructions available in extended mode*)
    TEMP_CONTROL = {2}; TEMP_CONTROL_MASK = {2..8};
    BIAS_SYSTEM = {4}; BIAS_SYSTEM_MASK = {3..8};
    SET_VOP = {7}; SET_VOP_MASK = {7..8};

    (*Characters glyphs*)
    GLYPH_WIDTH = 5;
    (*basic font*)
    font = $ 
      00 00 00 00 00      00 00 5F 00 00      00 07 00 07 00      14 7F 14 7F 14
      24 2A 7F 2A 12      23 13 08 64 62      36 49 55 22 50      00 05 03 00 00
      00 1C 22 41 00      00 41 22 1C 00      14 08 3E 08 14      08 08 3E 08 08
      00 50 30 00 00      08 08 08 08 08      00 60 60 00 00      20 10 08 04 02
      3E 51 49 45 3E      00 42 7F 40 00      42 61 51 49 46      21 41 45 4B 31
      18 14 12 7F 10      27 45 45 45 39      3C 4A 49 49 30      01 71 09 05 03
      36 49 49 49 36      06 49 49 29 1E      00 36 36 00 00      00 56 36 00 00
      08 14 22 41 00      14 14 14 14 14      00 41 22 14 08      02 01 51 09 06
      32 49 79 41 3E      7E 11 11 11 7E      7F 49 49 49 36      3E 41 41 41 22
      7F 41 41 22 1C      7F 49 49 49 41      7F 09 09 09 01      3E 41 49 49 7A
      7F 08 08 08 7F      00 41 7F 41 00      20 40 41 3F 01      7F 08 14 22 41
      7F 40 40 40 40      7F 02 0C 02 7F      7F 04 08 10 7F      3E 41 41 41 3E
      7F 09 09 09 06      3E 41 51 21 5E      7F 09 19 29 46      46 49 49 49 31
      01 01 7F 01 01      3F 40 40 40 3F      1F 20 40 20 1F      3F 40 38 40 3F
      63 14 08 14 63      07 08 70 08 07      61 51 49 45 43      00 7F 41 41 00
      02 04 08 10 20      00 41 41 7F 00      14 3E 55 41 22      40 40 40 40 40
      00 06 09 09 06      20 54 54 54 78      7F 48 44 44 38      38 44 44 44 20
      38 44 44 48 7F      38 54 54 54 18      08 7E 09 01 02      0C 52 52 52 3E
      7F 08 04 04 78      00 44 7D 40 00      20 40 44 3D 00      7F 10 28 44 00
      00 41 7F 40 00      7C 04 18 04 78      7C 08 04 04 78      38 44 44 44 38
      7C 14 14 14 08      08 14 14 18 7C      7C 08 04 04 08      48 54 54 54 20
      04 3F 44 40 20      3C 40 40 20 7C      1C 20 40 20 1C      3C 40 30 40 3C
      44 28 10 28 44      0C 50 50 50 3C      44 64 54 4C 44      00 08 36 41 00
      00 00 7F 00 00      00 41 36 08 00      00 44 7C 40 00$;
 
    (*"dead" and miscellaneous characters*)
    composeFont = $
      10 08 08 10 08      00 02 00 02 00      00 02 01 02 00      00 01 02 00 00
      00 00 02 01 00      00 80 40 00 00      7E 43 43 7E 00      7E 73 73 7E 00
      7E 7F 7F 7E 00      20 3C 7E 3C 20$;

  VAR (*Store LCD state cannot be queried from the device, so must be memorized*)
    XAddr, YAddr: BYTE; FunctionSet: BYTESET; composeChar: CHAR;

  PROCEDURE send(d: SET*);
  (*send a command or data to LCD*)
  BEGIN BIC(PO_NCE^, NCE); (*Select LCD for SPI communication*)
    (*Memorize state of LCD screen*)
    IF d*FUNCTION_SET_MASK = FUNCTION_SET THEN FunctionSet := d
    ELSIF ~(H IN FunctionSet) & (d*SET_Y_ADDRESS_MASK = SET_Y_ADDRESS) THEN
      YAddr := ORD(d*(SET_Y_ADDRESS_MASK/INVERT))
    ELSIF ~(H IN FunctionSet) & (d*SET_X_ADDRESS_MASK = SET_X_ADDRESS) THEN
      XAddr := ORD(d*(SET_X_ADDRESS_MASK/INVERT))
    END;
    IF DATA IN d THEN BIS(PO_DC^, DC) ELSE BIC(PO_DC^, DC) END; (*Set Data/Command line for Nokia 5110 LCD*)
    REPEAT UNTIL BIT(M.IFG2^, M.UCA0TXIFG); (*Wait for USCI availability*)
    M.UCA0TXBUF^ := ORD(d); (*USCI A is ready, send character*)
    REPEAT UNTIL ~BIT(M.UCA0STAT^, M.UCBUSY); (*Wait for end of transmission*)
    IF DATA IN d THEN (*Send data : need to update X and Y addresses*)
      IF  V IN FunctionSet THEN INC(YAddr); (*One bank down to the bottom*)
        IF YAddr >= VBANKS THEN YAddr := 0; INC(XAddr); (*One row to the right*)
          IF XAddr >= HPIXELS THEN XAddr := 0 END
        END
      ELSE (*Horizontal addressing*) INC(XAddr); (*One row to the right*)
        IF XAddr >= HPIXELS THEN XAddr := 0; INC(YAddr); (*One bank down to the bottom*)
          IF YAddr >= VBANKS THEN YAddr := 0 END
        END
      END
    END;
    BIS(PO_NCE^, NCE) (*Deselect LCD for SPI communication*)
  END send;

  PROCEDURE WriteChar*(car: CHAR);
    (*Write a character on LCD Screen*)
    VAR i: INTEGER; column: BYTESET;
  BEGIN
    IF (car > 88X) OR (car < 20X) THEN (*Invalid character*) car := "?" END;
    IF car > 7EX (*Load accent in compose character*) THEN composeChar := car
    ELSE
      FOR i := 0 TO 4 DO (*Compose character with accent and send it to LCD*)
        column := TOSET(ORD(font[i + (ORD(car) - 20H)*GLYPH_WIDTH]));
        IF composeChar # 0X THEN BIS(column, composeFont[i + (ORD(composeChar) - 7FH)*GLYPH_WIDTH]) END;
        send({DATA} + column);
      END; send({DATA}); (*Space between characters*) composeChar := 0X
    END
  END WriteChar;

  PROCEDURE WriteString*(string: ARRAY OF CHAR);
    (* Write a string on LCD Screen *)
    VAR i: INTEGER;
  BEGIN i := 0; WHILE string[i] # 0X DO WriteChar(string[i]); INC(i) END
  END WriteString;

  PROCEDURE SetAddr*(xAddr, yAddr: BYTE);
    (*Set address of next LCD write*)
    VAR oldFunctionSet: BYTESET;
  BEGIN oldFunctionSet := FunctionSet; (* Store current Function set in order to restore it before return *)
    IF H IN FunctionSet THEN send(FUNCTION_SET) END; (*Request basic instruction set*)
    send(SET_X_ADDRESS + TOSET(xAddr)); send(SET_Y_ADDRESS + TOSET(yAddr));
    IF oldFunctionSet # FunctionSet THEN send(oldFunctionSet) END (*Restore previous function set*)
  END SetAddr;

  PROCEDURE Clear*;
    VAR i: INTEGER;
  BEGIN SetAddr(0, 0); (*Set X=0, Y=0*)
    FOR i := HPIXELS*VBANKS - 1 TO 0 BY -1 DO send({DATA}) END (*Clear RAM*)
  END Clear;

  PROCEDURE Init*;
  BEGIN send(FUNCTION_SET + {H}); (* function set PD = 0 and V = 0, select extended instruction set (H = 1 mode) *)
    Delay.CyclesX3(10);
    send(TEMP_CONTROL); (*set TC = 00 *) send(BIAS_SYSTEM + TOSET(3)); (*set BS = 011*)
    send(SET_VOP +  TOSET(3AH)); (* set VOP =  a+58 x b [V]*)
    send(FUNCTION_SET); (*select normal instruction set (H = 0 mode)*)
    send(DISPLAY_CONTROL + {D}); (*display control set normal mode (D = 1 and E = 0)*)
  END Init;

  PROCEDURE SetVop*(vop: INTEGER);
    VAR oldFunctionSet: BYTESET;
  BEGIN oldFunctionSet := FunctionSet;
    IF ~(H IN FunctionSet) THEN send(FUNCTION_SET + {H}) END; (*Request extended instruction set*)
    send(SET_VOP +  TOSET(vop)*(SET_VOP_MASK/INVERT)); (*set VOP = a + vop x b volts*)
    IF oldFunctionSet # FunctionSet THEN send(oldFunctionSet) END (*Restore previous function set*)
  END SetVop;

  PROCEDURE WriteLongint*(th, tl: INTEGER; nx, ny, nbc: INTEGER; pad: CHAR);
    (* th, tl : value to output on display
     * nx, ny : screen coordinates in character unit
     * nbc : number of digits to output
     * pad : padding character*)
    VAR dl, dh, p: INTEGER;
  BEGIN p := nx + nbc - 1;
    (*Display the number*)
    REPEAT dh := 0; dl := 10; MP.DivLongLong(th, tl, dh, dl); (*d : = t%10; t /= 10;*)
      SetAddr(6*p, ny); DEC(p);  (*On positionne l'adresse d'affichage*)
      WriteChar(CHR(dl + ORD("0")));
    UNTIL (th = 0) & (tl = 0);
    SetAddr(6*nx, ny); WHILE p >= nx DO DEC(p); WriteChar(pad) END; (*clear heading characters*)
    SetAddr(6*(nx + nbc), ny)
  END WriteLongint;

BEGIN XAddr := 0; YAddr := 0; FunctionSet := {PD}; composeChar := 0X
END pcd8544.

OMSPTool.DecObj pcd8544.mpc
decode pcd8544.mpc
pcd8544 670AAC44 Flash  1352
imports:
	msp430g2553 F10488DC
	MultiPrecisionArith B561C064
	msp430delay EE6A4099
type descriptors

data     4
strings
|||||||_|||||$**#db6IU"P||||"A||A"|>>|P0|||``|| >QIE>|B@|BaQIF!AEK1'EEE9<JII0q	6III6II)|66|||V6||"A||A"Q	2IyA>~~III6>AAA"AA"IIIA			>AIIz|AA| @A?"A@@@@>AAA>			>AQ!^	)FFIII1?@@@? @ ?@8@?ccpaQIEC|AA| |AA|>UA"@@@@@|		 TTTxHDD88DDD 8DDH8TTT~	RRR>x|D}@| @D=|(D||A@||x|x8DDD8|||HTTT ?D@ <@@ | @ <@0@<D((DPPP<DdTLD|6A||||||A6||D|@||||||||||||||\80@||~CC~|~ss~|~~| <~< 
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0328 c 00CC c 0164 c 018E c 01CE c 01F8 c 0230 c 026C
fixup procedures in code space chains
 0266     0	 0000
 0300     0	 00CC
 031E     0	 018E
 029C     2	 0007
 0206     3	 0001
fixup handlers in vector space chains
fixup data in code space chains
 0336     0	 0003
 032A     0	 0000
 032E     0	 0001
 0332     0	 0002
fixup constants in code space chains
 013A     0	 01DC
 0118     0	 0000
fixup variables in constant space chains
fixup constants in constant space chains
entry =  0328
code   826
 0000	     C0F2	BIC.B #32,&41
 0002	     0020
 0004	     0029
 0006	     4405	MOV R4,R5
 0008	     F035	AND #504,R5
 000A	     01F8
 000C	     9035	CMP #32,R5
 000E	     0020
 0010	     2003	JNE $+8, goes to  0018
 0012	     44C2	MOV.B R4,&0
 0014	     0000
 0016	     3C1D	JMP $+60, goes to  0052
 0018	     B3D2	BIT.B #1,&20
 001A	     0014
 001C	     200C	JNE $+26, goes to  0036
 001E	     4405	MOV R4,R5
 0020	     F035	AND #504,R5
 0022	     01F8
 0024	     9035	CMP #64,R5
 0026	     0040
 0028	     2006	JNE $+14, goes to  0036
 002A	     4405	MOV R4,R5
 002C	     F035	AND #7,R5
 002E	     0007
 0030	     45C2	MOV.B R5,&0
 0032	     0000
 0034	     3C0E	JMP $+30, goes to  0052
 0036	     B3D2	BIT.B #1,&26
 0038	     001A
 003A	     200B	JNE $+24, goes to  0052
 003C	     4405	MOV R4,R5
 003E	     F035	AND #384,R5
 0040	     0180
 0042	     9035	CMP #128,R5
 0044	     0080
 0046	     2005	JNE $+12, goes to  0052
 0048	     4405	MOV R4,R5
 004A	     F035	AND #127,R5
 004C	     007F
 004E	     45C2	MOV.B R5,&0
 0050	     0000
 0052	     B034	BIT #256,R4
 0054	     0100
 0056	     2404	JEQ $+10, goes to  0060
 0058	     D0F2	BIS.B #64,&41
 005A	     0040
 005C	     0029
 005E	     3C03	JMP $+8, goes to  0066
 0060	     C0F2	BIC.B #64,&41
 0062	     0040
 0064	     0029
 0066	     B3E2	BIT.B #2,&3
 0068	     0003
 006A	     27FD	JEQ $-4, goes to  0066
 006C	     44C2	MOV.B R4,&103
 006E	     0067
 0070	     B3D2	BIT.B #1,&101
 0072	     0065
 0074	     23FD	JNE $-4, goes to  0070
 0076	     B034	BIT #256,R4
 0078	     0100
 007A	     2424	JEQ $+74, goes to  00C4
 007C	     B3E2	BIT.B #2,&56
 007E	     0038
 0080	     2411	JEQ $+36, goes to  00A4
 0082	     53D2	ADD.B #1,&50
 0084	     0032
 0086	     90F2	CMP.B #6,&132
 0088	     0006
 008A	     0084
 008C	     280A	JNC $+22, goes to  00A2
 008E	     43C2	MOV.B #0,&138
 0090	     008A
 0092	     53D2	ADD.B #1,&80
 0094	     0050
 0096	     90F2	CMP.B #84,&148
 0098	     0054
 009A	     0094
 009C	     2802	JNC $+6, goes to  00A2
 009E	     43C2	MOV.B #0,&154
 00A0	     009A
 00A2	     3C10	JMP $+34, goes to  00C4
 00A4	     53D2	ADD.B #1,&160
 00A6	     00A0
 00A8	     90F2	CMP.B #84,&166
 00AA	     0054
 00AC	     00A6
 00AE	     280A	JNC $+22, goes to  00C4
 00B0	     43C2	MOV.B #0,&172
 00B2	     00AC
 00B4	     53D2	ADD.B #1,&144
 00B6	     0090
 00B8	     90F2	CMP.B #6,&182
 00BA	     0006
 00BC	     00B6
 00BE	     2802	JNC $+6, goes to  00C4
 00C0	     43C2	MOV.B #0,&188
 00C2	     00BC
 00C4	     D0F2	BIS.B #32,&41
 00C6	     0020
 00C8	     0029
 00CA	     4130	RET
 00CC	     8221	SUB #4,SP
 00CE	     403F	MOV #136,R15
 00D0	     0088
 00D2	     915F	CMP.B 6(SP),R15
 00D4	     0006
 00D6	     2804	JNC $+10, goes to  00E0
 00D8	     90F1	CMP.B #32,6(SP)
 00DA	     0020
 00DC	     0006
 00DE	     2C03	JC $+8, goes to  00E6
 00E0	     40F1	MOV.B #63,6(SP)
 00E2	     003F
 00E4	     0006
 00E6	     403F	MOV #126,R15
 00E8	     007E
 00EA	     915F	CMP.B 6(SP),R15
 00EC	     0006
 00EE	     2C04	JC $+10, goes to  00F8
 00F0	     41D2	MOV.B 6(SP),&0
 00F2	     0006
 00F4	     0000
 00F6	     3C34	JMP $+106, goes to  0160
 00F8	     4381	MOV #0,0(SP)
 00FA	     0000
 00FC	     422F	MOV #4,R15
 00FE	     912F	CMP @SP,R15
 0100	     3829	JL $+84, goes to  0154
 0102	     415F	MOV.B 6(SP),R15
 0104	     0006
 0106	     807F	SUB.B #32,R15
 0108	     0020
 010A	     4F0E	MOV R15,R14
 010C	     5E0E	ADD R14,R14
 010E	     5E0E	ADD R14,R14
 0110	     5E0F	ADD R14,R15
 0112	     412E	MOV @SP,R14
 0114	     5F0E	ADD R15,R14
 0116	     503E	ADD #0,R14
 0118	     0000
 011A	     4EE1	MOV.B @R14,2(SP)
 011C	     0002
 011E	     93C2	CMP.B #0,&244
 0120	     00F4
 0122	     240E	JEQ $+30, goes to  0140
 0124	     425F	MOV.B &288,R15
 0126	     0120
 0128	     807F	SUB.B #127,R15
 012A	     007F
 012C	     4F0E	MOV R15,R14
 012E	     5E0E	ADD R14,R14
 0130	     5E0E	ADD R14,R14
 0132	     5E0F	ADD R14,R15
 0134	     412E	MOV @SP,R14
 0136	     5F0E	ADD R15,R14
 0138	     503E	ADD #0,R14
 013A	     0000
 013C	     DEE1	BIS.B @R14,2(SP)
 013E	     0002
 0140	     4034	MOV #256,R4
 0142	     0100
 0144	     4155	MOV.B 2(SP),R5
 0146	     0002
 0148	     D504	BIS R5,R4
 014A	     12B0	CALL #0
 014C	     0000
 014E	     5391	ADD #1,0(SP)
 0150	     0000
 0152	     3FD4	JMP $-86, goes to  00FC
 0154	     4034	MOV #256,R4
 0156	     0100
 0158	     12B0	CALL #332
 015A	     014C
 015C	     43C2	MOV.B #0,&294
 015E	     0126
 0160	     5221	ADD #4,SP
 0162	     4130	RET
 0164	     8321	SUB #2,SP
 0166	     4381	MOV #0,0(SP)
 0168	     0000
 016A	     412F	MOV @SP,R15
 016C	     511F	ADD 4(SP),R15
 016E	     0004
 0170	     93CF	CMP.B #0,0(R15)
 0172	     0000
 0174	     240A	JEQ $+22, goes to  018A
 0176	     412F	MOV @SP,R15
 0178	     511F	ADD 4(SP),R15
 017A	     0004
 017C	     126F	PUSH.B @R15
 017E	     12B0	CALL #0
 0180	     0000
 0182	     5321	ADD #2,SP
 0184	     5391	ADD #1,0(SP)
 0186	     0000
 0188	     3FF0	JMP $-30, goes to  016A
 018A	     5321	ADD #2,SP
 018C	     4130	RET
 018E	     8321	SUB #2,SP
 0190	     42D1	MOV.B &126,0(SP)
 0192	     007E
 0194	     0000
 0196	     B3D2	BIT.B #1,&402
 0198	     0192
 019A	     2404	JEQ $+10, goes to  01A4
 019C	     4034	MOV #32,R4
 019E	     0020
 01A0	     12B0	CALL #346
 01A2	     015A
 01A4	     4034	MOV #128,R4
 01A6	     0080
 01A8	     D114	BIS 6(SP),R4
 01AA	     0006
 01AC	     12B0	CALL #418
 01AE	     01A2
 01B0	     4034	MOV #64,R4
 01B2	     0040
 01B4	     D114	BIS 4(SP),R4
 01B6	     0004
 01B8	     12B0	CALL #430
 01BA	     01AE
 01BC	     92D1	CMP.B &408,0(SP)
 01BE	     0198
 01C0	     0000
 01C2	     2403	JEQ $+8, goes to  01CA
 01C4	     4164	MOV.B @SP,R4
 01C6	     12B0	CALL #442
 01C8	     01BA
 01CA	     5321	ADD #2,SP
 01CC	     4130	RET
 01CE	     8321	SUB #2,SP
 01D0	     1203	PUSH #0
 01D2	     1203	PUSH #0
 01D4	     12B0	CALL #0
 01D6	     0000
 01D8	     5221	ADD #4,SP
 01DA	     40B1	MOV #503,0(SP)
 01DC	     01F7
 01DE	     0000
 01E0	     9381	CMP #0,0(SP)
 01E2	     0000
 01E4	     3807	JL $+16, goes to  01F4
 01E6	     4034	MOV #256,R4
 01E8	     0100
 01EA	     12B0	CALL #456
 01EC	     01C8
 01EE	     53B1	ADD #-1,0(SP)
 01F0	     0000
 01F2	     3FF6	JMP $-18, goes to  01E0
 01F4	     5321	ADD #2,SP
 01F6	     4130	RET
 01F8	     4034	MOV #33,R4
 01FA	     0021
 01FC	     12B0	CALL #492
 01FE	     01EC
 0200	     4034	MOV #10,R4
 0202	     000A
 0204	     12B0	CALL #0
 0206	     0000
 0208	     4224	MOV #4,R4
 020A	     12B0	CALL #510
 020C	     01FE
 020E	     4034	MOV #19,R4
 0210	     0013
 0212	     12B0	CALL #524
 0214	     020C
 0216	     4034	MOV #186,R4
 0218	     00BA
 021A	     12B0	CALL #532
 021C	     0214
 021E	     4034	MOV #32,R4
 0220	     0020
 0222	     12B0	CALL #540
 0224	     021C
 0226	     4034	MOV #12,R4
 0228	     000C
 022A	     12B0	CALL #548
 022C	     0224
 022E	     4130	RET
 0230	     8321	SUB #2,SP
 0232	     42D1	MOV.B &446,0(SP)
 0234	     01BE
 0236	     0000
 0238	     B3D2	BIT.B #1,&564
 023A	     0234
 023C	     2004	JNE $+10, goes to  0246
 023E	     4034	MOV #33,R4
 0240	     0021
 0242	     12B0	CALL #556
 0244	     022C
 0246	     4114	MOV 4(SP),R4
 0248	     0004
 024A	     F034	AND #127,R4
 024C	     007F
 024E	     4035	MOV #128,R5
 0250	     0080
 0252	     D405	BIS R4,R5
 0254	     4504	MOV R5,R4
 0256	     12B0	CALL #580
 0258	     0244
 025A	     92D1	CMP.B &570,0(SP)
 025C	     023A
 025E	     0000
 0260	     2403	JEQ $+8, goes to  0268
 0262	     4164	MOV.B @SP,R4
 0264	     12B0	CALL #600
 0266	     0258
 0268	     5321	ADD #2,SP
 026A	     4130	RET
 026C	     8031	SUB #6,SP
 026E	     0006
 0270	     411F	MOV 14(SP),R15
 0272	     000E
 0274	     511F	ADD 10(SP),R15
 0276	     000A
 0278	     831F	SUB #1,R15
 027A	     4F81	MOV R15,4(SP)
 027C	     0004
 027E	     4381	MOV #0,2(SP)
 0280	     0002
 0282	     40B1	MOV #10,0(SP)
 0284	     000A
 0286	     0000
 0288	     4104	MOV SP,R4
 028A	     5034	ADD #18,R4
 028C	     0012
 028E	     4105	MOV SP,R5
 0290	     5035	ADD #16,R5
 0292	     0010
 0294	     4106	MOV SP,R6
 0296	     5326	ADD #2,R6
 0298	     4107	MOV SP,R7
 029A	     12B0	CALL #0
 029C	     0000
 029E	     411F	MOV 4(SP),R15
 02A0	     0004
 02A2	     5F0F	ADD R15,R15
 02A4	     4F0E	MOV R15,R14
 02A6	     5E0E	ADD R14,R14
 02A8	     5E0F	ADD R14,R15
 02AA	     120F	PUSH R15
 02AC	     1211	PUSH 16(SP)
 02AE	     0010
 02B0	     12B0	CALL #470
 02B2	     01D6
 02B4	     5221	ADD #4,SP
 02B6	     8391	SUB #1,4(SP)
 02B8	     0004
 02BA	     403F	MOV #48,R15
 02BC	     0030
 02BE	     412E	MOV @SP,R14
 02C0	     5F0E	ADD R15,R14
 02C2	     124E	PUSH.B R14
 02C4	     12B0	CALL #384
 02C6	     0180
 02C8	     5321	ADD #2,SP
 02CA	     9381	CMP #0,18(SP)
 02CC	     0012
 02CE	     23D7	JNE $-80, goes to  027E
 02D0	     9381	CMP #0,16(SP)
 02D2	     0010
 02D4	     23D4	JNE $-86, goes to  027E
 02D6	     411F	MOV 14(SP),R15
 02D8	     000E
 02DA	     5F0F	ADD R15,R15
 02DC	     4F0E	MOV R15,R14
 02DE	     5E0E	ADD R14,R14
 02E0	     5E0F	ADD R14,R15
 02E2	     120F	PUSH R15
 02E4	     1211	PUSH 16(SP)
 02E6	     0010
 02E8	     12B0	CALL #690
 02EA	     02B2
 02EC	     5221	ADD #4,SP
 02EE	     9191	CMP 14(SP),4(SP)
 02F0	     000E
 02F2	     0004
 02F4	     3808	JL $+18, goes to  0306
 02F6	     8391	SUB #1,4(SP)
 02F8	     0004
 02FA	     1251	PUSH.B 10(SP)
 02FC	     000A
 02FE	     12B0	CALL #710
 0300	     02C6
 0302	     5321	ADD #2,SP
 0304	     3FF4	JMP $-22, goes to  02EE
 0306	     411F	MOV 14(SP),R15
 0308	     000E
 030A	     511F	ADD 10(SP),R15
 030C	     000A
 030E	     5F0F	ADD R15,R15
 0310	     4F0E	MOV R15,R14
 0312	     5E0E	ADD R14,R14
 0314	     5E0F	ADD R14,R15
 0316	     120F	PUSH R15
 0318	     1211	PUSH 16(SP)
 031A	     0010
 031C	     12B0	CALL #746
 031E	     02EA
 0320	     5221	ADD #4,SP
 0322	     5031	ADD #6,SP
 0324	     0006
 0326	     4130	RET
 0328	     43C2	MOV.B #0,&178
 032A	     00B2
 032C	     43C2	MOV.B #0,&194
 032E	     00C2
 0330	     42E2	MOV.B #4,&604
 0332	     025C
 0334	     43C2	MOV.B #0,&350
 0336	     015E
 0338	     4130	RET
