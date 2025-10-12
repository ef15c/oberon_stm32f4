MODULE pcd8544;
  IMPORT M := msp430g2553, String, Delay := msp430delay;
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

  CONST HPIXELS =  84; VBANKS =  6; (*screen size*)

    (*Instruction flags*)
    DATA = 8; (*specify data instead of command*) INVERT = {0..8};

    (*instructions available in all modes*)
    NOp = {}; NOP_MASK = {0..8}; FUNCTION_SET* = {5}; FUNCTION_SET_MASK = {3..8}; H* = {0}; V* = {1}; PD* = {2}; (*function flags*)

    (*instructions available in basic mode*)
    DISPLAY_CONTROL* = {3}; DISPLAY_CONTROL_MASK = {1, 3..8}; D = 2; E = 0;
    SET_Y_ADDRESS* = {6}; SET_Y_ADDRESS_MASK = {3..8};
    SET_X_ADDRESS* = {7}; SET_X_ADDRESS_MASK = {7..8};

    (*instructions available in extended mode*)
    TEMP_CONTROL* = {2}; TEMP_CONTROL_MASK = {2..8};
    BIAS_SYSTEM* = {4}; BIAS_SYSTEM_MASK = {3..8};
    SET_VOP* = {7}; SET_VOP_MASK = {7..8};

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

  TYPE Callback = PROCEDURE {4..15};

  VAR (*Store LCD state cannot be queried from the device, so must be memorized*)
    XAddr*, YAddr*, Vop*: BYTE; FunctionSet*: BYTESET; composeChar: CHAR;
    select, deselect, setData, setCommand: Callback;

  PROCEDURE doSend(d: SET* );
  (*do the real job*)
  BEGIN (*Memorize state of LCD screen*)
    IF d*FUNCTION_SET_MASK = FUNCTION_SET THEN FunctionSet := d
    ELSIF ~BIT(FunctionSet, H) & (d*SET_Y_ADDRESS_MASK = SET_Y_ADDRESS) THEN
      YAddr := ORD(d*(SET_Y_ADDRESS_MASK/INVERT))
    ELSIF ~BIT(FunctionSet, H) & (d*SET_X_ADDRESS_MASK = SET_X_ADDRESS) THEN
      XAddr := ORD(d*(SET_X_ADDRESS_MASK/INVERT))
    ELSIF BIT(FunctionSet, H) & (d*SET_VOP_MASK = SET_VOP) THEN
      Vop := ORD(d*(SET_VOP_MASK/INVERT))
    END;
    REPEAT UNTIL BIT(M.IFG2^, M.UCA0TXIFG); (*Wait for USCI availability*)
    M.UCA0TXBUF^ := ORD(d); (*USCI A is ready, send character*)
    REPEAT UNTIL ~BIT(M.UCA0STAT^, M.UCBUSY); (*Wait for end of transmission*)
    IF DATA IN d THEN (*Send data : need to update X and Y addresses*)
      IF  BIT(FunctionSet, V) THEN INC(YAddr); (*One bank down to the bottom*)
        IF YAddr >= VBANKS THEN YAddr := 0; INC(XAddr); (*One row to the right*)
          IF XAddr >= HPIXELS THEN XAddr := 0 END
        END
      ELSE (*Horizontal addressing*) INC(XAddr); (*One row to the right*)
        IF XAddr >= HPIXELS THEN XAddr := 0; INC(YAddr); (*One bank down to the bottom*)
          IF YAddr >= VBANKS THEN YAddr := 0 END
        END
      END
    END;
  END doSend;

  PROCEDURE send*(d: SET);
  (*send a command or data to LCD*)
  BEGIN select; (*Select LCD for SPI communication*)
    IF DATA IN d THEN setData ELSE setCommand END; (*Set Data/Command line for Nokia 5110 LCD*)
    doSend(d);
    deselect (*Deselect LCD for SPI communication*)
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
    IF BIT(FunctionSet, H) THEN send(FUNCTION_SET) END; (*Request basic instruction set*)
    send(SET_X_ADDRESS + TOSET(xAddr)); send(SET_Y_ADDRESS + TOSET(yAddr));
    IF oldFunctionSet # FunctionSet THEN send(oldFunctionSet) END (*Restore previous function set*)
  END SetAddr;

  PROCEDURE GetAddr*(VAR xAddr, yAddr: BYTE*);
    (*Get address of next LCD write*)
  BEGIN xAddr :=  XAddr; yAddr := YAddr
  END GetAddr;

  PROCEDURE Clear*;
    VAR i: INTEGER;
  BEGIN SetAddr(0, 0); (*Set X=0, Y=0*)
    FOR i := HPIXELS*VBANKS - 1 TO 0 BY -1 DO send({DATA}) END (*Clear RAM*)
  END Clear;

  PROCEDURE Init*;
  BEGIN send(FUNCTION_SET + H); (* function set PD = 0 and V = 0, select extended instruction set (H = 1 mode) *)
    Delay.CyclesX3(10);
    send(TEMP_CONTROL); (*set TC = 00 *) send(BIAS_SYSTEM + TOSET(3)); (*set BS = 011*)
    send(SET_VOP +  TOSET(3AH)); (* set VOP =  a+58 x b [V]*)
    send(FUNCTION_SET); (*select normal instruction set (H = 0 mode)*)
    send(DISPLAY_CONTROL + {D}); (*display control set normal mode (D = 1 and E = 0)*)
  END Init;

  PROCEDURE SetVop*(vop: INTEGER);
    VAR oldFunctionSet: BYTESET;
  BEGIN oldFunctionSet := FunctionSet;
    IF ~BIT(FunctionSet, H) THEN send(FUNCTION_SET + H) END; (*Request extended instruction set*)
    send(SET_VOP +  TOSET(vop)*(SET_VOP_MASK/INVERT)); (*set VOP = a + vop x b volts*)
    IF oldFunctionSet # FunctionSet THEN send(oldFunctionSet) END (*Restore previous function set*)
  END SetVop;

  PROCEDURE WriteLongint*(th, tl: INTEGER; nx, ny, nbc: INTEGER; pad: CHAR);
    (* th, tl : value to output on display
     * nx, ny : screen coordinates in character unit
     * nbc : number of digits to output
     * pad : padding character*)
    VAR str: ARRAY 12 OF CHAR;
  BEGIN SetAddr(6*nx, ny); String.FromLong(th, tl, nbc, str); WriteString(str)
  END WriteLongint;

  PROCEDURE setCallbacks*(sel, desel, setD, setC: Callback* );
  BEGIN select := sel; deselect := desel; setData := setD; setCommand := setC
  END setCallbacks;

