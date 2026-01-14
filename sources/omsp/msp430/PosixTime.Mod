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
    IF tm.isdst THEN dec(time, PTR(Time, timeOffset)) END;
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
      WHILE MP.CmpLongLong(ltime.h, ltime.l, 0, DAYS_IN_YR(year)) >= 0 DO
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
    mktime(t, PTR(Time, systemTime));
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
