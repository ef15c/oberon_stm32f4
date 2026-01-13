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
    NOp* = {}; NOP_MASK* = {0..8}; FUNCTION_SET* = {5}; FUNCTION_SET_MASK* = {3..8}; H* = {0}; V* = {1}; PD* = {2}; (*function flags*)

    (*instructions available in basic mode*)
    DISPLAY_CONTROL* = {3}; DISPLAY_CONTROL_MASK* = {1, 3..8}; D* = 2; E* = 0;
    SET_Y_ADDRESS* = {6}; SET_Y_ADDRESS_MASK* = {3..8};
    SET_X_ADDRESS* = {7}; SET_X_ADDRESS_MASK* = {7..8};

    (*instructions available in extended mode*)
    TEMP_CONTROL* = {2}; TEMP_CONTROL_MASK* = {2..8};
    BIAS_SYSTEM* = {4}; BIAS_SYSTEM_MASK* = {3..8};
    SET_VOP* = {7}; SET_VOP_MASK* = {7..8};

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

  TYPE Callback = PROCEDURE {4..15}; SendDataProc = PROCEDURE {5..15} (d: BYTE* );

  VAR (*Store LCD state cannot be queried from the device, so must be memorized*)
    XAddr*, YAddr*, Vop*: BYTE; FunctionSet*: BYTESET; composeChar: CHAR;
    select, deselect, setData, setCommand: Callback; sendD: SendDataProc;

  PROCEDURE track(d: SET* );
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
  END track;

  PROCEDURE send*(d: SET);
  (*send a command or data to LCD*)
  BEGIN select; (*Select LCD for SPI communication*)
    IF DATA IN d THEN setData ELSE setCommand END; (*Set Data/Command line for Nokia 5110 LCD*)
    track(d); sendD(ORD(d));
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
        column := TOSET(ORD(font[i + (0 + ORD(car) - 20H)*GLYPH_WIDTH]));
        IF composeChar # 0X THEN BIS(column, composeFont[i + (0 + ORD(composeChar) - 7FH)*GLYPH_WIDTH]) END;
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
    send(TEMP_CONTROL + TOSET(2)); (*set TC = 10 *) send(BIAS_SYSTEM + TOSET(3)); (*set BS = 011*)
    send(SET_VOP +  TOSET(70)); (* set VOP =  a+70 x b [V]*)
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

  PROCEDURE WriteLongint*(th, tl: INTEGER; nx, ny, nbc, len: INTEGER);
    (* th, tl : value to output on display
     * nx, ny : screen coordinates in character unit
     * nbc : number of digits to output
     * pad : padding character*)
    VAR str: ARRAY 12 OF CHAR;
  BEGIN SetAddr(6*nx, ny); String.FromLong(th, tl, nbc, len, str); WriteString(str)
  END WriteLongint;

  PROCEDURE setCallbacks*(sel, desel, setD, setC: Callback*; send: SendDataProc* );
  BEGIN select := sel; deselect := desel; setData := setD; setCommand := setC; sendD := send;
  END setCallbacks;

BEGIN XAddr := 0; YAddr := 0; Vop := 0; FunctionSet := FUNCTION_SET + PD; composeChar := 0X
END pcd8544.

OMSPP.Compile pcd8544.Mod/s~