BEGIN XAddr := 0; YAddr := 0; Vop := 0; FunctionSet := FUNCTION_SET + PD; composeChar := 0X
END pcd8544.

OMSPP.Compile pcd8544.Mod/s~
OMSPTool.DecSym pcd8544.sms
decode pcd8544.sms
pcd8544 3A99ADE2  1
   1 FUNCTION_SET [^6]      32
   1 H [^6]       1
   1 V [^6]       2
   1 PD [^6]       4
   1 DISPLAY_CONTROL [^6]       8
   1 SET_Y_ADDRESS [^6]      64
   1 SET_X_ADDRESS [^6]     128
   1 TEMP_CONTROL [^6]       4
   1 BIAS_SYSTEM [^6]      16
   1 SET_VOP [^6]     128
   2 XAddr [^1]     1
   2 YAddr [^1]     2
   2 Vop [^1]     3
   2 FunctionSet [^16]     4
   1 send [0  form = 10  size = 2 [^9] UR 0030( class = 2 [^6])]       5
   1 WriteChar [0  form = 10  size = 2 [^9] UR C030( class = 2 [^3])]       6
   1 WriteString [0  form = 10  size = 2 [^9] UR C030( class = 3# [0  form = 12  size = 4 [^3]  len = -1])]       7
   1 SetAddr [0  form = 10  size = 2 [^9] UR 8030( class = 2 [^1] class = 2 [^1])]       8
   1 GetAddr [0  form = 10  size = 2 [^9] leaf UR 0030( class = 3 R5 [^1] class = 3 R4 [^1])]       9
   1 Clear [0  form = 10  size = 2 [^9] UR 8030()]      10
   1 Init [0  form = 10  size = 2 [^9] UR 0030()]      11
   1 SetVop [0  form = 10  size = 2 [^9] UR C030( class = 2 [^4])]      12
   1 WriteLongint [0  form = 10  size = 2 [^9] UR DFF0( class = 2 [^3] class = 2 [^4] class = 2 [^4] class = 2 [^4] class = 2 [^4] class = 2 [^4])]      13
   1 setCallbacks [0  form = 10  size = 2 [^9] leaf UR 00F0( class = 2 R7 [19  form = 10  size = 2 [^9] UR 0000()] class = 2 R6 [^19] class = 2 R5 [^19] class = 2 R4 [^19])]      14

OMSPTool.DecObj pcd8544.mpc
decode pcd8544.mpc
pcd8544 28932780 Flash  1356
imports:
	msp430g2553 F10488DC
	String 393F15C3
	msp430delay EE6A4099
type descriptors

data    14
strings
|||||||_|||||$**#db6IU"P||||"A||A"|>>|P0|||``|| >QIE>|B@|BaQIF!AEK1'EEE9<JII0q	6III6II)|66|||V6||"A||A"Q	2IyA>~~III6>AAA"AA"IIIA			>AIIz|AA| @A?"A@@@@>AAA>			>AQ!^	)FFIII1?@@@? @ ?@8@?ccpaQIEC|AA| |AA|>UA"@@@@@|		 TTTxHDD88DDD 8DDH8TTT~	RRR>x|D}@| @D=|(D||A@||x|x8DDD8|||HTTT ?D@ <@@ | @ <@0@<D((DPPP<DdTLD|6A||||||A6||D|@||||||||||||||\80@||~CC~|~ss~|~~| <~< 
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0326 d 0002 d 0003 c 00CA c 00EE c 0188 c 01B2 c 0200 c 020E c 023A c 0280 c 02C4 c 0314
fixup procedures in code space chains
 00E6     0	 0000
 02BC     0	 00CA
 01A4     0	 00EE
 030A     0	 0188
 02DC     0	 01B2
 02F8     2	 0001
 024A     3	 0001
fixup handlers in vector space chains
fixup data in code space chains
 033A     0	 0004
 031A     0	 0008
 0322     0	 000C
 031E     0	 000A
 0316     0	 0006
 0330     0	 0002
 0328     0	 0000
 032C     0	 0001
 0336     0	 0003
fixup constants in code space chains
 015A     0	 01DC
 013A     0	 0000
fixup variables in constant space chains
fixup constants in constant space chains
entry =  0326
code   830
 0000	     4405	MOV R4,R5
 0002	     F035	AND #504,R5
 0004	     01F8
 0006	     9035	CMP #32,R5
 0008	     0020
 000A	     2003	JNE $+8, goes to  0012
 000C	     44C2	MOV.B R4,&0
 000E	     0000
 0010	     3C2C	JMP $+90, goes to  006A
 0012	     B3D2	BIT.B #1,&14
 0014	     000E
 0016	     200C	JNE $+26, goes to  0030
 0018	     4405	MOV R4,R5
 001A	     F035	AND #504,R5
 001C	     01F8
 001E	     9035	CMP #64,R5
 0020	     0040
 0022	     2006	JNE $+14, goes to  0030
 0024	     4405	MOV R4,R5
 0026	     F035	AND #7,R5
 0028	     0007
 002A	     45C2	MOV.B R5,&0
 002C	     0000
 002E	     3C1D	JMP $+60, goes to  006A
 0030	     B3D2	BIT.B #1,&20
 0032	     0014
 0034	     200C	JNE $+26, goes to  004E
 0036	     4405	MOV R4,R5
 0038	     F035	AND #384,R5
 003A	     0180
 003C	     9035	CMP #128,R5
 003E	     0080
 0040	     2006	JNE $+14, goes to  004E
 0042	     4405	MOV R4,R5
 0044	     F035	AND #127,R5
 0046	     007F
 0048	     45C2	MOV.B R5,&0
 004A	     0000
 004C	     3C0E	JMP $+30, goes to  006A
 004E	     B3D2	BIT.B #1,&50
 0050	     0032
 0052	     240B	JEQ $+24, goes to  006A
 0054	     4405	MOV R4,R5
 0056	     F035	AND #384,R5
 0058	     0180
 005A	     9035	CMP #128,R5
 005C	     0080
 005E	     2005	JNE $+12, goes to  006A
 0060	     4405	MOV R4,R5
 0062	     F035	AND #127,R5
 0064	     007F
 0066	     45C2	MOV.B R5,&0
 0068	     0000
 006A	     B3E2	BIT.B #2,&3
 006C	     0003
 006E	     27FD	JEQ $-4, goes to  006A
 0070	     44C2	MOV.B R4,&103
 0072	     0067
 0074	     B3D2	BIT.B #1,&101
 0076	     0065
 0078	     23FD	JNE $-4, goes to  0074
 007A	     B034	BIT #256,R4
 007C	     0100
 007E	     2424	JEQ $+74, goes to  00C8
 0080	     B3E2	BIT.B #2,&80
 0082	     0050
 0084	     2411	JEQ $+36, goes to  00A8
 0086	     53D2	ADD.B #1,&44
 0088	     002C
 008A	     90F2	CMP.B #6,&136
 008C	     0006
 008E	     0088
 0090	     280A	JNC $+22, goes to  00A6
 0092	     43C2	MOV.B #0,&142
 0094	     008E
 0096	     53D2	ADD.B #1,&74
 0098	     004A
 009A	     90F2	CMP.B #84,&152
 009C	     0054
 009E	     0098
 00A0	     2802	JNC $+6, goes to  00A6
 00A2	     43C2	MOV.B #0,&158
 00A4	     009E
 00A6	     3C10	JMP $+34, goes to  00C8
 00A8	     53D2	ADD.B #1,&164
 00AA	     00A4
 00AC	     90F2	CMP.B #84,&170
 00AE	     0054
 00B0	     00AA
 00B2	     280A	JNC $+22, goes to  00C8
 00B4	     43C2	MOV.B #0,&176
 00B6	     00B0
 00B8	     53D2	ADD.B #1,&148
 00BA	     0094
 00BC	     90F2	CMP.B #6,&186
 00BE	     0006
 00C0	     00BA
 00C2	     2802	JNC $+6, goes to  00C8
 00C4	     43C2	MOV.B #0,&192
 00C6	     00C0
 00C8	     4130	RET
 00CA	     1292	CALL &0
 00CC	     0000
 00CE	     B0B1	BIT #256,2(SP)
 00D0	     0100
 00D2	     0002
 00D4	     2403	JEQ $+8, goes to  00DC
 00D6	     1292	CALL &0
 00D8	     0000
 00DA	     3C02	JMP $+6, goes to  00E0
 00DC	     1292	CALL &0
 00DE	     0000
 00E0	     4114	MOV 2(SP),R4
 00E2	     0002
 00E4	     12B0	CALL #0
 00E6	     0000
 00E8	     1292	CALL &0
 00EA	     0000
 00EC	     4130	RET
 00EE	     8221	SUB #4,SP
 00F0	     403F	MOV #136,R15
 00F2	     0088
 00F4	     915F	CMP.B 6(SP),R15
 00F6	     0006
 00F8	     2804	JNC $+10, goes to  0102
 00FA	     90F1	CMP.B #32,6(SP)
 00FC	     0020
 00FE	     0006
 0100	     2C03	JC $+8, goes to  0108
 0102	     40F1	MOV.B #63,6(SP)
 0104	     003F
 0106	     0006
 0108	     403F	MOV #126,R15
 010A	     007E
 010C	     915F	CMP.B 6(SP),R15
 010E	     0006
 0110	     2C04	JC $+10, goes to  011A
 0112	     41D2	MOV.B 6(SP),&0
 0114	     0006
 0116	     0000
 0118	     3C35	JMP $+108, goes to  0184
 011A	     4381	MOV #0,0(SP)
 011C	     0000
 011E	     422F	MOV #4,R15
 0120	     912F	CMP @SP,R15
 0122	     3829	JL $+84, goes to  0176
 0124	     415F	MOV.B 6(SP),R15
 0126	     0006
 0128	     807F	SUB.B #32,R15
 012A	     0020
 012C	     4F0E	MOV R15,R14
 012E	     5E0E	ADD R14,R14
 0130	     5E0E	ADD R14,R14
 0132	     5E0F	ADD R14,R15
 0134	     412E	MOV @SP,R14
 0136	     5F0E	ADD R15,R14
 0138	     4ED1	MOV.B 0(R14),2(SP)
 013A	     0000
 013C	     0002
 013E	     93C2	CMP.B #0,&278
 0140	     0116
 0142	     240D	JEQ $+28, goes to  015E
 0144	     425F	MOV.B &320,R15
 0146	     0140
 0148	     807F	SUB.B #127,R15
 014A	     007F
 014C	     4F0E	MOV R15,R14
 014E	     5E0E	ADD R14,R14
 0150	     5E0E	ADD R14,R14
 0152	     5E0F	ADD R14,R15
 0154	     412E	MOV @SP,R14
 0156	     5F0E	ADD R15,R14
 0158	     DED1	BIS.B 0(R14),2(SP)
 015A	     0000
 015C	     0002
 015E	     403F	MOV #256,R15
 0160	     0100
 0162	     415E	MOV.B 2(SP),R14
 0164	     0002
 0166	     DE0F	BIS R14,R15
 0168	     120F	PUSH R15
 016A	     12B0	CALL #0
 016C	     0000
 016E	     5321	ADD #2,SP
 0170	     5391	ADD #1,0(SP)
 0172	     0000
 0174	     3FD4	JMP $-86, goes to  011E
 0176	     1230	PUSH #256
 0178	     0100
 017A	     12B0	CALL #364
 017C	     016C
 017E	     5321	ADD #2,SP
 0180	     43C2	MOV.B #0,&326
 0182	     0146
 0184	     5221	ADD #4,SP
 0186	     4130	RET
 0188	     8321	SUB #2,SP
 018A	     4381	MOV #0,0(SP)
 018C	     0000
 018E	     412F	MOV @SP,R15
 0190	     511F	ADD 4(SP),R15
 0192	     0004
 0194	     93CF	CMP.B #0,0(R15)
 0196	     0000
 0198	     240A	JEQ $+22, goes to  01AE
 019A	     412F	MOV @SP,R15
 019C	     511F	ADD 4(SP),R15
 019E	     0004
 01A0	     126F	PUSH.B @R15
 01A2	     12B0	CALL #0
 01A4	     0000
 01A6	     5321	ADD #2,SP
 01A8	     5391	ADD #1,0(SP)
 01AA	     0000
 01AC	     3FF0	JMP $-30, goes to  018E
 01AE	     5321	ADD #2,SP
 01B0	     4130	RET
 01B2	     8321	SUB #2,SP
 01B4	     42D1	MOV.B &130,0(SP)
 01B6	     0082
 01B8	     0000
 01BA	     B3D2	BIT.B #1,&438
 01BC	     01B6
 01BE	     2405	JEQ $+12, goes to  01CA
 01C0	     1230	PUSH #32
 01C2	     0020
 01C4	     12B0	CALL #380
 01C6	     017C
 01C8	     5321	ADD #2,SP
 01CA	     403F	MOV #128,R15
 01CC	     0080
 01CE	     D11F	BIS 6(SP),R15
 01D0	     0006
 01D2	     120F	PUSH R15
 01D4	     12B0	CALL #454
 01D6	     01C6
 01D8	     5321	ADD #2,SP
 01DA	     403F	MOV #64,R15
 01DC	     0040
 01DE	     D11F	BIS 4(SP),R15
 01E0	     0004
 01E2	     120F	PUSH R15
 01E4	     12B0	CALL #470
 01E6	     01D6
 01E8	     5321	ADD #2,SP
 01EA	     92D1	CMP.B &444,0(SP)
 01EC	     01BC
 01EE	     0000
 01F0	     2405	JEQ $+12, goes to  01FC
 01F2	     416F	MOV.B @SP,R15
 01F4	     120F	PUSH R15
 01F6	     12B0	CALL #486
 01F8	     01E6
 01FA	     5321	ADD #2,SP
 01FC	     5321	ADD #2,SP
 01FE	     4130	RET
 0200	     42D4	MOV.B &182,0(R4)
 0202	     00B6
 0204	     0000
 0206	     42D5	MOV.B &198,0(R5)
 0208	     00C6
 020A	     0000
 020C	     4130	RET
 020E	     8321	SUB #2,SP
 0210	     1203	PUSH #0
 0212	     1203	PUSH #0
 0214	     12B0	CALL #0
 0216	     0000
 0218	     5221	ADD #4,SP
 021A	     40B1	MOV #503,0(SP)
 021C	     01F7
 021E	     0000
 0220	     9381	CMP #0,0(SP)
 0222	     0000
 0224	     3808	JL $+18, goes to  0236
 0226	     1230	PUSH #256
 0228	     0100
 022A	     12B0	CALL #504
 022C	     01F8
 022E	     5321	ADD #2,SP
 0230	     53B1	ADD #-1,0(SP)
 0232	     0000
 0234	     3FF5	JMP $-20, goes to  0220
 0236	     5321	ADD #2,SP
 0238	     4130	RET
 023A	     1230	PUSH #33
 023C	     0021
 023E	     12B0	CALL #556
 0240	     022C
 0242	     5321	ADD #2,SP
 0244	     4034	MOV #10,R4
 0246	     000A
 0248	     12B0	CALL #0
 024A	     0000
 024C	     1230	PUSH #4
 024E	     0004
 0250	     12B0	CALL #576
 0252	     0240
 0254	     5321	ADD #2,SP
 0256	     1230	PUSH #19
 0258	     0013
 025A	     12B0	CALL #594
 025C	     0252
 025E	     5321	ADD #2,SP
 0260	     1230	PUSH #186
 0262	     00BA
 0264	     12B0	CALL #604
 0266	     025C
 0268	     5321	ADD #2,SP
 026A	     1230	PUSH #32
 026C	     0020
 026E	     12B0	CALL #614
 0270	     0266
 0272	     5321	ADD #2,SP
 0274	     1230	PUSH #12
 0276	     000C
 0278	     12B0	CALL #624
 027A	     0270
 027C	     5321	ADD #2,SP
 027E	     4130	RET
 0280	     8321	SUB #2,SP
 0282	     42D1	MOV.B &492,0(SP)
 0284	     01EC
 0286	     0000
 0288	     B3D2	BIT.B #1,&644
 028A	     0284
 028C	     2005	JNE $+12, goes to  0298
 028E	     1230	PUSH #33
 0290	     0021
 0292	     12B0	CALL #634
 0294	     027A
 0296	     5321	ADD #2,SP
 0298	     411F	MOV 4(SP),R15
 029A	     0004
 029C	     F03F	AND #127,R15
 029E	     007F
 02A0	     403E	MOV #128,R14
 02A2	     0080
 02A4	     DF0E	BIS R15,R14
 02A6	     120E	PUSH R14
 02A8	     12B0	CALL #660
 02AA	     0294
 02AC	     5321	ADD #2,SP
 02AE	     92D1	CMP.B &650,0(SP)
 02B0	     028A
 02B2	     0000
 02B4	     2405	JEQ $+12, goes to  02C0
 02B6	     416F	MOV.B @SP,R15
 02B8	     120F	PUSH R15
 02BA	     12B0	CALL #682
 02BC	     02AA
 02BE	     5321	ADD #2,SP
 02C0	     5321	ADD #2,SP
 02C2	     4130	RET
 02C4	     8031	SUB #12,SP
 02C6	     000C
 02C8	     411F	MOV 20(SP),R15
 02CA	     0014
 02CC	     5F0F	ADD R15,R15
 02CE	     4F0E	MOV R15,R14
 02D0	     5E0E	ADD R14,R14
 02D2	     5E0F	ADD R14,R15
 02D4	     120F	PUSH R15
 02D6	     1211	PUSH 22(SP)
 02D8	     0016
 02DA	     12B0	CALL #534
 02DC	     0216
 02DE	     5221	ADD #4,SP
 02E0	     1211	PUSH 26(SP)
 02E2	     001A
 02E4	     1211	PUSH 26(SP)
 02E6	     001A
 02E8	     1211	PUSH 22(SP)
 02EA	     0016
 02EC	     1230	PUSH #12
 02EE	     000C
 02F0	     410F	MOV SP,R15
 02F2	     523F	ADD #8,R15
 02F4	     120F	PUSH R15
 02F6	     12B0	CALL #0
 02F8	     0000
 02FA	     5031	ADD #10,SP
 02FC	     000A
 02FE	     1230	PUSH #12
 0300	     000C
 0302	     410F	MOV SP,R15
 0304	     532F	ADD #2,R15
 0306	     120F	PUSH R15
 0308	     12B0	CALL #0
 030A	     0000
 030C	     5221	ADD #4,SP
 030E	     5031	ADD #12,SP
 0310	     000C
 0312	     4130	RET
 0314	     4482	MOV R4,&204
 0316	     00CC
 0318	     4582	MOV R5,&234
 031A	     00EA
 031C	     4682	MOV R6,&216
 031E	     00D8
 0320	     4782	MOV R7,&222
 0322	     00DE
 0324	     4130	RET
 0326	     43C2	MOV.B #0,&514
 0328	     0202
 032A	     43C2	MOV.B #0,&520
 032C	     0208
 032E	     43C2	MOV.B #0,&104
 0330	     0068
 0332	     40F2	MOV.B #36,&688
 0334	     0024
 0336	     02B0
 0338	     43C2	MOV.B #0,&386
 033A	     0182
 033C	     4130	RET
