MODULE PosixTime;
  (* Created on: 13 avr. 2013, author: C. Schoffit.
    17.09.25: oberon portage
    * based on : 
    /*****************************************************************************/
    /* time.h     v4.1.5                                                         */
    /*                                                                           */
    /* Copyright (c) 1990-2013 Texas Instruments Incorporated                    */
    /* http://www.ti.com/                                                        */
    /*                                                                           */
    /*  Redistribution and  use in source  and binary forms, with  or without    */
    /*  modification,  are permitted provided  that the  following conditions    */
    /*  are met:                                                                 */
    /*                                                                           */
    /*     Redistributions  of source  code must  retain the  above copyright    */
    /*     notice, this list of conditions and the following disclaimer.         */
    /*                                                                           */
    /*     Redistributions in binary form  must reproduce the above copyright    */
    /*     notice, this  list of conditions  and the following  disclaimer in    */
    /*     the  documentation  and/or   other  materials  provided  with  the    */
    /*     distribution.                                                         */
    /*                                                                           */
    /*     Neither the  name of Texas Instruments Incorporated  nor the names    */
    /*     of its  contributors may  be used to  endorse or  promote products    */
    /*     derived  from   this  software  without   specific  prior  written    */
    /*     permission.                                                           */
    /*                                                                           */
    /*  THIS SOFTWARE  IS PROVIDED BY THE COPYRIGHT  HOLDERS AND CONTRIBUTORS    */
    /*  "AS IS"  AND ANY  EXPRESS OR IMPLIED  WARRANTIES, INCLUDING,  BUT NOT    */
    /*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR    */
    /*  A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT    */
    /*  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,    */
    /*  SPECIAL,  EXEMPLARY,  OR CONSEQUENTIAL  DAMAGES  (INCLUDING, BUT  NOT    */
    /*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,    */
    /*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY    */
    /*  THEORY OF  LIABILITY, WHETHER IN CONTRACT, STRICT  LIABILITY, OR TORT    */
    /*  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE    */
    /*  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.     */
    /*                                                                           */
    /*****************************************************************************/
  *)
  IMPORT Arith, MP := MultiPrecisionArith, String;

  CONST SECS_IN_MIN* = 60; MINS_IN_HR* = 60; HRS_IN_DAY* = 24;
    SECS_IN_HR* = SECS_IN_MIN * MINS_IN_HR;
    SECS_IN_DAY = SECS_IN_HR * HRS_IN_DAY; SECS_IN_DAY_l* = SECS_IN_DAY  MOD 10000H; SECS_IN_DAY_h* = SECS_IN_DAY  DIV 10000H;
    JAN11970 = 4; (*Jeudi*)

    TIMEMAX_H = 07FFFH; TIMEMAX_L = 0FFFFH;

  TYPE Time* = POINTER TO TimeDesc;
    TimeDesc* = RECORD l*, h*: INTEGER END;

    Tm* = POINTER TO TmDesc;
    TmDesc* = RECORD
      sec*, (*seconds after the minute   - [0,59]*)
      min*, (*minutes after the hour     - [0,59] *)
      hour*, (*hours after the midnight   - [0,23]*)
      mday*, (*day of the month           - [1,31]*)
      mon*, (* months since January       - [0,11]*)
      year*, (* years since 1900*)
      wday*, (* days since Sunday          - [0,6]*)
      yday*: INTEGER; (* days since Jan 1st         - [0,365] *)
      isdst*: BOOLEAN (* Daylight Savings Time flag*)
    END;

    Tz = RECORD
      daylight: BOOLEAN;
      timezone: TimeDesc;
      dstday, (*day of change : 0->Sunday ... 6->Saturday*)
      dsthour, (*hour of change*)
      wtostmonth, (*month of change from winter time to summer time*)
      stowtmonth: INTEGER; (*month of change from summer time to winter time*)
      dstoffset: INTEGER; (*ifference between summer time and winter time is seconds*)
    END;

  VAR TimeMax*, OneSec*: TimeDesc-; tz: Tz-;
    mon_len: ARRAY 12 OF BYTE-; mon_day: ARRAY 12 OF INTEGER-;
    timeOffset*, systemTime*: TimeDesc; timeIsST: BOOLEAN;

  PROCEDURE setMax*(t: Time* );
  BEGIN t.h := TIMEMAX_H; t.l := TIMEMAX_L
  END setMax;

  PROCEDURE setMin*(t: Time* );
  BEGIN t.l := 0; t.h := 0
  END setMin;

  PROCEDURE cmp*(a, b: Time): INTEGER;
    RETURN MP.CmpLongLong(a.h, a.l, b.h, b.l)
  END cmp;

  PROCEDURE inc*(a, b: Time* );
  BEGIN INC(a.l, b.l); ADC(a.h, b.h)
  END inc;

  PROCEDURE tick*;
  BEGIN INC(systemTime.l); ADC(systemTime.h, 0)
  END tick;

  PROCEDURE dec*(a, b: Time* );
  BEGIN DEC(a.l, b.l); SBC(a.h, b.h)
  END dec;

  PROCEDURE LEAPYEAR(y: INTEGER* ): BOOLEAN;
    VAR res: BOOLEAN* ;
  BEGIN INC(y, 1970);
    RETURN (y MOD 4 = 0) & ((y MOD 100 # 0) OR (y MOD 400 = 0))
  END LEAPYEAR;

  PROCEDURE DAYS_IN_YR*(y: INTEGER): INTEGER;
    RETURN 0 + ORD(LEAPYEAR(y)) + 365
  END DAYS_IN_YR;

  PROCEDURE gmhms*(ltime: Time; res: Tm);
    VAR th: INTEGER;
  BEGIN
    (*------------------------------------------------------------------*)
    (* MAKE SURE THE NUMBER OF SECONDS SINCE Jan 1, 1970 CAN BE         *)
    (* REPRESENTED IN SIGNED INTS.                                      *)
    (*------------------------------------------------------------------*)
    th := 0; res.sec := SECS_IN_MIN; MP.DivLongLong(ltime.h, ltime.l, th, res.sec);
    res.min := MINS_IN_HR; MP.DivLongLong(ltime.h, ltime.l, th, res.min);
    res.hour  := HRS_IN_DAY; MP.DivLongLong(ltime.h, ltime.l, th, res.hour);

    (*------------------------------------------------------------------*)
    (* ltime now equalt to NUMBER OF DAYS                                  *)
    (*------------------------------------------------------------------*)
  END gmhms;

  PROCEDURE mktime*(tm: Tm; time: Time);
    VAR daycount, tmp: TimeDesc; mdays, adjust: INTEGER;
  BEGIN
    (*-----------------------------------------------------------------*)
    (* HANDLE SECONDS.  IF TOO MANY OR TOO FEW, MODIFY MINUTES.        *)
    (*-----------------------------------------------------------------*)
    IF tm.sec < 0 THEN adjust := -((-tm.sec + 59) DIV 60) ELSE adjust := tm.sec DIV 60 END;
    INC(tm.min, adjust); DEC(tm.sec, Arith.mul16(adjust, 60));

    (*-----------------------------------------------------------------*)
    (* HANDLE MINUTES.  IF TOO MANY OR TOO FEW, MODIFY HOURS           *)
    (*-----------------------------------------------------------------*)
    IF tm.min < 0 THEN adjust := -((-tm.min + 59) DIV 60) ELSE adjust := tm.min DIV 60 END;
    INC(tm.hour, adjust); DEC(tm.min, Arith.mul16(adjust, 60));

    (*-----------------------------------------------------------------*)
    (* HANDLE HOURS.    IF TOO MANY OR TOO FEW, MODIFY DAYS            *)
    (*-----------------------------------------------------------------*)
    IF tm.hour < 0 THEN adjust := -((-tm.hour + 23) DIV 24) ELSE adjust := tm.hour DIV 24 END;
    INC(tm.mday, adjust); DEC(tm.hour, Arith.mul16(adjust, 24));

    REPEAT
      (*-----------------------------------------------------------------*)
      (* HANDLE MONTHS.   IF TOO MANY OR TOO FEW, MODIFY YEARS           *)
      (*-----------------------------------------------------------------*)
      IF tm.mon < 0 THEN adjust := -((-tm.mon + 11) DIV 12) ELSE adjust := tm.mon DIV 12 END;
      INC(tm.year, adjust); DEC(tm.mon, Arith.mul16(adjust, 12));

      (*-----------------------------------------------------------------*)
      (* HANDLE DAYS.     IF TOO MANY OR TOO FEW, MODIFY MONTHS          *)
      (*-----------------------------------------------------------------*)
      IF tm.mday <= 0 THEN DEC(tm.mon);
        adjust := tm.mon; IF adjust < 0 THEN adjust := 11 END;
        INC(tm.mday, mon_len[adjust] + ORD((tm.mon = 1) & LEAPYEAR(tm.year)));
      ELSE
        (*-----------------------------------------------------------------*)
        (* CALCULATE NUMBER OF DAYS IN THIS MONTH.                         *)
        (*-----------------------------------------------------------------*)
        mdays := mon_len[tm.mon] + ORD((tm.mon = 1) & LEAPYEAR(tm.year));
        IF tm.mday > mdays THEN DEC(tm.mday, mdays); INC(tm.mon) END
      END
    UNTIL tm.mday <= mdays;

    (*--------------------------------------------------------------------*)
    (* WE CAN NOW BE SURE THAT ALL FIELDS IN THE TIME STRUCTURE ARE RIGHT *)
    (*--------------------------------------------------------------------*)
    tm.yday := mon_day[tm.mon] + tm.mday - 1 + ORD((tm.mon > 1) & LEAPYEAR(tm.year));

    daycount.h := 0; daycount.l := tm.year - 70; (* daycount = tm.year - 70 *)
    MP.MulLongLong(daycount.h, daycount.l, 0, 365); (* daycount = (tm.year - 70) * 365 *)
    INC(daycount.l,(tm.year - 69) DIV 4 -ORD(tm.year > 200) (* 2100 isn't a leap year *) + tm.yday); ADC(daycount.h, 0);
    (*daycount:= (tm.year - 70) * 365 + (tm.year - 69) DIV 4 -ORD(tm.year > 200) (* 2100 isn't a leap year *)
      + tm.yday*)

    time.h := daycount.h; time.l := daycount.l; MP.MulLongLong(time.h, time.l, SECS_IN_DAY_h, SECS_IN_DAY_l); (*result = daycount * SECS_IN_DAY*)
    tmp.h := 0; tmp.l := tm.hour; MP.MulLongLong(tmp.h, tmp.l, 0, SECS_IN_HR); INC(time.l, tmp.l); ADC(time.h, tmp.h);
    INC(time.l, Arith.mul16(tm.min, SECS_IN_MIN) + tm.sec); ADC(time.h, 0);
    (*time += tm.hour*SECS_IN_HR + tm.min*SECS_IN_MIN + tm.sec);*)
    IF tm.isdst THEN inc(time, PTR(Time, timeOffset)) END;
    (*result = daycount * SECS_IN_DAY + tm.hour * SECS_IN_HR + tm.min*SECS_IN_MIN + tm.sec - ORD(tm.isdst)*timeOffset*)

    INC(daycount.l, JAN11970); ADC(daycount.h, 0);
    tm.wday := 7; adjust := 0; MP.DivLongLong(daycount.h, daycount.l, adjust, tm.wday);
    (*tm.wday  = (JAN11970 + daycount) MOD 7*)
  END mktime;

  (*format UTC time*)
  PROCEDURE gmtime*(timer: Time; res: Tm);
    VAR ltime: TimeDesc; year: INTEGER;
  BEGIN ltime := timer^;
    res.sec := 0; res.min := 0; res.hour := 0; res.mday := 1; res.mon := 0; res.year := 0;
    IF (ltime.h # TIMEMAX_H) OR (ltime.l # TIMEMAX_L) THEN
      gmhms(PTR(Time, ltime), res);

      (*------------------------------------------------------------------*)
      (* TO DETERMINE THE YEAR, INSTEAD OF DIVIDING BY 365, DO A SUBTRACT *)
      (* LOOP THAT ACCOUNTS FOR LEAP YEARS.                               *)
      (*------------------------------------------------------------------*)
      year := 0;
      WHILE MP.CmpLongLong(ltime.h, ltime.h, 0, DAYS_IN_YR(year)) >= 0 DO
        DEC(ltime.l, DAYS_IN_YR(year)); SBC(ltime.l, 0); INC(year)
      END;

      res.year :=  year+70; INC(res.mday, ltime.l);

      (*------------------------------------------------------------------*)
      (* MAKE VALUES IN res INTO A VALID TIME.                          *)
      (*------------------------------------------------------------------*)
      mktime(res, PTR(Time, ltime))
    END
  END gmtime; 

  (*format local time*)
  PROCEDURE localtime*(timer: Time; res: Tm);
    VAR gtime: TimeDesc;
  BEGIN gtime := timeOffset; (*DIFFERENCE BETWEEN CURRENT TIME ZONE AND GMT IN SECONDS*)
    inc(PTR(Time, gtime), timer);
    gmtime(PTR(Time, gtime), res);
    res.isdst := TRUE; (*set dst flag to indicate that the result is a locat time*)
  END localtime;

  PROCEDURE findlastweekdayofmonth(ft: Tm; mon: INTEGER; dst: Time);
  (*Find the time of the last week day of month.
    For example findlastweekdayofmonth(tm, 2, 0) returns the last sunday of march*)

    VAR dayoffset: TimeDesc;
  BEGIN (*first, go to end of the searched month*)
    ft.mon := mon; ft.mday := mon_len[mon]; ft.hour := tz.dsthour; ft.min := 0; ft.sec := 0; ft.isdst := FALSE; (*UTC Time*)
    mktime(ft, dst); dayoffset.h := 0;
    dayoffset.l := ft.wday - tz.dstday; (*offset to be applied*) IF dayoffset.l < 0 THEN dayoffset.l := 7 - dayoffset.l END;
    MP.MulLongLong(dayoffset.h, dayoffset.l, SECS_IN_DAY_h, SECS_IN_DAY_l); dec(dst, PTR(Time, dayoffset))
  END findlastweekdayofmonth;

  PROCEDURE findnextdsttime(timer: Time; VAR isST: BOOLEAN; dst: Time);
  (* Find de time of next DST change
   * parameters :
   * 	the base time
   * 	the summer time flag (output) : 1 if base time is in summer time
   *
   * return the time of next Daylight Saving Time
   *)

  VAR (*the parameters of DST changes are stored in tmzone structure*)
    current: TmDesc; theMonth: INTEGER; found: BOOLEAN;

  BEGIN isST := FALSE;
    gmtime(timer, PTR(Tm, current)); (*format date*)
	theMonth := current.mon; found := FALSE;

    IF theMonth <= tz.wtostmonth THEN (*search summer time transition time*)
      findlastweekdayofmonth(PTR(Tm, current), tz.wtostmonth, dst);
      IF cmp(timer, dst) < 0 THEN (*we have found the next dst time*) found := TRUE END
    END;

    IF ~found & (theMonth <= tz.stowtmonth) THEN (*do the same for wt*)
      findlastweekdayofmonth(PTR(Tm, current), tz.stowtmonth, dst); (*search winter time transition time*)
      IF cmp(timer, dst) < 0 THEN (*we have found the next dst time*) found := TRUE; isST := TRUE END
    END;

    IF ~found THEN (*the next dst is winter to summer next year*)
      INC(current.year); findlastweekdayofmonth(PTR(Tm, current), tz.wtostmonth, dst)
    END
  END findnextdsttime;

  PROCEDURE settime*(t: Tm; nextdst: Time);
  (*set system time form localtime and adjust DST values
   *
   * Parameter
   *   t : the formatted time (input)
   *
   * returns the new system time
   *)
  BEGIN (*assume winter time (CET)*)
    timeOffset := tz.timezone;
    mktime(t,  PTR(Time, systemTime));
    findnextdsttime(PTR(Time, systemTime), timeIsST, nextdst); (*find next transition for Daylight Saving Time*)
    IF timeIsST THEN (*we assumed to be in winter time and the specified time is summer time*)
      (*we need to adjust UTC time and DST values*)
      IF t.isdst THEN DEC(systemTime.l, tz.dstoffset); SBC(systemTime.h, 0) END;
      timeOffset := tz.timezone; INC(timeOffset.l, tz.dstoffset); ADC(timeOffset.h, 0)
	END
  END settime;

  PROCEDURE TimeToString*(t: Time; nbc, len: INTEGER; VAR str: ARRAY OF CHAR);
  BEGIN String.FromLong(t.h, t.l, nbc, len, str)
  END TimeToString;

  PROCEDURE changedsttime*(nextdst: Time);
(*todo : debug 0 value returned*)
  (*apply Daylight Saving Time transition and compute the next DST transition time*)
    VAR current: TmDesc; isST: BOOLEAN; mon: INTEGER;
  BEGIN (*do some common sense checks and if OK switch for appropriate dst time*)
    gmtime(PTR(Time, systemTime), PTR(Tm, current)); (*format current time*)
    mon := current.mon;

    (*find next DST*)
    INC(current.mon); (*inc month to speedup process*)
    mktime(PTR(Tm, current), nextdst);
	findnextdsttime(nextdst, isST, nextdst); timeOffset := tz.timezone; timeIsST := FALSE;
    IF (mon = tz.wtostmonth) & ~timeIsST THEN (*winter time to summer time transition*)
      INC(timeOffset.l, tz.dstoffset); ADC(timeOffset.h, 0); timeIsST := TRUE
    END
  END changedsttime;

BEGIN TimeMax.h := TIMEMAX_H; TimeMax.l := TIMEMAX_L; OneSec.h := 0; OneSec.l := 1;
  mon_len[0] := 31; mon_len[1] := 28; mon_len[2] := 31; mon_len[3] := 30;
  mon_len[4] := 31; mon_len[5] := 30; mon_len[6] := 31; mon_len[7] := 31;
  mon_len[8] := 30; mon_len[9] := 31; mon_len[10] := 30; mon_len[11] := 31;
  mon_day[0] := 0; mon_day[1] := 31; mon_day[2] := 59; mon_day[3] := 90;
  mon_day[4] := 120; mon_day[5] := 151; mon_day[6] := 181; mon_day[7] := 212;
  mon_day[8] := 243; mon_day[9] := 273; mon_day[10] := 304; mon_day[11] := 334;

  tz. daylight := TRUE; tz.timezone.h := 0; tz.timezone.l := 3600;
  tz.dstday := 0; (*DST change on sunday*)
  tz.dsthour := 1; (*DST change at 01:00*)
  tz.wtostmonth := 2; (*DST winter to summer last Sunday of March*)
  tz.stowtmonth := 9; (*DST summer to winter last Sunday of October*)
  tz.dstoffset := 3600; (*Difference between summer time and winter time in seconds*)

  setMin(PTR(Time, timeOffset)); setMin(PTR(Time, systemTime))
END PosixTime.

OMSPP.Compile PosixTime.Mod/s~
OMSPTool.DecSym PosixTime.sms
decode PosixTime.sms
PosixTime 5B40AD77  3
   1 SECS_IN_MIN [^4]      60
   1 MINS_IN_HR [^4]      60
   1 HRS_IN_DAY [^4]      24
   1 SECS_IN_HR [^4]    3600
   1 SECS_IN_DAY_l [^4]   20864
   1 SECS_IN_DAY_h [^4]       1
   5 Time [19  form = 7 [20  form = 13 [^9]{  exno = 1  extlev = 0  size = 4 { h [^4]   2 l [^4]   0}]]()
   5 TimeDesc [^20]( ->  19)
   5 Tm [21  form = 7 [22  form = 13 [^9]{  exno = 2  extlev = 0  size = 18 { isdst [^2]  16 yday [^4]  14 wday [^4]  12 year [^4]  10 mon [^4]   8 mday [^4]   6 hour [^4]   4 min [^4]   2 sec [^4]   0}]]()
   5 TmDesc [^22]( ->  21)
   9 TimeMax [^20]     3
   9 OneSec [^20]     4
   2 timeOffset [^20]     5
   2 systemTime [^20]     6
   9 setMax [0  form = 10 [^9] leaf UR 0010( class = 2 R4 [^19])]     7
   9 setMin [0  form = 10 [^9] leaf UR 0010( class = 2 R4 [^19])]     8
   9 cmp [0  form = 10 [^4] UR 81F0( class = 2 [^19] class = 2 [^19])]     9
   9 inc [0  form = 10 [^9] leaf UR 0030( class = 2 R5 [^19] class = 2 R4 [^19])]    10
   9 tick [0  form = 10 [^9] UR 0000()]    11
   9 dec [0  form = 10 [^9] leaf UR 0030( class = 2 R5 [^19] class = 2 R4 [^19])]    12
   9 DAYS_IN_YR [0  form = 10 [^4] UR 83F0( class = 2 [^4])]    13
   9 gmhms [0  form = 10 [^9] UR 9FF0( class = 2 [^21] class = 2 [^19])]    14
   9 mktime [0  form = 10 [^9] UR FFF0( class = 2 [^19] class = 2 [^21])]    15
   9 gmtime [0  form = 10 [^9] UR FFF0( class = 2 [^21] class = 2 [^19])]    16
   9 localtime [0  form = 10 [^9] UR FFF0( class = 2 [^21] class = 2 [^19])]    17
   9 settime [0  form = 10 [^9] UR FFF0( class = 2 [^19] class = 2 [^21])]    18
   9 TimeToString [0  form = 10 [^9] UR DFF0( class = 3 [0  form = 12 [^3]  len = -1  size = 4] class = 2 [^4] class = 2 [^19])]    19
   9 changedsttime [0  form = 10 [^9] UR FFF0( class = 2 [^19])]    20

OMSPTool.DecObj PosixTime.mpc
decode PosixTime.mpc
PosixTime 60324DE2
imports:
	Arith CA33A8B5
	MultiPrecisionArith 7965D39A
	String 938D3CFC

section     0	d    8	TimeDesc
 04 00 FF FF FF FF FF FF
fixups:

section     1	d    8	TmDesc
 12 00 FF FF FF FF FF FF
fixups:

section     2	d    8	Tz
 10 00 FF FF FF FF FF FF
fixups:

section     3	d    4	TimeMax
 FF FF FF 7F
fixups:

section     4	d    4	OneSec
 01 00 00 00
fixups:

section     5	d   16	tz
 01 FF 10 0E 00 00 00 00 01 00 02 00 09 00 10 0E
fixups:

section     6	d   12	mon_len
 1F 1C 1F 1E 1F 1E 1F 1F 1E 1F 1E 1F
fixups:

section     7	d   24	mon_day
 00 00 1F 00 3B 00 5A 00 78 00 97 00 B5 00 D4 00
 F3 00 11 01 30 01 4E 01
fixups:

section     8	r    4	timeOffset
fixups:

section     9	r    4	systemTime
fixups:

section    10	r    1	timeIsST
fixups:

section    11	c   12	setMax
 0000	     40B4	MOV #32767,2(R4)
 0002	     7FFF
 0004	     0002
 0006	     43B4	MOV #-1,0(R4)
 0008	     0000
 000A	     4130	RET
fixups:

section    12	c   10	setMin
 0000	     4384	MOV #0,0(R4)
 0002	     0000
 0004	     4384	MOV #0,2(R4)
 0006	     0002
 0008	     4130	RET
fixups:

section    13	c   36	cmp
 0000	     4114	MOV 4(SP),R4
 0002	     0004
 0004	     4415	MOV 2(R4),R5
 0006	     0002
 0008	     4114	MOV 4(SP),R4
 000A	     0004
 000C	     4426	MOV @R4,R6
 000E	     4114	MOV 2(SP),R4
 0010	     0002
 0012	     4417	MOV 2(R4),R7
 0014	     0002
 0016	     4114	MOV 2(SP),R4
 0018	     0002
 001A	     4428	MOV @R4,R8
 001C	     12B0	CALL #0
 001E	     0000
 0020	     440F	MOV R4,R15
 0022	     4130	RET
fixups:
 001F	s2.12

section    14	c   12	inc
 0000	     55A4	ADD @R5,0(R4)
 0002	     0000
 0004	     6594	ADDC 2(R5),2(R4)
 0006	     0002
 0008	     0002
 000A	     4130	RET
fixups:

section    15	c   10	tick
 0000	     5392	ADD #1,&0
 0002	     0000
 0004	     6382	ADDC #0,&0
 0006	     0000
 0008	     4130	RET
fixups:
 0007	s0.9+2
 0003	s0.9

section    16	c   12	dec
 0000	     85A4	SUB @R5,0(R4)
 0002	     0000
 0004	     7594	SUBC 2(R5),2(R4)
 0006	     0002
 0008	     0002
 000A	     4130	RET
fixups:

section    17	c   72	LEAPYEAR
 0000	     5035	ADD #1970,R5
 0002	     07B2
 0004	     4506	MOV R5,R6
 0006	     F036	AND #3,R6
 0008	     0003
 000A	     201C	JNE $+58, goes to  0044
 000C	     1205	PUSH R5
 000E	     1204	PUSH R4
 0010	     4036	MOV #100,R6
 0012	     0064
 0014	     4317	MOV #1,R7
 0016	     12B0	CALL #0
 0018	     0000
 001A	     4406	MOV R4,R6
 001C	     4134	POP R4
 001E	     4135	POP R5
 0020	     9306	CMP #0,R6
 0022	     200E	JNE $+30, goes to  0040
 0024	     1206	PUSH R6
 0026	     1205	PUSH R5
 0028	     1204	PUSH R4
 002A	     4036	MOV #400,R6
 002C	     0190
 002E	     4317	MOV #1,R7
 0030	     12B0	CALL #25
 0032	     0019
 0034	     4407	MOV R4,R7
 0036	     4134	POP R4
 0038	     4135	POP R5
 003A	     4136	POP R6
 003C	     9307	CMP #0,R7
 003E	     2002	JNE $+6, goes to  0044
 0040	     4314	MOV #1,R4
 0042	     3C01	JMP $+4, goes to  0046
 0044	     4304	MOV #0,R4
 0046	     4130	RET
fixups:
 0033	s1.2

section    18	c   16	DAYS_IN_YR
 0000	     4115	MOV 2(SP),R5
 0002	     0002
 0004	     12B0	CALL #0
 0006	     0000
 0008	     440F	MOV R4,R15
 000A	     503F	ADD #365,R15
 000C	     016D
 000E	     4130	RET
fixups:
 0007	s0.17

section    19	c  104	gmhms
 0000	     8321	SUB #2,SP
 0002	     4381	MOV #0,0(SP)
 0004	     0000
 0006	     411F	MOV 4(SP),R15
 0008	     0004
 000A	     40BF	MOV #60,0(R15)
 000C	     003C
 000E	     0000
 0010	     4114	MOV 6(SP),R4
 0012	     0006
 0014	     5324	ADD #2,R4
 0016	     4115	MOV 6(SP),R5
 0018	     0006
 001A	     4106	MOV SP,R6
 001C	     4117	MOV 4(SP),R7
 001E	     0004
 0020	     12B0	CALL #0
 0022	     0000
 0024	     411F	MOV 4(SP),R15
 0026	     0004
 0028	     40BF	MOV #60,2(R15)
 002A	     003C
 002C	     0002
 002E	     4114	MOV 6(SP),R4
 0030	     0006
 0032	     5324	ADD #2,R4
 0034	     4115	MOV 6(SP),R5
 0036	     0006
 0038	     4106	MOV SP,R6
 003A	     4117	MOV 4(SP),R7
 003C	     0004
 003E	     5327	ADD #2,R7
 0040	     12B0	CALL #35
 0042	     0023
 0044	     411F	MOV 4(SP),R15
 0046	     0004
 0048	     40BF	MOV #24,4(R15)
 004A	     0018
 004C	     0004
 004E	     4114	MOV 6(SP),R4
 0050	     0006
 0052	     5324	ADD #2,R4
 0054	     4115	MOV 6(SP),R5
 0056	     0006
 0058	     4106	MOV SP,R6
 005A	     4117	MOV 4(SP),R7
 005C	     0004
 005E	     5227	ADD #4,R7
 0060	     12B0	CALL #67
 0062	     0043
 0064	     5321	ADD #2,SP
 0066	     4130	RET
fixups:
 0063	s2.8

section    20	c  950	mktime
 0000	     8031	SUB #12,SP
 0002	     000C
 0004	     411F	MOV 16(SP),R15
 0006	     0010
 0008	     938F	CMP #0,0(R15)
 000A	     0000
 000C	     3412	JGE $+38, goes to  0032
 000E	     411F	MOV 16(SP),R15
 0010	     0010
 0012	     4F2F	MOV @R15,R15
 0014	     E33F	XOR #-1,R15
 0016	     531F	ADD #1,R15
 0018	     503F	ADD #59,R15
 001A	     003B
 001C	     4F05	MOV R15,R5
 001E	     4036	MOV #60,R6
 0020	     003C
 0022	     4307	MOV #0,R7
 0024	     12B0	CALL #0
 0026	     0000
 0028	     E334	XOR #-1,R4
 002A	     5314	ADD #1,R4
 002C	     4481	MOV R4,10(SP)
 002E	     000A
 0030	     3C0A	JMP $+22, goes to  0046
 0032	     411F	MOV 16(SP),R15
 0034	     0010
 0036	     4F25	MOV @R15,R5
 0038	     4036	MOV #60,R6
 003A	     003C
 003C	     4307	MOV #0,R7
 003E	     12B0	CALL #39
 0040	     0027
 0042	     4481	MOV R4,10(SP)
 0044	     000A
 0046	     411F	MOV 16(SP),R15
 0048	     0010
 004A	     519F	ADD 10(SP),2(R15)
 004C	     000A
 004E	     0002
 0050	     411F	MOV 16(SP),R15
 0052	     0010
 0054	     4115	MOV 10(SP),R5
 0056	     000A
 0058	     4036	MOV #60,R6
 005A	     003C
 005C	     12B0	CALL #0
 005E	     0000
 0060	     848F	SUB R4,0(R15)
 0062	     0000
 0064	     411F	MOV 16(SP),R15
 0066	     0010
 0068	     938F	CMP #0,2(R15)
 006A	     0002
 006C	     3413	JGE $+40, goes to  0094
 006E	     411F	MOV 16(SP),R15
 0070	     0010
 0072	     4F1F	MOV 2(R15),R15
 0074	     0002
 0076	     E33F	XOR #-1,R15
 0078	     531F	ADD #1,R15
 007A	     503F	ADD #59,R15
 007C	     003B
 007E	     4F05	MOV R15,R5
 0080	     4036	MOV #60,R6
 0082	     003C
 0084	     4307	MOV #0,R7
 0086	     12B0	CALL #65
 0088	     0041
 008A	     E334	XOR #-1,R4
 008C	     5314	ADD #1,R4
 008E	     4481	MOV R4,10(SP)
 0090	     000A
 0092	     3C0B	JMP $+24, goes to  00AA
 0094	     411F	MOV 16(SP),R15
 0096	     0010
 0098	     4F15	MOV 2(R15),R5
 009A	     0002
 009C	     4036	MOV #60,R6
 009E	     003C
 00A0	     4307	MOV #0,R7
 00A2	     12B0	CALL #137
 00A4	     0089
 00A6	     4481	MOV R4,10(SP)
 00A8	     000A
 00AA	     411F	MOV 16(SP),R15
 00AC	     0010
 00AE	     519F	ADD 10(SP),4(R15)
 00B0	     000A
 00B2	     0004
 00B4	     411F	MOV 16(SP),R15
 00B6	     0010
 00B8	     4115	MOV 10(SP),R5
 00BA	     000A
 00BC	     4036	MOV #60,R6
 00BE	     003C
 00C0	     12B0	CALL #95
 00C2	     005F
 00C4	     848F	SUB R4,2(R15)
 00C6	     0002
 00C8	     411F	MOV 16(SP),R15
 00CA	     0010
 00CC	     938F	CMP #0,4(R15)
 00CE	     0004
 00D0	     3413	JGE $+40, goes to  00F8
 00D2	     411F	MOV 16(SP),R15
 00D4	     0010
 00D6	     4F1F	MOV 4(R15),R15
 00D8	     0004
 00DA	     E33F	XOR #-1,R15
 00DC	     531F	ADD #1,R15
 00DE	     503F	ADD #23,R15
 00E0	     0017
 00E2	     4F05	MOV R15,R5
 00E4	     4036	MOV #24,R6
 00E6	     0018
 00E8	     4307	MOV #0,R7
 00EA	     12B0	CALL #165
 00EC	     00A5
 00EE	     E334	XOR #-1,R4
 00F0	     5314	ADD #1,R4
 00F2	     4481	MOV R4,10(SP)
 00F4	     000A
 00F6	     3C0B	JMP $+24, goes to  010E
 00F8	     411F	MOV 16(SP),R15
 00FA	     0010
 00FC	     4F15	MOV 4(R15),R5
 00FE	     0004
 0100	     4036	MOV #24,R6
 0102	     0018
 0104	     4307	MOV #0,R7
 0106	     12B0	CALL #237
 0108	     00ED
 010A	     4481	MOV R4,10(SP)
 010C	     000A
 010E	     411F	MOV 16(SP),R15
 0110	     0010
 0112	     519F	ADD 10(SP),6(R15)
 0114	     000A
 0116	     0006
 0118	     411F	MOV 16(SP),R15
 011A	     0010
 011C	     4115	MOV 10(SP),R5
 011E	     000A
 0120	     4036	MOV #24,R6
 0122	     0018
 0124	     12B0	CALL #195
 0126	     00C3
 0128	     848F	SUB R4,4(R15)
 012A	     0004
 012C	     411F	MOV 16(SP),R15
 012E	     0010
 0130	     938F	CMP #0,8(R15)
 0132	     0008
 0134	     3413	JGE $+40, goes to  015C
 0136	     411F	MOV 16(SP),R15
 0138	     0010
 013A	     4F1F	MOV 8(R15),R15
 013C	     0008
 013E	     E33F	XOR #-1,R15
 0140	     531F	ADD #1,R15
 0142	     503F	ADD #11,R15
 0144	     000B
 0146	     4F05	MOV R15,R5
 0148	     4036	MOV #12,R6
 014A	     000C
 014C	     4307	MOV #0,R7
 014E	     12B0	CALL #265
 0150	     0109
 0152	     E334	XOR #-1,R4
 0154	     5314	ADD #1,R4
 0156	     4481	MOV R4,10(SP)
 0158	     000A
 015A	     3C0B	JMP $+24, goes to  0172
 015C	     411F	MOV 16(SP),R15
 015E	     0010
 0160	     4F15	MOV 8(R15),R5
 0162	     0008
 0164	     4036	MOV #12,R6
 0166	     000C
 0168	     4307	MOV #0,R7
 016A	     12B0	CALL #337
 016C	     0151
 016E	     4481	MOV R4,10(SP)
 0170	     000A
 0172	     411F	MOV 16(SP),R15
 0174	     0010
 0176	     519F	ADD 10(SP),10(R15)
 0178	     000A
 017A	     000A
 017C	     411F	MOV 16(SP),R15
 017E	     0010
 0180	     4115	MOV 10(SP),R5
 0182	     000A
 0184	     4036	MOV #12,R6
 0186	     000C
 0188	     12B0	CALL #295
 018A	     0127
 018C	     848F	SUB R4,8(R15)
 018E	     0008
 0190	     411F	MOV 16(SP),R15
 0192	     0010
 0194	     430E	MOV #0,R14
 0196	     9F1E	CMP 6(R15),R14
 0198	     0006
 019A	     3829	JL $+84, goes to  01EE
 019C	     411F	MOV 16(SP),R15
 019E	     0010
 01A0	     839F	SUB #1,8(R15)
 01A2	     0008
 01A4	     411F	MOV 16(SP),R15
 01A6	     0010
 01A8	     4F91	MOV 8(R15),10(SP)
 01AA	     0008
 01AC	     000A
 01AE	     9381	CMP #0,10(SP)
 01B0	     000A
 01B2	     3403	JGE $+8, goes to  01BA
 01B4	     40B1	MOV #11,10(SP)
 01B6	     000B
 01B8	     000A
 01BA	     411F	MOV 16(SP),R15
 01BC	     0010
 01BE	     411E	MOV 10(SP),R14
 01C0	     000A
 01C2	     411D	MOV 16(SP),R13
 01C4	     0010
 01C6	     939D	CMP #1,8(R13)
 01C8	     0008
 01CA	     200A	JNE $+22, goes to  01E0
 01CC	     4114	MOV 16(SP),R4
 01CE	     0010
 01D0	     4415	MOV 10(R4),R5
 01D2	     000A
 01D4	     12B0	CALL #0
 01D6	     0000
 01D8	     9344	CMP.B #0,R4
 01DA	     2402	JEQ $+6, goes to  01E0
 01DC	     431D	MOV #1,R13
 01DE	     3C01	JMP $+4, goes to  01E2
 01E0	     430D	MOV #0,R13
 01E2	     4E5E	MOV.B 0(R14),R14
 01E4	     0000
 01E6	     5D4E	ADD.B R13,R14
 01E8	     5E8F	ADD R14,6(R15)
 01EA	     0006
 01EC	     3C28	JMP $+82, goes to  023E
 01EE	     411F	MOV 16(SP),R15
 01F0	     0010
 01F2	     4F1F	MOV 8(R15),R15
 01F4	     0008
 01F6	     411E	MOV 16(SP),R14
 01F8	     0010
 01FA	     939E	CMP #1,8(R14)
 01FC	     0008
 01FE	     200A	JNE $+22, goes to  0214
 0200	     4114	MOV 16(SP),R4
 0202	     0010
 0204	     4415	MOV 10(R4),R5
 0206	     000A
 0208	     12B0	CALL #471
 020A	     01D7
 020C	     9344	CMP.B #0,R4
 020E	     2402	JEQ $+6, goes to  0214
 0210	     431E	MOV #1,R14
 0212	     3C01	JMP $+4, goes to  0216
 0214	     430E	MOV #0,R14
 0216	     4F5F	MOV.B 485(R15),R15
 0218	     01E5
 021A	     5E4F	ADD.B R14,R15
 021C	     4F81	MOV R15,8(SP)
 021E	     0008
 0220	     411F	MOV 16(SP),R15
 0222	     0010
 0224	     9F91	CMP 6(R15),8(SP)
 0226	     0006
 0228	     0008
 022A	     3409	JGE $+20, goes to  023E
 022C	     411F	MOV 16(SP),R15
 022E	     0010
 0230	     819F	SUB 8(SP),6(R15)
 0232	     0008
 0234	     0006
 0236	     411F	MOV 16(SP),R15
 0238	     0010
 023A	     539F	ADD #1,8(R15)
 023C	     0008
 023E	     411F	MOV 16(SP),R15
 0240	     0010
 0242	     9F91	CMP 6(R15),8(SP)
 0244	     0006
 0246	     0008
 0248	     3B71	JL $-284, goes to  012C
 024A	     411F	MOV 16(SP),R15
 024C	     0010
 024E	     411E	MOV 16(SP),R14
 0250	     0010
 0252	     4E1E	MOV 8(R14),R14
 0254	     0008
 0256	     5E0E	ADD R14,R14
 0258	     411D	MOV 16(SP),R13
 025A	     0010
 025C	     4E1E	MOV 0(R14),R14
 025E	     0000
 0260	     5D1E	ADD 6(R13),R14
 0262	     0006
 0264	     831E	SUB #1,R14
 0266	     411D	MOV 16(SP),R13
 0268	     0010
 026A	     431C	MOV #1,R12
 026C	     9D1C	CMP 8(R13),R12
 026E	     0008
 0270	     340A	JGE $+22, goes to  0286
 0272	     4114	MOV 16(SP),R4
 0274	     0010
 0276	     4415	MOV 10(R4),R5
 0278	     000A
 027A	     12B0	CALL #523
 027C	     020B
 027E	     9344	CMP.B #0,R4
 0280	     2402	JEQ $+6, goes to  0286
 0282	     431D	MOV #1,R13
 0284	     3C01	JMP $+4, goes to  0288
 0286	     430D	MOV #0,R13
 0288	     5D0E	ADD R13,R14
 028A	     4E8F	MOV R14,14(R15)
 028C	     000E
 028E	     4381	MOV #0,2(SP)
 0290	     0002
 0292	     411F	MOV 16(SP),R15
 0294	     0010
 0296	     4F1F	MOV 10(R15),R15
 0298	     000A
 029A	     803F	SUB #70,R15
 029C	     0046
 029E	     4F81	MOV R15,0(SP)
 02A0	     0000
 02A2	     4104	MOV SP,R4
 02A4	     5324	ADD #2,R4
 02A6	     4105	MOV SP,R5
 02A8	     4306	MOV #0,R6
 02AA	     4037	MOV #365,R7
 02AC	     016D
 02AE	     12B0	CALL #0
 02B0	     0000
 02B2	     411F	MOV 16(SP),R15
 02B4	     0010
 02B6	     4F1F	MOV 10(R15),R15
 02B8	     000A
 02BA	     803F	SUB #69,R15
 02BC	     0045
 02BE	     110F	RRA R15
 02C0	     110F	RRA R15
 02C2	     411E	MOV 16(SP),R14
 02C4	     0010
 02C6	     403D	MOV #200,R13
 02C8	     00C8
 02CA	     9E1D	CMP 10(R14),R13
 02CC	     000A
 02CE	     3402	JGE $+6, goes to  02D4
 02D0	     431E	MOV #1,R14
 02D2	     3C01	JMP $+4, goes to  02D6
 02D4	     430E	MOV #0,R14
 02D6	     8E0F	SUB R14,R15
 02D8	     411E	MOV 16(SP),R14
 02DA	     0010
 02DC	     5E1F	ADD 14(R14),R15
 02DE	     000E
 02E0	     5F81	ADD R15,0(SP)
 02E2	     0000
 02E4	     6381	ADDC #0,2(SP)
 02E6	     0002
 02E8	     411F	MOV 14(SP),R15
 02EA	     000E
 02EC	     419F	MOV 2(SP),2(R15)
 02EE	     0002
 02F0	     0002
 02F2	     411F	MOV 14(SP),R15
 02F4	     000E
 02F6	     41AF	MOV @SP,0(R15)
 02F8	     0000
 02FA	     4114	MOV 14(SP),R4
 02FC	     000E
 02FE	     5324	ADD #2,R4
 0300	     4115	MOV 14(SP),R5
 0302	     000E
 0304	     4316	MOV #1,R6
 0306	     4037	MOV #20864,R7
 0308	     5180
 030A	     12B0	CALL #689
 030C	     02B1
 030E	     4381	MOV #0,6(SP)
 0310	     0006
 0312	     411F	MOV 16(SP),R15
 0314	     0010
 0316	     4F91	MOV 4(R15),4(SP)
 0318	     0004
 031A	     0004
 031C	     4104	MOV SP,R4
 031E	     5034	ADD #6,R4
 0320	     0006
 0322	     4105	MOV SP,R5
 0324	     5225	ADD #4,R5
 0326	     4306	MOV #0,R6
 0328	     4037	MOV #3600,R7
 032A	     0E10
 032C	     12B0	CALL #781
 032E	     030D
 0330	     411F	MOV 14(SP),R15
 0332	     000E
 0334	     519F	ADD 4(SP),0(R15)
 0336	     0004
 0338	     0000
 033A	     411F	MOV 14(SP),R15
 033C	     000E
 033E	     619F	ADDC 6(SP),2(R15)
 0340	     0006
 0342	     0002
 0344	     411F	MOV 14(SP),R15
 0346	     000E
 0348	     4114	MOV 16(SP),R4
 034A	     0010
 034C	     4415	MOV 2(R4),R5
 034E	     0002
 0350	     4036	MOV #60,R6
 0352	     003C
 0354	     12B0	CALL #395
 0356	     018B
 0358	     411E	MOV 16(SP),R14
 035A	     0010
 035C	     440D	MOV R4,R13
 035E	     5E2D	ADD @R14,R13
 0360	     5D8F	ADD R13,0(R15)
 0362	     0000
 0364	     411F	MOV 14(SP),R15
 0366	     000E
 0368	     638F	ADDC #0,2(R15)
 036A	     0002
 036C	     411F	MOV 16(SP),R15
 036E	     0010
 0370	     93CF	CMP.B #0,16(R15)
 0372	     0010
 0374	     2406	JEQ $+14, goes to  0382
 0376	     4114	MOV 14(SP),R4
 0378	     000E
 037A	     4035	MOV #0,R5
 037C	     0000
 037E	     12B0	CALL #0
 0380	     0000
 0382	     52A1	ADD #4,0(SP)
 0384	     0000
 0386	     6381	ADDC #0,2(SP)
 0388	     0002
 038A	     411F	MOV 16(SP),R15
 038C	     0010
 038E	     40BF	MOV #7,12(R15)
 0390	     0007
 0392	     000C
 0394	     4381	MOV #0,10(SP)
 0396	     000A
 0398	     4104	MOV SP,R4
 039A	     5324	ADD #2,R4
 039C	     4105	MOV SP,R5
 039E	     4106	MOV SP,R6
 03A0	     5036	ADD #10,R6
 03A2	     000A
 03A4	     4117	MOV 16(SP),R7
 03A6	     0010
 03A8	     5037	ADD #12,R7
 03AA	     000C
 03AC	     12B0	CALL #0
 03AE	     0000
 03B0	     5031	ADD #12,SP
 03B2	     000C
 03B4	     4130	RET
fixups:
 03AF	s2.8
 0381	s0.14
 037D	s0.8
 032F	s2.7
 025F	s0.7
 0219	s0.6
 027D	s0.17
 0357	s1.1
 016D	s1.2

section    21	c  214	gmtime
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     411F	MOV 10(SP),R15
 0006	     000A
 0008	     410E	MOV SP,R14
 000A	     432D	MOV #2,R13
 000C	     4FBE	MOV @R15+,0(R14)
 000E	     0000
 0010	     532E	ADD #2,R14
 0012	     831D	SUB #1,R13
 0014	     23FB	JNE $-8, goes to  000C
 0016	     411F	MOV 8(SP),R15
 0018	     0008
 001A	     438F	MOV #0,0(R15)
 001C	     0000
 001E	     411F	MOV 8(SP),R15
 0020	     0008
 0022	     438F	MOV #0,2(R15)
 0024	     0002
 0026	     411F	MOV 8(SP),R15
 0028	     0008
 002A	     438F	MOV #0,4(R15)
 002C	     0004
 002E	     411F	MOV 8(SP),R15
 0030	     0008
 0032	     439F	MOV #1,6(R15)
 0034	     0006
 0036	     411F	MOV 8(SP),R15
 0038	     0008
 003A	     438F	MOV #0,8(R15)
 003C	     0008
 003E	     411F	MOV 8(SP),R15
 0040	     0008
 0042	     438F	MOV #0,10(R15)
 0044	     000A
 0046	     90B1	CMP #32767,2(SP)
 0048	     7FFF
 004A	     0002
 004C	     2003	JNE $+8, goes to  0054
 004E	     93B1	CMP #-1,0(SP)
 0050	     0000
 0052	     243E	JEQ $+126, goes to  00D0
 0054	     410F	MOV SP,R15
 0056	     120F	PUSH R15
 0058	     1211	PUSH 12(SP)
 005A	     000C
 005C	     12B0	CALL #0
 005E	     0000
 0060	     5221	ADD #4,SP
 0062	     4381	MOV #0,4(SP)
 0064	     0004
 0066	     4115	MOV 2(SP),R5
 0068	     0002
 006A	     4116	MOV 2(SP),R6
 006C	     0002
 006E	     4307	MOV #0,R7
 0070	     1207	PUSH R7
 0072	     1206	PUSH R6
 0074	     1205	PUSH R5
 0076	     1211	PUSH 12(SP)
 0078	     000C
 007A	     12B0	CALL #0
 007C	     0000
 007E	     5321	ADD #2,SP
 0080	     4135	POP R5
 0082	     4136	POP R6
 0084	     4137	POP R7
 0086	     4F08	MOV R15,R8
 0088	     12B0	CALL #0
 008A	     0000
 008C	     9304	CMP #0,R4
 008E	     380C	JL $+26, goes to  00A8
 0090	     1211	PUSH 6(SP)
 0092	     0006
 0094	     12B0	CALL #125
 0096	     007D
 0098	     5321	ADD #2,SP
 009A	     8F81	SUB R15,0(SP)
 009C	     0000
 009E	     7381	SUBC #0,0(SP)
 00A0	     0000
 00A2	     5391	ADD #1,4(SP)
 00A4	     0004
 00A6	     3FDF	JMP $-64, goes to  0066
 00A8	     411F	MOV 8(SP),R15
 00AA	     0008
 00AC	     411E	MOV 4(SP),R14
 00AE	     0004
 00B0	     503E	ADD #70,R14
 00B2	     0046
 00B4	     4E8F	MOV R14,10(R15)
 00B6	     000A
 00B8	     411F	MOV 8(SP),R15
 00BA	     0008
 00BC	     51AF	ADD @SP,6(R15)
 00BE	     0006
 00C0	     1211	PUSH 10(SP)
 00C2	     000A
 00C4	     410F	MOV SP,R15
 00C6	     532F	ADD #2,R15
 00C8	     120F	PUSH R15
 00CA	     12B0	CALL #0
 00CC	     0000
 00CE	     5221	ADD #4,SP
 00D0	     5031	ADD #6,SP
 00D2	     0006
 00D4	     4130	RET
fixups:
 00CD	s0.20
 008B	s2.12
 0097	s0.18
 005F	s0.19

section    22	c   50	localtime
 0000	     8221	SUB #4,SP
 0002	     4291	MOV &0,0(SP)
 0004	     0000
 0006	     0000
 0008	     4291	MOV &0,2(SP)
 000A	     0000
 000C	     0002
 000E	     4104	MOV SP,R4
 0010	     4115	MOV 8(SP),R5
 0012	     0008
 0014	     12B0	CALL #0
 0016	     0000
 0018	     410F	MOV SP,R15
 001A	     120F	PUSH R15
 001C	     1211	PUSH 10(SP)
 001E	     000A
 0020	     12B0	CALL #0
 0022	     0000
 0024	     5221	ADD #4,SP
 0026	     411F	MOV 6(SP),R15
 0028	     0006
 002A	     43DF	MOV.B #1,16(R15)
 002C	     0010
 002E	     5221	ADD #4,SP
 0030	     4130	RET
fixups:
 0023	s0.21
 0017	s0.14
 000B	s0.8+2
 0005	s0.8

section    23	c  142	findlastweekdayofmonth
 0000	     8221	SUB #4,SP
 0002	     411F	MOV 10(SP),R15
 0004	     000A
 0006	     419F	MOV 8(SP),8(R15)
 0008	     0008
 000A	     0008
 000C	     411F	MOV 10(SP),R15
 000E	     000A
 0010	     411E	MOV 8(SP),R14
 0012	     0008
 0014	     4E5E	MOV.B 0(R14),R14
 0016	     0000
 0018	     4E8F	MOV R14,6(R15)
 001A	     0006
 001C	     411F	MOV 10(SP),R15
 001E	     000A
 0020	     429F	MOV &0,4(R15)
 0022	     0000
 0024	     0004
 0026	     411F	MOV 10(SP),R15
 0028	     000A
 002A	     438F	MOV #0,2(R15)
 002C	     0002
 002E	     411F	MOV 10(SP),R15
 0030	     000A
 0032	     438F	MOV #0,0(R15)
 0034	     0000
 0036	     411F	MOV 10(SP),R15
 0038	     000A
 003A	     43CF	MOV.B #0,16(R15)
 003C	     0010
 003E	     1211	PUSH 12(SP)
 0040	     000C
 0042	     1211	PUSH 10(SP)
 0044	     000A
 0046	     12B0	CALL #0
 0048	     0000
 004A	     5221	ADD #4,SP
 004C	     4381	MOV #0,2(SP)
 004E	     0002
 0050	     411F	MOV 10(SP),R15
 0052	     000A
 0054	     4F1F	MOV 12(R15),R15
 0056	     000C
 0058	     821F	SUB &0,R15
 005A	     0000
 005C	     4F81	MOV R15,0(SP)
 005E	     0000
 0060	     9381	CMP #0,0(SP)
 0062	     0000
 0064	     3405	JGE $+12, goes to  0070
 0066	     403F	MOV #7,R15
 0068	     0007
 006A	     812F	SUB @SP,R15
 006C	     4F81	MOV R15,0(SP)
 006E	     0000
 0070	     4104	MOV SP,R4
 0072	     5324	ADD #2,R4
 0074	     4105	MOV SP,R5
 0076	     4316	MOV #1,R6
 0078	     4037	MOV #20864,R7
 007A	     5180
 007C	     12B0	CALL #0
 007E	     0000
 0080	     4114	MOV 6(SP),R4
 0082	     0006
 0084	     4105	MOV SP,R5
 0086	     12B0	CALL #0
 0088	     0000
 008A	     5221	ADD #4,SP
 008C	     4130	RET
fixups:
 0089	s0.16
 007F	s2.7
 005B	s0.5+6
 0049	s0.20
 0023	s0.5+8
 0017	s0.6

section    24	c  188	findnextdsttime
 0000	     8031	SUB #22,SP
 0002	     0016
 0004	     411F	MOV 26(SP),R15
 0006	     001A
 0008	     43CF	MOV.B #0,0(R15)
 000A	     0000
 000C	     1211	PUSH 30(SP)
 000E	     001E
 0010	     410F	MOV SP,R15
 0012	     532F	ADD #2,R15
 0014	     120F	PUSH R15
 0016	     12B0	CALL #0
 0018	     0000
 001A	     5221	ADD #4,SP
 001C	     4191	MOV 8(SP),18(SP)
 001E	     0008
 0020	     0012
 0022	     43C1	MOV.B #0,20(SP)
 0024	     0014
 0026	     9192	CMP 18(SP),&0
 0028	     0012
 002A	     0000
 002C	     3815	JL $+44, goes to  0058
 002E	     410F	MOV SP,R15
 0030	     120F	PUSH R15
 0032	     1212	PUSH &43
 0034	     002B
 0036	     1211	PUSH 30(SP)
 0038	     001E
 003A	     12B0	CALL #0
 003C	     0000
 003E	     5031	ADD #6,SP
 0040	     0006
 0042	     1211	PUSH 30(SP)
 0044	     001E
 0046	     1211	PUSH 28(SP)
 0048	     001C
 004A	     12B0	CALL #0
 004C	     0000
 004E	     5221	ADD #4,SP
 0050	     930F	CMP #0,R15
 0052	     3402	JGE $+6, goes to  0058
 0054	     43D1	MOV.B #1,20(SP)
 0056	     0014
 0058	     93C1	CMP.B #0,20(SP)
 005A	     0014
 005C	     201D	JNE $+60, goes to  0098
 005E	     9192	CMP 18(SP),&0
 0060	     0012
 0062	     0000
 0064	     3819	JL $+52, goes to  0098
 0066	     410F	MOV SP,R15
 0068	     120F	PUSH R15
 006A	     1212	PUSH &99
 006C	     0063
 006E	     1211	PUSH 30(SP)
 0070	     001E
 0072	     12B0	CALL #61
 0074	     003D
 0076	     5031	ADD #6,SP
 0078	     0006
 007A	     1211	PUSH 30(SP)
 007C	     001E
 007E	     1211	PUSH 28(SP)
 0080	     001C
 0082	     12B0	CALL #77
 0084	     004D
 0086	     5221	ADD #4,SP
 0088	     930F	CMP #0,R15
 008A	     3406	JGE $+14, goes to  0098
 008C	     43D1	MOV.B #1,20(SP)
 008E	     0014
 0090	     411F	MOV 26(SP),R15
 0092	     001A
 0094	     43DF	MOV.B #1,0(R15)
 0096	     0000
 0098	     93C1	CMP.B #0,20(SP)
 009A	     0014
 009C	     200C	JNE $+26, goes to  00B6
 009E	     5391	ADD #1,10(SP)
 00A0	     000A
 00A2	     410F	MOV SP,R15
 00A4	     120F	PUSH R15
 00A6	     1212	PUSH &53
 00A8	     0035
 00AA	     1211	PUSH 30(SP)
 00AC	     001E
 00AE	     12B0	CALL #117
 00B0	     0075
 00B2	     5031	ADD #6,SP
 00B4	     0006
 00B6	     5031	ADD #22,SP
 00B8	     0016
 00BA	     4130	RET
fixups:
 006D	s0.5+12
 0085	s0.13
 00B1	s0.23
 00A9	s0.5+10
 0019	s0.21

section    25	c   96	settime
 0000	     4292	MOV &0,&0
 0002	     0000
 0004	     0000
 0006	     4292	MOV &0,&0
 0008	     0000
 000A	     0000
 000C	     1211	PUSH 6(SP)
 000E	     0006
 0010	     1230	PUSH #0
 0012	     0000
 0014	     12B0	CALL #0
 0016	     0000
 0018	     5221	ADD #4,SP
 001A	     1230	PUSH #19
 001C	     0013
 001E	     1230	PUSH #0
 0020	     0000
 0022	     1211	PUSH 8(SP)
 0024	     0008
 0026	     12B0	CALL #0
 0028	     0000
 002A	     5031	ADD #6,SP
 002C	     0006
 002E	     93C2	CMP.B #0,&33
 0030	     0021
 0032	     2415	JEQ $+44, goes to  005E
 0034	     411F	MOV 4(SP),R15
 0036	     0004
 0038	     93CF	CMP.B #0,16(R15)
 003A	     0010
 003C	     2405	JEQ $+12, goes to  0048
 003E	     8292	SUB &0,&29
 0040	     0000
 0042	     001D
 0044	     7382	SUBC #0,&0
 0046	     0000
 0048	     4292	MOV &3,&5
 004A	     0003
 004C	     0005
 004E	     4292	MOV &9,&11
 0050	     0009
 0052	     000B
 0054	     5292	ADD &65,&77
 0056	     0041
 0058	     004D
 005A	     6382	ADDC #0,&83
 005C	     0053
 005E	     4130	RET
fixups:
 0047	s0.9+2
 0057	s0.5+14
 0029	s0.24
 0031	s0.10
 0017	s0.20
 0043	s0.9
 005D	s0.8+2
 0051	s0.5+4
 0059	s0.8
 004B	s0.5+2

section    26	c   40	TimeToString
 0000	     411F	MOV 10(SP),R15
 0002	     000A
 0004	     121F	PUSH 2(R15)
 0006	     0002
 0008	     411F	MOV 12(SP),R15
 000A	     000C
 000C	     122F	PUSH @R15
 000E	     1211	PUSH 14(SP)
 0010	     000E
 0012	     1251	PUSH.B 14(SP)
 0014	     000E
 0016	     1211	PUSH 14(SP)
 0018	     000E
 001A	     1211	PUSH 14(SP)
 001C	     000E
 001E	     12B0	CALL #0
 0020	     0000
 0022	     5031	ADD #12,SP
 0024	     000C
 0026	     4130	RET
fixups:
 0021	s3.1

section    27	c  118	changedsttime
 0000	     8031	SUB #22,SP
 0002	     0016
 0004	     1230	PUSH #0
 0006	     0000
 0008	     410F	MOV SP,R15
 000A	     532F	ADD #2,R15
 000C	     120F	PUSH R15
 000E	     12B0	CALL #0
 0010	     0000
 0012	     5221	ADD #4,SP
 0014	     4191	MOV 8(SP),20(SP)
 0016	     0008
 0018	     0014
 001A	     5391	ADD #1,8(SP)
 001C	     0008
 001E	     410F	MOV SP,R15
 0020	     120F	PUSH R15
 0022	     1211	PUSH 28(SP)
 0024	     001C
 0026	     12B0	CALL #0
 0028	     0000
 002A	     5221	ADD #4,SP
 002C	     1211	PUSH 26(SP)
 002E	     001A
 0030	     410F	MOV SP,R15
 0032	     503F	ADD #20,R15
 0034	     0014
 0036	     120F	PUSH R15
 0038	     1211	PUSH 30(SP)
 003A	     001E
 003C	     12B0	CALL #0
 003E	     0000
 0040	     5031	ADD #6,SP
 0042	     0006
 0044	     4292	MOV &0,&0
 0046	     0000
 0048	     0000
 004A	     4292	MOV &0,&0
 004C	     0000
 004E	     0000
 0050	     43C2	MOV.B #0,&0
 0052	     0000
 0054	     9291	CMP &0,20(SP)
 0056	     0000
 0058	     0014
 005A	     200A	JNE $+22, goes to  0070
 005C	     93C2	CMP.B #0,&83
 005E	     0053
 0060	     2007	JNE $+16, goes to  0070
 0062	     5292	ADD &0,&73
 0064	     0000
 0066	     0049
 0068	     6382	ADDC #0,&79
 006A	     004F
 006C	     43D2	MOV.B #1,&95
 006E	     005F
 0070	     5031	ADD #22,SP
 0072	     0016
 0074	     4130	RET
fixups:
 0065	s0.5+14
 0057	s0.5+10
 006F	s0.10
 006B	s0.8+2
 004D	s0.5+4
 0067	s0.8
 0047	s0.5+2
 003F	s0.24
 0029	s0.20
 0011	s0.21
 0007	s0.9

section    28	c   18	module body
 0000	     4034	MOV #0,R4
 0002	     0000
 0004	     12B0	CALL #0
 0006	     0000
 0008	     4034	MOV #0,R4
 000A	     0000
 000C	     12B0	CALL #7
 000E	     0007
 0010	     4130	RET
fixups:
 000B	s0.9
 000F	s0.12
 0003	s0.8

section    29	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
   28    0    1    3    4    8    9   11   12   13
   14   15   16   18   19   20   21   22   25   26
   27