OMSPTool.DecSym pcd8544.sms
decode pcd8544.sms
pcd8544 139EDDCB  3
   1 NOp [^6]       0
   1 NOP_MASK [^6]     511
   1 FUNCTION_SET [^6]      32
   1 FUNCTION_SET_MASK [^6]     504
   1 H [^6]       1
   1 V [^6]       2
   1 PD [^6]       4
   1 DISPLAY_CONTROL [^6]       8
   1 DISPLAY_CONTROL_MASK [^6]     506
   1 D [^4]       2
   1 E [^4]       0
   1 SET_Y_ADDRESS [^6]      64
   1 SET_Y_ADDRESS_MASK [^6]     504
   1 SET_X_ADDRESS [^6]     128
   1 SET_X_ADDRESS_MASK [^6]     384
   1 TEMP_CONTROL [^6]       4
   1 TEMP_CONTROL_MASK [^6]     508
   1 BIAS_SYSTEM [^6]      16
   1 BIAS_SYSTEM_MASK [^6]     504
   1 SET_VOP [^6]     128
   1 SET_VOP_MASK [^6]     384
   2 XAddr [^1]     1
   2 YAddr [^1]     2
   2 Vop [^1]     3
   2 FunctionSet [^16]     4
   9 send [0  form = 10 [^9] UR 0030( class = 2 [^6])]     5
   9 WriteChar [0  form = 10 [^9] UR C030( class = 2 [^3])]     6
   9 WriteString [0  form = 10 [^9] UR C030( class = 3# [0  form = 12 [^3]  len = -1  size = 4])]     7
   9 SetAddr [0  form = 10 [^9] UR C030( class = 2 [^1] class = 2 [^1])]     8
   9 GetAddr [0  form = 10 [^9] leaf UR 0030( class = 3 R5 [^1] class = 3 R4 [^1])]     9
   9 Clear [0  form = 10 [^9] UR C030()]    10
   9 Init [0  form = 10 [^9] UR 0030()]    11
   9 SetVop [0  form = 10 [^9] UR C030( class = 2 [^4])]    12
   9 WriteLongint [0  form = 10 [^9] UR DFF0( class = 2 [^3] class = 2 [^4] class = 2 [^4] class = 2 [^4] class = 2 [^4] class = 2 [^4])]    13
   9 setCallbacks [0  form = 10 [^9] leaf UR 01F0( class = 2 R8 [19  form = 10 [^9] leaf UR 0010( class = 2 R4 [^1])] class = 2 R7 [20  form = 10 [^9] UR 0000()] class = 2 R6 [^20] class = 2 R5 [^20] class = 2 R4 [^20])]    14

OMSPTool.DecObj pcd8544.mpc
decode pcd8544.mpc
pcd8544 139EDDCB
imports:
	msp430g2553 BBD31A01
	String 938D3CFC
	msp430delay AAE4F156

section     0	s  476	
|||||||_|||||$**#db6IU"P||||"A||A"|>>|P0|||``|| >QIE>|B@|BaQIF!AEK1'EEE9<JII0q	6III6II)|66|||V6||"A||A"Q	2IyA>~~III6>AAA"AA"IIIA			>AIIz|AA| @A?"A@@@@>AAA>			>AQ!^	)FFIII1?@@@? @ ?@8@?ccpaQIEC|AA| |AA|>UA"@@@@@|		 TTTxHDD88DDD 8DDH8TTT~	RRR>x|D}@| @D=|(D||A@||x|x8DDD8|||HTTT ?D@ <@@ | @ <@0@<D((DPPP<DdTLD|6A||||||A6||D|@||
fixups:

section     1	s   50	
||||||||||||\80@||~CC~|~ss~|~~| <~< 
fixups:

section     2	r    1	XAddr
fixups:

section     3	r    1	YAddr
fixups:

section     4	r    1	Vop
fixups:

section     5	r    1	FunctionSet
fixups:

section     6	r    1	composeChar
fixups:

section     7	r    2	select
fixups:

section     8	r    2	deselect
fixups:

section     9	r    2	setData
fixups:

section    10	r    2	setCommand
fixups:

section    11	r    2	sendD
fixups:

section    12	c  186	track
 0000	     4405	MOV R4,R5
 0002	     F035	AND #504,R5
 0004	     01F8
 0006	     9035	CMP #32,R5
 0008	     0020
 000A	     2003	JNE $+8, goes to  0012
 000C	     44C2	MOV.B R4,&0
 000E	     0000
 0010	     3C2C	JMP $+90, goes to  006A
 0012	     B3D2	BIT.B #1,&15
 0014	     000F
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
 0030	     B3D2	BIT.B #1,&21
 0032	     0015
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
 004E	     B3D2	BIT.B #1,&51
 0050	     0033
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
 006A	     B034	BIT #256,R4
 006C	     0100
 006E	     2424	JEQ $+74, goes to  00B8
 0070	     B3E2	BIT.B #2,&81
 0072	     0051
 0074	     2411	JEQ $+36, goes to  0098
 0076	     53D2	ADD.B #1,&45
 0078	     002D
 007A	     90F2	CMP.B #6,&121
 007C	     0006
 007E	     0079
 0080	     280A	JNC $+22, goes to  0096
 0082	     43C2	MOV.B #0,&127
 0084	     007F
 0086	     53D2	ADD.B #1,&75
 0088	     004B
 008A	     90F2	CMP.B #84,&137
 008C	     0054
 008E	     0089
 0090	     2802	JNC $+6, goes to  0096
 0092	     43C2	MOV.B #0,&143
 0094	     008F
 0096	     3C10	JMP $+34, goes to  00B8
 0098	     53D2	ADD.B #1,&149
 009A	     0095
 009C	     90F2	CMP.B #84,&155
 009E	     0054
 00A0	     009B
 00A2	     280A	JNC $+22, goes to  00B8
 00A4	     43C2	MOV.B #0,&161
 00A6	     00A1
 00A8	     53D2	ADD.B #1,&133
 00AA	     0085
 00AC	     90F2	CMP.B #6,&171
 00AE	     0006
 00B0	     00AB
 00B2	     2802	JNC $+6, goes to  00B8
 00B4	     43C2	MOV.B #0,&177
 00B6	     00B1
 00B8	     4130	RET
fixups:
 0069	s0.4
 00A7	s0.2
 00B7	s0.3
 0073	s0.5

section    13	c   44	send
 0000	     1292	CALL &0
 0002	     0000
 0004	     B0B1	BIT #256,2(SP)
 0006	     0100
 0008	     0002
 000A	     2403	JEQ $+8, goes to  0012
 000C	     1292	CALL &0
 000E	     0000
 0010	     3C02	JMP $+6, goes to  0016
 0012	     1292	CALL &0
 0014	     0000
 0016	     4114	MOV 2(SP),R4
 0018	     0002
 001A	     12B0	CALL #0
 001C	     0000
 001E	     4114	MOV 2(SP),R4
 0020	     0002
 0022	     1292	CALL &0
 0024	     0000
 0026	     1292	CALL &0
 0028	     0000
 002A	     4130	RET
fixups:
 0029	s0.8
 0025	s0.11
 001D	s0.12
 0015	s0.10
 000F	s0.9
 0003	s0.7

section    14	c  154	WriteChar
 0000	     8221	SUB #4,SP
 0002	     407F	MOV.B #136,R15
 0004	     0088
 0006	     915F	CMP.B 6(SP),R15
 0008	     0006
 000A	     2804	JNC $+10, goes to  0014
 000C	     90F1	CMP.B #32,6(SP)
 000E	     0020
 0010	     0006
 0012	     2C03	JC $+8, goes to  001A
 0014	     40F1	MOV.B #63,6(SP)
 0016	     003F
 0018	     0006
 001A	     407F	MOV.B #126,R15
 001C	     007E
 001E	     915F	CMP.B 6(SP),R15
 0020	     0006
 0022	     2C04	JC $+10, goes to  002C
 0024	     41D2	MOV.B 6(SP),&0
 0026	     0006
 0028	     0000
 002A	     3C35	JMP $+108, goes to  0096
 002C	     4381	MOV #0,0(SP)
 002E	     0000
 0030	     422F	MOV #4,R15
 0032	     912F	CMP @SP,R15
 0034	     3829	JL $+84, goes to  0088
 0036	     415F	MOV.B 6(SP),R15
 0038	     0006
 003A	     803F	SUB #32,R15
 003C	     0020
 003E	     4F0E	MOV R15,R14
 0040	     5E0E	ADD R14,R14
 0042	     5E0E	ADD R14,R14
 0044	     5E0F	ADD R14,R15
 0046	     412E	MOV @SP,R14
 0048	     5F0E	ADD R15,R14
 004A	     4ED1	MOV.B 0(R14),2(SP)
 004C	     0000
 004E	     0002
 0050	     93C2	CMP.B #0,&41
 0052	     0029
 0054	     240D	JEQ $+28, goes to  0070
 0056	     425F	MOV.B &83,R15
 0058	     0053
 005A	     803F	SUB #127,R15
 005C	     007F
 005E	     4F0E	MOV R15,R14
 0060	     5E0E	ADD R14,R14
 0062	     5E0E	ADD R14,R14
 0064	     5E0F	ADD R14,R15
 0066	     412E	MOV @SP,R14
 0068	     5F0E	ADD R15,R14
 006A	     DED1	BIS.B 0(R14),2(SP)
 006C	     0000
 006E	     0002
 0070	     415F	MOV.B 2(SP),R15
 0072	     0002
 0074	     403E	MOV #256,R14
 0076	     0100
 0078	     DF0E	BIS R15,R14
 007A	     120E	PUSH R14
 007C	     12B0	CALL #0
 007E	     0000
 0080	     5321	ADD #2,SP
 0082	     5391	ADD #1,0(SP)
 0084	     0000
 0086	     3FD4	JMP $-86, goes to  0030
 0088	     1230	PUSH #256
 008A	     0100
 008C	     12B0	CALL #127
 008E	     007F
 0090	     5321	ADD #2,SP
 0092	     43C2	MOV.B #0,&89
 0094	     0059
 0096	     5221	ADD #4,SP
 0098	     4130	RET
fixups:
 008F	s0.13
 006D	s0.1
 004D	s0.0
 0095	s0.6

section    15	c   42	WriteString
 0000	     8321	SUB #2,SP
 0002	     4381	MOV #0,0(SP)
 0004	     0000
 0006	     412F	MOV @SP,R15
 0008	     511F	ADD 4(SP),R15
 000A	     0004
 000C	     93CF	CMP.B #0,0(R15)
 000E	     0000
 0010	     240A	JEQ $+22, goes to  0026
 0012	     412F	MOV @SP,R15
 0014	     511F	ADD 4(SP),R15
 0016	     0004
 0018	     126F	PUSH.B @R15
 001A	     12B0	CALL #0
 001C	     0000
 001E	     5321	ADD #2,SP
 0020	     5391	ADD #1,0(SP)
 0022	     0000
 0024	     3FF0	JMP $-30, goes to  0006
 0026	     5321	ADD #2,SP
 0028	     4130	RET
fixups:
 001D	s0.14

section    16	c   82	SetAddr
 0000	     8321	SUB #2,SP
 0002	     42D1	MOV.B &0,0(SP)
 0004	     0000
 0006	     0000
 0008	     B3D2	BIT.B #1,&5
 000A	     0005
 000C	     2405	JEQ $+12, goes to  0018
 000E	     1230	PUSH #32
 0010	     0020
 0012	     12B0	CALL #0
 0014	     0000
 0016	     5321	ADD #2,SP
 0018	     415F	MOV.B 6(SP),R15
 001A	     0006
 001C	     403E	MOV #128,R14
 001E	     0080
 0020	     DF0E	BIS R15,R14
 0022	     120E	PUSH R14
 0024	     12B0	CALL #21
 0026	     0015
 0028	     5321	ADD #2,SP
 002A	     415F	MOV.B 4(SP),R15
 002C	     0004
 002E	     403E	MOV #64,R14
 0030	     0040
 0032	     DF0E	BIS R15,R14
 0034	     120E	PUSH R14
 0036	     12B0	CALL #39
 0038	     0027
 003A	     5321	ADD #2,SP
 003C	     92D1	CMP.B &11,0(SP)
 003E	     000B
 0040	     0000
 0042	     2405	JEQ $+12, goes to  004E
 0044	     416F	MOV.B @SP,R15
 0046	     120F	PUSH R15
 0048	     12B0	CALL #57
 004A	     0039
 004C	     5321	ADD #2,SP
 004E	     5321	ADD #2,SP
 0050	     4130	RET
fixups:
 004B	s0.13
 003F	s0.5

section    17	c   14	GetAddr
 0000	     42D4	MOV.B &0,0(R4)
 0002	     0000
 0004	     0000
 0006	     42D5	MOV.B &0,0(R5)
 0008	     0000
 000A	     0000
 000C	     4130	RET
fixups:
 0009	s0.3
 0003	s0.2

section    18	c   44	Clear
 0000	     8321	SUB #2,SP
 0002	     1203	PUSH #0
 0004	     1203	PUSH #0
 0006	     12B0	CALL #0
 0008	     0000
 000A	     5221	ADD #4,SP
 000C	     40B1	MOV #503,0(SP)
 000E	     01F7
 0010	     0000
 0012	     9381	CMP #0,0(SP)
 0014	     0000
 0016	     3808	JL $+18, goes to  0028
 0018	     1230	PUSH #256
 001A	     0100
 001C	     12B0	CALL #0
 001E	     0000
 0020	     5321	ADD #2,SP
 0022	     53B1	ADD #-1,0(SP)
 0024	     0000
 0026	     3FF5	JMP $-20, goes to  0012
 0028	     5321	ADD #2,SP
 002A	     4130	RET
fixups:
 001F	s0.13
 0009	s0.16

section    19	c   70	Init
 0000	     1230	PUSH #33
 0002	     0021
 0004	     12B0	CALL #0
 0006	     0000
 0008	     5321	ADD #2,SP
 000A	     4034	MOV #10,R4
 000C	     000A
 000E	     12B0	CALL #0
 0010	     0000
 0012	     1230	PUSH #6
 0014	     0006
 0016	     12B0	CALL #7
 0018	     0007
 001A	     5321	ADD #2,SP
 001C	     1230	PUSH #19
 001E	     0013
 0020	     12B0	CALL #25
 0022	     0019
 0024	     5321	ADD #2,SP
 0026	     1230	PUSH #198
 0028	     00C6
 002A	     12B0	CALL #35
 002C	     0023
 002E	     5321	ADD #2,SP
 0030	     1230	PUSH #32
 0032	     0020
 0034	     12B0	CALL #45
 0036	     002D
 0038	     5321	ADD #2,SP
 003A	     1230	PUSH #12
 003C	     000C
 003E	     12B0	CALL #55
 0040	     0037
 0042	     5321	ADD #2,SP
 0044	     4130	RET
fixups:
 0011	s3.1
 0041	s0.13

section    20	c   68	SetVop
 0000	     8321	SUB #2,SP
 0002	     42D1	MOV.B &0,0(SP)
 0004	     0000
 0006	     0000
 0008	     B3D2	BIT.B #1,&5
 000A	     0005
 000C	     2005	JNE $+12, goes to  0018
 000E	     1230	PUSH #33
 0010	     0021
 0012	     12B0	CALL #0
 0014	     0000
 0016	     5321	ADD #2,SP
 0018	     411F	MOV 4(SP),R15
 001A	     0004
 001C	     F03F	AND #127,R15
 001E	     007F
 0020	     403E	MOV #128,R14
 0022	     0080
 0024	     DF0E	BIS R15,R14
 0026	     120E	PUSH R14
 0028	     12B0	CALL #21
 002A	     0015
 002C	     5321	ADD #2,SP
 002E	     92D1	CMP.B &11,0(SP)
 0030	     000B
 0032	     0000
 0034	     2405	JEQ $+12, goes to  0040
 0036	     416F	MOV.B @SP,R15
 0038	     120F	PUSH R15
 003A	     12B0	CALL #43
 003C	     002B
 003E	     5321	ADD #2,SP
 0040	     5321	ADD #2,SP
 0042	     4130	RET
fixups:
 003D	s0.13
 0031	s0.5

section    21	c   86	WriteLongint
 0000	     8031	SUB #12,SP
 0002	     000C
 0004	     411F	MOV 20(SP),R15
 0006	     0014
 0008	     5F0F	ADD R15,R15
 000A	     4F0E	MOV R15,R14
 000C	     5E0E	ADD R14,R14
 000E	     5E0F	ADD R14,R15
 0010	     120F	PUSH R15
 0012	     1211	PUSH 22(SP)
 0014	     0016
 0016	     12B0	CALL #0
 0018	     0000
 001A	     5221	ADD #4,SP
 001C	     1211	PUSH 26(SP)
 001E	     001A
 0020	     1211	PUSH 26(SP)
 0022	     001A
 0024	     1211	PUSH 22(SP)
 0026	     0016
 0028	     1251	PUSH.B 22(SP)
 002A	     0016
 002C	     1230	PUSH #12
 002E	     000C
 0030	     410F	MOV SP,R15
 0032	     503F	ADD #10,R15
 0034	     000A
 0036	     120F	PUSH R15
 0038	     12B0	CALL #0
 003A	     0000
 003C	     5031	ADD #12,SP
 003E	     000C
 0040	     1230	PUSH #12
 0042	     000C
 0044	     410F	MOV SP,R15
 0046	     532F	ADD #2,R15
 0048	     120F	PUSH R15
 004A	     12B0	CALL #0
 004C	     0000
 004E	     5221	ADD #4,SP
 0050	     5031	ADD #12,SP
 0052	     000C
 0054	     4130	RET
fixups:
 004D	s0.15
 003B	s2.1
 0019	s0.16

section    22	c   22	setCallbacks
 0000	     4482	MOV R4,&0
 0002	     0000
 0004	     4582	MOV R5,&0
 0006	     0000
 0008	     4682	MOV R6,&0
 000A	     0000
 000C	     4782	MOV R7,&0
 000E	     0000
 0010	     4882	MOV R8,&0
 0012	     0000
 0014	     4130	RET
fixups:
 0013	s0.11
 000F	s0.10
 000B	s0.9
 0007	s0.8
 0003	s0.7

section    23	c   24	module body
 0000	     43C2	MOV.B #0,&0
 0002	     0000
 0004	     43C2	MOV.B #0,&0
 0006	     0000
 0008	     43C2	MOV.B #0,&0
 000A	     0000
 000C	     40F2	MOV.B #36,&0
 000E	     0024
 0010	     0000
 0012	     43C2	MOV.B #0,&0
 0014	     0000
 0016	     4130	RET
fixups:
 0015	s0.6
 0011	s0.5
 000B	s0.4
 0007	s0.3
 0003	s0.2

section    24	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
   23    2    3    4    5   13   14   15   16   17
   18   19   20   21   22
