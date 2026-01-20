MODULE sDiary;
  IMPORT SYSTEM, FB := preserveMSPFlash, M := msp430g2553, MP := MultiPrecisionArith, String, PT := PosixTime,
    ST := sDiaryTypes, LCD := pcd8544, Delay := msp430delay;

  CONST NB_DIARY_SLOTS = 10*8;
    NB_MAX_SIMULTANEOUS_EVENTS = 5; NB_EVTAB_ELTS = 7;

    (*calibration parameters for watch crystal*)
    DEFAULT_BASE_FREQ = 32766; DEFAULT_EXTRA_CYCLES = 5; DEFAULT_TRIM_PERIOD = 11;
    EXTRA_CYCLES = SYSTEM.VAL(PBYTE, 1080H); TRIM_PERIOD = SYSTEM.VAL(PBYTE, 1081H);
    BASE_FREQ = SYSTEM.VAL(PINTEGER, 1082H);

    flashDE = SYSTEM.VAL(ST.DE, 0C400H); (*the DE table stored in Flash memory*)
    LAST_FLASH_SEGMENT = SYSTEM.VAL(PINTEGER, SYSTEM.VAL(INTEGER, flashDE) + NB_DIARY_SLOTS*64);

    PROMPT = "" + 0DX + "=>";
    BAD = "=>KO";
    DEVICE_IDENTITY = "sDiary|B4";

    RELATIVE_EVENT = {7}; (*a relative event must be adjusted when system time is set*)
    NO_EVENT = {}; VCC_MEASURE_EVENT = {0} + RELATIVE_EVENT; DIARY_EVENT = {1};
    DST_EVENT = {2}; LIGHT_OFF_EVENT = {3} + RELATIVE_EVENT; LCD_POWER_OFF_EVENT = {4} + RELATIVE_EVENT;
    BEEP_OFF_EVENT = {5} + RELATIVE_EVENT; CLEAR_LCD_EVENT = {6} + RELATIVE_EVENT;

    CM_INIT = 0; (*CM_LIGHT = 1; *)CM_RAW = 2; CM_SECOND_DIGIT = 3; CM_DISPLAY_CHAR = 4;
    CM_SET_DATETIME = 5; (*CM_SOUND = 6; *)CM_DELETE_EVENT = 7; CM_CREATE_EVENT = 8;
    CM_OVERFLOW_ERROR = 9;

    NCE = {1}; (*P2*) DC = {0}; (*P2*) NRST = {2}; (*P2*) NLIGHT = {0}; (*P1*)

  TYPE
    DEs = RECORD
      events: ARRAY NB_MAX_SIMULTANEOUS_EVENTS OF ST.DE;
      nbSimultaneousEvents: BYTE
    END;

    (*event structure*)
    EVT = POINTER TO EVTDesc;
    EVTDesc = RECORD
      ety: BYTESET; (*event type*)
      eti: PT.TimeDesc (*time of event triggering*)
    END;

    DAY_OF_WEEK = ARRAY 7, 4 OF CHAR;

  VAR ramDE: ST.DEDesc; (*DE structure in RAM for temporary purposes*)
    currentDE: DEs; evTab: ARRAY NB_EVTAB_ELTS OF EVTDesc; dayOfWeek: DAY_OF_WEEK-;
    old_day, nextEventTime: PT.TimeDesc; nextEventType: BYTESET;
    vcc, beepOn: INTEGER;
    extraCycles, trimPeriod: BYTE; baseFreq: INTEGER;

    (*global variables for parseCommand procedure*)
    state, DEIndex: INTEGER; setTime: PT.TmDesc; oldSetTime: PT.TimeDesc;
    cOrD: SET; countData (*count character of string sent by host*), hexData: INTEGER;
    pdata: PBYTE;

    (*global variables for nextSecond procedure*)
    trimmer: INTEGER;

    (*for interrupt handlers*)
    BPReq, ADCReq, NSReq: BOOLEAN; RcdChar: INTEGER;

  PROCEDURE select;
  BEGIN BIC(M.P2OUT^, NCE)
  END select;

  PROCEDURE deselect;
  BEGIN BIS(M.P2OUT^, NCE)
  END deselect;

  PROCEDURE setData;
  BEGIN BIS(M.P2OUT^, DC)
  END setData;

  PROCEDURE setCommand;
  BEGIN BIC(M.P2OUT^, DC)
  END setCommand;

  PROCEDURE send(d: BYTE* );
  BEGIN
    REPEAT UNTIL BIT(M.IFG2^, M.UCB0TXIFG); (*Wait for USCI availability*)
    M.UCB0TXBUF^ := ORD(d); (*USCI B is ready, send character*)
    REPEAT UNTIL ~BIT(M.UCB0STAT^, M.UCBUSY); (*Wait for end of transmission*)
  END send;

  PROCEDURE nbFreeSlots(): INTEGER;
    VAR ds, i, fs: INTEGER*; cde!: ST.DE*; (*the current diary event*)
      fbot: BYTE*;
  BEGIN fs := 0; ds := 0; (*number of free and deleted slots*)
    i := NB_DIARY_SLOTS - 1; cde := flashDE;
    REPEAT fbot := cde.titre[0];
      IF fbot = 0FFH THEN INC(fs) ELSIF fbot = 0 THEN INC(ds) END;
      INC(SYSTEM.VAL(INTEGER, cde), SYSTEM.SIZE(ST.DEDesc)); (*move cde to next slot*)
      DEC(i)
    UNTIL i < 0;
    IF fs # 0 THEN INC(ds, fs) (*directly usable slots are available*)
    ELSE NEG(ds) (*packing is required to free the deleted slots*)
    END

    RETURN ds
  END nbFreeSlots;

  PROCEDURE respondC(c: CHAR*);
  BEGIN REPEAT UNTIL BIT(M.IFG2^, M.UCA0TXIFG); (*USCI_A0 TX buffer ready*)
    M.UCA0TXBUF^ := ORD(c); (*TX -> character*)
  END  respondC;

  PROCEDURE respondS(pMsg: PBYTE);
  BEGIN WHILE pMsg^ # 0 DO respondC(CHR(pMsg^)); INC(SYSTEM.VAL(INTEGER, pMsg)) END
  END respondS;

  PROCEDURE respondBAD;
  BEGIN respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR(BAD)))
  END respondBAD;

  PROCEDURE appendDigit(VAR dest: INTEGER; c: CHAR);
    (*add digit to the number dest*)
  BEGIN
    IF (c >= "0") & (c <= "9") THEN dest := dest*10 + ORD(c) - ORD("0")
    ELSE respondBAD
    END
  END appendDigit;

  PROCEDURE appendHexDigit(c: INTEGER);
  BEGIN
    IF (c >= ORD("0")) & (c < ORD("9") + 1) THEN INC(hexData, c - ORD("0"))
    ELSIF (c >= ORD("a")) & (c < ORD("f") + 1) THEN INC(hexData, c-(ORD("a") - 10))
    ELSE respondBAD
    END
  END appendHexDigit;

  PROCEDURE scheduleNextEvent;
    VAR i, cmp: INTEGER; evt!: EVT;
  BEGIN PT.setMax(PTR(PT.Time, nextEventTime));
    nextEventType := NO_EVENT;

    (*parse event tab to find the nearest event*)
    i := NB_EVTAB_ELTS - 1; evt := PTR(EVT, evTab[0]);
    REPEAT cmp := PT.cmp(PTR(PT.Time, evt.eti), PTR(PT.Time, nextEventTime)); (*check current element*)
      IF cmp < 0 THEN
        nextEventType := evt.ety; (*unschedule previous envents*)
        nextEventTime := evt.eti (*record new next event time*)
      ELSIF cmp = 0 THEN
        (*two or more events are scheduled for the same time,
           schedule the event but don't unschedule the others*)
        BIS(nextEventType, evt.ety)
      END;
      INC(SYSTEM.VAL(INTEGER, evt), SYSTEM.SIZE(EVTDesc));
      DEC(i)
    UNTIL i < 0;
  END scheduleNextEvent;

  PROCEDURE adjustEvents(offset: PT.Time); (*add offset to event times*)
    VAR i: INTEGER; evt!: EVT;
  BEGIN i := NB_EVTAB_ELTS-1; evt := PTR(EVT, evTab[0]);
    REPEAT (*Check current element*)
      IF BIT(evt.ety, RELATIVE_EVENT) & (PT.cmp(PTR(PT.Time, evt.eti), PTR(PT.Time, PT.TimeMax)) # 0) THEN
        PT.inc(PTR(PT.Time, evt.eti), offset); (*the event is subject to offset*)
      END;
      INC(SYSTEM.VAL(INTEGER, evt), SYSTEM.SIZE(EVTDesc));
      DEC(i)
    UNTIL i < 0
  END adjustEvents;

  PROCEDURE rearmEvent(eventType: BYTESET; newTime: PT.Time);
    VAR i: INTEGER; evt!: EVT;
  BEGIN i := NB_EVTAB_ELTS - 1; evt := PTR(EVT, evTab[0]);
    REPEAT (*check current element*)
      IF evt.ety = eventType THEN evt.eti := newTime^ END; (*set new scheduled time*)
      INC(SYSTEM.VAL(INTEGER, evt), SYSTEM.SIZE(EVTDesc));
      DEC(i)
    UNTIL i < 0
  END rearmEvent;

  PROCEDURE getEventTime(eventType: BYTESET): PT.Time;
    VAR i: INTEGER; evt!: EVT; res!: PT.Time;
  BEGIN i := NB_EVTAB_ELTS - 1; evt := PTR(EVT, evTab[0]); res := NIL;
    REPEAT
      IF evt.ety = eventType THEN res := PTR(PT.Time, evt.eti) END;
      INC(SYSTEM.VAL(INTEGER, evt), SYSTEM.SIZE(EVTDesc));
      DEC(i)
    UNTIL (i < 0) OR (res # NIL);
    IF res = NIL THEN res := PTR(PT.Time, PT.TimeMax) END

     RETURN res
  END getEventTime;

  PROCEDURE nextCompatibleDate(cron: ARRAY OF BYTE; nextDETime, nextTime: PT.Time);
    VAR lt: PT.TmDesc; (*the local time*) previousTime: PT.TimeDesc; done: BOOLEAN;
  BEGIN PT.setMin(nextTime);
    IF ~BIT(cron[5], {0..6}) THEN PT.setMax(nextTime) (*If no available week day, return the last possible date*)
    ELSE PT.localtime(nextDETime, PTR(PT.Tm, lt)); (*find local time*)
      (*fix imposed values*)
      lt.sec := 0; (*seconds are always zero*)
      IF cron[0] # 0FFH THEN lt.min := cron[0] END;
      IF cron[1] # 0FFH THEN lt.hour := cron[1]END;
      IF cron[2] # 0FFH THEN lt.mday := cron[2] END; (*day of month*)
      IF cron[3] # 0FFH THEN lt.mon := cron[3] END;
      IF cron[4] # 0FFH THEN lt.year := cron[4]+70 END; (*in my own cron table structure, year is relative to 1970*)

      previousTime := nextTime^; PT.dec(PTR(PT.Time, previousTime), PTR(PT.Time, PT.OneSec)); done := FALSE;
      REPEAT PT.mktime(PTR(PT.Tm, lt), nextTime); (*compute next time*)
        IF PT.cmp(nextTime, PTR(PT.Time, previousTime)) = 0 THEN (*we are stalled*) nextTime^ := PT.TimeMax; done := TRUE
        ELSE previousTime := nextTime^;
          (*check if date is compatible with cron tab pattern*)
          IF (cron[0] # 0FFH) & (cron[0] # lt.min) OR
            (cron[1] # 0FFH) & (cron[1] # lt.hour) OR
            (cron[2] # 0FFH) & (cron[2] # lt.mday) OR
            (cron[3] # 0FFH) & (cron[3] # lt.mon) OR
            (cron[4] # 0FFH) & (cron[4]+70 # lt.year) THEN (*no future compatible date: return max ulong value*)
            nextTime^ := PT.TimeMax; done := TRUE
          ELSE (*check if day of week is compatible with cron table pattern and candidate date is in future*)
            IF (lt.wday IN TOSET(cron[5])) & (PT.cmp(nextTime, nextDETime) > 0) THEN done := TRUE
            ELSE (*try a time*)
              IF cron[0] = 0FFH THEN (*every minute is allowed : try next minute*) INC(lt.min)
              ELSIF cron[1] = 0FFH THEN (*every hour is allowed : try next hour*) INC(lt.hour)
              ELSIF cron[2] = 0FFH THEN (*every month day is allowed : try next month day*) INC(lt.mday)
              ELSIF cron[3] = 0FFH THEN (*every month is allowed : try next month*) INC(lt.mon)
              ELSIF cron[4] = 0FFH THEN (*every year is allowed : try next year*) INC(lt.year)
              ELSE (*fixed date in the past, return the last possible date*) nextTime^ := PT.TimeMax; done := TRUE
              END
            END
          END
        END
      UNTIL done
    END
  END nextCompatibleDate;

  PROCEDURE updateBell;
    (*display a bell if a new diary event is scheduled*)
    VAR x, y: BYTE;
  BEGIN
    IF PT.cmp(getEventTime(DIARY_EVENT), PTR(PT.Time, PT.TimeMax)) # 0 THEN
      LCD.GetAddr(x, y); LCD.SetAddr(6*13, 0);
      LCD.WriteChar(88X); LCD.WriteChar(" "); (*display a bell*)
      LCD.SetAddr(x, y)
    END
  END updateBell;

  PROCEDURE popEvent;
    (*remove event[0] from currentDE*)
    VAR i: INTEGER*;
  BEGIN
    IF currentDE.nbSimultaneousEvents > 0 THEN
      FOR i := 1 TO currentDE.nbSimultaneousEvents - 1 DO currentDE.events[i-1] := currentDE.events[i] END;
      DEC(currentDE.nbSimultaneousEvents)
    END
  END popEvent;

  PROCEDURE findNextDiaryEvent(populate: BOOLEAN; nearestDE: PT.Time);
  (**
   * 1/ Find the current diary events and if asked so, populate currentDE accordingly
   * 2/ Find the time of the next Diary event
   * *)
  VAR ncd, net: PT.TimeDesc; i: INTEGER; cde!: ST.DE;
    fbot: BYTE; (*the first byte of the title*)
  BEGIN nearestDE^ := PT.TimeMax;
    i := NB_DIARY_SLOTS - 1; cde := flashDE;
    PT.setMin(PTR(PT.Time, net));
    IF PT.cmp(PTR(PT.Time, net), PTR(PT.Time, nextEventTime)) # 0 THEN
      net := nextEventTime; PT.dec(PTR(PT.Time, net), PTR(PT.Time, PT.OneSec))
    END;
    REPEAT fbot := cde.titre[0];
      IF (fbot # 0FFH) & (fbot # 0) THEN
        nextCompatibleDate(cde.cron, PTR(PT.Time, net), PTR(PT.Time, ncd)); (*find the current diary events and populate currentDE accordingly*)
        IF populate & (PT.cmp(PTR(PT.Time, ncd), PTR(PT.Time, nextEventTime)) = 0) THEN (*a new current date event has been found*)
          (*store it afer making room if necessary*)
          IF currentDE.nbSimultaneousEvents >= NB_MAX_SIMULTANEOUS_EVENTS THEN popEvent END;
          currentDE.events[currentDE.nbSimultaneousEvents] := cde; INC(currentDE.nbSimultaneousEvents)
        END;
        nextCompatibleDate(cde.cron, PTR(PT.Time, PT.systemTime), PTR(PT.Time, ncd)); (*find the time of the next Diary event*)
        IF PT.cmp(PTR(PT.Time, ncd), nearestDE) < 0 THEN nearestDE^ := ncd END
      END;
      INC(SYSTEM.VAL(INTEGER, cde), SYSTEM.SIZE(ST.DEDesc));
      DEC(i)
    UNTIL i < 0
  END findNextDiaryEvent;

  PROCEDURE findAndArmNextDiaryEvent(populate: BOOLEAN);
  (*find next diary event and arm it*)
    VAR de: PT.TimeDesc;
  BEGIN findNextDiaryEvent(populate, PTR(PT.Time, de)); rearmEvent(DIARY_EVENT, PTR(PT.Time, de)); updateBell()
  END findAndArmNextDiaryEvent;

  PROCEDURE eraseAllDiaryEvents;
    VAR seg!: PINTEGER;
  BEGIN seg := SYSTEM.VAL(PINTEGER, flashDE);
    M.FCTL3^ := M.FWKEY; (*clear lock*)
    WHILE seg # LAST_FLASH_SEGMENT DO
      (*erase flash segment*)
      M.FCTL1^ := M.FWKEY + M.ERASE; (*nable segment erase*)
      seg^ := 0; (*dummy write to erase segment*)
      INC(SYSTEM.VAL(INTEGER, seg), 512)
    END;
    M.FCTL3^ := M.FWKEY + M.LOCK; (*Set lock*)
    rearmEvent(DIARY_EVENT, PTR(PT.Time, PT.TimeMax)); (*disable next DIARY EVENT*)
    scheduleNextEvent(); (*reschedule next event*)
  END eraseAllDiaryEvents;

  PROCEDURE deleteDiaryEvent(index: INTEGER);
  VAR i,j: INTEGER; ev!: ST.DE;
  BEGIN
    IF index < NB_DIARY_SLOTS THEN (*index in bounds*)
      ev := flashDE; INC(SYSTEM.VAL(INTEGER, ev), index*SYSTEM.SIZE(ST.DEDesc));
      IF (ev.titre[0] # 0FFH) & (ev.titre[0] # 0) THEN (*slot contains an active event*)
        (*mark slot as deleted*)
        M.FCTL3^ := M.FWKEY; (*clear lock*)
        M.FCTL1^ := M.FWKEY + M.WRT; (*enable write*)
        ev.titre[0] := 0; (*write 0 in first bye of slot*)
        M.FCTL1^ := M.FWKEY; (*lear WRT*)
        M.FCTL3^ := M.FWKEY + M.LOCK; (*set lock*)
        i := 0; (*check if the deleted event was in next events list*)
        FOR j := 0 TO currentDE.nbSimultaneousEvents - 1 DO
          currentDE.events[i] := currentDE.events[j];
          IF ev = currentDE.events[j] THEN (*it was, so remove it from list*) DEC(currentDE.nbSimultaneousEvents)
          ELSE INC(i)
          END
        END
      END
    END
  END deleteDiaryEvent;

  PROCEDURE createDiaryEvent(): INTEGER;
  (*store in flash an event found in the structure ramDE
    return the index of the event if success, or a negative value in case of error*)
    VAR res, i: INTEGER; cde!: ST.DE;
  BEGIN res := -1; i := 0; cde := flashDE;
    REPEAT
      IF cde.titre[0] = 0FFH THEN (*this slot is free*)
        FB.flashBlock(SYSTEM.VAL(PINTEGER, PTR(ST.DE, ramDE)), SYSTEM.VAL(PINTEGER, cde), 64);
        findAndArmNextDiaryEvent(FALSE); (*arm next diary event, but don't populate currentDE structure*)
        scheduleNextEvent; res := i
      END;
      INC(SYSTEM.VAL(INTEGER, cde), SYSTEM.SIZE(ST.DEDesc));
      INC(i)
    UNTIL (i >= NB_DIARY_SLOTS) OR (res # -1)

    RETURN res
  END  createDiaryEvent;

  PROCEDURE prompt; (*display prompt*)
  BEGIN respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR(PROMPT)))
  END prompt;

  PROCEDURE respondL(th, tl: INTEGER);
    VAR msg: ARRAY 12 OF CHAR;
  BEGIN String.FromLong(th, tl, 1, 1, msg); respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR(msg)))
  END respondL;

  PROCEDURE respondI(t: INTEGER);
    VAR th: INTEGER;
  BEGIN th := 0; IF t < 0 THEN th := -1 END; respondL(th, t)
  END respondI;

  PROCEDURE respondT(t: PT.Time);
    VAR msg: ARRAY 12 OF CHAR;
  BEGIN PT.TimeToString(t, 1, 1, msg); respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR(msg)));
  END respondT;

  PROCEDURE sendEvents;
  (*send events stored in flash to host*)
    VAR i,j : INTEGER; cde!: ST.DE; fbot: BYTE; (*the first byte of the title*)
      cb!: PBYTE;
  BEGIN i := 0; cde := flashDE;
    REPEAT fbot := cde.titre[0];
      IF (fbot # 0FFH) & (fbot # 0) THEN (*the slot contains a valid event*)
        respondI(i); (*send the index on current slot*) respondC("|");
        cb := PTR(PBYTE, cde.titre[0]);
        j := 63; REPEAT respondC(CHR(cb^)); INC(SYSTEM.VAL(INTEGER, cb)); DEC(j); UNTIL j < 0; (*send 64 bytes*)
        respondC("|")
      END;
      INC(SYSTEM.VAL(INTEGER, cde), SYSTEM.SIZE(ST.DEDesc));
      INC(i)
    UNTIL i >= NB_DIARY_SLOTS;
  END sendEvents;

  PROCEDURE doCommand;
  (* Parse commands sent by UART interface
      Each command start with a letter, following by arguments and terminated by a carriage return
      List of available commands
      a.* : display characters on LCD. Example aHello World ! displays
            this classical sentence to the LCD screen. Must be terminated by a \r.
      b[{C|D|<double hex digit>]* : send raw data to LCD. Must be terminated by a \r.
            C indicates that the following is a command
            D indicates that the following is data
            <double hex digit> is the command or data to send
      dDDMMYYYYHHMISS : set local date and time. Must be terminated by a \r.
      uDDMMYYYYHHMISS : set UTC date and time. Must be terminated by a \r.
      v : reinit display.
      w : sent the scheduled event info to host.
      i : get information from sDiary configuration and state.
      e : send the Diary events to host.
      z : erase all Diary Event in flash memory.
      r<event index> : delete an event identified by a given index. Must be terminated by a \r.
      c<64 bytes> : create a new event initialized with the 64 bytes given.
                    Returns the index number of the created event. Must be terminated by a \r.
      @ : activate bootloader

      Commands only available in extended command mode:
      s{0|1}* : Sound off | on. Example: s0 turns sound off. Must be terminated by a \r.
      l{0|1}* : LCD Light off | on. Example: l0 turns LCD light off. Must be terminated by a \r.
  *)
  VAR c: INTEGER;
  BEGIN BIC(RcdChar, {9}); c := RcdChar; BIS(M.IE2^, M.UCA0RXIE);
    IF BIT(c, {8}) THEN (*set overflow error*) state := CM_OVERFLOW_ERROR; respondBAD
    ELSIF (c = 0DH) OR (countData = 0) THEN
      IF (c # 0DH) OR (countData >= 1) THEN respondBAD
      ELSIF state = CM_CREATE_EVENT THEN DEIndex := createDiaryEvent(); respondI(DEIndex)
      ELSIF state = CM_SET_DATETIME THEN
        DEC(setTime.mon); (*TM struct need month between 0 and 11*)
        DEC(setTime.year, 1900); (*TM struct count year from 1900*)
        (*adjust relative events: step 1*)
        oldSetTime.h := 0; oldSetTime.l := 0; PT.dec(PTR(PT.Time, oldSetTime), PTR(PT.Time, PT.systemTime));
        adjustEvents(PTR(PT.Time, oldSetTime));
        PT.settime(PTR(PT.Tm, setTime), PTR(PT.Time, oldSetTime));
        rearmEvent(DST_EVENT, PTR(PT.Time, oldSetTime)); (*setting time and arm DST change trigger*)
        oldSetTime := PT.systemTime; PT.setMax(PTR(PT.Time, old_day));
        findAndArmNextDiaryEvent(FALSE); (*setting time and arm next calendar event trigger, don't populate currentDE*)
        currentDE.nbSimultaneousEvents := 0; (*clear currentDE list*)
        (*Adjust relative events: step 2*)
        adjustEvents(PTR(PT.Time, PT.systemTime));
        scheduleNextEvent
      ELSIF state = CM_SECOND_DIGIT THEN respondBAD
      ELSIF state = CM_DELETE_EVENT THEN deleteDiaryEvent(DEIndex)
      END;
      state := CM_INIT; prompt; countData := -1
    ELSIF state = CM_CREATE_EVENT THEN pdata^ := c; INC(SYSTEM.VAL(INTEGER, pdata)); DEC(countData)
    ELSIF state = CM_INIT THEN
      IF c = ORD("a") THEN state := CM_DISPLAY_CHAR
      ELSIF c = ORD("b") THEN state := CM_RAW
      ELSIF c = ORD("c") THEN state := CM_CREATE_EVENT; pdata :=  SYSTEM.VAL(PBYTE, SYSTEM.ADR(ramDE)); countData := 64
      ELSIF (c = ORD("d")) OR (c = ORD("u")) THEN state := CM_SET_DATETIME;
        setTime.isdst := c = ORD("d"); (*time expressed in local(d) or UTC(u) time*)
        setTime.mday := 0; setTime.mon := 0; setTime.year := 0; setTime.hour := 0; setTime.min := 0; setTime.sec := 0;
        countData := 14
      ELSIF c = ORD("e") THEN sendEvents; prompt
      ELSIF c = ORD("i") THEN (*send information about configuration and state to host*)
        respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR(DEVICE_IDENTITY)));
        respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|t="))); respondT(PTR(PT.Time, PT.systemTime));
        respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|sf="))); respondI(nbFreeSlots()); (*send total number of free slots*)
        respondC("/"); respondI(NB_DIARY_SLOTS); (*end total number of slots*)
        respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|v="))); respondI(vcc); respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("mV")));
        respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|Vop="))); respondI(LCD.Vop);
        respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|Bell="))); respondI(ORD(PT.cmp(getEventTime(DIARY_EVENT), PTR(PT.Time, PT.TimeMax))));
        respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|st="))); respondT(PTR(PT.Time, oldSetTime));
        respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|bf="))); respondL(0,baseFreq);
        respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|ec="))); respondI(extraCycles);
        respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|tp="))); respondI(trimPeriod);
        prompt
(*#ifdef EXTENDED_COMMANDS
		case 'l':
			state = CM_LIGHT;
			break;
		case 's':
			state = CM_SOUND;
			break;
#endif*)
      ELSIF c = ORD("r") THEN state := CM_DELETE_EVENT; DEIndex := 0; (*Diary event Index initialization*)
      ELSIF c = ORD("v") THEN BIC(M.P2OUT^, NRST); (*~RESET going LOW*)
        Delay.CyclesX3(10000 DIV 3); BIS(M.P2OUT^, NRST); (*~RESET going HIGH*)
        LCD.Clear; LCD.Init;
      ELSIF c = ORD("w") THEN respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("type="))); respondI(ORD(nextEventType));
        respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR(", time="))); respondT(PTR(PT.Time, nextEventTime));
        prompt
      ELSIF c = ORD("z") THEN eraseAllDiaryEvents; prompt
      ELSIF c = ORD("@") THEN (*restart in boot loader mode*) M.WDTCTL^ := {}
      ELSE respondBAD
      END
    ELSIF state = CM_RAW THEN respondC(CHR(c));
      IF c = ORD("C") THEN cOrD := {} (*command*)
      ELSIF c = ORD("D") THEN cOrD := {8}; (*data*)
      ELSE hexData := 0; appendHexDigit(c); state := CM_SECOND_DIGIT
      END
    ELSIF state = CM_SECOND_DIGIT THEN respondC(CHR(c)); RLA(hexData, 4); appendHexDigit(c);
      (*the data is built, send it to LCD with appropriate command or data signal*)
      LCD.send(cOrD + TOSET(hexData)); state := CM_RAW
    ELSIF state = CM_DISPLAY_CHAR THEN LCD.WriteChar(CHR(c))
    ELSIF state = CM_DELETE_EVENT THEN appendDigit(DEIndex, CHR(c))
    ELSIF state = CM_SET_DATETIME THEN
      IF countData >= 13 THEN (*day of month expected*) appendDigit(setTime.mday, CHR(c))
      ELSIF countData >= 11 THEN (*month expected*) appendDigit(setTime.mon, CHR(c))
      ELSIF countData >= 7 THEN appendDigit(setTime.year, CHR(c))
      ELSIF countData >= 5 THEN (*hour (0, 23) expected*) appendDigit(setTime.hour, CHR(c))
      ELSIF countData >= 3 THEN (*minutes (0, 59) expected*) appendDigit(setTime.min, CHR(c))
      ELSIF countData >= 1 THEN (*seconds (0, 59) expected*) appendDigit(setTime.sec, CHR(c))
      END; DEC(countData)
(*#ifdef EXTENDED_COMMANDS
	case CM_SOUND:
		respondC(c);
		switch (c) {
		case '0':
			BEEP_OFF
			break;
		case '1':
			BEEP_ON
			break;
		default:
			respondBAD;
		}
		break;
		case CM_LIGHT:
			respondC(c);
			switch (c) {
			case '0':
				LIGHT_OFF
				break;
			case '1':
				LIGHT_ON
				break;
			default:
				respondBAD;
			}
			break;
#endif*)
    END
  END doCommand;

  PROCEDURE parseCommand;
  BEGIN WHILE BIT(RcdChar, {9}) DO doCommand END
  END parseCommand;

  PROCEDURE setVcc;
    VAR x, y: BYTE;
  BEGIN LCD.GetAddr(x, y); LCD.SetAddr(0, 0);
    IF vcc >= 2750 THEN (*battery full*) LCD.WriteChar(87X)
    ELSIF vcc >= 2500 THEN (*battery half charged*) LCD.WriteChar(86X)
    ELSE (*battery low*) LCD.WriteChar(85X)
    END;
    LCD.WriteChar(" ");
    LCD.SetAddr(x, y)
  END setVcc;

  PROCEDURE displayTime;
    VAR x, y: BYTE; ltime: PT.TimeDesc; tm: PT.TmDesc;
  BEGIN (*conversion du temps*)
    ltime := PT.systemTime; PT.inc(PTR(PT.Time, ltime), PTR(PT.Time, PT.timeOffset));
    PT.gmhms(PTR(PT.Time, ltime), PTR(PT.Tm, tm));
    LCD.GetAddr(x, y);
    LCD.WriteLongint(0, tm.hour, 3, 0, 1, 2); LCD.WriteChar(":");
    LCD.WriteLongint(0, tm.min, 6, 0, 2, 2); LCD.WriteChar(":");
    LCD.WriteLongint(0, tm.sec, 9, 0, 2, 2); setVcc;
    IF PT.cmp(PTR(PT.Time, old_day), PTR(PT.Time, ltime)) # 0 THEN
      (*do the following only if day has changed, to save few micro amps.*)
      old_day := ltime; PT.localtime(PTR(PT.Time, PT.systemTime), PTR(PT.Tm, tm)); LCD.SetAddr(0, 1);
      LCD.WriteString(dayOfWeek[tm.wday]);
      LCD.WriteLongint(0, tm.mday, 4, 1, 1, 2); LCD.WriteChar("/");
      LCD.WriteLongint(0, tm.mon+1, 7, 1, 2, 2); LCD.WriteChar("/");
      LCD.WriteLongint(0, tm.year+1900, 10, 1, 1, 4)
    END;
    LCD.SetAddr(x, y)
  END displayTime;

  PROCEDURE displayEvent(nextDiaryEventTime: PT.Time);
  (*
   * display the Diary Event message and perform the specified scheduling
   *   nextDiaryEventTime : time of next diary event
   *)
  VAR len: INTEGER; x, y: BYTE; pMsg!: PBYTE; cle!: PT.Time; eoe: PT.TimeDesc;
  BEGIN  pMsg := PTR(PBYTE, currentDE.events[0].titre[0]);
    (*clear LCD screen*)
    LCD.GetAddr(x,  y); LCD.SetAddr(6*12, 0);
    IF PT.cmp(nextDiaryEventTime, PTR(PT.Time, PT.TimeMax)) = 0 THEN
      len := 0; LCD.WriteChar(" ")
    ELSE len := ST.TITLE_LEN;
      (*update the schedule if the next diary event time is nearest than the currently scheduled one*)
      IF PT.cmp(getEventTime(DIARY_EVENT), nextDiaryEventTime) > 0 THEN rearmEvent(DIARY_EVENT, nextDiaryEventTime) END;
      LCD.WriteChar(CHR(currentDE.nbSimultaneousEvents + ORD("0")))
    END;
    LCD.SetAddr(0, 2); REPEAT LCD.WriteChar(CHR(pMsg^)); INC(SYSTEM.VAL(INTEGER, pMsg)); DEC(len) UNTIL len < 0;
    WHILE (LCD.XAddr # 0) & (LCD.YAddr # 0) DO (*wipe screen from here to beginning of line 0*)
      LCD.WriteChar(" ")
    END;
    LCD.SetAddr(x, y);
    (*CLEAR_LCD_EVENT must not be rearmed if it is already armed*)
    cle := getEventTime(CLEAR_LCD_EVENT); eoe := PT.systemTime; INC(eoe.l, PT.SECS_IN_MIN*currentDE.events[0].clearingDelay); ADC(eoe.h, 0);
    IF (PT.cmp(cle, PTR(PT.Time, PT.systemTime)) <= 0) OR (PT.cmp(cle,  PTR(PT.Time, eoe)) > 0) THEN
      IF PT.cmp(nextDiaryEventTime, PTR(PT.Time, PT.TimeMax)) # 0 THEN rearmEvent(CLEAR_LCD_EVENT, PTR(PT.Time, eoe))
      ELSE (*if no diary event armed, CLEAR_LCD_EVENT must be unarmed*) rearmEvent(CLEAR_LCD_EVENT, nextDiaryEventTime)
      END
    END
  END displayEvent;

  PROCEDURE nextSecond;
  BEGIN INC(M.TA0CCR0^, baseFreq); (*prochaine interruption dans une seconde*)
    IF beepOn > 0 THEN M.TA0CCR1^ := M.TA0CCR0^ - beepOn END; (*beepOn : duree du beep en 32768 emes de secondes*)
    IF trimmer = 0 THEN INC(M.TA0CCR0^, extraCycles) (*add extra cycles*) END;
    INC(trimmer); IF trimmer >= trimPeriod THEN trimmer := 0 END;
    PT.tick (*yes, we are one second older!*)
  END nextSecond;

  PROCEDURE displayEventOneHour;
    VAR t: PT.TimeDesc;
  BEGIN t := PT.systemTime; INC(t.l, 3600); ADC(t.h, 0); displayEvent(PTR(PT.Time, t))
  END displayEventOneHour;

  PROCEDURE rearmVCCSense;
    VAR t: PT.TimeDesc;
  BEGIN  t := PT.systemTime; INC(t.l, 3); ADC(t.h, 0);
    (*measure of tension is more accurate when done 3 seconds after LCD is put on*)
    rearmEvent(VCC_MEASURE_EVENT, PTR(PT.Time, t)); (*schedule VCC measurement in 3s*)
  END rearmVCCSense;

  PROCEDURE rearmBeepOff;
    VAR t: PT.TimeDesc;
  BEGIN  t := PT.systemTime; INC(t.l, 30); ADC(t.h, 0);
    rearmEvent(BEEP_OFF_EVENT, PTR(PT.Time, t));
  END rearmBeepOff;

  PROCEDURE buttonPressed; (*implement action when button is pressed*)
    VAR t: PT.TimeDesc;
  BEGIN rearmVCCSense; t := PT.systemTime;
    IF beepOn > 0 THEN (*stop sound*) beepOn := 0; M.TA0CCTL1^ := M.CM_0 + M.CCIS_0 + M.OUTMOD_0;
      INC(t.l, 30); ADC(t.h, 0);
      rearmEvent(LCD_POWER_OFF_EVENT, PTR(PT.Time, t)); (*stop LCD in 30s*)
    ELSE BIC(M.P1OUT^, NLIGHT); (*Turn Light On*)
      (*we have to power up the LCD if needed.*)
      IF BIT(LCD.FunctionSet, LCD.PD) (*LCD is in powerd down mode*) THEN
        displayTime; (*but before that, refresh display*)
        LCD.send(LCD.FunctionSet - LCD.PD) (* Request Power on*)
      END;
      INC(t.l, 5); ADC(t.h, 0);
      rearmEvent(LIGHT_OFF_EVENT, PTR(PT.Time, t)); (*arm event LIGHT off in 5 seconds*)
      INC(t.l, 295); ADC(t.h, 0);
      rearmEvent(LCD_POWER_OFF_EVENT, PTR(PT.Time, t)); (*power down LCD in 5 minutes*)
    END;
    IF PT.cmp(getEventTime(CLEAR_LCD_EVENT), PTR(PT.Time, PT.TimeMax)) # 0 THEN
      (*the user acknowledged the event, arm trigger for next event*)
      popEvent;
      IF currentDE.nbSimultaneousEvents > 0 THEN (*an event is currently displayed, try to display the next one*)
        displayEventOneHour
      END
    END;
    scheduleNextEvent;
    BPReq := FALSE
  END buttonPressed;

  PROCEDURE computeVcc;
    VAR vcc_h, d_h, d_l: INTEGER;
  BEGIN  
    vcc_h := 0; vcc := M.ADC10MEM^; MP.MulLongLong(vcc_h, vcc, 0, 5000);
    d_h := 0; d_l := 1023; MP.DivLongLong(vcc_h, vcc, d_h, d_l);
    ADCReq := FALSE
  END computeVcc;

  PROCEDURE* (M.PORT1_VECTOR) PORT1_ISR_HOOK;
  (*
   *  ======== PORT1 Interrupt Service Routine ========
   *
   * Here are several important notes on using PORTx interrupt Handler:
   *
   * 1. User must explicitly clear the port interrupt flag before exiting
   *
   *    BIC(M.PxIFG, {y});
   *
   * 2. User could also exit from low power mode and continue with main
   *    program execution by using the following instruction before exiting
   *    this interrupt handler.
   *
   *    SYSTEM.BIC_SR_ON_EXIT(M.LPMx_bits);
   *
   *)
  BEGIN BIC(M.P1IE^, {3}); (*disable button interrupt*)
    (*desactive l'interruption du bouton pendant 2/10emes de seconde pour eviter les rebonds*)
    REPEAT M.TA0CCR2^ := M.TA0R^ UNTIL M.TA0CCR2^ = M.TA0R^; (*prevent async capture*)
    INC(M.TA0CCR2^, 6570); M.TA0CCTL2^ := M.CM_0 + M.CCIS_0 + M.OUTMOD_0 + M.CCIE;
    IF BIT(M.P1IFG^, {3}) & BIT(M.P1IES^, {3}) THEN BPReq := TRUE; SYSTEM.BIC_SR_ON_EXIT(M.LPM4_bits)
    END;
    BIC(M.P1IFG^, {3}) (*reset interrupt flag*)
  END PORT1_ISR_HOOK;

  PROCEDURE* (M.ADC10_VECTOR) ADC10_ISR_HOOK;
  (*
   *  ======== ADC10 Interrupt Service Routine ========
   *)
   VAR vcc_h, d_h, d_l: INTEGER;
  BEGIN BIC(M.ADC10CTL0^, M.ENC); (*disable conversion*)
    BIC(M.ADC10CTL0^, M.REFON + M.ADC10IFG + M.ADC10ON); (*disable ADC reference generator, clear flag, ADC Off*)
    ADCReq := TRUE; SYSTEM.BIC_SR_ON_EXIT(M.LPM4_bits)
  END ADC10_ISR_HOOK;

  PROCEDURE* (M.USCIAB0RX_VECTOR) {4, 5} USCI0RX_ISR_HOOK;
  (*
   *  ======== USCI A0/B0 RX Interrupt Handler Generation ========
   *
   * Here are several important notes on using USCI_A0/B0 RX interrupt Handler:
   * 1. User could use the following code as a template to service the interrupt
   *    handler. Just simply copy and paste it into your user definable code
   *    section.
   *  For UART and SPI configuration:

      IF BIT(M.IFG2^, M.UCA0RXIFG) THEN

      ELSIF BIT(M.IFG2^, M.UCB0RXIFG) THEN

      END

  *  For I2C configuration:
      IF BIT(M.UCB0STAT^, M.UCSTTIFG) THEN

      ELSIF BIT(M.UCB0STAT^, M.UCSTPIFG) THEN

      ELSIF BIT(M.UCB0STAT^, M.UCNACKIFG) THEN

      ELSIF BIT(M.UCB0STAT^, M.UCALIFG) THEN

      END

   * 2. User could also exit from low power mode and continue with main
   *    program execution by using the following instruction before exiting
   *    this interrupt handler.
   *
   *    SYSTEM.BIC_SR_ON_EXIT(M.LPMx_bits);
   *)
  BEGIN
    IF BIT(M.IFG2^, M.UCA0RXIFG) THEN
      BIC(M.IE2^, M.UCA0RXIE); (*disable RX interrupt to synchronize with parseCommand*)
      RcdChar :=  ORD({9}) + ORD(M.UCA0STAT^*M.UCOE)*ORD({8}) + M.UCA0RXBUF^;
      (*exit from low power mode to allow background processing of events in main loop*)
      SYSTEM.BIC_SR_ON_EXIT(M.LPM4_bits)
    END
  END USCI0RX_ISR_HOOK;

  PROCEDURE* (M.TIMER0_A0_VECTOR) TIMER0_A0_ISR_HOOK;
  (*
   *  ======== Timer0_A3 Interrupt Service Routine ======== 
   *)
  BEGIN nextSecond(); NSReq := TRUE;
    SYSTEM.BIC_SR_ON_EXIT(M.LPM4_bits)
  END TIMER0_A0_ISR_HOOK;

  PROCEDURE* (M.TIMER0_A1_VECTOR) {15} TIMER0_A1_ISR_HOOK;
  (*
   *  ======== Timer0_A3 Interrupt Service Routine ======== 
   *)
  BEGIN
    IF M.TA0IV^ = 4 THEN (*debounce button handling press and release events*)
      BIC(M.P1IES^, {3}); BIS(M.P1IES^, M.P1IN^*{3}); BIC(M.P1IFG^, {3});
      BIS(M.P1IE^, {3}); (*enable button interrupt*)
      M.TA0CCTL2^ := M.CM_0 + M.CCIS_0 + M.OUTMOD_0 (*disable interrupt on this compare comunter*) 
    END
  END  TIMER0_A1_ISR_HOOK;

  PROCEDURE doDSTEvent;
    VAR nextDST: PT.TimeDesc;
  BEGIN PT.changedsttime(PTR(PT.Time, nextDST)); rearmEvent(DST_EVENT, PTR(PT.Time, nextDST));
    findAndArmNextDiaryEvent(FALSE); (*don't populate currentEV*)
  END doDSTEvent;

(* Main code *)

BEGIN dayOfWeek[0] := "Dim"; dayOfWeek[1] :="Lun"; dayOfWeek[2] := "Mar"; dayOfWeek[3] := "Mer";
  dayOfWeek[4] := "Jeu"; dayOfWeek[5] := "Ven"; dayOfWeek[6] :=  "Sam";
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD;

  evTab[0].ety := VCC_MEASURE_EVENT; evTab[0].eti.h := 0; evTab[0].eti.l := 1;
  evTab[1].ety := DIARY_EVENT; PT.setMax(PTR(PT.Time, evTab[1].eti));
  evTab[2].ety := DST_EVENT; PT.setMax(PTR(PT.Time, evTab[2].eti));
  evTab[3].ety := LIGHT_OFF_EVENT; PT.setMax(PTR(PT.Time, evTab[3].eti)); (*not scheduled, because back light is off at startup*)
  evTab[4].ety := LCD_POWER_OFF_EVENT; evTab[4].eti.h := 0; evTab[4].eti.l := 301; (*scheduled after 5 minutes*)
  evTab[5].ety := BEEP_OFF_EVENT; PT.setMax(PTR(PT.Time, evTab[5].eti)); (*not scheduled, because sound is off at startup*)
  evTab[6].ety := CLEAR_LCD_EVENT;PT.setMax(PTR(PT.Time, evTab[6].eti)); (*not scheduled, because no event is displayed at startup*)

  (*
   *  ======== Flash_2xx_graceInit ========
   *  Initialize MSP430F2xx Family Flash Module
   *)

  (* nothing to do, the reset values are sufficient for this configuration *)
 
  (*
   *  ======== GPIO_graceInit ========
   *  Initialize MSP430 General Purpose Input Output Ports
   *
   *  The GPIO registers should be set in a specific order:
   *     PxOUT
   *     PxSEL or PxSELx
   *     PxDIR
   *     PxREN
   *     PxIES
   *     PxIFG
   *     PxIE
   *
   *     This will ensure that:
   *         - IFG doesn't get set by manipulating the pin function, edge
   *           select, and pull-up/down resistor functionalities (see
   *           Section 8.2.6 of the MSP430 User's manual)
   *         - Glitch-free setup (configuring the OUT register _before_
   *           setting the pin direction)
   *         - Pull-up/pull-down resistor enable with the correct direction
   *           (.up. vs. .down.)
   *)

  M.P1SEL2^ := {1, 2, 5, 7}; (* Port 1 Port Select 2 Register *)
  M.P1OUT^ := {0, 3, 4}; (** Port 1 Output Register *)
  M.P1SEL^ := {1, 2, 5..7}; (* Port 1 Port Select Register *)
  M.P1DIR^ := {0, 6}; (* Port 1 Direction Register *)
  M.P1REN^ := {3, 4}; (* Port 1 Resistor Enable Register *)
  M.P1IES^ := {3}; (* Port 1 Interrupt Edge Select Register *)
  M.P1IFG^ := {}; (* Port 1 Interrupt Flag Register *)
  M.P1IE^ := {3}; (* Port 1 Interrupt Enable Register *)

  M.P2OUT^ := {1, 3..5}; (* Port 2 Output Register *)
  M.P2DIR^ := {0..2}; (* Port 2 Direction Register *)
  M.P2REN^ := {3..5}; (* Port 2 Resistor Enable Register *)
  M.P2IES^ := {}; (* Port 2 Interrupt Edge Select Register *)
  M.P2IFG^ := {};    (* Port 2 Interrupt Flag Register *)

  M.P3OUT^ := {}; (* Port 3 Output Register *)
  M.P3DIR^ := {}; (* Port 3 Direction Register *)

  (*
   *  ======== BCSplus_graceInit ========
   *  Initialize MSP430 Basic Clock System
   *)

  (* 
   * Basic Clock System Control 2
   * 
   * SELM_0 -- DCOCLK
   * DIVM_0 -- Divide by 1
   * ~SELS -- DCOCLK
   * DIVS_0 -- Divide by 1
   * ~DCOR -- DCO uses internal resistor
   * 
    * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.BCSCTL2^ := M.SELM_0 + M.DIVM_0 + M.DIVS_0;

  IF M.CALBC1_1MHZ^ # {0..7} THEN
    (* Follow recommended flow. First, clear all DCOx and MODx bits. Then
     * apply new RSELx values. Finally, apply new DCOx and MODx bit values.
     *)
    M.DCOCTL^ := {};
    M.BCSCTL1^ := M.CALBC1_1MHZ^; (* Set DCO to 1MHz *)
    M.DCOCTL^ := M.CALDCO_1MHZ^
  END;

  (* 
   * Basic Clock System Control 1
   * 
   * XT2OFF -- Disable XT2CLK
   * ~XTS -- Low Frequency
   * DIVA_0 -- Divide by 1
   * 
   * Note: ~XTS indicates that XTS has value zero
   *)
  BIS(M.BCSCTL1^, M.XT2OFF + M.DIVA_0);

  (* 
   * Basic Clock System Control 3
   * 
   * XT2S_0 -- 0.4 - 1 MHz
   * LFXT1S_0 -- If XTS = 0, XT1 = 32768kHz Crystal ; If XTS = 1, XT1 = 0.4 - 1-MHz crystal or resonator
   * XCAP_1 -- ~6 pF
   *)
  M.BCSCTL3^ := M.XT2S_0 + M.LFXT1S_0 + M.XCAP_1;

  (*
   *  ======== USCI_A0_graceInit ========
   *  Initialize Universal Serial Communication Interface A0 SPI 2xx
   *)
  BIS(M.UCA0CTL1^, M.UCSWRST); (* Disable USCI *)

  (* 
   * Control Register 1
   * 
   * UCSSEL_2 -- SMCLK
   * ~UCRXEIE -- Erroneous characters rejected and UCAxRXIFG is not set
   * ~UCBRKIE -- Received break characters do not set UCAxRXIFG
   * ~UCDORM -- Not dormant. All received characters will set UCAxRXIFG
   * ~UCTXADDR -- Next frame transmitted is data
   * ~UCTXBRK -- Next frame transmitted is not a break
   * UCSWRST -- Enabled. USCI logic held in reset state
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.UCA0CTL1^ := M.UCSSEL_2 + M.UCSWRST;

  M.UCA0BR0^ := 26; (* Bit Rate Control Register 0 *)
  BIC(M.UCA0CTL1^, M.UCSWRST); (* Enable USCI *)

  (*
   *  ======== USCI_B0_graceInit ========
   *  Initialize Universal Serial Communication Interface B0 SPI 2xx
   *)
  BIS(M.UCB0CTL1^, M.UCSWRST); (* Disable USCI *)

  (* 
   * Control Register 0
   * 
   * UCCKPH -- Data is captured on the first UCLK edge and changed on the following edge
   * ~UCCKPL -- Inactive state is low
   * UCMSB -- MSB first
   * ~UC7BIT -- 8-bit
   * UCMST -- Master mode
   * UCMODE_0 -- 3-Pin SPI
   * UCSYNC -- Synchronous Mode
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.UCB0CTL0^ := M.UCCKPH + M.UCMSB + M.UCMST + M.UCMODE_0 + M.UCSYNC;

  (* 
   * Control Register 1
   * 
   * UCSSEL_2 -- SMCLK
   * UCSWRST -- Enabled. USCI logic held in reset state
   *)
  M.UCB0CTL1^ := M.UCSSEL_2 + M.UCSWRST;

  M.UCB0BR0^ := 2; (* Bit Rate Control Register 0 *)
  BIC(M.UCB0CTL1^, M.UCSWRST); (* Enable USCI *)

  (*
   *  ======== ADC10_graceInit ========
   *  Initialize MSP430 10-bit Analog to Digital Converter
   *)
  BIC(M.ADC10CTL0^, M.ENC); (* disable ADC10 during initialization *)

  (* 
   * Control Register 0
   * 
   * ~ADC10SC -- No conversion
   * ~ENC -- Disable ADC
   * ~ADC10IFG -- Clear ADC interrupt flag
   * ADC10IE -- Enable ADC interrupt
   * ADC10ON -- Switch On ADC10
   * REFON -- Enable ADC reference generator
   * REF2_5V -- Set reference voltage generator = 2.5V
   * ~MSC -- Disable multiple sample and conversion
   * ~REFBURST -- Reference buffer on continuously
   * ~REFOUT -- Reference output off
   * ADC10SR -- Reference buffer supports up to ~50 ksps
   * ADC10SHT_3 -- 64 x ADC10CLKs
   * SREF_1 -- VR+ = VREF+ and VR- = VSS
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.ADC10CTL0^ := M.ADC10IE + M.ADC10ON + M.REFON + M.REF2_5V + M.ADC10SR + M.ADC10SHT_3 + M.SREF_1;

  (* 
   * Control Register 1
   * 
   * ~ADC10BUSY -- No operation is active
   * CONSEQ_0 -- Single channel single conversion
   * ADC10SSEL_0 -- ADC10OSC
   * ADC10DIV_0 -- Divide by 1
   * ~ISSH -- Input signal not inverted
   * ~ADC10DF -- ADC10 Data Format as binary
   * SHS_0 -- ADC10SC
   * INCH_11 -- ADC convert VCC
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.ADC10CTL1^ := M.CONSEQ_0 + M.ADC10SSEL_0 + M.ADC10DIV_0 + M.SHS_0 + M.INCH_11;

  Delay.CyclesX3(30000 DIV 3); (* Software delay for REFON to settle *)

  BIS(M.ADC10CTL0^, M.ENC); (** enable ADC10 *)

  (*
   *  ======== System_graceInit ========
   *  Initialize MSP430 Status Register
   *)
  (* Clear oscillator fault flag with software delay *)
  REPEAT BIC(M.IFG1^, M.OFIFG); (* Clear OSC fault flag *)
    Delay.CyclesX3(50 DIV 3); (* 50us delay *)
  UNTIL ~BIT(M.IFG1^, M.OFIFG);

  (* 
   * IFG2, Interrupt Flag Register 2
   * 
   * ~UCA0RXIFG -- No Interrupt pending
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  BIC(M.IFG2^, M.UCA0RXIFG);

  (* 
   * IE2, Interrupt Enable Register 2
   * 
   * ~UCB0TXIE -- Interrupt disabled
   * ~UCB0RXIE -- Interrupt disabled
   * ~UCA0TXIE -- Interrupt disabled
   * UCA0RXIE -- Interrupt enabled
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  BIS(M.IE2^, M.UCA0RXIE);

  (* 
   * SR, Status Register
   * 
   * ~SCG1 -- Disable System clock generator 1
   * ~SCG0 -- Disable System clock generator 0
   * ~OSCOFF -- Oscillator On
   * ~CPUOFF -- CPU On
   * GIE -- General interrupt enable
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  SYSTEM.BIS_SR(M.GIE);

  (*
   *  ======== Timer0_A3_graceInit ========
   *  Initialize MSP430 Timer0_A3 timer
   *)

  (* 
   * TA0CCTL0, Capture/Compare Control Register 0
   * 
   * CM_0 -- No Capture
   * CCIS_0 -- CCIxA
   * ~SCS -- Asynchronous Capture
   * ~SCCI -- Latched capture signal (read)
   * ~CAP -- Compare mode
   * OUTMOD_0 -- PWM output mode: 0 - OUT bit value
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.TA0CCTL0^ := M.CM_0 + M.CCIS_0 + M.OUTMOD_0 + M.CCIE;

  (* 
   * TA0CCTL2, Capture/Compare Control Register 2
   * 
   * CM_0 -- No Capture
   * CCIS_0 -- CCIxA
   * ~SCS -- Asynchronous Capture
   * ~SCCI -- Latched capture signal (read)
   * ~CAP -- Compare mode
   * OUTMOD_0 -- PWM output mode: 0 - OUT bit value
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.TA0CCTL2^ := M.CM_0 + M.CCIS_0 + M.OUTMOD_0 + M.CCIE;

  (* TA0CCR0, Timer_A Capture/Compare Register 0 *)
  M.TA0CCR0^ := 32768;

  (* TA0CCR1, Timer_A Capture/Compare Register 1 *)
  M.TA0CCR1^ := 3293;

  (* 
   * TA0CTL, Timer_A3 Control Register
   * 
   * TASSEL_1 -- ACLK
   * ID_0 -- Divider - /1
   * MC_2 -- Continuous Mode
   *)
  M.TA0CTL^ := M.TASSEL_1 + M.ID_0 + M.MC_2;

  (*start of sDiary main code*)
  BPReq := FALSE; ADCReq := FALSE; NSReq := FALSE; RcdChar := 0;

  PT.setMax(PTR(PT.Time, old_day));

  beepOn := 0;
  LCD.setCallbacks(select, deselect, setData, setCommand, send); (*register pcd8544 callbacks*)
  state := 0; countData := -1; currentDE.nbSimultaneousEvents := 0; vcc := 0;
  nextEventTime.h := 0; nextEventTime.l := 0; oldSetTime.h := 0; oldSetTime.l := 0;
  nextEventType := {};

  (*lecture des constantes de calibration du quartz 32768 Hz*)
  IF BASE_FREQ^ # 0FFFFH THEN baseFreq := BASE_FREQ^; extraCycles := EXTRA_CYCLES^; trimPeriod := TRIM_PERIOD^
  ELSE baseFreq := DEFAULT_BASE_FREQ; extraCycles := DEFAULT_EXTRA_CYCLES; trimPeriod := DEFAULT_TRIM_PERIOD
  END;

  (*need to wait 10ms, however  30ms are consumed in ADC10 Initilization*)

  BIS(M.P2OUT^, NRST); (*release LCD*) LCD.Init; LCD.Clear;
  prompt;
  currentDE.nbSimultaneousEvents := 0; (*no diary event scheduled for now*)
  (*find 1st date event*)
  findAndArmNextDiaryEvent(FALSE); (*don't populate currentDE*)

  REPEAT SYSTEM.BIS_SR(M.LPM3_bits); (*Enter LPM 3*)
    (*process background actions*)
    parseCommand;
    IF BPReq THEN buttonPressed END;
    IF ADCReq THEN computeVcc END;
    IF NSReq THEN
      IF ~BIT(LCD.FunctionSet, LCD.PD) THEN displayTime END;
      IF PT.cmp (PTR(PT.Time, PT.systemTime), PTR(PT.Time, nextEventTime)) >= 0 THEN
        IF BIT(nextEventType, VCC_MEASURE_EVENT - RELATIVE_EVENT) THEN
          BIS(M.ADC10CTL0^, M.ADC10ON); BIS(M.ADC10CTL0^, M.REFON); (*turn ADC reference ON*)
          Delay.CyclesX3(129 DIV 3); (*wait for stabilization of ADC reference*)
          BIS(M.ADC10CTL0^, M.ENC + M.ADC10SC); (*start conversion*)
          rearmEvent(VCC_MEASURE_EVENT, PTR(PT.Time, PT.TimeMax)) (*VCC measure is not scheduled anymore*)
        END;
        IF BIT(nextEventType, DST_EVENT - RELATIVE_EVENT) THEN (*perform DST change and rearm the event for the next DST*) doDSTEvent END;
        IF BIT(nextEventType, DIARY_EVENT - RELATIVE_EVENT) THEN (*populate the currentDE whit all the events occuring at this precise time*)
          findAndArmNextDiaryEvent(TRUE); (*arm next diary event and populate currentEV*)
          (*display the title of the event and do necessary rescheduling*)
          (*trigger event for next hour as a reminder. This will be cancelled when
             the user will acknowledge the event by pressing the push button*)
          IF currentDE.nbSimultaneousEvents # 0 THEN displayEventOneHour;
            IF BIT(LCD.FunctionSet, LCD.PD) THEN (*LCD is off, turn it on to display the event*)
              displayTime; (*but before that, refresh display*)
              LCD.send(LCD.FunctionSet - LCD.PD); (*request Power on*) rearmVCCSense;
            END;
            (*turn alarm on*)
            IF currentDE.nbSimultaneousEvents > 1 THEN beepOn := 15000 ELSE beepOn := 3293 END;
            M.TA0CCTL1^ := M.CM_0 + M.CCIS_0 + M.OUTMOD_3; M.TA0CCR1^ := M.TA0CCR0^ - beepOn;
            rearmBeepOff
          END
        END;
        IF BIT(nextEventType, LIGHT_OFF_EVENT - RELATIVE_EVENT) THEN BIS(M.P1OUT^, NLIGHT); (*light off*)
          rearmEvent(LIGHT_OFF_EVENT, PTR(PT.Time, PT.TimeMax))
        END;
        IF BIT(nextEventType, BEEP_OFF_EVENT - RELATIVE_EVENT) THEN
          IF beepOn # 0 THEN beepOn := 0; M.TA0CCTL1^ := M.CM_0 + M.CCIS_0 + M.OUTMOD_0;
            LCD.send(LCD.FunctionSet + LCD.PD) (* Request LCD Power off*)
          END;
          rearmEvent(BEEP_OFF_EVENT, PTR(PT.Time, PT.TimeMax)) (*unschedule BEEP OFF event*)
        END;
        IF BIT(nextEventType, LCD_POWER_OFF_EVENT - RELATIVE_EVENT) THEN 
          LCD.send(LCD.FunctionSet + LCD.PD); (* Request LCD Power off*)
          rearmEvent(LCD_POWER_OFF_EVENT, PTR(PT.Time, PT.TimeMax)) (*unschedule LCD POWER OFF event*)
        END;
        IF BIT(nextEventType,  CLEAR_LCD_EVENT - RELATIVE_EVENT) THEN 
          (*clear LCD screen and reschedule events*)
          popEvent;
          IF currentDE.nbSimultaneousEvents # 0 THEN displayEventOneHour ELSE displayEvent(PTR(PT.Time, PT.TimeMax)) END
        END;
        scheduleNextEvent
      END;
      NSReq := FALSE;
    END
  UNTIL FALSE
END sDiary.

OMSPP.Compile MSPFlashTypes.Mod/s preserveMSPFlash.Mod/s msp430g2553.Mod MultiPrecisionArith.Mod/s
  String.Mod/s Arith.Mod/s PosixTime.Mod/s sDiaryTypes.Mod/s msp430delay.Mod/s pcd8544.Mod/s sDiary.Mod/s ~

2800H = 3C00H - NB_DIARY_SLOTS*SYSTEM.SIZE(ST.DEDesc)
OMSPL.Link 32 2800H 200H sDiary ~
  linking MSPFlashTypes preserveMSPFlash msp430g2553 MultiPrecisionArith String Arith PosixTime sDiaryTypes
 msp430delay pcd8544 sDiary
    flash10098, data  298, stack  214 bytes

OMSPTool.DecSym sDiary.sms

OMSPTool.DecObj sDiary.mpc
