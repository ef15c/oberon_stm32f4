MODULE pcd8544;
  IMPORT M := msp430g2553, MP := MultiPrecisionArith;
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

(*
#define LIGHT_ON PO_NLIGHT &= ~NLIGHT;
#define LIGHT_OFF PO_NLIGHT |= NLIGHT;
*)

    HPIXELS =  84; VBANKS =  6; (*screen size*)

    (*Instruction flags*)
    DATA = 8; (*specify data instead of command*) INVERT = {0..8};

    (*instructions available in all modes*)
    NOP = {}; NOP_MASK = {0..8}; FUNCTION_SET = {5}; FUNCTION_SET_MASK = {3..8}; H = 0; V = 1; PD = 2; (*function flags*)

    (*instructions available in basic mode*)
    DISPLAY_CONTROL = {3}; DISPLAY_CONTROL_MASK = {1, 3..8}; D = 2; E = 0;
    SET_Y_ADDRESS = {6}; SET_Y_ADDRESS_MASK = {3..8};
    SET_X_ADDRESS = {7}; SET_X_ADDRESS_MASK = {7..8};

    (*instructions available in extended mode*)
    TEMP_CONTROL = {2}; TEMP_CONTROL_MASK = {2..8};
    BIAS_SYSTEM = {4}; BIAS_SYSTEM_MASK = {3..8};
    SET_VOP = {7}; SET_VOP_MASK = {7..8};
(*
#define IS_EXTENDED_FUNCTION_SET (_pcd8544_currentLCDFunctionSet&0x01)
#define IS_BASIC_FUNCTION_SET (!(IS_EXTENDED_FUNCTION_SET))
#define IS_VERTICAL_ADDRESSING (_pcd8544_currentLCDFunctionSet&0x02)
#define IS_LCD_OFF (_pcd8544_currentLCDFunctionSet&0x04)
#define IS_LCD_ON (!(IS_LCD_OFF))
*)

(*
// When PUSH_LCD_POS is used, it must be followed by POP_LCD_POS in the same block
// Otherwise, a compilation error appears to signal the mismatch problem

#define PUSH_LCD_POS {unsigned char px, py; unsigned int cc; px = _pcd8544_LCDXAddr; py = _pcd8544_LCDYAddr; cc = _pcd8544_composeChar;
#define POP_LCD_POS	_pcd8544_composeChar = cc; setAddrLCD(px, py);}
*)

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
    XAddr, YAddr: BYTE; FunctionSet: BYTESET;

  PROCEDURE send(d: SET*);
  (*send a command or data to LCD*)
  BEGIN BIC(PO_NCE^, NCE); (*Select LCD for SPI communication*)
    (*Memorize state of LCD screen*)
    IF d*FUNCTION_SET_MASK = FUNCTION_SET THEN FunctionSet := d
    ELSIF ~(H IN FunctionSet) & (d*SET_Y_ADDRESS_MASK = SET_Y_ADDRESS) THEN
      YAddr := ORD(d*(SET_Y_ADDRESS_MASK/INVERT))
    ELSIF ~(H IN FunctionSet) & (d*SET_X_ADDRESS_MASK = SET_X_ADDRESS) THEN
      XAddr := ORD(d*(SET_X_ADDRESS_MASK/INVERT))
    ELSIF DATA IN d THEN (*Send data : need to update X and Y addresses*)
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

    IF DATA IN d THEN BIS(PO_DC^, DC) ELSE BIC(PO_DC^, DC) END; (*Set Data/Command line for Nokia 5110 LCD*)
    REPEAT UNTIL BIT(M.IFG2^, M.UCA0TXIFG); (*Wait for USCI availability*)
    M.UCA0TXBUF^ := ORD(d); (*USCI A is ready, send character*)
    REPEAT UNTIL ~BIT(M.UCA0STAT^, M.UCBUSY); (*Wait for end of transmission*)
    BIS(PO_NCE^, NCE); (*Release LCD for SPI communication*)
  END send;

  PROCEDURE writeChar*(car: CHAR);
    (*Write a character on LCD Screen*)
    VAR composeChar: CHAR; i: INTEGER; column: BYTESET;
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
  END writeChar;

  PROCEDURE writeString*(string: ARRAY OF CHAR);
    (* Write a string on LCD Screen *)
    VAR i: INTEGER;
  BEGIN i := 0; WHILE string[i] # 0X DO writeChar(string[i]); INC(i) END
  END writeString;

  PROCEDURE setAddr*(xAddr, yAddr: BYTE);
    (*Set address of next LCD write*)
    VAR oldFunctionSet: BYTESET;
  BEGIN oldFunctionSet := FunctionSet; (* Store current Function set in order to restore it before return *)
    IF H IN FunctionSet THEN send(FUNCTION_SET) END; (*Request basic instruction set*)
    send(SET_X_ADDRESS + TOSET(xAddr)); send(SET_Y_ADDRESS + TOSET(yAddr));
    IF oldFunctionSet # FunctionSet THEN send(oldFunctionSet) END; (*Restore previous function set*)
  END setAddr;

  PROCEDURE clear*;
    VAR i: INTEGER;
  BEGIN setAddr(0, 0); (*Set X=0, Y=0*)
    FOR i := HPIXELS*VBANKS - 1 TO 0 BY -1 DO send({DATA}) END (*Clear RAM*)
  END clear;

  PROCEDURE init*;
  BEGIN send(FUNCTION_SET + {H}); (* function set PD = 0 and V = 0, select extended instruction set (H = 1 mode) *)
    send(TEMP_CONTROL); (*set TC = 00 *) send(BIAS_SYSTEM + TOSET(3)); (*set BS = 011*)
    send(SET_VOP +  TOSET(3AH)); (* set VOP =  a+58 x b [V]*)
    send(FUNCTION_SET); (*select normal instruction set (H = 0 mode)*)
    send(DISPLAY_CONTROL + {D}); (*display control set normal mode (D = 1 and E = 0)*)
  END init;

  PROCEDURE setVop*(vop: INTEGER);
    VAR oldFunctionSet: BYTESET;
  BEGIN oldFunctionSet := FunctionSet;
    IF ~(H IN FunctionSet) THEN send(FUNCTION_SET + {H}) END; (*Request extended instruction set*)
    send(SET_VOP +  TOSET(vop)*(SET_VOP_MASK/INVERT)); (*set VOP = a + vop x b volts*)
    IF oldFunctionSet # FunctionSet THEN send(oldFunctionSet) END; (*Restore previous function set*)
  END setVop;

  PROCEDURE writeLongint*(th, tl: INTEGER; nx, ny, nbc: INTEGER; pad: CHAR);
    (* th, tl : value to output on display
     * nx, ny : screen coordinates in character unit
     * nbc : number of digits to output
     * pad : padding character*)
    VAR dl, dh, p: INTEGER;
  BEGIN p := nx + nbc - 1;
    (*Display the number*)
    REPEAT dh := 0; dl := 10; MP.DivLongLong(th, tl, dh, dl); (*d : = t%10; t /= 10;*)
      setAddr(6*p, ny); DEC(p);  (*On positionne l'adresse d'affichage*)
      writeChar(CHR(dl + ORD("0")));
    UNTIL (th = 0) & (tl = 0);
    setAddr(6*nx, ny); WHILE p >= nx DO DEC(p); writeChar(pad) END; (*clear heading characters*)
	setAddr(6*(nx + nbc), ny)
  END writeLongint;

BEGIN XAddr := 0; YAddr := 0; FunctionSet := {PD}
END pcd8544.

OMSPTool.DecObj pcd8544.mpc
