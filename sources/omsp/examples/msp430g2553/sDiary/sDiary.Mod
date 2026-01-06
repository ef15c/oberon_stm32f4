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
    commandBusy: BOOLEAN; (*command processing in progress and sound indicators*)
    old_day, nextEventTime: PT.TimeDesc; nextEventType: BYTESET;
    vcc, beepOn: INTEGER;
    extraCycles, trimPeriod: BYTE; baseFreq: INTEGER;

    (*global variables for parseCommand procedure*)
    state, DEIndex: INTEGER; setTime: PT.TmDesc; oldSetTime: PT.TimeDesc;
    cOrD: SET; parseData: INTEGER; (*hex data or index on string sent by host*)

    (*global variables for nextSecond procedure*)
    trimmer: INTEGER;

    (*for interrupt handlers*)
    BPReq, ADCReq, PCReq: BOOLEAN;

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
    (*add digit to the litteral dest and count the number of digits into parseData*)
  BEGIN
    IF (c >= "0") & (c <= "9") THEN dest := dest*10 + ORD(c) - ORD("0"); INC(parseData)
    ELSE respondBAD
    END
  END appendDigit;

  PROCEDURE appendHexDigit(c: INTEGER);
  BEGIN
    IF (c >= ORD("0")) & (c < ORD("9") + 1) THEN INC(parseData, c - ORD("0"))
    ELSIF (c >= ORD("a")) & (c < ORD("f") + 1) THEN INC(parseData, c-(ORD("a") - 10))
    ELSE respondBAD
    END
  END appendHexDigit;

  PROCEDURE scheduleNextEvent;
    VAR i: INTEGER; evt!: EVT;
  BEGIN nextEventTime.h := -1; nextEventTime.l := -1;
    nextEventType := NO_EVENT;

    (*parse event tab to find the nearest event*)
    i := NB_EVTAB_ELTS - 1; evt := PTR(EVT, evTab[0]);
    REPEAT
      (*check current element*)
      IF PT.cmp(PTR(PT.Time, evt.eti), PTR(PT.Time, nextEventTime)) < 0 THEN
        nextEventType := evt.ety; (*unschedule previous envents*)
        nextEventTime := evt.eti (*record new next event time*)
      ELSIF PT.cmp(PTR(PT.Time, evt.eti), PTR(PT.Time, nextEventTime)) = 0 THEN
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
      IF BIT(evt.ety, eventType) THEN evt.eti := newTime^ END; (*set new scheduled time*)
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
  BEGIN res := -1; i := NB_DIARY_SLOTS - 1; cde := flashDE;
    REPEAT
      IF cde.titre[0] = 0FFH THEN (*this slot is free*)
        FB.flashBlock(SYSTEM.VAL(PINTEGER, PTR(ST.DE, ramDE)), SYSTEM.VAL(PINTEGER, cde), 64);
        findAndArmNextDiaryEvent(FALSE); (*arm next diary event, but don't populate currentDE structure*)
        scheduleNextEvent
      END;
      INC(SYSTEM.VAL(INTEGER, cde), SYSTEM.SIZE(ST.DEDesc));
      DEC(i)
    UNTIL (i < 0) OR (res # -1)

    RETURN res
  END  createDiaryEvent;

  PROCEDURE prompt; (*display prompt*)
  BEGIN respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR(PROMPT)))
  END prompt;

  PROCEDURE respondI(t, nbc: INTEGER);
    VAR msg: ARRAY 12 OF CHAR;
  BEGIN String.FromInteger(t, nbc, msg); respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR(msg)))
  END respondI;

  PROCEDURE respondUL(th, tl, nbc: INTEGER);
    VAR msg: ARRAY 12 OF CHAR;
  BEGIN String.FromLong(th, tl, nbc, msg); respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR(msg)))
  END respondUL;

  PROCEDURE respondT(t: PT.Time; nbc: INTEGER);
    VAR msg: ARRAY 12 OF CHAR;
  BEGIN PT.TimeToString(t, nbc, msg); respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR(msg)));
  END respondT;

  PROCEDURE parseCommand(c: INTEGER);
  (* Parse commands sent by UART interface
      Each command start with a letter, following by arguments and terminated by a carriage return
      List of available commands
      a.* : display characters on LCD. Example aHello World ! displays
            this classical sentence to the LCD screen. Must be terminated by a \r.
      b[{C|D|<double hex digit>]* : send raw data to LCD. Must be terminated by a \r.
     		C indicates that the following is a command
     		D indicates that the following is data
     		|<double hex digit> is the command or data to send
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
  BEGIN
    IF ~commandBusy THEN
      IF c >= 100H THEN (*set overflow error*) state := CM_OVERFLOW_ERROR; respondBAD
      ELSIF (c = 0DH) & ((state # CM_CREATE_EVENT) OR (parseData >= 64)) THEN
        IF state = CM_SET_DATETIME THEN
          IF parseData = 14 THEN (*the data are complete*)
			DEC(setTime.mon); (*TM struct need month between 0 and 11*)
			DEC(setTime.year, 1900); (*TM struct count year from 1900*)
            (*adjust nextVccEvent step 1*)
            oldSetTime.h := 0; oldSetTime.l := 0; PT.dec(PTR(PT.Time, oldSetTime), PTR(PT.Time, PT.systemTime));
            adjustEvents(PTR(PT.Time, oldSetTime));
            PT.settime(PTR(PT.Tm, setTime), PTR(PT.Time, oldSetTime));
            rearmEvent(DST_EVENT, PTR(PT.Time, oldSetTime)); (*setting time and arm DST change trigger*)
            oldSetTime := PT.systemTime; PT.setMax(PTR(PT.Time, old_day));
            findAndArmNextDiaryEvent(FALSE); (*setting time and arm next calendar event trigger, don't populate currentDE*)
            currentDE.nbSimultaneousEvents := 0; (*clear currentDE list*)
            adjustEvents(PTR(PT.Time, PT.systemTime)); (*Adjust nextVccEvent step 2*)
            scheduleNextEvent
          END
        ELSIF state = CM_SECOND_DIGIT THEN respondBAD
        ELSIF state = CM_DELETE_EVENT THEN deleteDiaryEvent(DEIndex)
        ELSIF state = CM_CREATE_EVENT THEN
          IF parseData = 64 THEN (*he data are complete*)
            DEIndex := createDiaryEvent(); respondI(DEIndex, 4)
          ELSE (*error when creating Event*) respondBAD
          END;
          state := CM_INIT; prompt
        END
      ELSIF state = CM_INIT THEN
        IF c = ORD("a") THEN state := CM_DISPLAY_CHAR
        ELSIF c = ORD("b") THEN state := CM_RAW
        ELSIF c = ORD("c") THEN state := CM_CREATE_EVENT; parseData := 0; (*no char read yet*)
        ELSIF (c = ORD("d")) OR (c = ORD("u")) THEN state := CM_SET_DATETIME;
          setTime.isdst := c = ORD("d"); (*time expressed in local(d) or UTC(u) time*)
          setTime.mday := 0; setTime.mon := 0; setTime.year := 0; setTime.hour := 0; setTime.min := 0; setTime.sec := 0;
          parseData := 0; (*no char read yet*)
        ELSIF c = ORD("e") THEN commandBusy := TRUE; (*triggers sending events to host in main loop*)
        ELSIF c = ORD("i") THEN (*send information about configuration and state to host*)
          respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR(DEVICE_IDENTITY)));
          respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|t="))); respondT(PTR(PT.Time, PT.systemTime), 11);
          respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|sf="))); respondI(nbFreeSlots(), 5); (*send total number of free slots*)
          respondC("/"); respondUL(0, NB_DIARY_SLOTS, 4); (*end total number of slots*)
          respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|v="))); respondI(vcc, 5); respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("mV")));
          respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|Vop="))); respondI(LCD.Vop, 4);
          respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|Bell="))); respondI(ORD(PT.cmp(getEventTime(DIARY_EVENT), PTR(PT.Time, PT.TimeMax))), 2);
          respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|st="))); respondT(PTR(PT.Time, oldSetTime), 11);
          respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|bf="))); respondUL(0,baseFreq, 6);
          respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|ec="))); respondI(extraCycles, 5);
          respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("|tp="))); respondI(trimPeriod, 4);
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
        ELSIF c = ORD("w") THEN respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR("type="))); respondI(ORD(nextEventType), 4);
          respondS(SYSTEM.VAL(PBYTE, SYSTEM.ADR(", time="))); respondT(PTR(PT.Time, nextEventTime), 11);
          prompt
        ELSIF c = ORD("z") THEN eraseAllDiaryEvents; prompt
        ELSIF c = ORD("@") THEN (*restart in boot loader mode*) M.WDTCTL^ := {}
        ELSE respondBAD
        END
      ELSIF state = CM_RAW THEN respondC(CHR(c));
        IF c = ORD("C") THEN cOrD := {} (*command*)
        ELSIF c = ORD("D") THEN cOrD := {8}; (*data*)
        ELSE parseData := 0; appendHexDigit(c); state := CM_SECOND_DIGIT
        END
      ELSIF state = CM_SECOND_DIGIT THEN respondC(CHR(c)); RLA(parseData, 4); appendHexDigit(c);
        (*the data is built, send it to LCD with appropriate command or data signal*)
        LCD.send(cOrD + TOSET(parseData)); state := CM_RAW
      ELSIF state = CM_DISPLAY_CHAR THEN LCD.WriteChar(CHR(c))
      ELSIF state = CM_DELETE_EVENT THEN appendDigit(DEIndex, CHR(c))
      ELSIF state = CM_CREATE_EVENT THEN
        IF parseData < SYSTEM.SIZE(ST.DEDesc) THEN SYSTEM.VAL(PBYTE, SYSTEM.ADR(ramDE) + parseData)^ := c; INC(parseData)
        ELSE respondBAD
        END
      ELSIF state = CM_SET_DATETIME THEN
        IF parseData < 2 THEN (*day of month expected*) appendDigit(setTime.mday, CHR(c))
        ELSIF parseData < 4 THEN (*month expected*) appendDigit(setTime.mon, CHR(c))
        ELSIF parseData < 8 THEN appendDigit(setTime.year, CHR(c))
        ELSIF parseData < 10 THEN (*hour (0, 23) expected*) appendDigit(setTime.hour, CHR(c))
        ELSIF parseData < 12 THEN (*minutes (0, 59) expected*) appendDigit(setTime.min, CHR(c))
        ELSIF parseData < 14 THEN (*seconds (0, 59) expected*) appendDigit(setTime.sec, CHR(c))
        END
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
    END
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
    LCD.WriteLongint(0, tm.hour, 3, 0, 2, " "); LCD.WriteChar(":");
    LCD.WriteLongint(0, tm.min, 6, 0, 2, "0"); LCD.WriteChar(":");
    LCD.WriteLongint(0, tm.sec, 9, 0, 2, "0");
    IF PT.cmp(PTR(PT.Time, old_day), PTR(PT.Time, ltime)) # 0 THEN setVcc;
      (*do the following only if day has change, to save few micro amps.*)
      old_day := ltime; PT.localtime(PTR(PT.Time, PT.systemTime), PTR(PT.Tm, tm)); LCD.SetAddr(0, 1);
      LCD.WriteString(dayOfWeek[tm.wday]);
      LCD.WriteLongint(0, tm.mday, 4, 1, 2, " "); LCD.WriteChar("/");
      LCD.WriteLongint(0, tm.mon+1, 7, 1, 2, "0"); LCD.WriteChar("/");
      LCD.WriteLongint(0, tm.year+1900, 10, 1, 4, " ")
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

  PROCEDURE buttonPressed; (*mplement action when button is pressed*)
    VAR t: PT.TimeDesc;
  BEGIN rearmVCCSense;
    IF beepOn > 0 THEN (*stop sound*) beepOn := 0; M.TA0CCTL1^ := M.CM_0 + M.CCIS_0 + M.OUTMOD_0;
      INC(t.l, 27); ADC(t.h, 0);
      rearmEvent(LCD_POWER_OFF_EVENT, PTR(PT.Time, t)); (*stop LCD in 30s*)
    ELSE BIC(M.P1OUT^, NLIGHT); (*Turn Light On*)
      (*we have to power up the LCD if needed.*)
      IF BIT(LCD.FunctionSet, LCD.PD) (*LCD is in powerd down mode*) THEN
        displayTime; (*but before that, refresh display*)
        LCD.send(LCD.FunctionSet - LCD.PD) (* Request Power on*)
      END;
      t := PT.systemTime; INC(t.l, 5); ADC(t.h, 0);
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

  PROCEDURE* (M.USCIAB0RX_VECTOR) USCI0RX_ISR_HOOK;
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
      PCReq := TRUE; (*process character and overflow condition*)
      (*exit from low power mode to allow background processing of events in main loop*)
      SYSTEM.BIC_SR_ON_EXIT(M.LPM4_bits)
    END
  END USCI0RX_ISR_HOOK;

  PROCEDURE* (M.TIMER0_A0_VECTOR) TIMER0_A0_ISR_HOOK;
  (*
   *  ======== Timer0_A3 Interrupt Service Routine ======== 
   *)
  BEGIN nextSecond();
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

  PROCEDURE sendEvents;
  (*send events stored in flash to host*)
    VAR i,j : INTEGER; cde!: ST.DE; fbot: BYTE; (*the first byte of the title*)
      cb!: PBYTE;
  BEGIN i :=NB_DIARY_SLOTS - 1; cde := flashDE;
    REPEAT fbot := cde.titre[0];
      IF (fbot # 0FFH) & (fbot # 0) THEN (*the slot contains a valid event*)
        respondI(i, 4); (*send the index on current slot*) respondC("|");
        cb := PTR(PBYTE, cde.titre[0]);
        j := 63; REPEAT respondC(CHR(cb^)); INC(SYSTEM.VAL(INTEGER, cb)); DEC(j); UNTIL j < 0; (*send 64 bytes*)
		respondC("|")
      END;
      INC(SYSTEM.VAL(INTEGER, cde), SYSTEM.SIZE(ST.DEDesc));
      DEC(i)
    UNTIL i < 0;
  END sendEvents;

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
  M.P1REN^ := {3, 4}; (** Port 1 Resistor Enable Register *)
  M.P1IES^ := {3}; (* Port 1 Interrupt Edge Select Register *)
  M.P1IFG^ := {0}; (* Port 1 Interrupt Flag Register *)
  M.P1IE^ := {3}; (** Port 1 Interrupt Enable Register *)

  M.P2OUT^ := {1, 3..5}; (* Port 2 Output Register *)
  M.P2DIR^ := {0, 1, 2}; (* Port 2 Direction Register *)
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
  BPReq := FALSE; ADCReq := FALSE; PCReq := FALSE;

  PT.setMax(PTR(PT.Time, old_day));

  commandBusy := FALSE; beepOn := 0;
  LCD.setCallbacks(select, deselect, setData, setCommand); (*register pcd8544 callbacks*)

  (*TODO: init ramDE, currentDE, vcc intialized in an interrupt handler*)

  (*lecture des constantes de calibration du quartz 32768 Hz*)
  IF BASE_FREQ^ # 0FFFFH THEN baseFreq := BASE_FREQ^; extraCycles := EXTRA_CYCLES^; trimPeriod := TRIM_PERIOD^
  ELSE baseFreq := DEFAULT_BASE_FREQ; extraCycles := DEFAULT_EXTRA_CYCLES; trimPeriod := DEFAULT_TRIM_PERIOD
  END;

  (*need to wait 10ms, however  30ms are consumed in ADC10 Initilization*)

  BIC(M.P2OUT^, NRST); (*reset LCD*) LCD.Clear; LCD.Init;
  parseCommand(0DH);
  currentDE.nbSimultaneousEvents := 0; (*no diary event scheduled for now*)
  (*find 1st date event*)
  findAndArmNextDiaryEvent(FALSE); (*don't populate currentDE*)

  REPEAT SYSTEM.BIS_SR(M.LPM3_bits); (*Enter LPM 3*)
    IF commandBusy THEN sendEvents; prompt; commandBusy := FALSE
    ELSE (*process background actions*)
      IF BPReq THEN buttonPressed END;
      IF ADCReq THEN computeVcc END;
      IF PCReq THEN REPEAT UNTIL BIT(M.IFG2^, M.UCA0TXIFG); (*USCI_A0 TX buffer ready?*)
        parseCommand(1*ORD(M.UCA0STAT^*M.UCOE)*100H + M.UCA0RXBUF^)
      END;
      IF ~BIT(LCD.FunctionSet, LCD.PD) THEN displayTime END;
(*      IF ~BIT(M.UCB0STAT^, M.UCBUSY) THEN (*SPI operation is complete*) BIS(M.P2OUT^, NCE); (*deassert LCD*)*)
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
      END
    END
  UNTIL FALSE
END sDiary.

OMSPP.Compile MSPFlashTypes.Mod/s preserveMSPFlash.Mod/s msp430g2553.Mod Arith.Mod/s MultiPrecisionArith.Mod/s
  String.Mod/s PosixTime.Mod/s sDiaryTypes.Mod/s
  msp430delay.Mod/s pcd8544.Mod/s sDiary.Mod/s ~

2800H = 3C00H - NB_DIARY_SLOTS*SYSTEM.SIZE(ST.DEDesc)
OMSPL.Link 32 2800H 200H sDiary ~
  linking MSPFlashTypes preserveMSPFlash msp430g2553 MultiPrecisionArith Arith String PosixTime sDiaryTypes
 msp430delay pcd8544 sDiary
    flash10136, data  195, stack  317 bytes

OMSPTool.DecSym sDiary.sms

OMSPTool.DecObj sDiary.mpc
decode sDiary.mpc
sDiary 7E126BF3
imports:
	preserveMSPFlash 02DC2762
	MSPFlashTypes 39EB6FB6
	msp430g2553 BBD31A01
	MultiPrecisionArith 7965D39A
	String 6528ABA7
	PosixTime 5B40AD77
	sDiaryTypes D1E0607E
	pcd8544 9F8FAE37
	msp430delay AAE4F156

section     0	s    4	

=>|
fixups:

section     1	s    6	
=>KO||
fixups:

section     2	s   10	
sDiary|B4|
fixups:

section     3	d    8	DEs
 0C 00 FF FF FF FF FF FF
fixups:

section     4	d    8	EVTDesc
 06 00 FF FF FF FF FF FF
fixups:

section     5	r   64	ramDE
fixups:

section     6	r   12	currentDE
fixups:

section     7	r   42	evTab
fixups:

section     8	d   28	dayOfWeek
 44 69 6D 00 4C 75 6E 00 4D 61 72 00 4D 65 72 00
 4A 65 75 00 56 65 6E 00 53 61 6D 00
fixups:

section     9	r    1	commandBusy
fixups:

section    10	r    4	old_day
fixups:

section    11	r    4	nextEventTime
fixups:

section    12	r    1	nextEventType
fixups:

section    13	r    2	vcc
fixups:

section    14	r    2	beepOn
fixups:

section    15	r    1	extraCycles
fixups:

section    16	r    1	trimPeriod
fixups:

section    17	r    2	baseFreq
fixups:

section    18	r    2	state
fixups:

section    19	r    2	DEIndex
fixups:

section    20	r   18	setTime
fixups:

section    21	r    4	oldSetTime
fixups:

section    22	r    2	cOrD
fixups:

section    23	r    2	parseData
fixups:

section    24	r    2	trimmer
fixups:

section    25	r    1	BPReq
fixups:

section    26	r    1	ADCReq
fixups:

section    27	r    1	PCReq
fixups:

section    28	c    6	select
 0000	     C3E2	BIC.B #2,&41
 0002	     0029
 0004	     4130	RET
fixups:

section    29	c    6	deselect
 0000	     D3E2	BIS.B #2,&41
 0002	     0029
 0004	     4130	RET
fixups:

section    30	c    6	setData
 0000	     D3D2	BIS.B #1,&41
 0002	     0029
 0004	     4130	RET
fixups:

section    31	c    6	setCommand
 0000	     C3D2	BIC.B #1,&41
 0002	     0029
 0004	     4130	RET
fixups:

section    32	c   50	nbFreeSlots
 0000	     4306	MOV #0,R6
 0002	     4304	MOV #0,R4
 0004	     4035	MOV #79,R5
 0006	     004F
 0008	     4037	MOV #-15360,R7
 000A	     C400
 000C	     4768	MOV.B @R7,R8
 000E	     9378	CMP.B #-1,R8
 0010	     2002	JNE $+6, goes to  0016
 0012	     5316	ADD #1,R6
 0014	     3C03	JMP $+8, goes to  001C
 0016	     9348	CMP.B #0,R8
 0018	     2001	JNE $+4, goes to  001C
 001A	     5314	ADD #1,R4
 001C	     5037	ADD #64,R7
 001E	     0040
 0020	     8315	SUB #1,R5
 0022	     37F4	JGE $-22, goes to  000C
 0024	     9306	CMP #0,R6
 0026	     2402	JEQ $+6, goes to  002C
 0028	     5604	ADD R6,R4
 002A	     3C02	JMP $+6, goes to  0030
 002C	     E334	XOR #-1,R4
 002E	     5314	ADD #1,R4
 0030	     4130	RET
fixups:

section    33	c   12	respondC
 0000	     B3E2	BIT.B #2,&3
 0002	     0003
 0004	     27FD	JEQ $-4, goes to  0000
 0006	     44C2	MOV.B R4,&103
 0008	     0067
 000A	     4130	RET
fixups:

section    34	c   28	respondS
 0000	     411F	MOV 2(SP),R15
 0002	     0002
 0004	     93CF	CMP.B #0,0(R15)
 0006	     0000
 0008	     2408	JEQ $+18, goes to  001A
 000A	     4114	MOV 2(SP),R4
 000C	     0002
 000E	     4464	MOV.B @R4,R4
 0010	     12B0	CALL #0
 0012	     0000
 0014	     5391	ADD #1,2(SP)
 0016	     0002
 0018	     3FF3	JMP $-24, goes to  0000
 001A	     4130	RET
fixups:
 0013	s0.33

section    35	c   12	respondBAD
 0000	     1230	PUSH #0
 0002	     0000
 0004	     12B0	CALL #0
 0006	     0000
 0008	     5321	ADD #2,SP
 000A	     4130	RET
fixups:
 0007	s0.34
 0003	s0.1

section    36	c   64	appendDigit
 0000	     90F1	CMP.B #48,2(SP)
 0002	     0030
 0004	     0002
 0006	     2819	JNC $+52, goes to  003A
 0008	     407F	MOV.B #57,R15
 000A	     0039
 000C	     915F	CMP.B 2(SP),R15
 000E	     0002
 0010	     2814	JNC $+42, goes to  003A
 0012	     411E	MOV 4(SP),R14
 0014	     0004
 0016	     4E2F	MOV @R14,R15
 0018	     5F0F	ADD R15,R15
 001A	     4F0E	MOV R15,R14
 001C	     5E0E	ADD R14,R14
 001E	     5E0E	ADD R14,R14
 0020	     5E0F	ADD R14,R15
 0022	     415E	MOV.B 2(SP),R14
 0024	     0002
 0026	     5E0F	ADD R14,R15
 0028	     803F	SUB #48,R15
 002A	     0030
 002C	     411E	MOV 4(SP),R14
 002E	     0004
 0030	     4F8E	MOV R15,0(R14)
 0032	     0000
 0034	     5392	ADD #1,&0
 0036	     0000
 0038	     3C02	JMP $+6, goes to  003E
 003A	     12B0	CALL #0
 003C	     0000
 003E	     4130	RET
fixups:
 003D	s0.35
 0037	s0.23

section    37	c   66	appendHexDigit
 0000	     90B1	CMP #48,2(SP)
 0002	     0030
 0004	     0002
 0006	     380B	JL $+24, goes to  001E
 0008	     90B1	CMP #58,2(SP)
 000A	     003A
 000C	     0002
 000E	     3407	JGE $+16, goes to  001E
 0010	     411F	MOV 2(SP),R15
 0012	     0002
 0014	     803F	SUB #48,R15
 0016	     0030
 0018	     5F82	ADD R15,&0
 001A	     0000
 001C	     3C11	JMP $+36, goes to  0040
 001E	     90B1	CMP #97,2(SP)
 0020	     0061
 0022	     0002
 0024	     380B	JL $+24, goes to  003C
 0026	     90B1	CMP #103,2(SP)
 0028	     0067
 002A	     0002
 002C	     3407	JGE $+16, goes to  003C
 002E	     411F	MOV 2(SP),R15
 0030	     0002
 0032	     803F	SUB #87,R15
 0034	     0057
 0036	     5F82	ADD R15,&27
 0038	     001B
 003A	     3C02	JMP $+6, goes to  0040
 003C	     12B0	CALL #0
 003E	     0000
 0040	     4130	RET
fixups:
 003F	s0.35
 0039	s0.23

section    38	c  126	scheduleNextEvent
 0000	     8221	SUB #4,SP
 0002	     43B2	MOV #-1,&0
 0004	     0000
 0006	     43B2	MOV #-1,&0
 0008	     0000
 000A	     43C2	MOV.B #0,&0
 000C	     0000
 000E	     40B1	MOV #6,0(SP)
 0010	     0006
 0012	     0000
 0014	     40B1	MOV #0,2(SP)
 0016	     0000
 0018	     0002
 001A	     411F	MOV 2(SP),R15
 001C	     0002
 001E	     532F	ADD #2,R15
 0020	     120F	PUSH R15
 0022	     1230	PUSH #9
 0024	     0009
 0026	     12B0	CALL #0
 0028	     0000
 002A	     5221	ADD #4,SP
 002C	     930F	CMP #0,R15
 002E	     3410	JGE $+34, goes to  0050
 0030	     411F	MOV 2(SP),R15
 0032	     0002
 0034	     4FE2	MOV.B @R15,&13
 0036	     000D
 0038	     411F	MOV 2(SP),R15
 003A	     0002
 003C	     532F	ADD #2,R15
 003E	     403E	MOV #37,R14
 0040	     0025
 0042	     432D	MOV #2,R13
 0044	     4FBE	MOV @R15+,0(R14)
 0046	     0000
 0048	     532E	ADD #2,R14
 004A	     831D	SUB #1,R13
 004C	     23FB	JNE $-8, goes to  0044
 004E	     3C0F	JMP $+32, goes to  006E
 0050	     411F	MOV 2(SP),R15
 0052	     0002
 0054	     532F	ADD #2,R15
 0056	     120F	PUSH R15
 0058	     1230	PUSH #65
 005A	     0041
 005C	     12B0	CALL #41
 005E	     0029
 0060	     5221	ADD #4,SP
 0062	     930F	CMP #0,R15
 0064	     2004	JNE $+10, goes to  006E
 0066	     411F	MOV 2(SP),R15
 0068	     0002
 006A	     DFE2	BIS.B @R15,&55
 006C	     0037
 006E	     50B1	ADD #6,2(SP)
 0070	     0006
 0072	     0002
 0074	     8391	SUB #1,0(SP)
 0076	     0000
 0078	     37D0	JGE $-94, goes to  001A
 007A	     5221	ADD #4,SP
 007C	     4130	RET
fixups:
 005F	s6.9
 0017	s0.7
 006D	s0.12
 005B	s0.11
 0005	s0.11+2

section    39	c   78	adjustEvents
 0000	     8221	SUB #4,SP
 0002	     40B1	MOV #6,0(SP)
 0004	     0006
 0006	     0000
 0008	     40B1	MOV #0,2(SP)
 000A	     0000
 000C	     0002
 000E	     411F	MOV 2(SP),R15
 0010	     0002
 0012	     B0FF	BIT.B #128,0(R15)
 0014	     0080
 0016	     0000
 0018	     2412	JEQ $+38, goes to  003E
 001A	     411F	MOV 2(SP),R15
 001C	     0002
 001E	     532F	ADD #2,R15
 0020	     120F	PUSH R15
 0022	     1230	PUSH #0
 0024	     0000
 0026	     12B0	CALL #0
 0028	     0000
 002A	     5221	ADD #4,SP
 002C	     930F	CMP #0,R15
 002E	     2407	JEQ $+16, goes to  003E
 0030	     4114	MOV 2(SP),R4
 0032	     0002
 0034	     5324	ADD #2,R4
 0036	     4115	MOV 6(SP),R5
 0038	     0006
 003A	     12B0	CALL #0
 003C	     0000
 003E	     50B1	ADD #6,2(SP)
 0040	     0006
 0042	     0002
 0044	     8391	SUB #1,0(SP)
 0046	     0000
 0048	     37E2	JGE $-58, goes to  000E
 004A	     5221	ADD #4,SP
 004C	     4130	RET
fixups:
 003D	s6.10
 0029	s6.9
 0025	s6.3
 000B	s0.7

section    40	c   64	rearmEvent
 0000	     8221	SUB #4,SP
 0002	     40B1	MOV #6,0(SP)
 0004	     0006
 0006	     0000
 0008	     40B1	MOV #0,2(SP)
 000A	     0000
 000C	     0002
 000E	     411F	MOV 2(SP),R15
 0010	     0002
 0012	     B1DF	BIT.B 8(SP),0(R15)
 0014	     0008
 0016	     0000
 0018	     240B	JEQ $+24, goes to  0030
 001A	     411F	MOV 2(SP),R15
 001C	     0002
 001E	     411E	MOV 6(SP),R14
 0020	     0006
 0022	     532F	ADD #2,R15
 0024	     432D	MOV #2,R13
 0026	     4EBF	MOV @R14+,0(R15)
 0028	     0000
 002A	     532F	ADD #2,R15
 002C	     831D	SUB #1,R13
 002E	     23FB	JNE $-8, goes to  0026
 0030	     50B1	ADD #6,2(SP)
 0032	     0006
 0034	     0002
 0036	     8391	SUB #1,0(SP)
 0038	     0000
 003A	     37E9	JGE $-44, goes to  000E
 003C	     5221	ADD #4,SP
 003E	     4130	RET
fixups:
 000B	s0.7

section    41	c   82	getEventTime
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     40B1	MOV #6,0(SP)
 0006	     0006
 0008	     0000
 000A	     40B1	MOV #0,2(SP)
 000C	     0000
 000E	     0002
 0010	     4381	MOV #0,4(SP)
 0012	     0004
 0014	     411F	MOV 2(SP),R15
 0016	     0002
 0018	     91DF	CMP.B 8(SP),0(R15)
 001A	     0008
 001C	     0000
 001E	     2005	JNE $+12, goes to  002A
 0020	     411F	MOV 2(SP),R15
 0022	     0002
 0024	     532F	ADD #2,R15
 0026	     4F81	MOV R15,4(SP)
 0028	     0004
 002A	     50B1	ADD #6,2(SP)
 002C	     0006
 002E	     0002
 0030	     8391	SUB #1,0(SP)
 0032	     0000
 0034	     3803	JL $+8, goes to  003C
 0036	     9381	CMP #0,4(SP)
 0038	     0004
 003A	     27EC	JEQ $-38, goes to  0014
 003C	     9381	CMP #0,4(SP)
 003E	     0004
 0040	     2003	JNE $+8, goes to  0048
 0042	     40B1	MOV #0,4(SP)
 0044	     0000
 0046	     0004
 0048	     411F	MOV 4(SP),R15
 004A	     0004
 004C	     5031	ADD #6,SP
 004E	     0006
 0050	     4130	RET
fixups:
 0045	s6.3
 000D	s0.7

section    42	c  592	nextCompatibleDate
 0000	     8031	SUB #24,SP
 0002	     0018
 0004	     4114	MOV 26(SP),R4
 0006	     001A
 0008	     12B0	CALL #0
 000A	     0000
 000C	     411F	MOV 30(SP),R15
 000E	     001E
 0010	     B0FF	BIT.B #127,5(R15)
 0012	     007F
 0014	     0005
 0016	     2005	JNE $+12, goes to  0022
 0018	     4114	MOV 26(SP),R4
 001A	     001A
 001C	     12B0	CALL #0
 001E	     0000
 0020	     3D14	JMP $+554, goes to  024A
 0022	     1211	PUSH 30(SP)
 0024	     001E
 0026	     410F	MOV SP,R15
 0028	     532F	ADD #2,R15
 002A	     120F	PUSH R15
 002C	     12B0	CALL #0
 002E	     0000
 0030	     5221	ADD #4,SP
 0032	     4381	MOV #0,0(SP)
 0034	     0000
 0036	     411F	MOV 30(SP),R15
 0038	     001E
 003A	     93FF	CMP.B #-1,0(R15)
 003C	     0000
 003E	     2405	JEQ $+12, goes to  004A
 0040	     411E	MOV 30(SP),R14
 0042	     001E
 0044	     4E6F	MOV.B @R14,R15
 0046	     4F81	MOV R15,2(SP)
 0048	     0002
 004A	     411F	MOV 30(SP),R15
 004C	     001E
 004E	     93FF	CMP.B #-1,1(R15)
 0050	     0001
 0052	     2406	JEQ $+14, goes to  0060
 0054	     411E	MOV 30(SP),R14
 0056	     001E
 0058	     4E5F	MOV.B 1(R14),R15
 005A	     0001
 005C	     4F81	MOV R15,4(SP)
 005E	     0004
 0060	     411F	MOV 30(SP),R15
 0062	     001E
 0064	     93FF	CMP.B #-1,2(R15)
 0066	     0002
 0068	     2406	JEQ $+14, goes to  0076
 006A	     411E	MOV 30(SP),R14
 006C	     001E
 006E	     4E5F	MOV.B 2(R14),R15
 0070	     0002
 0072	     4F81	MOV R15,6(SP)
 0074	     0006
 0076	     411F	MOV 30(SP),R15
 0078	     001E
 007A	     93FF	CMP.B #-1,3(R15)
 007C	     0003
 007E	     2406	JEQ $+14, goes to  008C
 0080	     411E	MOV 30(SP),R14
 0082	     001E
 0084	     4E5F	MOV.B 3(R14),R15
 0086	     0003
 0088	     4F81	MOV R15,8(SP)
 008A	     0008
 008C	     411F	MOV 30(SP),R15
 008E	     001E
 0090	     93FF	CMP.B #-1,4(R15)
 0092	     0004
 0094	     2408	JEQ $+18, goes to  00A6
 0096	     411E	MOV 30(SP),R14
 0098	     001E
 009A	     4E5F	MOV.B 4(R14),R15
 009C	     0004
 009E	     507F	ADD.B #70,R15
 00A0	     0046
 00A2	     4F81	MOV R15,10(SP)
 00A4	     000A
 00A6	     411F	MOV 26(SP),R15
 00A8	     001A
 00AA	     410E	MOV SP,R14
 00AC	     503E	ADD #18,R14
 00AE	     0012
 00B0	     432D	MOV #2,R13
 00B2	     4FBE	MOV @R15+,0(R14)
 00B4	     0000
 00B6	     532E	ADD #2,R14
 00B8	     831D	SUB #1,R13
 00BA	     23FB	JNE $-8, goes to  00B2
 00BC	     4104	MOV SP,R4
 00BE	     5034	ADD #18,R4
 00C0	     0012
 00C2	     4035	MOV #0,R5
 00C4	     0000
 00C6	     12B0	CALL #0
 00C8	     0000
 00CA	     43C1	MOV.B #0,22(SP)
 00CC	     0016
 00CE	     1201	PUSH SP
 00D0	     1211	PUSH 30(SP)
 00D2	     001E
 00D4	     12B0	CALL #0
 00D6	     0000
 00D8	     5221	ADD #4,SP
 00DA	     1211	PUSH 28(SP)
 00DC	     001C
 00DE	     410F	MOV SP,R15
 00E0	     503F	ADD #20,R15
 00E2	     0014
 00E4	     120F	PUSH R15
 00E6	     12B0	CALL #0
 00E8	     0000
 00EA	     5221	ADD #4,SP
 00EC	     930F	CMP #0,R15
 00EE	     200B	JNE $+24, goes to  0106
 00F0	     411F	MOV 26(SP),R15
 00F2	     001A
 00F4	     429F	MOV &0,0(R15)
 00F6	     0000
 00F8	     0000
 00FA	     429F	MOV &0,2(R15)
 00FC	     0000
 00FE	     0002
 0100	     43D1	MOV.B #1,22(SP)
 0102	     0016
 0104	     3C9F	JMP $+320, goes to  0244
 0106	     411F	MOV 26(SP),R15
 0108	     001A
 010A	     410E	MOV SP,R14
 010C	     503E	ADD #18,R14
 010E	     0012
 0110	     432D	MOV #2,R13
 0112	     4FBE	MOV @R15+,0(R14)
 0114	     0000
 0116	     532E	ADD #2,R14
 0118	     831D	SUB #1,R13
 011A	     23FB	JNE $-8, goes to  0112
 011C	     411F	MOV 30(SP),R15
 011E	     001E
 0120	     93FF	CMP.B #-1,0(R15)
 0122	     0000
 0124	     2406	JEQ $+14, goes to  0132
 0126	     411E	MOV 30(SP),R14
 0128	     001E
 012A	     4E6F	MOV.B @R14,R15
 012C	     911F	CMP 2(SP),R15
 012E	     0002
 0130	     2032	JNE $+102, goes to  0196
 0132	     411F	MOV 30(SP),R15
 0134	     001E
 0136	     93FF	CMP.B #-1,1(R15)
 0138	     0001
 013A	     2407	JEQ $+16, goes to  014A
 013C	     411E	MOV 30(SP),R14
 013E	     001E
 0140	     4E5F	MOV.B 1(R14),R15
 0142	     0001
 0144	     911F	CMP 4(SP),R15
 0146	     0004
 0148	     2026	JNE $+78, goes to  0196
 014A	     411F	MOV 30(SP),R15
 014C	     001E
 014E	     93FF	CMP.B #-1,2(R15)
 0150	     0002
 0152	     2407	JEQ $+16, goes to  0162
 0154	     411E	MOV 30(SP),R14
 0156	     001E
 0158	     4E5F	MOV.B 2(R14),R15
 015A	     0002
 015C	     911F	CMP 6(SP),R15
 015E	     0006
 0160	     201A	JNE $+54, goes to  0196
 0162	     411F	MOV 30(SP),R15
 0164	     001E
 0166	     93FF	CMP.B #-1,3(R15)
 0168	     0003
 016A	     2407	JEQ $+16, goes to  017A
 016C	     411E	MOV 30(SP),R14
 016E	     001E
 0170	     4E5F	MOV.B 3(R14),R15
 0172	     0003
 0174	     911F	CMP 8(SP),R15
 0176	     0008
 0178	     200E	JNE $+30, goes to  0196
 017A	     411F	MOV 30(SP),R15
 017C	     001E
 017E	     93FF	CMP.B #-1,4(R15)
 0180	     0004
 0182	     2414	JEQ $+42, goes to  01AC
 0184	     411E	MOV 30(SP),R14
 0186	     001E
 0188	     4E5F	MOV.B 4(R14),R15
 018A	     0004
 018C	     507F	ADD.B #70,R15
 018E	     0046
 0190	     911F	CMP 10(SP),R15
 0192	     000A
 0194	     240B	JEQ $+24, goes to  01AC
 0196	     411F	MOV 26(SP),R15
 0198	     001A
 019A	     429F	MOV &247,0(R15)
 019C	     00F7
 019E	     0000
 01A0	     429F	MOV &253,2(R15)
 01A2	     00FD
 01A4	     0002
 01A6	     43D1	MOV.B #1,22(SP)
 01A8	     0016
 01AA	     3C4C	JMP $+154, goes to  0244
 01AC	     411F	MOV 12(SP),R15
 01AE	     000C
 01B0	     411D	MOV 30(SP),R13
 01B2	     001E
 01B4	     4D1E	MOV 5(R13),R14
 01B6	     0005
 01B8	     531F	ADD #1,R15
 01BA	     831F	SUB #1,R15
 01BC	     2402	JEQ $+6, goes to  01C2
 01BE	     100E	RRC R14
 01C0	     3FFC	JMP $-6, goes to  01BA
 01C2	     B31E	BIT #1,R14
 01C4	     240D	JEQ $+28, goes to  01E0
 01C6	     1211	PUSH 28(SP)
 01C8	     001C
 01CA	     1211	PUSH 32(SP)
 01CC	     0020
 01CE	     12B0	CALL #233
 01D0	     00E9
 01D2	     5221	ADD #4,SP
 01D4	     430E	MOV #0,R14
 01D6	     9F0E	CMP R15,R14
 01D8	     3403	JGE $+8, goes to  01E0
 01DA	     43D1	MOV.B #1,22(SP)
 01DC	     0016
 01DE	     3C32	JMP $+102, goes to  0244
 01E0	     411F	MOV 30(SP),R15
 01E2	     001E
 01E4	     93FF	CMP.B #-1,0(R15)
 01E6	     0000
 01E8	     2003	JNE $+8, goes to  01F0
 01EA	     5391	ADD #1,2(SP)
 01EC	     0002
 01EE	     3C2A	JMP $+86, goes to  0244
 01F0	     411F	MOV 30(SP),R15
 01F2	     001E
 01F4	     93FF	CMP.B #-1,1(R15)
 01F6	     0001
 01F8	     2003	JNE $+8, goes to  0200
 01FA	     5391	ADD #1,4(SP)
 01FC	     0004
 01FE	     3C22	JMP $+70, goes to  0244
 0200	     411F	MOV 30(SP),R15
 0202	     001E
 0204	     93FF	CMP.B #-1,2(R15)
 0206	     0002
 0208	     2003	JNE $+8, goes to  0210
 020A	     5391	ADD #1,6(SP)
 020C	     0006
 020E	     3C1A	JMP $+54, goes to  0244
 0210	     411F	MOV 30(SP),R15
 0212	     001E
 0214	     93FF	CMP.B #-1,3(R15)
 0216	     0003
 0218	     2003	JNE $+8, goes to  0220
 021A	     5391	ADD #1,8(SP)
 021C	     0008
 021E	     3C12	JMP $+38, goes to  0244
 0220	     411F	MOV 30(SP),R15
 0222	     001E
 0224	     93FF	CMP.B #-1,4(R15)
 0226	     0004
 0228	     2003	JNE $+8, goes to  0230
 022A	     5391	ADD #1,10(SP)
 022C	     000A
 022E	     3C0A	JMP $+22, goes to  0244
 0230	     411F	MOV 26(SP),R15
 0232	     001A
 0234	     429F	MOV &413,0(R15)
 0236	     019D
 0238	     0000
 023A	     429F	MOV &419,2(R15)
 023C	     01A3
 023E	     0002
 0240	     43D1	MOV.B #1,22(SP)
 0242	     0016
 0244	     93C1	CMP.B #0,22(SP)
 0246	     0016
 0248	     2742	JEQ $-378, goes to  00CE
 024A	     5031	ADD #24,SP
 024C	     0018
 024E	     4130	RET
fixups:
 023D	s6.3+2
 0237	s6.3
 01D1	s6.9
 00D7	s6.15
 00C9	s6.12
 00C5	s6.4
 002F	s6.17
 001F	s6.7
 000B	s6.8

section    43	c   86	updateBell
 0000	     8321	SUB #2,SP
 0002	     1223	PUSH #2
 0004	     12B0	CALL #0
 0006	     0000
 0008	     5321	ADD #2,SP
 000A	     120F	PUSH R15
 000C	     1230	PUSH #0
 000E	     0000
 0010	     12B0	CALL #0
 0012	     0000
 0014	     5221	ADD #4,SP
 0016	     930F	CMP #0,R15
 0018	     241C	JEQ $+58, goes to  0052
 001A	     4144	MOV.B SP,R4
 001C	     4105	MOV SP,R5
 001E	     5315	ADD #1,R5
 0020	     12B0	CALL #0
 0022	     0000
 0024	     1230	PUSH #78
 0026	     004E
 0028	     1203	PUSH #0
 002A	     12B0	CALL #0
 002C	     0000
 002E	     5221	ADD #4,SP
 0030	     1270	PUSH.B #136
 0032	     0088
 0034	     12B0	CALL #0
 0036	     0000
 0038	     5321	ADD #2,SP
 003A	     1270	PUSH.B #32
 003C	     0020
 003E	     12B0	CALL #55
 0040	     0037
 0042	     5321	ADD #2,SP
 0044	     1251	PUSH.B 2(SP)
 0046	     0002
 0048	     1251	PUSH.B 5(SP)
 004A	     0005
 004C	     12B0	CALL #45
 004E	     002D
 0050	     5221	ADD #4,SP
 0052	     5321	ADD #2,SP
 0054	     4130	RET
fixups:
 0041	s8.6
 004F	s8.8
 0023	s8.9
 0013	s6.9
 000F	s6.3
 0007	s0.41

section    44	c   46	popEvent
 0000	     4345	MOV.B #0,R5
 0002	     9255	CMP.B &0,R5
 0004	     0000
 0006	     2C12	JC $+38, goes to  002C
 0008	     4314	MOV #1,R4
 000A	     4255	MOV.B &5,R5
 000C	     0005
 000E	     8355	SUB.B #1,R5
 0010	     9445	CMP.B R4,R5
 0012	     380A	JL $+22, goes to  0028
 0014	     4405	MOV R4,R5
 0016	     8315	SUB #1,R5
 0018	     5505	ADD R5,R5
 001A	     4406	MOV R4,R6
 001C	     5606	ADD R6,R6
 001E	     4695	MOV 0(R6),33(R5)
 0020	     0000
 0022	     0021
 0024	     5314	ADD #1,R4
 0026	     3FF1	JMP $-28, goes to  000A
 0028	     83D2	SUB.B #1,&13
 002A	     000D
 002C	     4130	RET
fixups:
 0023	s0.6
 002B	s0.6+10

section    45	c  268	findNextDiaryEvent
 0000	     8031	SUB #14,SP
 0002	     000E
 0004	     411F	MOV 16(SP),R15
 0006	     0010
 0008	     429F	MOV &0,0(R15)
 000A	     0000
 000C	     0000
 000E	     429F	MOV &0,2(R15)
 0010	     0000
 0012	     0002
 0014	     40B1	MOV #79,8(SP)
 0016	     004F
 0018	     0008
 001A	     40B1	MOV #-15360,10(SP)
 001C	     C400
 001E	     000A
 0020	     4104	MOV SP,R4
 0022	     5224	ADD #4,R4
 0024	     12B0	CALL #0
 0026	     0000
 0028	     410F	MOV SP,R15
 002A	     522F	ADD #4,R15
 002C	     120F	PUSH R15
 002E	     1230	PUSH #0
 0030	     0000
 0032	     12B0	CALL #0
 0034	     0000
 0036	     5221	ADD #4,SP
 0038	     930F	CMP #0,R15
 003A	     240C	JEQ $+26, goes to  0054
 003C	     4291	MOV &49,4(SP)
 003E	     0031
 0040	     0004
 0042	     4291	MOV &0,6(SP)
 0044	     0000
 0046	     0006
 0048	     4104	MOV SP,R4
 004A	     5224	ADD #4,R4
 004C	     4035	MOV #0,R5
 004E	     0000
 0050	     12B0	CALL #0
 0052	     0000
 0054	     411F	MOV 10(SP),R15
 0056	     000A
 0058	     4FE1	MOV.B @R15,12(SP)
 005A	     000C
 005C	     93F1	CMP.B #-1,12(SP)
 005E	     000C
 0060	     244C	JEQ $+154, goes to  00FA
 0062	     93C1	CMP.B #0,12(SP)
 0064	     000C
 0066	     2449	JEQ $+148, goes to  00FA
 0068	     411F	MOV 10(SP),R15
 006A	     000A
 006C	     1230	PUSH #6
 006E	     0006
 0070	     503F	ADD #56,R15
 0072	     0038
 0074	     120F	PUSH R15
 0076	     410F	MOV SP,R15
 0078	     523F	ADD #8,R15
 007A	     120F	PUSH R15
 007C	     410F	MOV SP,R15
 007E	     503F	ADD #6,R15
 0080	     0006
 0082	     120F	PUSH R15
 0084	     12B0	CALL #0
 0086	     0000
 0088	     5231	ADD #8,SP
 008A	     93C1	CMP.B #0,18(SP)
 008C	     0012
 008E	     2416	JEQ $+46, goes to  00BC
 0090	     1201	PUSH SP
 0092	     1230	PUSH #63
 0094	     003F
 0096	     12B0	CALL #53
 0098	     0035
 009A	     5221	ADD #4,SP
 009C	     930F	CMP #0,R15
 009E	     200E	JNE $+30, goes to  00BC
 00A0	     90F2	CMP.B #5,&0
 00A2	     0005
 00A4	     0000
 00A6	     2802	JNC $+6, goes to  00AC
 00A8	     12B0	CALL #0
 00AA	     0000
 00AC	     425F	MOV.B &165,R15
 00AE	     00A5
 00B0	     5F4F	ADD.B R15,R15
 00B2	     419F	MOV 10(SP),0(R15)
 00B4	     000A
 00B6	     0000
 00B8	     53D2	ADD.B #1,&175
 00BA	     00AF
 00BC	     411F	MOV 10(SP),R15
 00BE	     000A
 00C0	     1230	PUSH #6
 00C2	     0006
 00C4	     503F	ADD #56,R15
 00C6	     0038
 00C8	     120F	PUSH R15
 00CA	     1230	PUSH #0
 00CC	     0000
 00CE	     410F	MOV SP,R15
 00D0	     503F	ADD #6,R15
 00D2	     0006
 00D4	     120F	PUSH R15
 00D6	     12B0	CALL #135
 00D8	     0087
 00DA	     5231	ADD #8,SP
 00DC	     1201	PUSH SP
 00DE	     1211	PUSH 20(SP)
 00E0	     0014
 00E2	     12B0	CALL #153
 00E4	     0099
 00E6	     5221	ADD #4,SP
 00E8	     930F	CMP #0,R15
 00EA	     3407	JGE $+16, goes to  00FA
 00EC	     411F	MOV 16(SP),R15
 00EE	     0010
 00F0	     41AF	MOV @SP,0(R15)
 00F2	     0000
 00F4	     419F	MOV 2(SP),2(R15)
 00F6	     0002
 00F8	     0002
 00FA	     50B1	ADD #64,10(SP)
 00FC	     0040
 00FE	     000A
 0100	     8391	SUB #1,8(SP)
 0102	     0008
 0104	     37A7	JGE $-176, goes to  0054
 0106	     5031	ADD #14,SP
 0108	     000E
 010A	     4130	RET
fixups:
 00CD	s6.6
 00B7	s0.6
 00AB	s0.44
 00BB	s0.6+10
 00D9	s0.42
 0053	s6.12
 004F	s6.4
 0045	s0.11+2
 00E5	s6.9
 0095	s0.11
 0027	s6.8
 0011	s6.3+2
 000B	s6.3

section    46	c   40	findAndArmNextDiaryEvent
 0000	     8221	SUB #4,SP
 0002	     1251	PUSH.B 8(SP)
 0004	     0008
 0006	     410F	MOV SP,R15
 0008	     532F	ADD #2,R15
 000A	     120F	PUSH R15
 000C	     12B0	CALL #0
 000E	     0000
 0010	     5221	ADD #4,SP
 0012	     1223	PUSH #2
 0014	     410F	MOV SP,R15
 0016	     532F	ADD #2,R15
 0018	     120F	PUSH R15
 001A	     12B0	CALL #0
 001C	     0000
 001E	     5221	ADD #4,SP
 0020	     12B0	CALL #0
 0022	     0000
 0024	     5221	ADD #4,SP
 0026	     4130	RET
fixups:
 0023	s0.43
 001D	s0.40
 000F	s0.45

section    47	c   68	eraseAllDiaryEvents
 0000	     8321	SUB #2,SP
 0002	     40B1	MOV #-15360,0(SP)
 0004	     C400
 0006	     0000
 0008	     40B2	MOV #-23296,&300
 000A	     A500
 000C	     012C
 000E	     90B1	CMP #-10240,0(SP)
 0010	     D800
 0012	     0000
 0014	     240A	JEQ $+22, goes to  002A
 0016	     40B2	MOV #-23294,&296
 0018	     A502
 001A	     0128
 001C	     412F	MOV @SP,R15
 001E	     438F	MOV #0,0(R15)
 0020	     0000
 0022	     50B1	ADD #512,0(SP)
 0024	     0200
 0026	     0000
 0028	     3FF2	JMP $-26, goes to  000E
 002A	     40B2	MOV #-23280,&300
 002C	     A510
 002E	     012C
 0030	     1223	PUSH #2
 0032	     1230	PUSH #0
 0034	     0000
 0036	     12B0	CALL #0
 0038	     0000
 003A	     5221	ADD #4,SP
 003C	     12B0	CALL #0
 003E	     0000
 0040	     5321	ADD #2,SP
 0042	     4130	RET
fixups:
 003F	s0.38
 0039	s0.40
 0035	s6.3

section    48	c  162	deleteDiaryEvent
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     90B1	CMP #80,8(SP)
 0006	     0050
 0008	     0008
 000A	     3448	JGE $+146, goes to  009C
 000C	     40B1	MOV #-15360,4(SP)
 000E	     C400
 0010	     0004
 0012	     411F	MOV 8(SP),R15
 0014	     0008
 0016	     5F0F	ADD R15,R15
 0018	     5F0F	ADD R15,R15
 001A	     5F0F	ADD R15,R15
 001C	     5F0F	ADD R15,R15
 001E	     5F0F	ADD R15,R15
 0020	     5F0F	ADD R15,R15
 0022	     5F81	ADD R15,4(SP)
 0024	     0004
 0026	     411F	MOV 4(SP),R15
 0028	     0004
 002A	     93FF	CMP.B #-1,0(R15)
 002C	     0000
 002E	     2436	JEQ $+110, goes to  009C
 0030	     411F	MOV 4(SP),R15
 0032	     0004
 0034	     93CF	CMP.B #0,0(R15)
 0036	     0000
 0038	     2431	JEQ $+100, goes to  009C
 003A	     40B2	MOV #-23296,&300
 003C	     A500
 003E	     012C
 0040	     40B2	MOV #-23232,&296
 0042	     A540
 0044	     0128
 0046	     411F	MOV 4(SP),R15
 0048	     0004
 004A	     43CF	MOV.B #0,0(R15)
 004C	     0000
 004E	     40B2	MOV #-23296,&296
 0050	     A500
 0052	     0128
 0054	     40B2	MOV #-23280,&300
 0056	     A510
 0058	     012C
 005A	     4381	MOV #0,0(SP)
 005C	     0000
 005E	     4381	MOV #0,2(SP)
 0060	     0002
 0062	     425F	MOV.B &0,R15
 0064	     0000
 0066	     835F	SUB.B #1,R15
 0068	     915F	CMP.B 2(SP),R15
 006A	     0002
 006C	     3817	JL $+48, goes to  009C
 006E	     412F	MOV @SP,R15
 0070	     5F0F	ADD R15,R15
 0072	     411E	MOV 2(SP),R14
 0074	     0002
 0076	     5E0E	ADD R14,R14
 0078	     4E9F	MOV 0(R14),123(R15)
 007A	     0000
 007C	     007B
 007E	     411F	MOV 2(SP),R15
 0080	     0002
 0082	     5F0F	ADD R15,R15
 0084	     9F91	CMP 125(R15),4(SP)
 0086	     007D
 0088	     0004
 008A	     2003	JNE $+8, goes to  0092
 008C	     83D2	SUB.B #1,&101
 008E	     0065
 0090	     3C02	JMP $+6, goes to  0096
 0092	     5391	ADD #1,0(SP)
 0094	     0000
 0096	     5391	ADD #1,2(SP)
 0098	     0002
 009A	     3FE3	JMP $-56, goes to  0062
 009C	     5031	ADD #6,SP
 009E	     0006
 00A0	     4130	RET
fixups:
 0087	s0.6
 008F	s0.6+10

section    49	c   84	createDiaryEvent
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     43B1	MOV #-1,0(SP)
 0006	     0000
 0008	     40B1	MOV #79,2(SP)
 000A	     004F
 000C	     0002
 000E	     40B1	MOV #-15360,4(SP)
 0010	     C400
 0012	     0004
 0014	     411F	MOV 4(SP),R15
 0016	     0004
 0018	     93FF	CMP.B #-1,0(R15)
 001A	     0000
 001C	     200E	JNE $+30, goes to  003A
 001E	     4034	MOV #0,R4
 0020	     0000
 0022	     4115	MOV 4(SP),R5
 0024	     0004
 0026	     4036	MOV #64,R6
 0028	     0040
 002A	     12B0	CALL #512
 002C	     0200
 002E	     1243	PUSH.B #0
 0030	     12B0	CALL #0
 0032	     0000
 0034	     5321	ADD #2,SP
 0036	     12B0	CALL #0
 0038	     0000
 003A	     50B1	ADD #64,4(SP)
 003C	     0040
 003E	     0004
 0040	     8391	SUB #1,2(SP)
 0042	     0002
 0044	     3803	JL $+8, goes to  004C
 0046	     93B1	CMP #-1,0(SP)
 0048	     0000
 004A	     27E4	JEQ $-54, goes to  0014
 004C	     412F	MOV @SP,R15
 004E	     5031	ADD #6,SP
 0050	     0006
 0052	     4130	RET
fixups:
 0039	s0.38
 0033	s0.46
 0021	s0.5

section    50	c   12	prompt
 0000	     1230	PUSH #0
 0002	     0000
 0004	     12B0	CALL #0
 0006	     0000
 0008	     5321	ADD #2,SP
 000A	     4130	RET
fixups:
 0007	s0.34
 0003	s0.0

section    51	c   44	respondI
 0000	     8031	SUB #12,SP
 0002	     000C
 0004	     1211	PUSH 18(SP)
 0006	     0012
 0008	     1211	PUSH 18(SP)
 000A	     0012
 000C	     1230	PUSH #12
 000E	     000C
 0010	     410F	MOV SP,R15
 0012	     503F	ADD #6,R15
 0014	     0006
 0016	     120F	PUSH R15
 0018	     12B0	CALL #0
 001A	     0000
 001C	     5231	ADD #8,SP
 001E	     1201	PUSH SP
 0020	     12B0	CALL #0
 0022	     0000
 0024	     5321	ADD #2,SP
 0026	     5031	ADD #12,SP
 0028	     000C
 002A	     4130	RET
fixups:
 0023	s0.34
 001B	s5.2

section    52	c   48	respondUL
 0000	     8031	SUB #12,SP
 0002	     000C
 0004	     1211	PUSH 20(SP)
 0006	     0014
 0008	     1211	PUSH 20(SP)
 000A	     0014
 000C	     1211	PUSH 20(SP)
 000E	     0014
 0010	     1230	PUSH #12
 0012	     000C
 0014	     410F	MOV SP,R15
 0016	     523F	ADD #8,R15
 0018	     120F	PUSH R15
 001A	     12B0	CALL #0
 001C	     0000
 001E	     5031	ADD #10,SP
 0020	     000A
 0022	     1201	PUSH SP
 0024	     12B0	CALL #0
 0026	     0000
 0028	     5321	ADD #2,SP
 002A	     5031	ADD #12,SP
 002C	     000C
 002E	     4130	RET
fixups:
 0027	s0.34
 001D	s5.1

section    53	c   44	respondT
 0000	     8031	SUB #12,SP
 0002	     000C
 0004	     1211	PUSH 18(SP)
 0006	     0012
 0008	     1211	PUSH 18(SP)
 000A	     0012
 000C	     1230	PUSH #12
 000E	     000C
 0010	     410F	MOV SP,R15
 0012	     503F	ADD #6,R15
 0014	     0006
 0016	     120F	PUSH R15
 0018	     12B0	CALL #0
 001A	     0000
 001C	     5231	ADD #8,SP
 001E	     1201	PUSH SP
 0020	     12B0	CALL #0
 0022	     0000
 0024	     5321	ADD #2,SP
 0026	     5031	ADD #12,SP
 0028	     000C
 002A	     4130	RET
fixups:
 0023	s0.34
 001B	s6.19

section    54	c 1228	parseCommand
 0000	     93C2	CMP.B #0,&0
 0002	     0000
 0004	     2262	JNE $-826, goes to  FFFFFCCA
 0006	     90B1	CMP #256,2(SP)
 0008	     0100
 000A	     0002
 000C	     3806	JL $+14, goes to  001A
 000E	     40B2	MOV #9,&0
 0010	     0009
 0012	     0000
 0014	     12B0	CALL #0
 0016	     0000
 0018	     3E58	JMP $-846, goes to  FFFFFCCA
 001A	     90B1	CMP #13,2(SP)
 001C	     000D
 001E	     0002
 0020	     2074	JNE $+234, goes to  010A
 0022	     92B2	CMP #8,&19
 0024	     0013
 0026	     2004	JNE $+10, goes to  0030
 0028	     90B2	CMP #64,&0
 002A	     0040
 002C	     0000
 002E	     386D	JL $+220, goes to  010A
 0030	     90B2	CMP #5,&37
 0032	     0005
 0034	     0025
 0036	     203E	JNE $+126, goes to  00B4
 0038	     90B2	CMP #14,&45
 003A	     000E
 003C	     002D
 003E	     2039	JNE $+116, goes to  00B2
 0040	     8392	SUB #1,&0
 0042	     0000
 0044	     80B2	SUB #1900,&0
 0046	     076C
 0048	     0000
 004A	     4382	MOV #0,&0
 004C	     0000
 004E	     4382	MOV #0,&0
 0050	     0000
 0052	     4034	MOV #81,R4
 0054	     0051
 0056	     4035	MOV #0,R5
 0058	     0000
 005A	     12B0	CALL #0
 005C	     0000
 005E	     1230	PUSH #85
 0060	     0055
 0062	     12B0	CALL #0
 0064	     0000
 0066	     5321	ADD #2,SP
 0068	     1230	PUSH #0
 006A	     0000
 006C	     1230	PUSH #97
 006E	     0061
 0070	     12B0	CALL #0
 0072	     0000
 0074	     5221	ADD #4,SP
 0076	     1230	PUSH #4
 0078	     0004
 007A	     1230	PUSH #111
 007C	     006F
 007E	     12B0	CALL #0
 0080	     0000
 0082	     5221	ADD #4,SP
 0084	     4292	MOV &89,&125
 0086	     0059
 0088	     007D
 008A	     4292	MOV &0,&77
 008C	     0000
 008E	     004D
 0090	     4034	MOV #0,R4
 0092	     0000
 0094	     12B0	CALL #0
 0096	     0000
 0098	     1243	PUSH.B #0
 009A	     12B0	CALL #0
 009C	     0000
 009E	     5321	ADD #2,SP
 00A0	     43C2	MOV.B #0,&0
 00A2	     0000
 00A4	     1230	PUSH #135
 00A6	     0087
 00A8	     12B0	CALL #101
 00AA	     0065
 00AC	     5321	ADD #2,SP
 00AE	     12B0	CALL #0
 00B0	     0000
 00B2	     3C2A	JMP $+86, goes to  0108
 00B4	     90B2	CMP #3,&53
 00B6	     0003
 00B8	     0035
 00BA	     2003	JNE $+8, goes to  00C2
 00BC	     12B0	CALL #23
 00BE	     0017
 00C0	     3C23	JMP $+72, goes to  0108
 00C2	     90B2	CMP #7,&185
 00C4	     0007
 00C6	     00B9
 00C8	     2006	JNE $+14, goes to  00D6
 00CA	     1212	PUSH &0
 00CC	     0000
 00CE	     12B0	CALL #0
 00D0	     0000
 00D2	     5321	ADD #2,SP
 00D4	     3C19	JMP $+52, goes to  0108
 00D6	     92B2	CMP #8,&199
 00D8	     00C7
 00DA	     2016	JNE $+46, goes to  0108
 00DC	     90B2	CMP #64,&61
 00DE	     0040
 00E0	     003D
 00E2	     200C	JNE $+26, goes to  00FC
 00E4	     12B0	CALL #0
 00E6	     0000
 00E8	     4F82	MOV R15,&205
 00EA	     00CD
 00EC	     1212	PUSH &235
 00EE	     00EB
 00F0	     1230	PUSH #4
 00F2	     0004
 00F4	     12B0	CALL #0
 00F6	     0000
 00F8	     5221	ADD #4,SP
 00FA	     3C02	JMP $+6, goes to  0100
 00FC	     12B0	CALL #191
 00FE	     00BF
 0100	     4382	MOV #0,&217
 0102	     00D9
 0104	     12B0	CALL #0
 0106	     0000
 0108	     3DE0	JMP $+962, goes to  04CA
 010A	     9382	CMP #0,&259
 010C	     0103
 010E	     2127	JNE $+592, goes to  035E
 0110	     90B1	CMP #97,2(SP)
 0112	     0061
 0114	     0002
 0116	     2003	JNE $+8, goes to  011E
 0118	     42A2	MOV #4,&269
 011A	     010D
 011C	     3D1F	JMP $+576, goes to  035C
 011E	     90B1	CMP #98,2(SP)
 0120	     0062
 0122	     0002
 0124	     2003	JNE $+8, goes to  012C
 0126	     43A2	MOV #2,&283
 0128	     011B
 012A	     3D18	JMP $+562, goes to  035C
 012C	     90B1	CMP #99,2(SP)
 012E	     0063
 0130	     0002
 0132	     2005	JNE $+12, goes to  013E
 0134	     42B2	MOV #8,&297
 0136	     0129
 0138	     4382	MOV #0,&225
 013A	     00E1
 013C	     3D0F	JMP $+544, goes to  035C
 013E	     90B1	CMP #100,2(SP)
 0140	     0064
 0142	     0002
 0144	     2404	JEQ $+10, goes to  014E
 0146	     90B1	CMP #117,2(SP)
 0148	     0075
 014A	     0002
 014C	     201B	JNE $+56, goes to  0184
 014E	     40B2	MOV #5,&311
 0150	     0005
 0152	     0137
 0154	     90B1	CMP #100,2(SP)
 0156	     0064
 0158	     0002
 015A	     2002	JNE $+6, goes to  0160
 015C	     431F	MOV #1,R15
 015E	     3C01	JMP $+4, goes to  0162
 0160	     430F	MOV #0,R15
 0162	     4FC2	MOV.B R15,&0
 0164	     0000
 0166	     4382	MOV #0,&0
 0168	     0000
 016A	     4382	MOV #0,&67
 016C	     0043
 016E	     4382	MOV #0,&73
 0170	     0049
 0172	     4382	MOV #0,&0
 0174	     0000
 0176	     4382	MOV #0,&0
 0178	     0000
 017A	     4382	MOV #0,&107
 017C	     006B
 017E	     4382	MOV #0,&315
 0180	     013B
 0182	     3CEC	JMP $+474, goes to  035C
 0184	     90B1	CMP #101,2(SP)
 0186	     0065
 0188	     0002
 018A	     2003	JNE $+8, goes to  0192
 018C	     43D2	MOV.B #1,&3
 018E	     0003
 0190	     3CE5	JMP $+460, goes to  035C
 0192	     90B1	CMP #105,2(SP)
 0194	     0069
 0196	     0002
 0198	     2094	JNE $+298, goes to  02C2
 019A	     1230	PUSH #0
 019C	     0000
 019E	     12B0	CALL #0
 01A0	     0000
 01A2	     5321	ADD #2,SP
 01A4	     1230	PUSH #0
 01A6	     0000
 01A8	     12B0	CALL #417
 01AA	     01A1
 01AC	     5321	ADD #2,SP
 01AE	     1230	PUSH #167
 01B0	     00A7
 01B2	     1230	PUSH #11
 01B4	     000B
 01B6	     12B0	CALL #0
 01B8	     0000
 01BA	     5221	ADD #4,SP
 01BC	     1230	PUSH #0
 01BE	     0000
 01C0	     12B0	CALL #427
 01C2	     01AB
 01C4	     5321	ADD #2,SP
 01C6	     12B0	CALL #0
 01C8	     0000
 01CA	     1204	PUSH R4
 01CC	     1230	PUSH #5
 01CE	     0005
 01D0	     12B0	CALL #247
 01D2	     00F7
 01D4	     5221	ADD #4,SP
 01D6	     4074	MOV.B #47,R4
 01D8	     002F
 01DA	     12B0	CALL #0
 01DC	     0000
 01DE	     1203	PUSH #0
 01E0	     1230	PUSH #80
 01E2	     0050
 01E4	     1230	PUSH #4
 01E6	     0004
 01E8	     12B0	CALL #0
 01EA	     0000
 01EC	     5031	ADD #6,SP
 01EE	     0006
 01F0	     1230	PUSH #0
 01F2	     0000
 01F4	     12B0	CALL #451
 01F6	     01C3
 01F8	     5321	ADD #2,SP
 01FA	     1212	PUSH &0
 01FC	     0000
 01FE	     1230	PUSH #5
 0200	     0005
 0202	     12B0	CALL #467
 0204	     01D3
 0206	     5221	ADD #4,SP
 0208	     1230	PUSH #0
 020A	     0000
 020C	     12B0	CALL #503
 020E	     01F7
 0210	     5321	ADD #2,SP
 0212	     1230	PUSH #0
 0214	     0000
 0216	     12B0	CALL #527
 0218	     020F
 021A	     5321	ADD #2,SP
 021C	     425F	MOV.B &0,R15
 021E	     0000
 0220	     120F	PUSH R15
 0222	     1230	PUSH #4
 0224	     0004
 0226	     12B0	CALL #517
 0228	     0205
 022A	     5221	ADD #4,SP
 022C	     1230	PUSH #0
 022E	     0000
 0230	     12B0	CALL #537
 0232	     0219
 0234	     5321	ADD #2,SP
 0236	     1223	PUSH #2
 0238	     12B0	CALL #0
 023A	     0000
 023C	     5321	ADD #2,SP
 023E	     120F	PUSH R15
 0240	     1230	PUSH #0
 0242	     0000
 0244	     12B0	CALL #0
 0246	     0000
 0248	     5221	ADD #4,SP
 024A	     120F	PUSH R15
 024C	     1223	PUSH #2
 024E	     12B0	CALL #553
 0250	     0229
 0252	     5221	ADD #4,SP
 0254	     1230	PUSH #0
 0256	     0000
 0258	     12B0	CALL #563
 025A	     0233
 025C	     5321	ADD #2,SP
 025E	     1230	PUSH #137
 0260	     0089
 0262	     1230	PUSH #11
 0264	     000B
 0266	     12B0	CALL #441
 0268	     01B9
 026A	     5221	ADD #4,SP
 026C	     1230	PUSH #0
 026E	     0000
 0270	     12B0	CALL #603
 0272	     025B
 0274	     5321	ADD #2,SP
 0276	     1203	PUSH #0
 0278	     1212	PUSH &0
 027A	     0000
 027C	     1230	PUSH #6
 027E	     0006
 0280	     12B0	CALL #491
 0282	     01EB
 0284	     5031	ADD #6,SP
 0286	     0006
 0288	     1230	PUSH #0
 028A	     0000
 028C	     12B0	CALL #627
 028E	     0273
 0290	     5321	ADD #2,SP
 0292	     425F	MOV.B &0,R15
 0294	     0000
 0296	     120F	PUSH R15
 0298	     1230	PUSH #5
 029A	     0005
 029C	     12B0	CALL #593
 029E	     0251
 02A0	     5221	ADD #4,SP
 02A2	     1230	PUSH #0
 02A4	     0000
 02A6	     12B0	CALL #655
 02A8	     028F
 02AA	     5321	ADD #2,SP
 02AC	     425F	MOV.B &0,R15
 02AE	     0000
 02B0	     120F	PUSH R15
 02B2	     1230	PUSH #4
 02B4	     0004
 02B6	     12B0	CALL #671
 02B8	     029F
 02BA	     5221	ADD #4,SP
 02BC	     12B0	CALL #263
 02BE	     0107
 02C0	     3C4D	JMP $+156, goes to  035C
 02C2	     90B1	CMP #114,2(SP)
 02C4	     0072
 02C6	     0002
 02C8	     2006	JNE $+14, goes to  02D6
 02CA	     40B2	MOV #7,&339
 02CC	     0007
 02CE	     0153
 02D0	     4382	MOV #0,&239
 02D2	     00EF
 02D4	     3C43	JMP $+136, goes to  035C
 02D6	     90B1	CMP #118,2(SP)
 02D8	     0076
 02DA	     0002
 02DC	     200D	JNE $+28, goes to  02F8
 02DE	     C2E2	BIC.B #4,&41
 02E0	     0029
 02E2	     4034	MOV #3333,R4
 02E4	     0D05
 02E6	     12B0	CALL #0
 02E8	     0000
 02EA	     D2E2	BIS.B #4,&41
 02EC	     0029
 02EE	     12B0	CALL #0
 02F0	     0000
 02F2	     12B0	CALL #0
 02F4	     0000
 02F6	     3C32	JMP $+102, goes to  035C
 02F8	     90B1	CMP #119,2(SP)
 02FA	     0077
 02FC	     0002
 02FE	     201C	JNE $+58, goes to  0338
 0300	     1230	PUSH #0
 0302	     0000
 0304	     12B0	CALL #681
 0306	     02A9
 0308	     5321	ADD #2,SP
 030A	     425F	MOV.B &0,R15
 030C	     0000
 030E	     120F	PUSH R15
 0310	     1230	PUSH #4
 0312	     0004
 0314	     12B0	CALL #697
 0316	     02B9
 0318	     5221	ADD #4,SP
 031A	     1230	PUSH #0
 031C	     0000
 031E	     12B0	CALL #775
 0320	     0307
 0322	     5321	ADD #2,SP
 0324	     1230	PUSH #0
 0326	     0000
 0328	     1230	PUSH #11
 032A	     000B
 032C	     12B0	CALL #617
 032E	     0269
 0330	     5221	ADD #4,SP
 0332	     12B0	CALL #703
 0334	     02BF
 0336	     3C12	JMP $+38, goes to  035C
 0338	     90B1	CMP #122,2(SP)
 033A	     007A
 033C	     0002
 033E	     2005	JNE $+12, goes to  034A
 0340	     12B0	CALL #0
 0342	     0000
 0344	     12B0	CALL #821
 0346	     0335
 0348	     3C09	JMP $+20, goes to  035C
 034A	     90B1	CMP #64,2(SP)
 034C	     0040
 034E	     0002
 0350	     2003	JNE $+8, goes to  0358
 0352	     4382	MOV #0,&288
 0354	     0120
 0356	     3C02	JMP $+6, goes to  035C
 0358	     12B0	CALL #255
 035A	     00FF
 035C	     3CB6	JMP $+366, goes to  04CA
 035E	     93A2	CMP #2,&719
 0360	     02CF
 0362	     201E	JNE $+62, goes to  03A0
 0364	     4154	MOV.B 2(SP),R4
 0366	     0002
 0368	     12B0	CALL #477
 036A	     01DD
 036C	     90B1	CMP #67,2(SP)
 036E	     0043
 0370	     0002
 0372	     2003	JNE $+8, goes to  037A
 0374	     4382	MOV #0,&0
 0376	     0000
 0378	     3C12	JMP $+38, goes to  039E
 037A	     90B1	CMP #68,2(SP)
 037C	     0044
 037E	     0002
 0380	     2004	JNE $+10, goes to  038A
 0382	     40B2	MOV #256,&887
 0384	     0100
 0386	     0377
 0388	     3C0A	JMP $+22, goes to  039E
 038A	     4382	MOV #0,&385
 038C	     0181
 038E	     1211	PUSH 4(SP)
 0390	     0004
 0392	     12B0	CALL #0
 0394	     0000
 0396	     5321	ADD #2,SP
 0398	     40B2	MOV #3,&865
 039A	     0003
 039C	     0361
 039E	     3C95	JMP $+300, goes to  04CA
 03A0	     90B2	CMP #3,&925
 03A2	     0003
 03A4	     039D
 03A6	     2020	JNE $+66, goes to  03E8
 03A8	     4154	MOV.B 2(SP),R4
 03AA	     0002
 03AC	     12B0	CALL #875
 03AE	     036B
 03B0	     5292	ADD &909,&947
 03B2	     038D
 03B4	     03B3
 03B6	     5292	ADD &949,&953
 03B8	     03B5
 03BA	     03B9
 03BC	     5292	ADD &955,&959
 03BE	     03BB
 03C0	     03BF
 03C2	     5292	ADD &961,&965
 03C4	     03C1
 03C6	     03C5
 03C8	     1211	PUSH 4(SP)
 03CA	     0004
 03CC	     12B0	CALL #917
 03CE	     0395
 03D0	     5321	ADD #2,SP
 03D2	     421F	MOV &903,R15
 03D4	     0387
 03D6	     D21F	BIS &967,R15
 03D8	     03C7
 03DA	     120F	PUSH R15
 03DC	     12B0	CALL #0
 03DE	     0000
 03E0	     5321	ADD #2,SP
 03E2	     43A2	MOV #2,&933
 03E4	     03A5
 03E6	     3C71	JMP $+228, goes to  04CA
 03E8	     92A2	CMP #4,&997
 03EA	     03E5
 03EC	     2006	JNE $+14, goes to  03FA
 03EE	     1251	PUSH.B 4(SP)
 03F0	     0004
 03F2	     12B0	CALL #0
 03F4	     0000
 03F6	     5321	ADD #2,SP
 03F8	     3C68	JMP $+210, goes to  04CA
 03FA	     90B2	CMP #7,&1003
 03FC	     0007
 03FE	     03EB
 0400	     2008	JNE $+18, goes to  0412
 0402	     1230	PUSH #723
 0404	     02D3
 0406	     1251	PUSH.B 6(SP)
 0408	     0006
 040A	     12B0	CALL #0
 040C	     0000
 040E	     5221	ADD #4,SP
 0410	     3C5C	JMP $+186, goes to  04CA
 0412	     92B2	CMP #8,&1023
 0414	     03FF
 0416	     2011	JNE $+36, goes to  043A
 0418	     90B2	CMP #64,&985
 041A	     0040
 041C	     03D9
 041E	     340A	JGE $+22, goes to  0434
 0420	     403F	MOV #0,R15
 0422	     0000
 0424	     521F	ADD &1053,R15
 0426	     041D
 0428	     41DF	MOV.B 2(SP),0(R15)
 042A	     0002
 042C	     0000
 042E	     5392	ADD #1,&1063
 0430	     0427
 0432	     3C02	JMP $+6, goes to  0438
 0434	     12B0	CALL #859
 0436	     035B
 0438	     3C48	JMP $+146, goes to  04CA
 043A	     90B2	CMP #5,&1045
 043C	     0005
 043E	     0415
 0440	     2044	JNE $+138, goes to  04CA
 0442	     93A2	CMP #2,&1073
 0444	     0431
 0446	     3408	JGE $+18, goes to  0458
 0448	     1230	PUSH #361
 044A	     0169
 044C	     1251	PUSH.B 6(SP)
 044E	     0006
 0450	     12B0	CALL #1037
 0452	     040D
 0454	     5221	ADD #4,SP
 0456	     3C39	JMP $+116, goes to  04CA
 0458	     92A2	CMP #4,&1093
 045A	     0445
 045C	     3408	JGE $+18, goes to  046E
 045E	     1230	PUSH #365
 0460	     016D
 0462	     1251	PUSH.B 6(SP)
 0464	     0006
 0466	     12B0	CALL #1107
 0468	     0453
 046A	     5221	ADD #4,SP
 046C	     3C2E	JMP $+94, goes to  04CA
 046E	     92B2	CMP #8,&1115
 0470	     045B
 0472	     3408	JGE $+18, goes to  0484
 0474	     1230	PUSH #369
 0476	     0171
 0478	     1251	PUSH.B 6(SP)
 047A	     0006
 047C	     12B0	CALL #1129
 047E	     0469
 0480	     5221	ADD #4,SP
 0482	     3C23	JMP $+72, goes to  04CA
 0484	     90B2	CMP #10,&1137
 0486	     000A
 0488	     0471
 048A	     3408	JGE $+18, goes to  049C
 048C	     1230	PUSH #373
 048E	     0175
 0490	     1251	PUSH.B 6(SP)
 0492	     0006
 0494	     12B0	CALL #1151
 0496	     047F
 0498	     5221	ADD #4,SP
 049A	     3C17	JMP $+48, goes to  04CA
 049C	     90B2	CMP #12,&1161
 049E	     000C
 04A0	     0489
 04A2	     3408	JGE $+18, goes to  04B4
 04A4	     1230	PUSH #377
 04A6	     0179
 04A8	     1251	PUSH.B 6(SP)
 04AA	     0006
 04AC	     12B0	CALL #1175
 04AE	     0497
 04B0	     5221	ADD #4,SP
 04B2	     3C0B	JMP $+24, goes to  04CA
 04B4	     90B2	CMP #14,&1185
 04B6	     000E
 04B8	     04A1
 04BA	     3407	JGE $+16, goes to  04CA
 04BC	     1230	PUSH #381
 04BE	     017D
 04C0	     1251	PUSH.B 6(SP)
 04C2	     0006
 04C4	     12B0	CALL #1199
 04C6	     04AF
 04C8	     5221	ADD #4,SP
 04CA	     4130	RET
fixups:
 0423	s0.5
 04C7	s0.36
 03F5	s8.6
 03DF	s8.5
 03CF	s0.37
 03D5	s0.22
 0343	s0.47
 0327	s0.11
 031D	s0.66
 030D	s0.12
 0303	s0.65
 02F5	s8.11
 02F1	s8.10
 02E9	s9.1
 02AF	s0.16
 02A5	s0.64
 0295	s0.15
 028B	s0.63
 027B	s0.17
 026F	s0.62
 0257	s0.61
 0247	s6.9
 0243	s6.3
 023B	s0.41
 022F	s0.60
 021F	s8.3
 0215	s0.59
 020B	s0.58
 01FD	s0.13
 01F3	s0.57
 0283	s0.52
 03AF	s0.33
 01C9	s0.32
 01BF	s0.56
 032F	s0.53
 01A7	s0.55
 0321	s0.34
 019D	s0.2
 04A7	s0.20+2
 048F	s0.20+4
 044B	s0.20+6
 0165	s0.20+16
 0347	s0.50
 0317	s0.51
 00E7	s0.49
 00D1	s0.48
 0405	s0.19
 00B1	s0.38
 00A3	s0.6+10
 009D	s0.46
 0097	s6.7
 0093	s0.10
 008D	s6.6+2
 0081	s0.40
 0073	s6.18
 04BF	s0.20
 00AB	s0.39
 005D	s6.12
 01B1	s6.6
 0261	s0.21
 008F	s0.21+2
 0477	s0.20+10
 0461	s0.20+8
 04B9	s0.23
 0437	s0.35
 043F	s0.18
 018F	s0.9

section    55	s    4	
|t=|
fixups:

section    56	s    6	
|sf=||
fixups:

section    57	s    4	
|v=|
fixups:

section    58	s    4	
mV||
fixups:

section    59	s    6	
|Vop=|
fixups:

section    60	s    8	
|Bell=||
fixups:

section    61	s    6	
|st=||
fixups:

section    62	s    6	
|bf=||
fixups:

section    63	s    6	
|ec=||
fixups:

section    64	s    6	
|tp=||
fixups:

section    65	s    6	
type=|
fixups:

section    66	s    8	
, time=|
fixups:

section    67	c  100	setVcc
 0000	     8321	SUB #2,SP
 0002	     4144	MOV.B SP,R4
 0004	     4105	MOV SP,R5
 0006	     5315	ADD #1,R5
 0008	     12B0	CALL #0
 000A	     0000
 000C	     1203	PUSH #0
 000E	     1203	PUSH #0
 0010	     12B0	CALL #0
 0012	     0000
 0014	     5221	ADD #4,SP
 0016	     90B2	CMP #2750,&0
 0018	     0ABE
 001A	     0000
 001C	     3806	JL $+14, goes to  002A
 001E	     1270	PUSH.B #135
 0020	     0087
 0022	     12B0	CALL #0
 0024	     0000
 0026	     5321	ADD #2,SP
 0028	     3C0F	JMP $+32, goes to  0048
 002A	     90B2	CMP #2500,&27
 002C	     09C4
 002E	     001B
 0030	     3806	JL $+14, goes to  003E
 0032	     1270	PUSH.B #134
 0034	     0086
 0036	     12B0	CALL #37
 0038	     0025
 003A	     5321	ADD #2,SP
 003C	     3C05	JMP $+12, goes to  0048
 003E	     1270	PUSH.B #133
 0040	     0085
 0042	     12B0	CALL #57
 0044	     0039
 0046	     5321	ADD #2,SP
 0048	     1270	PUSH.B #32
 004A	     0020
 004C	     12B0	CALL #69
 004E	     0045
 0050	     5321	ADD #2,SP
 0052	     1251	PUSH.B 2(SP)
 0054	     0002
 0056	     1251	PUSH.B 5(SP)
 0058	     0005
 005A	     12B0	CALL #19
 005C	     0013
 005E	     5221	ADD #4,SP
 0060	     5321	ADD #2,SP
 0062	     4130	RET
fixups:
 004F	s8.6
 002F	s0.13
 005D	s8.8
 000B	s8.9

section    68	c  370	displayTime
 0000	     8031	SUB #24,SP
 0002	     0018
 0004	     4291	MOV &0,2(SP)
 0006	     0000
 0008	     0002
 000A	     4291	MOV &0,4(SP)
 000C	     0000
 000E	     0004
 0010	     4104	MOV SP,R4
 0012	     5324	ADD #2,R4
 0014	     4035	MOV #0,R5
 0016	     0000
 0018	     12B0	CALL #0
 001A	     0000
 001C	     410F	MOV SP,R15
 001E	     532F	ADD #2,R15
 0020	     120F	PUSH R15
 0022	     410F	MOV SP,R15
 0024	     523F	ADD #8,R15
 0026	     120F	PUSH R15
 0028	     12B0	CALL #0
 002A	     0000
 002C	     5221	ADD #4,SP
 002E	     4144	MOV.B SP,R4
 0030	     4105	MOV SP,R5
 0032	     5315	ADD #1,R5
 0034	     12B0	CALL #0
 0036	     0000
 0038	     1203	PUSH #0
 003A	     1211	PUSH 14(SP)
 003C	     000E
 003E	     1230	PUSH #3
 0040	     0003
 0042	     1203	PUSH #0
 0044	     1223	PUSH #2
 0046	     1270	PUSH.B #32
 0048	     0020
 004A	     12B0	CALL #0
 004C	     0000
 004E	     5031	ADD #12,SP
 0050	     000C
 0052	     1270	PUSH.B #58
 0054	     003A
 0056	     12B0	CALL #0
 0058	     0000
 005A	     5321	ADD #2,SP
 005C	     1203	PUSH #0
 005E	     1211	PUSH 12(SP)
 0060	     000C
 0062	     1230	PUSH #6
 0064	     0006
 0066	     1203	PUSH #0
 0068	     1223	PUSH #2
 006A	     1270	PUSH.B #48
 006C	     0030
 006E	     12B0	CALL #77
 0070	     004D
 0072	     5031	ADD #12,SP
 0074	     000C
 0076	     1270	PUSH.B #58
 0078	     003A
 007A	     12B0	CALL #89
 007C	     0059
 007E	     5321	ADD #2,SP
 0080	     1203	PUSH #0
 0082	     1211	PUSH 10(SP)
 0084	     000A
 0086	     1230	PUSH #9
 0088	     0009
 008A	     1203	PUSH #0
 008C	     1223	PUSH #2
 008E	     1270	PUSH.B #48
 0090	     0030
 0092	     12B0	CALL #113
 0094	     0071
 0096	     5031	ADD #12,SP
 0098	     000C
 009A	     1230	PUSH #0
 009C	     0000
 009E	     410F	MOV SP,R15
 00A0	     522F	ADD #4,R15
 00A2	     120F	PUSH R15
 00A4	     12B0	CALL #0
 00A6	     0000
 00A8	     5221	ADD #4,SP
 00AA	     930F	CMP #0,R15
 00AC	     2458	JEQ $+178, goes to  015E
 00AE	     12B0	CALL #0
 00B0	     0000
 00B2	     4192	MOV 2(SP),&157
 00B4	     0002
 00B6	     009D
 00B8	     4192	MOV 4(SP),&0
 00BA	     0004
 00BC	     0000
 00BE	     1230	PUSH #7
 00C0	     0007
 00C2	     410F	MOV SP,R15
 00C4	     523F	ADD #8,R15
 00C6	     120F	PUSH R15
 00C8	     12B0	CALL #0
 00CA	     0000
 00CC	     5221	ADD #4,SP
 00CE	     1203	PUSH #0
 00D0	     1213	PUSH #1
 00D2	     12B0	CALL #0
 00D4	     0000
 00D6	     5221	ADD #4,SP
 00D8	     411F	MOV 18(SP),R15
 00DA	     0012
 00DC	     5F0F	ADD R15,R15
 00DE	     5F0F	ADD R15,R15
 00E0	     1230	PUSH #4
 00E2	     0004
 00E4	     503F	ADD #0,R15
 00E6	     0000
 00E8	     120F	PUSH R15
 00EA	     12B0	CALL #0
 00EC	     0000
 00EE	     5221	ADD #4,SP
 00F0	     1203	PUSH #0
 00F2	     1211	PUSH 16(SP)
 00F4	     0010
 00F6	     1230	PUSH #4
 00F8	     0004
 00FA	     1213	PUSH #1
 00FC	     1223	PUSH #2
 00FE	     1270	PUSH.B #32
 0100	     0020
 0102	     12B0	CALL #149
 0104	     0095
 0106	     5031	ADD #12,SP
 0108	     000C
 010A	     1270	PUSH.B #47
 010C	     002F
 010E	     12B0	CALL #125
 0110	     007D
 0112	     5321	ADD #2,SP
 0114	     1203	PUSH #0
 0116	     411F	MOV 16(SP),R15
 0118	     0010
 011A	     531F	ADD #1,R15
 011C	     120F	PUSH R15
 011E	     1230	PUSH #7
 0120	     0007
 0122	     1213	PUSH #1
 0124	     1223	PUSH #2
 0126	     1270	PUSH.B #48
 0128	     0030
 012A	     12B0	CALL #261
 012C	     0105
 012E	     5031	ADD #12,SP
 0130	     000C
 0132	     1270	PUSH.B #47
 0134	     002F
 0136	     12B0	CALL #273
 0138	     0111
 013A	     5321	ADD #2,SP
 013C	     1203	PUSH #0
 013E	     411F	MOV 18(SP),R15
 0140	     0012
 0142	     503F	ADD #1900,R15
 0144	     076C
 0146	     120F	PUSH R15
 0148	     1230	PUSH #10
 014A	     000A
 014C	     1213	PUSH #1
 014E	     1230	PUSH #4
 0150	     0004
 0152	     1270	PUSH.B #32
 0154	     0020
 0156	     12B0	CALL #301
 0158	     012D
 015A	     5031	ADD #12,SP
 015C	     000C
 015E	     1251	PUSH.B 2(SP)
 0160	     0002
 0162	     1251	PUSH.B 5(SP)
 0164	     0005
 0166	     12B0	CALL #213
 0168	     00D5
 016A	     5221	ADD #4,SP
 016C	     5031	ADD #24,SP
 016E	     0018
 0170	     4130	RET
fixups:
 00ED	s8.7
 00E7	s0.8
 0169	s8.8
 00CB	s6.17
 00BD	s0.10+2
 00B1	s0.67
 00A7	s6.9
 00B7	s0.10
 0139	s8.6
 0159	s8.13
 0037	s8.9
 002B	s6.14
 001B	s6.10
 0017	s6.5
 000D	s6.6+2
 00C1	s6.6

section    69	c  364	displayEvent
 0000	     8031	SUB #12,SP
 0002	     000C
 0004	     421F	MOV &0,R15
 0006	     0000
 0008	     4F81	MOV R15,4(SP)
 000A	     0004
 000C	     4104	MOV SP,R4
 000E	     5324	ADD #2,R4
 0010	     4105	MOV SP,R5
 0012	     5035	ADD #3,R5
 0014	     0003
 0016	     12B0	CALL #0
 0018	     0000
 001A	     1230	PUSH #72
 001C	     0048
 001E	     1203	PUSH #0
 0020	     12B0	CALL #0
 0022	     0000
 0024	     5221	ADD #4,SP
 0026	     1211	PUSH 16(SP)
 0028	     0010
 002A	     1230	PUSH #0
 002C	     0000
 002E	     12B0	CALL #0
 0030	     0000
 0032	     5221	ADD #4,SP
 0034	     930F	CMP #0,R15
 0036	     2008	JNE $+18, goes to  0048
 0038	     4381	MOV #0,0(SP)
 003A	     0000
 003C	     1270	PUSH.B #32
 003E	     0020
 0040	     12B0	CALL #0
 0042	     0000
 0044	     5321	ADD #2,SP
 0046	     3C1E	JMP $+62, goes to  0084
 0048	     40B1	MOV #56,0(SP)
 004A	     0038
 004C	     0000
 004E	     1223	PUSH #2
 0050	     12B0	CALL #0
 0052	     0000
 0054	     5321	ADD #2,SP
 0056	     120F	PUSH R15
 0058	     1211	PUSH 18(SP)
 005A	     0012
 005C	     12B0	CALL #49
 005E	     0031
 0060	     5221	ADD #4,SP
 0062	     430E	MOV #0,R14
 0064	     9F0E	CMP R15,R14
 0066	     3406	JGE $+14, goes to  0074
 0068	     1223	PUSH #2
 006A	     1211	PUSH 18(SP)
 006C	     0012
 006E	     12B0	CALL #0
 0070	     0000
 0072	     5221	ADD #4,SP
 0074	     425F	MOV.B &0,R15
 0076	     0000
 0078	     507F	ADD.B #48,R15
 007A	     0030
 007C	     124F	PUSH.B R15
 007E	     12B0	CALL #67
 0080	     0043
 0082	     5321	ADD #2,SP
 0084	     1203	PUSH #0
 0086	     1223	PUSH #2
 0088	     12B0	CALL #35
 008A	     0023
 008C	     5221	ADD #4,SP
 008E	     411F	MOV 4(SP),R15
 0090	     0004
 0092	     126F	PUSH.B @R15
 0094	     12B0	CALL #129
 0096	     0081
 0098	     5321	ADD #2,SP
 009A	     5391	ADD #1,4(SP)
 009C	     0004
 009E	     8391	SUB #1,0(SP)
 00A0	     0000
 00A2	     37F5	JGE $-20, goes to  008E
 00A4	     93C2	CMP.B #0,&0
 00A6	     0000
 00A8	     2409	JEQ $+20, goes to  00BC
 00AA	     93C2	CMP.B #0,&0
 00AC	     0000
 00AE	     2406	JEQ $+14, goes to  00BC
 00B0	     1270	PUSH.B #32
 00B2	     0020
 00B4	     12B0	CALL #151
 00B6	     0097
 00B8	     5321	ADD #2,SP
 00BA	     3FF4	JMP $-22, goes to  00A4
 00BC	     1251	PUSH.B 4(SP)
 00BE	     0004
 00C0	     1251	PUSH.B 7(SP)
 00C2	     0007
 00C4	     12B0	CALL #139
 00C6	     008B
 00C8	     5221	ADD #4,SP
 00CA	     1230	PUSH #192
 00CC	     00C0
 00CE	     12B0	CALL #83
 00D0	     0053
 00D2	     5321	ADD #2,SP
 00D4	     4F81	MOV R15,6(SP)
 00D6	     0006
 00D8	     4291	MOV &0,8(SP)
 00DA	     0000
 00DC	     0008
 00DE	     4291	MOV &0,10(SP)
 00E0	     0000
 00E2	     000A
 00E4	     421F	MOV &7,R15
 00E6	     0007
 00E8	     4F1F	MOV 62(R15),R15
 00EA	     003E
 00EC	     5F0F	ADD R15,R15
 00EE	     5F0F	ADD R15,R15
 00F0	     4F0E	MOV R15,R14
 00F2	     5E0E	ADD R14,R14
 00F4	     5E0F	ADD R14,R15
 00F6	     5E0E	ADD R14,R14
 00F8	     5E0F	ADD R14,R15
 00FA	     5E0E	ADD R14,R14
 00FC	     5E0F	ADD R14,R15
 00FE	     5F81	ADD R15,8(SP)
 0100	     0008
 0102	     6381	ADDC #0,10(SP)
 0104	     000A
 0106	     1211	PUSH 8(SP)
 0108	     0008
 010A	     1230	PUSH #219
 010C	     00DB
 010E	     12B0	CALL #95
 0110	     005F
 0112	     5221	ADD #4,SP
 0114	     430E	MOV #0,R14
 0116	     9F0E	CMP R15,R14
 0118	     340C	JGE $+26, goes to  0132
 011A	     1211	PUSH 8(SP)
 011C	     0008
 011E	     410F	MOV SP,R15
 0120	     503F	ADD #10,R15
 0122	     000A
 0124	     120F	PUSH R15
 0126	     12B0	CALL #273
 0128	     0111
 012A	     5221	ADD #4,SP
 012C	     430E	MOV #0,R14
 012E	     9F0E	CMP R15,R14
 0130	     341A	JGE $+54, goes to  0166
 0132	     1211	PUSH 16(SP)
 0134	     0010
 0136	     1230	PUSH #45
 0138	     002D
 013A	     12B0	CALL #297
 013C	     0129
 013E	     5221	ADD #4,SP
 0140	     930F	CMP #0,R15
 0142	     240A	JEQ $+22, goes to  0158
 0144	     1230	PUSH #192
 0146	     00C0
 0148	     410F	MOV SP,R15
 014A	     503F	ADD #10,R15
 014C	     000A
 014E	     120F	PUSH R15
 0150	     12B0	CALL #113
 0152	     0071
 0154	     5221	ADD #4,SP
 0156	     3C07	JMP $+16, goes to  0166
 0158	     1230	PUSH #192
 015A	     00C0
 015C	     1211	PUSH 18(SP)
 015E	     0012
 0160	     12B0	CALL #339
 0162	     0153
 0164	     5221	ADD #4,SP
 0166	     5031	ADD #12,SP
 0168	     000C
 016A	     4130	RET
fixups:
 00E1	s6.6+2
 010D	s6.6
 00AD	s8.2
 00A7	s8.1
 0077	s0.6+10
 0163	s0.40
 00D1	s0.41
 00B7	s8.6
 013D	s6.9
 0139	s6.3
 00C7	s8.8
 0019	s8.9
 00E7	s0.6

section    70	c   64	nextSecond
 0000	     5292	ADD &0,&370
 0002	     0000
 0004	     0172
 0006	     430F	MOV #0,R15
 0008	     921F	CMP &0,R15
 000A	     0000
 000C	     3406	JGE $+14, goes to  001A
 000E	     421F	MOV &370,R15
 0010	     0172
 0012	     821F	SUB &11,R15
 0014	     000B
 0016	     4F82	MOV R15,&372
 0018	     0174
 001A	     9382	CMP #0,&0
 001C	     0000
 001E	     2004	JNE $+10, goes to  0028
 0020	     425F	MOV.B &0,R15
 0022	     0000
 0024	     5F82	ADD R15,&370
 0026	     0172
 0028	     5392	ADD #1,&29
 002A	     001D
 002C	     425F	MOV.B &0,R15
 002E	     0000
 0030	     9F82	CMP R15,&43
 0032	     002B
 0034	     3802	JL $+6, goes to  003A
 0036	     4382	MOV #0,&51
 0038	     0033
 003A	     12B0	CALL #0
 003C	     0000
 003E	     4130	RET
fixups:
 003D	s6.11
 002F	s0.16
 0023	s0.15
 0039	s0.24
 0015	s0.14
 0003	s0.17

section    71	c   36	displayEventOneHour
 0000	     8221	SUB #4,SP
 0002	     4291	MOV &0,0(SP)
 0004	     0000
 0006	     0000
 0008	     4291	MOV &0,2(SP)
 000A	     0000
 000C	     0002
 000E	     50B1	ADD #3600,0(SP)
 0010	     0E10
 0012	     0000
 0014	     6381	ADDC #0,2(SP)
 0016	     0002
 0018	     1201	PUSH SP
 001A	     12B0	CALL #0
 001C	     0000
 001E	     5321	ADD #2,SP
 0020	     5221	ADD #4,SP
 0022	     4130	RET
fixups:
 001D	s0.69
 000B	s6.6+2
 0005	s6.6

section    72	c   44	rearmVCCSense
 0000	     8221	SUB #4,SP
 0002	     4291	MOV &0,0(SP)
 0004	     0000
 0006	     0000
 0008	     4291	MOV &0,2(SP)
 000A	     0000
 000C	     0002
 000E	     50B1	ADD #3,0(SP)
 0010	     0003
 0012	     0000
 0014	     6381	ADDC #0,2(SP)
 0016	     0002
 0018	     1230	PUSH #129
 001A	     0081
 001C	     410F	MOV SP,R15
 001E	     532F	ADD #2,R15
 0020	     120F	PUSH R15
 0022	     12B0	CALL #0
 0024	     0000
 0026	     5221	ADD #4,SP
 0028	     5221	ADD #4,SP
 002A	     4130	RET
fixups:
 0025	s0.40
 000B	s6.6+2
 0005	s6.6

section    73	c   44	rearmBeepOff
 0000	     8221	SUB #4,SP
 0002	     4291	MOV &0,0(SP)
 0004	     0000
 0006	     0000
 0008	     4291	MOV &0,2(SP)
 000A	     0000
 000C	     0002
 000E	     50B1	ADD #30,0(SP)
 0010	     001E
 0012	     0000
 0014	     6381	ADDC #0,2(SP)
 0016	     0002
 0018	     1230	PUSH #160
 001A	     00A0
 001C	     410F	MOV SP,R15
 001E	     532F	ADD #2,R15
 0020	     120F	PUSH R15
 0022	     12B0	CALL #0
 0024	     0000
 0026	     5221	ADD #4,SP
 0028	     5221	ADD #4,SP
 002A	     4130	RET
fixups:
 0025	s0.40
 000B	s6.6+2
 0005	s6.6

section    74	c  196	buttonPressed
 0000	     8221	SUB #4,SP
 0002	     12B0	CALL #0
 0004	     0000
 0006	     430F	MOV #0,R15
 0008	     921F	CMP &0,R15
 000A	     0000
 000C	     3412	JGE $+38, goes to  0032
 000E	     4382	MOV #0,&11
 0010	     000B
 0012	     4382	MOV #0,&356
 0014	     0164
 0016	     50B1	ADD #27,0(SP)
 0018	     001B
 001A	     0000
 001C	     6381	ADDC #0,2(SP)
 001E	     0002
 0020	     1230	PUSH #144
 0022	     0090
 0024	     410F	MOV SP,R15
 0026	     532F	ADD #2,R15
 0028	     120F	PUSH R15
 002A	     12B0	CALL #0
 002C	     0000
 002E	     5221	ADD #4,SP
 0030	     3C2E	JMP $+94, goes to  008E
 0032	     C3D2	BIC.B #1,&33
 0034	     0021
 0036	     B2E2	BIT.B #4,&0
 0038	     0000
 003A	     2409	JEQ $+20, goes to  004E
 003C	     12B0	CALL #0
 003E	     0000
 0040	     425F	MOV.B &57,R15
 0042	     0039
 0044	     C26F	BIC.B #4,R15
 0046	     120F	PUSH R15
 0048	     12B0	CALL #0
 004A	     0000
 004C	     5321	ADD #2,SP
 004E	     4291	MOV &0,0(SP)
 0050	     0000
 0052	     0000
 0054	     4291	MOV &0,2(SP)
 0056	     0000
 0058	     0002
 005A	     50B1	ADD #5,0(SP)
 005C	     0005
 005E	     0000
 0060	     6381	ADDC #0,2(SP)
 0062	     0002
 0064	     1230	PUSH #136
 0066	     0088
 0068	     410F	MOV SP,R15
 006A	     532F	ADD #2,R15
 006C	     120F	PUSH R15
 006E	     12B0	CALL #45
 0070	     002D
 0072	     5221	ADD #4,SP
 0074	     50B1	ADD #295,0(SP)
 0076	     0127
 0078	     0000
 007A	     6381	ADDC #0,2(SP)
 007C	     0002
 007E	     1230	PUSH #144
 0080	     0090
 0082	     410F	MOV SP,R15
 0084	     532F	ADD #2,R15
 0086	     120F	PUSH R15
 0088	     12B0	CALL #113
 008A	     0071
 008C	     5221	ADD #4,SP
 008E	     1230	PUSH #192
 0090	     00C0
 0092	     12B0	CALL #0
 0094	     0000
 0096	     5321	ADD #2,SP
 0098	     120F	PUSH R15
 009A	     1230	PUSH #0
 009C	     0000
 009E	     12B0	CALL #0
 00A0	     0000
 00A2	     5221	ADD #4,SP
 00A4	     930F	CMP #0,R15
 00A6	     2408	JEQ $+18, goes to  00B8
 00A8	     12B0	CALL #0
 00AA	     0000
 00AC	     434F	MOV.B #0,R15
 00AE	     925F	CMP.B &0,R15
 00B0	     0000
 00B2	     2C02	JC $+6, goes to  00B8
 00B4	     12B0	CALL #0
 00B6	     0000
 00B8	     12B0	CALL #0
 00BA	     0000
 00BC	     43C2	MOV.B #0,&0
 00BE	     0000
 00C0	     5221	ADD #4,SP
 00C2	     4130	RET
fixups:
 00BF	s0.25
 00BB	s0.38
 00B7	s0.71
 00B1	s0.6+10
 00AB	s0.44
 00A1	s6.9
 009D	s6.3
 0095	s0.41
 0057	s6.6+2
 0051	s6.6
 004B	s8.5
 003F	s0.68
 0043	s8.4
 008B	s0.40
 0011	s0.14
 0005	s0.72

section    75	c   68	computeVcc
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     4381	MOV #0,0(SP)
 0006	     0000
 0008	     4292	MOV &436,&0
 000A	     01B4
 000C	     0000
 000E	     4104	MOV SP,R4
 0010	     4035	MOV #13,R5
 0012	     000D
 0014	     4306	MOV #0,R6
 0016	     4037	MOV #5000,R7
 0018	     1388
 001A	     12B0	CALL #0
 001C	     0000
 001E	     4381	MOV #0,2(SP)
 0020	     0002
 0022	     40B1	MOV #1023,4(SP)
 0024	     03FF
 0026	     0004
 0028	     4104	MOV SP,R4
 002A	     4035	MOV #19,R5
 002C	     0013
 002E	     4106	MOV SP,R6
 0030	     5326	ADD #2,R6
 0032	     4107	MOV SP,R7
 0034	     5227	ADD #4,R7
 0036	     12B0	CALL #0
 0038	     0000
 003A	     43C2	MOV.B #0,&0
 003C	     0000
 003E	     5031	ADD #6,SP
 0040	     0006
 0042	     4130	RET
fixups:
 003D	s0.26
 0039	s4.8
 001D	s4.7
 002D	s0.13

section    76	c   58	PORT1_ISR_HOOK
 0000	     C2F2	BIC.B #8,&37
 0002	     0025
 0004	     4292	MOV &368,&374
 0006	     0170
 0008	     0176
 000A	     9292	CMP &368,&374
 000C	     0170
 000E	     0176
 0010	     23F9	JNE $-12, goes to  0004
 0012	     50B2	ADD #6570,&374
 0014	     19AA
 0016	     0176
 0018	     40B2	MOV #16,&358
 001A	     0010
 001C	     0166
 001E	     B2F2	BIT.B #8,&35
 0020	     0023
 0022	     2408	JEQ $+18, goes to  0034
 0024	     B2F2	BIT.B #8,&36
 0026	     0024
 0028	     2405	JEQ $+12, goes to  0034
 002A	     43D2	MOV.B #1,&0
 002C	     0000
 002E	     C0B1	BIC #240,0(SP)
 0030	     00F0
 0032	     0000
 0034	     C2F2	BIC.B #8,&35
 0036	     0023
 0038	     1300	RETI
fixups:
 002D	s0.25

section    77	c   30	ADC10_ISR_HOOK
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     C3A2	BIC #2,&432
 0006	     01B0
 0008	     C0B2	BIC #52,&432
 000A	     0034
 000C	     01B0
 000E	     43D2	MOV.B #1,&0
 0010	     0000
 0012	     C0B1	BIC #240,6(SP)
 0014	     00F0
 0016	     0006
 0018	     5031	ADD #6,SP
 001A	     0006
 001C	     1300	RETI
fixups:
 0011	s0.26

section    78	c   18	USCI0RX_ISR_HOOK
 0000	     B3D2	BIT.B #1,&3
 0002	     0003
 0004	     2405	JEQ $+12, goes to  0010
 0006	     43D2	MOV.B #1,&0
 0008	     0000
 000A	     C0B1	BIC #240,0(SP)
 000C	     00F0
 000E	     0000
 0010	     1300	RETI
fixups:
 0009	s0.27

section    79	c   16	TIMER0_A0_ISR_HOOK
 0000	     120F	PUSH R15
 0002	     12B0	CALL #0
 0004	     0000
 0006	     413F	POP R15
 0008	     C0B1	BIC #240,0(SP)
 000A	     00F0
 000C	     0000
 000E	     1300	RETI
fixups:
 0005	s0.70

section    80	c   38	TIMER0_A1_ISR_HOOK
 0000	     120F	PUSH R15
 0002	     92A2	CMP #4,&302
 0004	     012E
 0006	     200D	JNE $+28, goes to  0022
 0008	     C2F2	BIC.B #8,&36
 000A	     0024
 000C	     425F	MOV.B &32,R15
 000E	     0020
 0010	     F27F	AND.B #8,R15
 0012	     DFC2	BIS.B R15,&36
 0014	     0024
 0016	     C2F2	BIC.B #8,&35
 0018	     0023
 001A	     D2F2	BIS.B #8,&37
 001C	     0025
 001E	     4382	MOV #0,&358
 0020	     0166
 0022	     413F	POP R15
 0024	     1300	RETI
fixups:

section    81	c  118	sendEvents
 0000	     8031	SUB #10,SP
 0002	     000A
 0004	     40B1	MOV #79,0(SP)
 0006	     004F
 0008	     0000
 000A	     40B1	MOV #-15360,4(SP)
 000C	     C400
 000E	     0004
 0010	     411F	MOV 4(SP),R15
 0012	     0004
 0014	     4FE1	MOV.B @R15,6(SP)
 0016	     0006
 0018	     93F1	CMP.B #-1,6(SP)
 001A	     0006
 001C	     2423	JEQ $+72, goes to  0064
 001E	     93C1	CMP.B #0,6(SP)
 0020	     0006
 0022	     2420	JEQ $+66, goes to  0064
 0024	     1211	PUSH 2(SP)
 0026	     0002
 0028	     1230	PUSH #4
 002A	     0004
 002C	     12B0	CALL #0
 002E	     0000
 0030	     5221	ADD #4,SP
 0032	     4074	MOV.B #124,R4
 0034	     007C
 0036	     12B0	CALL #0
 0038	     0000
 003A	     411F	MOV 4(SP),R15
 003C	     0004
 003E	     4F81	MOV R15,8(SP)
 0040	     0008
 0042	     40B1	MOV #63,2(SP)
 0044	     003F
 0046	     0002
 0048	     4114	MOV 8(SP),R4
 004A	     0008
 004C	     4464	MOV.B @R4,R4
 004E	     12B0	CALL #57
 0050	     0039
 0052	     5391	ADD #1,8(SP)
 0054	     0008
 0056	     8391	SUB #1,2(SP)
 0058	     0002
 005A	     37F6	JGE $-18, goes to  0048
 005C	     4074	MOV.B #124,R4
 005E	     007C
 0060	     12B0	CALL #81
 0062	     0051
 0064	     50B1	ADD #64,4(SP)
 0066	     0040
 0068	     0004
 006A	     8391	SUB #1,0(SP)
 006C	     0000
 006E	     37D0	JGE $-94, goes to  0010
 0070	     5031	ADD #10,SP
 0072	     000A
 0074	     4130	RET
fixups:
 0063	s0.33
 002F	s0.51

section    82	c   38	doDSTEvent
 0000	     8221	SUB #4,SP
 0002	     1201	PUSH SP
 0004	     12B0	CALL #0
 0006	     0000
 0008	     5321	ADD #2,SP
 000A	     1230	PUSH #4
 000C	     0004
 000E	     410F	MOV SP,R15
 0010	     532F	ADD #2,R15
 0012	     120F	PUSH R15
 0014	     12B0	CALL #0
 0016	     0000
 0018	     5221	ADD #4,SP
 001A	     1243	PUSH.B #0
 001C	     12B0	CALL #0
 001E	     0000
 0020	     5321	ADD #2,SP
 0022	     5221	ADD #4,SP
 0024	     4130	RET
fixups:
 001F	s0.46
 0017	s0.40
 0007	s6.20

section    83	c  896	module body
 0000	     40B2	MOV #23168,&288
 0002	     5A80
 0004	     0120
 0006	     40F2	MOV.B #129,&0
 0008	     0081
 000A	     0000
 000C	     4382	MOV #0,&0
 000E	     0000
 0010	     4392	MOV #1,&0
 0012	     0000
 0014	     43E2	MOV.B #2,&0
 0016	     0000
 0018	     4034	MOV #0,R4
 001A	     0000
 001C	     12B0	CALL #0
 001E	     0000
 0020	     42E2	MOV.B #4,&0
 0022	     0000
 0024	     4034	MOV #0,R4
 0026	     0000
 0028	     12B0	CALL #31
 002A	     001F
 002C	     40F2	MOV.B #136,&0
 002E	     0088
 0030	     0000
 0032	     4034	MOV #0,R4
 0034	     0000
 0036	     12B0	CALL #43
 0038	     002B
 003A	     40F2	MOV.B #144,&0
 003C	     0090
 003E	     0000
 0040	     4382	MOV #0,&0
 0042	     0000
 0044	     40B2	MOV #301,&0
 0046	     012D
 0048	     0000
 004A	     40F2	MOV.B #160,&0
 004C	     00A0
 004E	     0000
 0050	     4034	MOV #0,R4
 0052	     0000
 0054	     12B0	CALL #57
 0056	     0039
 0058	     40F2	MOV.B #192,&0
 005A	     00C0
 005C	     0000
 005E	     4034	MOV #0,R4
 0060	     0000
 0062	     12B0	CALL #87
 0064	     0057
 0066	     40F2	MOV.B #166,&65
 0068	     00A6
 006A	     0041
 006C	     40F2	MOV.B #25,&33
 006E	     0019
 0070	     0021
 0072	     40F2	MOV.B #230,&38
 0074	     00E6
 0076	     0026
 0078	     40F2	MOV.B #65,&34
 007A	     0041
 007C	     0022
 007E	     40F2	MOV.B #24,&39
 0080	     0018
 0082	     0027
 0084	     42F2	MOV.B #8,&36
 0086	     0024
 0088	     43D2	MOV.B #1,&35
 008A	     0023
 008C	     42F2	MOV.B #8,&37
 008E	     0025
 0090	     40F2	MOV.B #58,&41
 0092	     003A
 0094	     0029
 0096	     40F2	MOV.B #7,&42
 0098	     0007
 009A	     002A
 009C	     40F2	MOV.B #56,&47
 009E	     0038
 00A0	     002F
 00A2	     43C2	MOV.B #0,&44
 00A4	     002C
 00A6	     43C2	MOV.B #0,&43
 00A8	     002B
 00AA	     43C2	MOV.B #0,&25
 00AC	     0019
 00AE	     43C2	MOV.B #0,&26
 00B0	     001A
 00B2	     43C2	MOV.B #0,&88
 00B4	     0058
 00B6	     93F2	CMP.B #-1,&4351
 00B8	     10FF
 00BA	     2408	JEQ $+18, goes to  00CC
 00BC	     43C2	MOV.B #0,&86
 00BE	     0056
 00C0	     42D2	MOV.B &4351,&87
 00C2	     10FF
 00C4	     0057
 00C6	     42D2	MOV.B &4350,&86
 00C8	     10FE
 00CA	     0056
 00CC	     D0F2	BIS.B #128,&87
 00CE	     0080
 00D0	     0057
 00D2	     42E2	MOV.B #4,&83
 00D4	     0053
 00D6	     D3D2	BIS.B #1,&97
 00D8	     0061
 00DA	     40F2	MOV.B #129,&97
 00DC	     0081
 00DE	     0061
 00E0	     40F2	MOV.B #26,&98
 00E2	     001A
 00E4	     0062
 00E6	     C3D2	BIC.B #1,&97
 00E8	     0061
 00EA	     D3D2	BIS.B #1,&105
 00EC	     0069
 00EE	     40F2	MOV.B #169,&104
 00F0	     00A9
 00F2	     0068
 00F4	     40F2	MOV.B #129,&105
 00F6	     0081
 00F8	     0069
 00FA	     43E2	MOV.B #2,&106
 00FC	     006A
 00FE	     C3D2	BIC.B #1,&105
 0100	     0069
 0102	     C3A2	BIC #2,&432
 0104	     01B0
 0106	     40B2	MOV #15480,&432
 0108	     3C78
 010A	     01B0
 010C	     40B2	MOV #-20480,&434
 010E	     B000
 0110	     01B2
 0112	     4034	MOV #10000,R4
 0114	     2710
 0116	     12B0	CALL #0
 0118	     0000
 011A	     D3A2	BIS #2,&432
 011C	     01B0
 011E	     C3E2	BIC.B #2,&2
 0120	     0002
 0122	     4034	MOV #16,R4
 0124	     0010
 0126	     12B0	CALL #281
 0128	     0119
 012A	     B3E2	BIT.B #2,&2
 012C	     0002
 012E	     23F7	JNE $-16, goes to  011E
 0130	     C3D2	BIC.B #1,&3
 0132	     0003
 0134	     D3D2	BIS.B #1,&1
 0136	     0001
 0138	     D232	BIS #8,SR
 013A	     40B2	MOV #16,&354
 013C	     0010
 013E	     0162
 0140	     40B2	MOV #16,&358
 0142	     0010
 0144	     0166
 0146	     40B2	MOV #-32768,&370
 0148	     8000
 014A	     0172
 014C	     40B2	MOV #3293,&372
 014E	     0CDD
 0150	     0174
 0152	     40B2	MOV #288,&352
 0154	     0120
 0156	     0160
 0158	     43C2	MOV.B #0,&0
 015A	     0000
 015C	     43C2	MOV.B #0,&0
 015E	     0000
 0160	     43C2	MOV.B #0,&0
 0162	     0000
 0164	     4034	MOV #0,R4
 0166	     0000
 0168	     12B0	CALL #101
 016A	     0065
 016C	     43C2	MOV.B #0,&0
 016E	     0000
 0170	     4382	MOV #0,&0
 0172	     0000
 0174	     4034	MOV #0,R4
 0176	     0000
 0178	     4035	MOV #0,R5
 017A	     0000
 017C	     4036	MOV #0,R6
 017E	     0000
 0180	     4037	MOV #0,R7
 0182	     0000
 0184	     12B0	CALL #0
 0186	     0000
 0188	     93B2	CMP #-1,&4226
 018A	     1082
 018C	     240A	JEQ $+22, goes to  01A2
 018E	     4292	MOV &4226,&0
 0190	     1082
 0192	     0000
 0194	     42D2	MOV.B &4224,&0
 0196	     1080
 0198	     0000
 019A	     42D2	MOV.B &4225,&0
 019C	     1081
 019E	     0000
 01A0	     3C09	JMP $+20, goes to  01B4
 01A2	     40B2	MOV #32766,&403
 01A4	     7FFE
 01A6	     0193
 01A8	     40F2	MOV.B #5,&409
 01AA	     0005
 01AC	     0199
 01AE	     40F2	MOV.B #11,&415
 01B0	     000B
 01B2	     019F
 01B4	     C2E2	BIC.B #4,&41
 01B6	     0029
 01B8	     12B0	CALL #0
 01BA	     0000
 01BC	     12B0	CALL #0
 01BE	     0000
 01C0	     1230	PUSH #13
 01C2	     000D
 01C4	     12B0	CALL #0
 01C6	     0000
 01C8	     5321	ADD #2,SP
 01CA	     43C2	MOV.B #0,&0
 01CC	     0000
 01CE	     1243	PUSH.B #0
 01D0	     12B0	CALL #0
 01D2	     0000
 01D4	     5321	ADD #2,SP
 01D6	     D032	BIS #208,SR
 01D8	     00D0
 01DA	     93C2	CMP.B #0,&367
 01DC	     016F
 01DE	     2407	JEQ $+16, goes to  01EE
 01E0	     12B0	CALL #0
 01E2	     0000
 01E4	     12B0	CALL #0
 01E6	     0000
 01E8	     43C2	MOV.B #0,&477
 01EA	     01DD
 01EC	     3CC7	JMP $+400, goes to  037C
 01EE	     93C2	CMP.B #0,&347
 01F0	     015B
 01F2	     2402	JEQ $+6, goes to  01F8
 01F4	     12B0	CALL #0
 01F6	     0000
 01F8	     93C2	CMP.B #0,&351
 01FA	     015F
 01FC	     2402	JEQ $+6, goes to  0202
 01FE	     12B0	CALL #0
 0200	     0000
 0202	     93C2	CMP.B #0,&355
 0204	     0163
 0206	     2416	JEQ $+46, goes to  0234
 0208	     B3E2	BIT.B #2,&3
 020A	     0003
 020C	     27FD	JEQ $-4, goes to  0208
 020E	     425F	MOV.B &101,R15
 0210	     0065
 0212	     F07F	AND.B #32,R15
 0214	     0020
 0216	     5F0F	ADD R15,R15
 0218	     5F0F	ADD R15,R15
 021A	     5F0F	ADD R15,R15
 021C	     5F0F	ADD R15,R15
 021E	     5F0F	ADD R15,R15
 0220	     5F0F	ADD R15,R15
 0222	     5F0F	ADD R15,R15
 0224	     5F0F	ADD R15,R15
 0226	     425E	MOV.B &102,R14
 0228	     0066
 022A	     5E0F	ADD R14,R15
 022C	     120F	PUSH R15
 022E	     12B0	CALL #455
 0230	     01C7
 0232	     5321	ADD #2,SP
 0234	     B2E2	BIT.B #4,&0
 0236	     0000
 0238	     2002	JNE $+6, goes to  023E
 023A	     12B0	CALL #0
 023C	     0000
 023E	     1230	PUSH #0
 0240	     0000
 0242	     1230	PUSH #0
 0244	     0000
 0246	     12B0	CALL #0
 0248	     0000
 024A	     5221	ADD #4,SP
 024C	     930F	CMP #0,R15
 024E	     3896	JL $+302, goes to  037C
 0250	     B3D2	BIT.B #1,&0
 0252	     0000
 0254	     2414	JEQ $+42, goes to  027E
 0256	     D0B2	BIS #16,&432
 0258	     0010
 025A	     01B0
 025C	     D0B2	BIS #32,&432
 025E	     0020
 0260	     01B0
 0262	     4034	MOV #43,R4
 0264	     002B
 0266	     12B0	CALL #297
 0268	     0129
 026A	     D0B2	BIS #3,&432
 026C	     0003
 026E	     01B0
 0270	     1230	PUSH #129
 0272	     0081
 0274	     1230	PUSH #0
 0276	     0000
 0278	     12B0	CALL #0
 027A	     0000
 027C	     5221	ADD #4,SP
 027E	     B2E2	BIT.B #4,&595
 0280	     0253
 0282	     2402	JEQ $+6, goes to  0288
 0284	     12B0	CALL #0
 0286	     0000
 0288	     B3E2	BIT.B #2,&641
 028A	     0281
 028C	     242D	JEQ $+92, goes to  02E8
 028E	     1253	PUSH.B #1
 0290	     12B0	CALL #467
 0292	     01D3
 0294	     5321	ADD #2,SP
 0296	     93C2	CMP.B #0,&461
 0298	     01CD
 029A	     2426	JEQ $+78, goes to  02E8
 029C	     12B0	CALL #0
 029E	     0000
 02A0	     B2E2	BIT.B #4,&567
 02A2	     0237
 02A4	     240B	JEQ $+24, goes to  02BC
 02A6	     12B0	CALL #573
 02A8	     023D
 02AA	     425F	MOV.B &675,R15
 02AC	     02A3
 02AE	     C26F	BIC.B #4,R15
 02B0	     120F	PUSH R15
 02B2	     12B0	CALL #0
 02B4	     0000
 02B6	     5321	ADD #2,SP
 02B8	     12B0	CALL #0
 02BA	     0000
 02BC	     435F	MOV.B #1,R15
 02BE	     925F	CMP.B &665,R15
 02C0	     0299
 02C2	     2C04	JC $+10, goes to  02CC
 02C4	     40B2	MOV #15000,&371
 02C6	     3A98
 02C8	     0173
 02CA	     3C03	JMP $+8, goes to  02D2
 02CC	     40B2	MOV #3293,&713
 02CE	     0CDD
 02D0	     02C9
 02D2	     40B2	MOV #96,&356
 02D4	     0060
 02D6	     0164
 02D8	     421F	MOV &370,R15
 02DA	     0172
 02DC	     821F	SUB &721,R15
 02DE	     02D1
 02E0	     4F82	MOV R15,&372
 02E2	     0174
 02E4	     12B0	CALL #0
 02E6	     0000
 02E8	     B2F2	BIT.B #8,&651
 02EA	     028B
 02EC	     2409	JEQ $+20, goes to  0300
 02EE	     D3D2	BIS.B #1,&33
 02F0	     0021
 02F2	     1230	PUSH #136
 02F4	     0088
 02F6	     1230	PUSH #631
 02F8	     0277
 02FA	     12B0	CALL #635
 02FC	     027B
 02FE	     5221	ADD #4,SP
 0300	     B0F2	BIT.B #32,&747
 0302	     0020
 0304	     02EB
 0306	     2415	JEQ $+44, goes to  0332
 0308	     9382	CMP #0,&735
 030A	     02DF
 030C	     240B	JEQ $+24, goes to  0324
 030E	     4382	MOV #0,&779
 0310	     030B
 0312	     4382	MOV #0,&356
 0314	     0164
 0316	     425F	MOV.B &685,R15
 0318	     02AD
 031A	     D26F	BIS.B #4,R15
 031C	     120F	PUSH R15
 031E	     12B0	CALL #693
 0320	     02B5
 0322	     5321	ADD #2,SP
 0324	     1230	PUSH #160
 0326	     00A0
 0328	     1230	PUSH #761
 032A	     02F9
 032C	     12B0	CALL #765
 032E	     02FD
 0330	     5221	ADD #4,SP
 0332	     B0F2	BIT.B #16,&773
 0334	     0010
 0336	     0305
 0338	     240E	JEQ $+30, goes to  0356
 033A	     425F	MOV.B &793,R15
 033C	     0319
 033E	     D26F	BIS.B #4,R15
 0340	     120F	PUSH R15
 0342	     12B0	CALL #801
 0344	     0321
 0346	     5321	ADD #2,SP
 0348	     1230	PUSH #144
 034A	     0090
 034C	     1230	PUSH #811
 034E	     032B
 0350	     12B0	CALL #815
 0352	     032F
 0354	     5221	ADD #4,SP
 0356	     B0F2	BIT.B #64,&823
 0358	     0040
 035A	     0337
 035C	     240D	JEQ $+28, goes to  0378
 035E	     12B0	CALL #0
 0360	     0000
 0362	     93C2	CMP.B #0,&705
 0364	     02C1
 0366	     2403	JEQ $+8, goes to  036E
 0368	     12B0	CALL #671
 036A	     029F
 036C	     3C05	JMP $+12, goes to  0378
 036E	     1230	PUSH #847
 0370	     034F
 0372	     12B0	CALL #0
 0374	     0000
 0376	     5321	ADD #2,SP
 0378	     12B0	CALL #0
 037A	     0000
 037C	     3F2C	JMP $-422, goes to  01D6
 037E	     4130	RET
fixups:
 037B	s0.38
 0375	s0.69
 0361	s0.44
 02E7	s0.73
 02BB	s0.72
 0345	s8.5
 036B	s0.71
 0287	s0.82
 0353	s0.40
 0371	s6.3
 035B	s0.12
 0249	s6.9
 0245	s0.11
 0241	s6.6
 02A9	s0.68
 033D	s8.4
 0201	s0.75
 01F7	s0.74
 01E7	s0.50
 01E3	s0.81
 0293	s0.46
 0365	s0.6+10
 0231	s0.54
 01BF	s8.11
 01BB	s8.10
 01B3	s0.16
 01AD	s0.15
 01A7	s0.17
 0187	s8.14
 0183	s0.31
 017F	s0.30
 017B	s0.29
 0177	s0.28
 0311	s0.14
 01EB	s0.9
 0167	s0.10
 0205	s0.27
 01FB	s0.26
 01F1	s0.25
 0269	s9.1
 0061	s0.7+38
 005D	s0.7+36
 0053	s0.7+32
 004F	s0.7+30
 0049	s0.7+26
 0043	s0.7+28
 003F	s0.7+24
 0035	s0.7+20
 0031	s0.7+18
 0027	s0.7+14
 0023	s0.7+12
 016B	s6.7
 001B	s0.7+8
 0017	s0.7+6
 0013	s0.7+2
 000F	s0.7+4
 000B	s0.7

section    84	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF 0000 FFFF FFFF 0000 FFFF 0000 0000 0000 FFFF FFFF FFFF FFFF FFFF FFFF
fixups:
 0031	s0.80
 0033	s0.79
 002F	s0.78
 002B	s0.77
 0025	s0.76

entries:
   83
