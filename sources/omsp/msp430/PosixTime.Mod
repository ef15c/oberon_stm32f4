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

    TIMEMAX_H = 0FFFFH; TIMEMAX_L = 0FFFFH;

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
  BEGIN t.l := TIMEMAX_H; t.h := TIMEMAX_L
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
    INC(tm.min, adjust); DEC(tm.sec, adjust * 60);

    (*-----------------------------------------------------------------*)
    (* HANDLE MINUTES.  IF TOO MANY OR TOO FEW, MODIFY HOURS           *)
    (*-----------------------------------------------------------------*)
    IF tm.min < 0 THEN adjust := -((-tm.min + 59) DIV 60) ELSE adjust := tm.min DIV 60 END;
    INC(tm.hour, adjust); DEC(tm.min, adjust * 60);

    (*-----------------------------------------------------------------*)
    (* HANDLE HOURS.    IF TOO MANY OR TOO FEW, MODIFY DAYS            *)
    (*-----------------------------------------------------------------*)
    IF tm.hour < 0 THEN adjust := -((-tm.hour + 23) DIV 24) ELSE adjust := tm.hour DIV 24 END;
    INC(tm.mday, adjust); DEC(tm.hour, adjust * 24);

    REPEAT
      (*-----------------------------------------------------------------*)
      (* HANDLE MONTHS.   IF TOO MANY OR TOO FEW, MODIFY YEARS           *)
      (*-----------------------------------------------------------------*)
      IF tm.mon < 0 THEN adjust := -((-tm.mon + 11) DIV 12) ELSE adjust := tm.mon DIV 12 END;
      INC(tm.year, adjust); DEC(tm.mon, adjust * 12);

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
    MP.MulLongInt(daycount.h, daycount.l, 365); (* daycount = (tm.year - 70) * 365 *)
    INC(daycount.l,(tm.year - 69) DIV 4 -ORD(tm.year > 200) (* 2100 isn't a leap year *) + tm.yday); ADC(daycount.h, 0);
    (*daycount:= (tm.year - 70) * 365 + (tm.year - 69) DIV 4 -ORD(tm.year > 200) (* 2100 isn't a leap year *)
      + tm.yday*)

    time.h := daycount.h; time.l := daycount.l; MP.MulLongLong(time.h, time.l, SECS_IN_DAY_h, SECS_IN_DAY_l); (*result = daycount * SECS_IN_DAY*)
    tmp.h := 0; tmp.l := tm.hour; MP.MulLongInt(tmp.h, tmp.l, SECS_IN_HR); INC(time.l, tmp.l); ADC(time.h, tmp.h);
    INC(time.l, tm.min*SECS_IN_MIN + tm.sec); ADC(time.h, 0);
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

  PROCEDURE TimeToString*(t: Time; nbc: INTEGER; VAR str: ARRAY OF CHAR);
  BEGIN String.FromLong(t.h, t.l, nbc, str)
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
PosixTime FAD15A9A  2
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
   1 setMax [0  form = 10 [^9] leaf UR 0010( class = 2 R4 [^19])]       7
   1 setMin [0  form = 10 [^9] leaf UR 0010( class = 2 R4 [^19])]       8
   1 cmp [0  form = 10 [^4] UR 81F0( class = 2 [^19] class = 2 [^19])]       9
   1 inc [0  form = 10 [^9] leaf UR 0030( class = 2 R5 [^19] class = 2 R4 [^19])]      10
   1 tick [0  form = 10 [^9] UR 0000()]      11
   1 dec [0  form = 10 [^9] leaf UR 0030( class = 2 R5 [^19] class = 2 R4 [^19])]      12
   1 DAYS_IN_YR [0  form = 10 [^4] UR 83F0( class = 2 [^4])]      13
   1 gmhms [0  form = 10 [^9] UR 9FF0( class = 2 [^21] class = 2 [^19])]      14
   1 mktime [0  form = 10 [^9] UR FFF0( class = 2 [^19] class = 2 [^21])]      15
   1 gmtime [0  form = 10 [^9] UR FFF0( class = 2 [^21] class = 2 [^19])]      16
   1 localtime [0  form = 10 [^9] UR FFF0( class = 2 [^21] class = 2 [^19])]      17
   1 settime [0  form = 10 [^9] UR FFF0( class = 2 [^19] class = 2 [^21])]      18
   1 TimeToString [0  form = 10 [^9] UR DFF0( class = 3 [0  form = 12 [^3]  len = -1  size = 4] class = 2 [^4] class = 2 [^19])]      19
   1 changedsttime [0  form = 10 [^9] UR FFF0( class = 2 [^19])]      20

OMSPTool.DecObj PosixTime.mpc
decode PosixTime.mpc
PosixTime B4F780EF Flash  2182
imports:
	Arith 570D2017
	MultiPrecisionArith EDF92C49
	String DD084CE7
type descriptors
 0004 FFFF FFFF FFFF 0012 FFFF FFFF FFFF 0010 FFFF FFFF FFFF
data    10
strings
\FF\FF\FF\FF|||\FF||||||	||||;|Z|x|\97|\B5|\D4|\F3|0N
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
	c 0820 18b	k 0000 4b	k 0008 18b	k 0018 4b	k 001C 4b	d 0000 4b	d 0004 4b	c 0000 10b	c 000A 10b	c 0014 36b	c 0038 12b	c 0044 10b	c 004E 12b	c 009E 16b	c 00AE 104b	c 0116 972b	c 04E2 210b	c 05B4 48b	c 0728 96b	c 0788 36b	c 07AC 116b
fixup procedures in code space chains
 082E     0	 000A	10b
 06F2     0	 0014	36b
 05CA     0	 0038	12b
 066C     0	 004E	12b
 03A4     0	 005A	68b
 0574     0	 009E	16b
 053C     0	 00AE	104b
 07D2     0	 0116	972b
 07BC     0	 04E2	210b
 071C     0	 05E4	142b
 07E8     0	 0672	182b
 0292     1	 0002	0b
 0568     2	 000C	0b
 04DA     2	 0008	0b
 0662     2	 0007	0b
 0452     2	 0006	0b
 07A4     3	 0001	0b
fixup handlers in vector space chains
fixup variables in code space chains
 0818     0	 0008	1b
 0814     0	 0002	4b
 0822     0	 0000	4b
 076E     0	 0006	4b
 082A     0	 0004	4b
fixup constants in code space chains
 080E     0	 002E	16b
 07F6     0	 0024	16b
 07F0     0	 0022	16b
 06DA     0	 002C	16b
 0800     0	 002A	16b
 063E     0	 0026	16b
 0606     0	 0028	16b
 0386     0	 003C	2b
 05FA     0	 0030	2b
fixup variables in constant space chains
fixup constants in constant space chains
entry =  0820
code  2098
 0000	     43B4	MOV #-1,0(R4)
 0002	     0000
 0004	     43B4	MOV #-1,2(R4)
 0006	     0002
 0008	     4130	RET
 000A	     4384	MOV #0,0(R4)
 000C	     0000
 000E	     4384	MOV #0,2(R4)
 0010	     0002
 0012	     4130	RET
 0014	     4114	MOV 4(SP),R4
 0016	     0004
 0018	     4415	MOV 2(R4),R5
 001A	     0002
 001C	     4114	MOV 4(SP),R4
 001E	     0004
 0020	     4426	MOV @R4,R6
 0022	     4114	MOV 2(SP),R4
 0024	     0002
 0026	     4417	MOV 2(R4),R7
 0028	     0002
 002A	     4114	MOV 2(SP),R4
 002C	     0002
 002E	     4428	MOV @R4,R8
 0030	     12B0	CALL #0
 0032	     0000
 0034	     440F	MOV R4,R15
 0036	     4130	RET
 0038	     55A4	ADD @R5,0(R4)
 003A	     0000
 003C	     6594	ADDC 2(R5),2(R4)
 003E	     0002
 0040	     0002
 0042	     4130	RET
 0044	     5392	ADD #1,&0
 0046	     0000
 0048	     6382	ADDC #0,&0
 004A	     0000
 004C	     4130	RET
 004E	     85A4	SUB @R5,0(R4)
 0050	     0000
 0052	     7594	SUBC 2(R5),2(R4)
 0054	     0002
 0056	     0002
 0058	     4130	RET
 005A	     5035	ADD #1970,R5
 005C	     07B2
 005E	     4506	MOV R5,R6
 0060	     F036	AND #3,R6
 0062	     0003
 0064	     201A	JNE $+54, goes to  009A
 0066	     1205	PUSH R5
 0068	     1204	PUSH R4
 006A	     4036	MOV #100,R6
 006C	     0064
 006E	     4317	MOV #1,R7
 0070	     12B0	CALL #0
 0072	     0000
 0074	     4406	MOV R4,R6
 0076	     4134	POP R4
 0078	     4135	POP R5
 007A	     9306	CMP #0,R6
 007C	     200C	JNE $+26, goes to  0096
 007E	     1205	PUSH R5
 0080	     1204	PUSH R4
 0082	     4036	MOV #400,R6
 0084	     0190
 0086	     4317	MOV #1,R7
 0088	     12B0	CALL #114
 008A	     0072
 008C	     4406	MOV R4,R6
 008E	     4134	POP R4
 0090	     4135	POP R5
 0092	     9306	CMP #0,R6
 0094	     2002	JNE $+6, goes to  009A
 0096	     4314	MOV #1,R4
 0098	     3C01	JMP $+4, goes to  009C
 009A	     4304	MOV #0,R4
 009C	     4130	RET
 009E	     4115	MOV 2(SP),R5
 00A0	     0002
 00A2	     12B0	CALL #0
 00A4	     0000
 00A6	     5034	ADD #365,R4
 00A8	     016D
 00AA	     440F	MOV R4,R15
 00AC	     4130	RET
 00AE	     8321	SUB #2,SP
 00B0	     4381	MOV #0,0(SP)
 00B2	     0000
 00B4	     411F	MOV 4(SP),R15
 00B6	     0004
 00B8	     40BF	MOV #60,0(R15)
 00BA	     003C
 00BC	     0000
 00BE	     4114	MOV 6(SP),R4
 00C0	     0006
 00C2	     5324	ADD #2,R4
 00C4	     4115	MOV 6(SP),R5
 00C6	     0006
 00C8	     4106	MOV SP,R6
 00CA	     4117	MOV 4(SP),R7
 00CC	     0004
 00CE	     12B0	CALL #0
 00D0	     0000
 00D2	     411F	MOV 4(SP),R15
 00D4	     0004
 00D6	     40BF	MOV #60,2(R15)
 00D8	     003C
 00DA	     0002
 00DC	     4114	MOV 6(SP),R4
 00DE	     0006
 00E0	     5324	ADD #2,R4
 00E2	     4115	MOV 6(SP),R5
 00E4	     0006
 00E6	     4106	MOV SP,R6
 00E8	     4117	MOV 4(SP),R7
 00EA	     0004
 00EC	     5327	ADD #2,R7
 00EE	     12B0	CALL #208
 00F0	     00D0
 00F2	     411F	MOV 4(SP),R15
 00F4	     0004
 00F6	     40BF	MOV #24,4(R15)
 00F8	     0018
 00FA	     0004
 00FC	     4114	MOV 6(SP),R4
 00FE	     0006
 0100	     5324	ADD #2,R4
 0102	     4115	MOV 6(SP),R5
 0104	     0006
 0106	     4106	MOV SP,R6
 0108	     4117	MOV 4(SP),R7
 010A	     0004
 010C	     5227	ADD #4,R7
 010E	     12B0	CALL #240
 0110	     00F0
 0112	     5321	ADD #2,SP
 0114	     4130	RET
 0116	     8031	SUB #12,SP
 0118	     000C
 011A	     411F	MOV 16(SP),R15
 011C	     0010
 011E	     938F	CMP #0,0(R15)
 0120	     0000
 0122	     3412	JGE $+38, goes to  0148
 0124	     411F	MOV 16(SP),R15
 0126	     0010
 0128	     4F2F	MOV @R15,R15
 012A	     E33F	XOR #-1,R15
 012C	     531F	ADD #1,R15
 012E	     503F	ADD #59,R15
 0130	     003B
 0132	     4F05	MOV R15,R5
 0134	     4036	MOV #60,R6
 0136	     003C
 0138	     4307	MOV #0,R7
 013A	     12B0	CALL #138
 013C	     008A
 013E	     E334	XOR #-1,R4
 0140	     5314	ADD #1,R4
 0142	     4481	MOV R4,10(SP)
 0144	     000A
 0146	     3C0A	JMP $+22, goes to  015C
 0148	     411F	MOV 16(SP),R15
 014A	     0010
 014C	     4F25	MOV @R15,R5
 014E	     4036	MOV #60,R6
 0150	     003C
 0152	     4307	MOV #0,R7
 0154	     12B0	CALL #316
 0156	     013C
 0158	     4481	MOV R4,10(SP)
 015A	     000A
 015C	     411F	MOV 16(SP),R15
 015E	     0010
 0160	     519F	ADD 10(SP),2(R15)
 0162	     000A
 0164	     0002
 0166	     411F	MOV 16(SP),R15
 0168	     0010
 016A	     411E	MOV 10(SP),R14
 016C	     000A
 016E	     5E0E	ADD R14,R14
 0170	     5E0E	ADD R14,R14
 0172	     4E0D	MOV R14,R13
 0174	     5D0D	ADD R13,R13
 0176	     5D0E	ADD R13,R14
 0178	     5D0D	ADD R13,R13
 017A	     5D0E	ADD R13,R14
 017C	     5D0D	ADD R13,R13
 017E	     5D0E	ADD R13,R14
 0180	     8E8F	SUB R14,0(R15)
 0182	     0000
 0184	     411F	MOV 16(SP),R15
 0186	     0010
 0188	     3413	JGE $+40, goes to  01B0
 018A	     411F	MOV 16(SP),R15
 018C	     0010
 018E	     4F1F	MOV 2(R15),R15
 0190	     0002
 0192	     E33F	XOR #-1,R15
 0194	     531F	ADD #1,R15
 0196	     503F	ADD #59,R15
 0198	     003B
 019A	     4F05	MOV R15,R5
 019C	     4036	MOV #60,R6
 019E	     003C
 01A0	     4307	MOV #0,R7
 01A2	     12B0	CALL #342
 01A4	     0156
 01A6	     E334	XOR #-1,R4
 01A8	     5314	ADD #1,R4
 01AA	     4481	MOV R4,10(SP)
 01AC	     000A
 01AE	     3C0B	JMP $+24, goes to  01C6
 01B0	     411F	MOV 16(SP),R15
 01B2	     0010
 01B4	     4F15	MOV 2(R15),R5
 01B6	     0002
 01B8	     4036	MOV #60,R6
 01BA	     003C
 01BC	     4307	MOV #0,R7
 01BE	     12B0	CALL #420
 01C0	     01A4
 01C2	     4481	MOV R4,10(SP)
 01C4	     000A
 01C6	     411F	MOV 16(SP),R15
 01C8	     0010
 01CA	     519F	ADD 10(SP),4(R15)
 01CC	     000A
 01CE	     0004
 01D0	     411F	MOV 16(SP),R15
 01D2	     0010
 01D4	     411E	MOV 10(SP),R14
 01D6	     000A
 01D8	     5E0E	ADD R14,R14
 01DA	     5E0E	ADD R14,R14
 01DC	     4E0D	MOV R14,R13
 01DE	     5D0D	ADD R13,R13
 01E0	     5D0E	ADD R13,R14
 01E2	     5D0D	ADD R13,R13
 01E4	     5D0E	ADD R13,R14
 01E6	     5D0D	ADD R13,R13
 01E8	     5D0E	ADD R13,R14
 01EA	     8E8F	SUB R14,2(R15)
 01EC	     0002
 01EE	     411F	MOV 16(SP),R15
 01F0	     0010
 01F2	     3413	JGE $+40, goes to  021A
 01F4	     411F	MOV 16(SP),R15
 01F6	     0010
 01F8	     4F1F	MOV 4(R15),R15
 01FA	     0004
 01FC	     E33F	XOR #-1,R15
 01FE	     531F	ADD #1,R15
 0200	     503F	ADD #23,R15
 0202	     0017
 0204	     4F05	MOV R15,R5
 0206	     4036	MOV #24,R6
 0208	     0018
 020A	     4307	MOV #0,R7
 020C	     12B0	CALL #448
 020E	     01C0
 0210	     E334	XOR #-1,R4
 0212	     5314	ADD #1,R4
 0214	     4481	MOV R4,10(SP)
 0216	     000A
 0218	     3C0B	JMP $+24, goes to  0230
 021A	     411F	MOV 16(SP),R15
 021C	     0010
 021E	     4F15	MOV 4(R15),R5
 0220	     0004
 0222	     4036	MOV #24,R6
 0224	     0018
 0226	     4307	MOV #0,R7
 0228	     12B0	CALL #526
 022A	     020E
 022C	     4481	MOV R4,10(SP)
 022E	     000A
 0230	     411F	MOV 16(SP),R15
 0232	     0010
 0234	     519F	ADD 10(SP),6(R15)
 0236	     000A
 0238	     0006
 023A	     411F	MOV 16(SP),R15
 023C	     0010
 023E	     411E	MOV 10(SP),R14
 0240	     000A
 0242	     5E0E	ADD R14,R14
 0244	     5E0E	ADD R14,R14
 0246	     5E0E	ADD R14,R14
 0248	     4E0D	MOV R14,R13
 024A	     5D0D	ADD R13,R13
 024C	     5D0E	ADD R13,R14
 024E	     8E8F	SUB R14,4(R15)
 0250	     0004
 0252	     411F	MOV 16(SP),R15
 0254	     0010
 0256	     938F	CMP #0,8(R15)
 0258	     0008
 025A	     3413	JGE $+40, goes to  0282
 025C	     411F	MOV 16(SP),R15
 025E	     0010
 0260	     4F1F	MOV 8(R15),R15
 0262	     0008
 0264	     E33F	XOR #-1,R15
 0266	     531F	ADD #1,R15
 0268	     503F	ADD #11,R15
 026A	     000B
 026C	     4F05	MOV R15,R5
 026E	     4036	MOV #12,R6
 0270	     000C
 0272	     4307	MOV #0,R7
 0274	     12B0	CALL #554
 0276	     022A
 0278	     E334	XOR #-1,R4
 027A	     5314	ADD #1,R4
 027C	     4481	MOV R4,10(SP)
 027E	     000A
 0280	     3C0B	JMP $+24, goes to  0298
 0282	     411F	MOV 16(SP),R15
 0284	     0010
 0286	     4F15	MOV 8(R15),R5
 0288	     0008
 028A	     4036	MOV #12,R6
 028C	     000C
 028E	     4307	MOV #0,R7
 0290	     12B0	CALL #630
 0292	     0276
 0294	     4481	MOV R4,10(SP)
 0296	     000A
 0298	     411F	MOV 16(SP),R15
 029A	     0010
 029C	     519F	ADD 10(SP),10(R15)
 029E	     000A
 02A0	     000A
 02A2	     411F	MOV 16(SP),R15
 02A4	     0010
 02A6	     411E	MOV 10(SP),R14
 02A8	     000A
 02AA	     5E0E	ADD R14,R14
 02AC	     5E0E	ADD R14,R14
 02AE	     4E0D	MOV R14,R13
 02B0	     5D0D	ADD R13,R13
 02B2	     5D0E	ADD R13,R14
 02B4	     8E8F	SUB R14,8(R15)
 02B6	     0008
 02B8	     411F	MOV 16(SP),R15
 02BA	     0010
 02BC	     430E	MOV #0,R14
 02BE	     9F1E	CMP 6(R15),R14
 02C0	     0006
 02C2	     3829	JL $+84, goes to  0316
 02C4	     411F	MOV 16(SP),R15
 02C6	     0010
 02C8	     839F	SUB #1,8(R15)
 02CA	     0008
 02CC	     411F	MOV 16(SP),R15
 02CE	     0010
 02D0	     4F91	MOV 8(R15),10(SP)
 02D2	     0008
 02D4	     000A
 02D6	     9381	CMP #0,10(SP)
 02D8	     000A
 02DA	     3403	JGE $+8, goes to  02E2
 02DC	     40B1	MOV #11,10(SP)
 02DE	     000B
 02E0	     000A
 02E2	     411F	MOV 16(SP),R15
 02E4	     0010
 02E6	     411E	MOV 10(SP),R14
 02E8	     000A
 02EA	     411D	MOV 16(SP),R13
 02EC	     0010
 02EE	     939D	CMP #1,8(R13)
 02F0	     0008
 02F2	     200A	JNE $+22, goes to  0308
 02F4	     4114	MOV 16(SP),R4
 02F6	     0010
 02F8	     4415	MOV 10(R4),R5
 02FA	     000A
 02FC	     12B0	CALL #164
 02FE	     00A4
 0300	     9344	CMP.B #0,R4
 0302	     2402	JEQ $+6, goes to  0308
 0304	     431D	MOV #1,R13
 0306	     3C01	JMP $+4, goes to  030A
 0308	     430D	MOV #0,R13
 030A	     4E5E	MOV.B 0(R14),R14
 030C	     0000
 030E	     5D4E	ADD.B R13,R14
 0310	     5E8F	ADD R14,6(R15)
 0312	     0006
 0314	     3C28	JMP $+82, goes to  0366
 0316	     411F	MOV 16(SP),R15
 0318	     0010
 031A	     4F1F	MOV 8(R15),R15
 031C	     0008
 031E	     411E	MOV 16(SP),R14
 0320	     0010
 0322	     939E	CMP #1,8(R14)
 0324	     0008
 0326	     200A	JNE $+22, goes to  033C
 0328	     4114	MOV 16(SP),R4
 032A	     0010
 032C	     4415	MOV 10(R4),R5
 032E	     000A
 0330	     12B0	CALL #766
 0332	     02FE
 0334	     9344	CMP.B #0,R4
 0336	     2402	JEQ $+6, goes to  033C
 0338	     431E	MOV #1,R14
 033A	     3C01	JMP $+4, goes to  033E
 033C	     430E	MOV #0,R14
 033E	     4F5F	MOV.B 780(R15),R15
 0340	     030C
 0342	     5E4F	ADD.B R14,R15
 0344	     4F81	MOV R15,8(SP)
 0346	     0008
 0348	     411F	MOV 16(SP),R15
 034A	     0010
 034C	     9F91	CMP 6(R15),8(SP)
 034E	     0006
 0350	     0008
 0352	     3409	JGE $+20, goes to  0366
 0354	     411F	MOV 16(SP),R15
 0356	     0010
 0358	     819F	SUB 8(SP),6(R15)
 035A	     0008
 035C	     0006
 035E	     411F	MOV 16(SP),R15
 0360	     0010
 0362	     539F	ADD #1,8(R15)
 0364	     0008
 0366	     411F	MOV 16(SP),R15
 0368	     0010
 036A	     9F91	CMP 6(R15),8(SP)
 036C	     0006
 036E	     0008
 0370	     3B70	JL $-286, goes to  0252
 0372	     411F	MOV 16(SP),R15
 0374	     0010
 0376	     411E	MOV 16(SP),R14
 0378	     0010
 037A	     4E1E	MOV 8(R14),R14
 037C	     0008
 037E	     5E0E	ADD R14,R14
 0380	     411D	MOV 16(SP),R13
 0382	     0010
 0384	     4E1E	MOV 0(R14),R14
 0386	     0000
 0388	     5D1E	ADD 6(R13),R14
 038A	     0006
 038C	     831E	SUB #1,R14
 038E	     411D	MOV 16(SP),R13
 0390	     0010
 0392	     431C	MOV #1,R12
 0394	     9D1C	CMP 8(R13),R12
 0396	     0008
 0398	     340A	JGE $+22, goes to  03AE
 039A	     4114	MOV 16(SP),R4
 039C	     0010
 039E	     4415	MOV 10(R4),R5
 03A0	     000A
 03A2	     12B0	CALL #818
 03A4	     0332
 03A6	     9344	CMP.B #0,R4
 03A8	     2402	JEQ $+6, goes to  03AE
 03AA	     431D	MOV #1,R13
 03AC	     3C01	JMP $+4, goes to  03B0
 03AE	     430D	MOV #0,R13
 03B0	     5D0E	ADD R13,R14
 03B2	     4E8F	MOV R14,14(R15)
 03B4	     000E
 03B6	     4381	MOV #0,2(SP)
 03B8	     0002
 03BA	     411F	MOV 16(SP),R15
 03BC	     0010
 03BE	     4F1F	MOV 10(R15),R15
 03C0	     000A
 03C2	     803F	SUB #70,R15
 03C4	     0046
 03C6	     4F81	MOV R15,0(SP)
 03C8	     0000
 03CA	     4104	MOV SP,R4
 03CC	     5324	ADD #2,R4
 03CE	     4105	MOV SP,R5
 03D0	     4036	MOV #365,R6
 03D2	     016D
 03D4	     12B0	CALL #0
 03D6	     0000
 03D8	     411F	MOV 16(SP),R15
 03DA	     0010
 03DC	     4F1F	MOV 10(R15),R15
 03DE	     000A
 03E0	     803F	SUB #69,R15
 03E2	     0045
 03E4	     110F	RRA R15
 03E6	     110F	RRA R15
 03E8	     411E	MOV 16(SP),R14
 03EA	     0010
 03EC	     403D	MOV #200,R13
 03EE	     00C8
 03F0	     9E1D	CMP 10(R14),R13
 03F2	     000A
 03F4	     3402	JGE $+6, goes to  03FA
 03F6	     431E	MOV #1,R14
 03F8	     3C01	JMP $+4, goes to  03FC
 03FA	     430E	MOV #0,R14
 03FC	     8E0F	SUB R14,R15
 03FE	     411E	MOV 16(SP),R14
 0400	     0010
 0402	     5E1F	ADD 14(R14),R15
 0404	     000E
 0406	     5F81	ADD R15,0(SP)
 0408	     0000
 040A	     6381	ADDC #0,2(SP)
 040C	     0002
 040E	     411F	MOV 14(SP),R15
 0410	     000E
 0412	     419F	MOV 2(SP),2(R15)
 0414	     0002
 0416	     0002
 0418	     411F	MOV 14(SP),R15
 041A	     000E
 041C	     41AF	MOV @SP,0(R15)
 041E	     0000
 0420	     4114	MOV 14(SP),R4
 0422	     000E
 0424	     5324	ADD #2,R4
 0426	     4115	MOV 14(SP),R5
 0428	     000E
 042A	     4316	MOV #1,R6
 042C	     4037	MOV #20864,R7
 042E	     5180
 0430	     12B0	CALL #0
 0432	     0000
 0434	     4381	MOV #0,6(SP)
 0436	     0006
 0438	     411F	MOV 16(SP),R15
 043A	     0010
 043C	     4F91	MOV 4(R15),4(SP)
 043E	     0004
 0440	     0004
 0442	     4104	MOV SP,R4
 0444	     5034	ADD #6,R4
 0446	     0006
 0448	     4105	MOV SP,R5
 044A	     5225	ADD #4,R5
 044C	     4036	MOV #3600,R6
 044E	     0E10
 0450	     12B0	CALL #982
 0452	     03D6
 0454	     411F	MOV 14(SP),R15
 0456	     000E
 0458	     519F	ADD 4(SP),0(R15)
 045A	     0004
 045C	     0000
 045E	     411F	MOV 14(SP),R15
 0460	     000E
 0462	     619F	ADDC 6(SP),2(R15)
 0464	     0006
 0466	     0002
 0468	     411F	MOV 14(SP),R15
 046A	     000E
 046C	     411E	MOV 16(SP),R14
 046E	     0010
 0470	     4E1E	MOV 2(R14),R14
 0472	     0002
 0474	     5E0E	ADD R14,R14
 0476	     5E0E	ADD R14,R14
 0478	     4E0D	MOV R14,R13
 047A	     5D0D	ADD R13,R13
 047C	     5D0E	ADD R13,R14
 047E	     5D0D	ADD R13,R13
 0480	     5D0E	ADD R13,R14
 0482	     5D0D	ADD R13,R13
 0484	     5D0E	ADD R13,R14
 0486	     411D	MOV 16(SP),R13
 0488	     0010
 048A	     5D2E	ADD @R13,R14
 048C	     5E8F	ADD R14,0(R15)
 048E	     0000
 0490	     411F	MOV 14(SP),R15
 0492	     000E
 0494	     638F	ADDC #0,2(R15)
 0496	     0002
 0498	     411F	MOV 16(SP),R15
 049A	     0010
 049C	     93CF	CMP.B #0,16(R15)
 049E	     0010
 04A0	     2406	JEQ $+14, goes to  04AE
 04A2	     4114	MOV 14(SP),R4
 04A4	     000E
 04A6	     4035	MOV #0,R5
 04A8	     0000
 04AA	     12B0	CALL #0
 04AC	     0000
 04AE	     52A1	ADD #4,0(SP)
 04B0	     0000
 04B2	     6381	ADDC #0,2(SP)
 04B4	     0002
 04B6	     411F	MOV 16(SP),R15
 04B8	     0010
 04BA	     40BF	MOV #7,12(R15)
 04BC	     0007
 04BE	     000C
 04C0	     4381	MOV #0,10(SP)
 04C2	     000A
 04C4	     4104	MOV SP,R4
 04C6	     5324	ADD #2,R4
 04C8	     4105	MOV SP,R5
 04CA	     4106	MOV SP,R6
 04CC	     5036	ADD #10,R6
 04CE	     000A
 04D0	     4117	MOV 16(SP),R7
 04D2	     0010
 04D4	     5037	ADD #12,R7
 04D6	     000C
 04D8	     12B0	CALL #272
 04DA	     0110
 04DC	     5031	ADD #12,SP
 04DE	     000C
 04E0	     4130	RET
 04E2	     8031	SUB #6,SP
 04E4	     0006
 04E6	     411F	MOV 10(SP),R15
 04E8	     000A
 04EA	     410E	MOV SP,R14
 04EC	     432D	MOV #2,R13
 04EE	     4FBE	MOV @R15+,0(R14)
 04F0	     0000
 04F2	     532E	ADD #2,R14
 04F4	     831D	SUB #1,R13
 04F6	     23FB	JNE $-8, goes to  04EE
 04F8	     411F	MOV 8(SP),R15
 04FA	     0008
 04FC	     438F	MOV #0,0(R15)
 04FE	     0000
 0500	     411F	MOV 8(SP),R15
 0502	     0008
 0504	     438F	MOV #0,2(R15)
 0506	     0002
 0508	     411F	MOV 8(SP),R15
 050A	     0008
 050C	     438F	MOV #0,4(R15)
 050E	     0004
 0510	     411F	MOV 8(SP),R15
 0512	     0008
 0514	     439F	MOV #1,6(R15)
 0516	     0006
 0518	     411F	MOV 8(SP),R15
 051A	     0008
 051C	     438F	MOV #0,8(R15)
 051E	     0008
 0520	     411F	MOV 8(SP),R15
 0522	     0008
 0524	     438F	MOV #0,10(R15)
 0526	     000A
 0528	     93B1	CMP #-1,2(SP)
 052A	     0002
 052C	     2003	JNE $+8, goes to  0534
 052E	     93B1	CMP #-1,0(SP)
 0530	     0000
 0532	     243D	JEQ $+124, goes to  05AE
 0534	     1201	PUSH SP
 0536	     1211	PUSH 12(SP)
 0538	     000C
 053A	     12B0	CALL #0
 053C	     0000
 053E	     5221	ADD #4,SP
 0540	     4381	MOV #0,4(SP)
 0542	     0004
 0544	     4115	MOV 2(SP),R5
 0546	     0002
 0548	     4116	MOV 2(SP),R6
 054A	     0002
 054C	     4307	MOV #0,R7
 054E	     1207	PUSH R7
 0550	     1206	PUSH R6
 0552	     1205	PUSH R5
 0554	     1211	PUSH 12(SP)
 0556	     000C
 0558	     12B0	CALL #0
 055A	     0000
 055C	     5321	ADD #2,SP
 055E	     4135	POP R5
 0560	     4136	POP R6
 0562	     4137	POP R7
 0564	     4408	MOV R4,R8
 0566	     12B0	CALL #50
 0568	     0032
 056A	     9304	CMP #0,R4
 056C	     380C	JL $+26, goes to  0586
 056E	     1211	PUSH 6(SP)
 0570	     0006
 0572	     12B0	CALL #1370
 0574	     055A
 0576	     5321	ADD #2,SP
 0578	     8F81	SUB R15,0(SP)
 057A	     0000
 057C	     7381	SUBC #0,0(SP)
 057E	     0000
 0580	     5391	ADD #1,4(SP)
 0582	     0004
 0584	     3FDF	JMP $-64, goes to  0544
 0586	     411F	MOV 8(SP),R15
 0588	     0008
 058A	     411E	MOV 4(SP),R14
 058C	     0004
 058E	     503E	ADD #70,R14
 0590	     0046
 0592	     4E8F	MOV R14,10(R15)
 0594	     000A
 0596	     411F	MOV 8(SP),R15
 0598	     0008
 059A	     51AF	ADD @SP,6(R15)
 059C	     0006
 059E	     1211	PUSH 10(SP)
 05A0	     000A
 05A2	     410F	MOV SP,R15
 05A4	     532F	ADD #2,R15
 05A6	     120F	PUSH R15
 05A8	     12B0	CALL #0
 05AA	     0000
 05AC	     5221	ADD #4,SP
 05AE	     5031	ADD #6,SP
 05B0	     0006
 05B2	     4130	RET
 05B4	     8221	SUB #4,SP
 05B6	     4291	MOV &1192,0(SP)
 05B8	     04A8
 05BA	     0000
 05BC	     4291	MOV &0,2(SP)
 05BE	     0000
 05C0	     0002
 05C2	     4104	MOV SP,R4
 05C4	     4115	MOV 8(SP),R5
 05C6	     0008
 05C8	     12B0	CALL #1196
 05CA	     04AC
 05CC	     1201	PUSH SP
 05CE	     1211	PUSH 10(SP)
 05D0	     000A
 05D2	     12B0	CALL #0
 05D4	     0000
 05D6	     5221	ADD #4,SP
 05D8	     411F	MOV 6(SP),R15
 05DA	     0006
 05DC	     43DF	MOV.B #1,16(R15)
 05DE	     0010
 05E0	     5221	ADD #4,SP
 05E2	     4130	RET
 05E4	     8221	SUB #4,SP
 05E6	     411F	MOV 10(SP),R15
 05E8	     000A
 05EA	     419F	MOV 8(SP),8(R15)
 05EC	     0008
 05EE	     0008
 05F0	     411F	MOV 10(SP),R15
 05F2	     000A
 05F4	     411E	MOV 8(SP),R14
 05F6	     0008
 05F8	     4E5E	MOV.B 832(R14),R14
 05FA	     0340
 05FC	     4E8F	MOV R14,6(R15)
 05FE	     0006
 0600	     411F	MOV 10(SP),R15
 0602	     000A
 0604	     429F	MOV &0,4(R15)
 0606	     0000
 0608	     0004
 060A	     411F	MOV 10(SP),R15
 060C	     000A
 060E	     438F	MOV #0,2(R15)
 0610	     0002
 0612	     411F	MOV 10(SP),R15
 0614	     000A
 0616	     438F	MOV #0,0(R15)
 0618	     0000
 061A	     411F	MOV 10(SP),R15
 061C	     000A
 061E	     43CF	MOV.B #0,16(R15)
 0620	     0010
 0622	     1211	PUSH 12(SP)
 0624	     000C
 0626	     1211	PUSH 10(SP)
 0628	     000A
 062A	     12B0	CALL #1450
 062C	     05AA
 062E	     5221	ADD #4,SP
 0630	     4381	MOV #0,2(SP)
 0632	     0002
 0634	     411F	MOV 10(SP),R15
 0636	     000A
 0638	     4F1F	MOV 12(R15),R15
 063A	     000C
 063C	     821F	SUB &0,R15
 063E	     0000
 0640	     4F81	MOV R15,0(SP)
 0642	     0000
 0644	     9381	CMP #0,0(SP)
 0646	     0000
 0648	     3405	JGE $+12, goes to  0654
 064A	     403F	MOV #7,R15
 064C	     0007
 064E	     812F	SUB @SP,R15
 0650	     4F81	MOV R15,0(SP)
 0652	     0000
 0654	     4104	MOV SP,R4
 0656	     5324	ADD #2,R4
 0658	     4105	MOV SP,R5
 065A	     4316	MOV #1,R6
 065C	     4037	MOV #20864,R7
 065E	     5180
 0660	     12B0	CALL #1074
 0662	     0432
 0664	     4114	MOV 6(SP),R4
 0666	     0006
 0668	     4105	MOV SP,R5
 066A	     12B0	CALL #0
 066C	     0000
 066E	     5221	ADD #4,SP
 0670	     4130	RET
 0672	     8031	SUB #22,SP
 0674	     0016
 0676	     411F	MOV 26(SP),R15
 0678	     001A
 067A	     43CF	MOV.B #0,0(R15)
 067C	     0000
 067E	     1211	PUSH 30(SP)
 0680	     001E
 0682	     410F	MOV SP,R15
 0684	     532F	ADD #2,R15
 0686	     120F	PUSH R15
 0688	     12B0	CALL #1492
 068A	     05D4
 068C	     5221	ADD #4,SP
 068E	     4191	MOV 8(SP),18(SP)
 0690	     0008
 0692	     0012
 0694	     43C1	MOV.B #0,20(SP)
 0696	     0014
 0698	     9192	CMP 18(SP),&0
 069A	     0012
 069C	     0000
 069E	     3814	JL $+42, goes to  06C8
 06A0	     1201	PUSH SP
 06A2	     1212	PUSH &1692
 06A4	     069C
 06A6	     1211	PUSH 30(SP)
 06A8	     001E
 06AA	     12B0	CALL #0
 06AC	     0000
 06AE	     5031	ADD #6,SP
 06B0	     0006
 06B2	     1211	PUSH 30(SP)
 06B4	     001E
 06B6	     1211	PUSH 28(SP)
 06B8	     001C
 06BA	     12B0	CALL #0
 06BC	     0000
 06BE	     5221	ADD #4,SP
 06C0	     930F	CMP #0,R15
 06C2	     3402	JGE $+6, goes to  06C8
 06C4	     43D1	MOV.B #1,20(SP)
 06C6	     0014
 06C8	     93C1	CMP.B #0,20(SP)
 06CA	     0014
 06CC	     201C	JNE $+58, goes to  0706
 06CE	     9192	CMP 18(SP),&0
 06D0	     0012
 06D2	     0000
 06D4	     3818	JL $+50, goes to  0706
 06D6	     1201	PUSH SP
 06D8	     1212	PUSH &1746
 06DA	     06D2
 06DC	     1211	PUSH 30(SP)
 06DE	     001E
 06E0	     12B0	CALL #1708
 06E2	     06AC
 06E4	     5031	ADD #6,SP
 06E6	     0006
 06E8	     1211	PUSH 30(SP)
 06EA	     001E
 06EC	     1211	PUSH 28(SP)
 06EE	     001C
 06F0	     12B0	CALL #1724
 06F2	     06BC
 06F4	     5221	ADD #4,SP
 06F6	     930F	CMP #0,R15
 06F8	     3406	JGE $+14, goes to  0706
 06FA	     43D1	MOV.B #1,20(SP)
 06FC	     0014
 06FE	     411F	MOV 26(SP),R15
 0700	     001A
 0702	     43DF	MOV.B #1,0(R15)
 0704	     0000
 0706	     93C1	CMP.B #0,20(SP)
 0708	     0014
 070A	     200B	JNE $+24, goes to  0722
 070C	     5391	ADD #1,10(SP)
 070E	     000A
 0710	     1201	PUSH SP
 0712	     1212	PUSH &1700
 0714	     06A4
 0716	     1211	PUSH 30(SP)
 0718	     001E
 071A	     12B0	CALL #1762
 071C	     06E2
 071E	     5031	ADD #6,SP
 0720	     0006
 0722	     5031	ADD #22,SP
 0724	     0016
 0726	     4130	RET
 0728	     4292	MOV &0,&1464
 072A	     0000
 072C	     05B8
 072E	     4292	MOV &0,&1470
 0730	     0000
 0732	     05BE
 0734	     1211	PUSH 6(SP)
 0736	     0006
 0738	     1230	PUSH #70
 073A	     0046
 073C	     12B0	CALL #1580
 073E	     062C
 0740	     5221	ADD #4,SP
 0742	     1230	PUSH #1850
 0744	     073A
 0746	     1230	PUSH #0
 0748	     0000
 074A	     1211	PUSH 8(SP)
 074C	     0008
 074E	     12B0	CALL #0
 0750	     0000
 0752	     5031	ADD #6,SP
 0754	     0006
 0756	     93C2	CMP.B #0,&1864
 0758	     0748
 075A	     2415	JEQ $+44, goes to  0786
 075C	     411F	MOV 4(SP),R15
 075E	     0004
 0760	     93CF	CMP.B #0,16(R15)
 0762	     0010
 0764	     2405	JEQ $+12, goes to  0770
 0766	     8292	SUB &0,&1860
 0768	     0000
 076A	     0744
 076C	     7382	SUBC #0,&74
 076E	     004A
 0770	     4292	MOV &1834,&1836
 0772	     072A
 0774	     072C
 0776	     4292	MOV &1840,&1842
 0778	     0730
 077A	     0732
 077C	     5292	ADD &1896,&1908
 077E	     0768
 0780	     0774
 0782	     6382	ADDC #0,&1914
 0784	     077A
 0786	     4130	RET
 0788	     411F	MOV 8(SP),R15
 078A	     0008
 078C	     121F	PUSH 2(R15)
 078E	     0002
 0790	     411F	MOV 10(SP),R15
 0792	     000A
 0794	     122F	PUSH @R15
 0796	     1211	PUSH 12(SP)
 0798	     000C
 079A	     1211	PUSH 12(SP)
 079C	     000C
 079E	     1211	PUSH 12(SP)
 07A0	     000C
 07A2	     12B0	CALL #0
 07A4	     0000
 07A6	     5031	ADD #10,SP
 07A8	     000A
 07AA	     4130	RET
 07AC	     8031	SUB #22,SP
 07AE	     0016
 07B0	     1230	PUSH #1898
 07B2	     076A
 07B4	     410F	MOV SP,R15
 07B6	     532F	ADD #2,R15
 07B8	     120F	PUSH R15
 07BA	     12B0	CALL #1674
 07BC	     068A
 07BE	     5221	ADD #4,SP
 07C0	     4191	MOV 8(SP),20(SP)
 07C2	     0008
 07C4	     0014
 07C6	     5391	ADD #1,8(SP)
 07C8	     0008
 07CA	     1201	PUSH SP
 07CC	     1211	PUSH 28(SP)
 07CE	     001C
 07D0	     12B0	CALL #1854
 07D2	     073E
 07D4	     5221	ADD #4,SP
 07D6	     1211	PUSH 26(SP)
 07D8	     001A
 07DA	     410F	MOV SP,R15
 07DC	     503F	ADD #20,R15
 07DE	     0014
 07E0	     120F	PUSH R15
 07E2	     1211	PUSH 30(SP)
 07E4	     001E
 07E6	     12B0	CALL #1872
 07E8	     0750
 07EA	     5031	ADD #6,SP
 07EC	     0006
 07EE	     4292	MOV &1906,&1920
 07F0	     0772
 07F2	     0780
 07F4	     4292	MOV &1912,&1924
 07F6	     0778
 07F8	     0784
 07FA	     43C2	MOV.B #0,&1880
 07FC	     0758
 07FE	     9291	CMP &1812,20(SP)
 0800	     0714
 0802	     0014
 0804	     200A	JNE $+22, goes to  081A
 0806	     93C2	CMP.B #0,&2044
 0808	     07FC
 080A	     2007	JNE $+16, goes to  081A
 080C	     5292	ADD &1918,&2034
 080E	     077E
 0810	     07F2
 0812	     6382	ADDC #0,&2040
 0814	     07F8
 0816	     43D2	MOV.B #1,&2056
 0818	     0808
 081A	     5031	ADD #22,SP
 081C	     0016
 081E	     4130	RET
 0820	     4034	MOV #2064,R4
 0822	     0810
 0824	     12B0	CALL #0
 0826	     0000
 0828	     4034	MOV #1970,R4
 082A	     07B2
 082C	     12B0	CALL #2086
 082E	     0826
 0830	     4130	RET
