MODULE Modules;  (*Link and load; NW 20.10.2013 / 8.1.2019
  on Cortex M4 CS 12/12/2023*)
  IMPORT SYSTEM, Kernel, Files;
  CONST versionkey = 1X; DescSize = 80;

    (*Powers of two*)
    C31=80000000H; C30=40000000H; C28=10000000H; C27=8000000H; C26=4000000H;
    C25=2000000H; C24=1000000H; C23=800000H; C22=400000H; 
    C21=200000H; C20=100000H; C19=80000H; C18=40000H; C17=20000H;
    C16=10000H; C15= 8000H; C13=2000H; C12=1000H; C11=800H; 
    C10=400H; C9=200H;C8=100H; C7=80H; C6=40H; C5=20H; 
    C4=10H; C3=8; C2=4; C1=2; C0=1;

    BL = 0F000D000H;
    (*|1111/0S  /im10/    /11J1/J   /im11/    |
                             1  2
      BL<c><q> <label>*)
  
    MOVIT3  = 0F2400000H;
    (*|1111/0i10/0100/imm4/0im3/ Rd / imm/8   |
      MOVW<c> <Rd>,#<imm16>*)

    MOVT    = 0F2C00000H;
    (*|1111/0i10/1100/imm4/0im3/ Rd / imm/8   |
      MOVT<c> <Rd>,#<imm16>*)

  TYPE Module* = POINTER TO ModDesc;
    Command* = PROCEDURE;
    ModuleName* = ARRAY 32 OF CHAR;

    ModDesc* = RECORD
        name*: ModuleName;
        next*: Module;
        key*, num*, size*, refcnt*: INTEGER;
        data*, code*, imp*, cmd*, ent*, ptr*, const*: INTEGER  (*addresses*)
      END ;

  VAR root*, M: Module;
    AllocPtr*, res*: INTEGER;
    importing*, imported*: ModuleName;
    limit: INTEGER;

  PROCEDURE formatEvenImm25(disp: INTEGER): INTEGER;
  (* |00000S   imm10  00J0J   imm11   |
     |                  1 2
     I1 = NOT(J1 EOR S); I2 = NOT(J2 EOR S); imm32 = SignExtend(S:I1:I2:imm10:imm11:'0', 32);
  *) 
  VAR res: INTEGER;
    S, J1, J2: BYTE;
    imm10, imm11: INTEGER;
  BEGIN
    disp := disp DIV C1;
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
    imm10 := disp DIV C11 MOD C10;
    imm11 := disp MOD C11;
 
    RETURN imm11 + S*C26 + imm10*C16+J1*C13+J2*C11
  END formatEvenImm25;
  
  PROCEDURE formatImm16(reg: BYTE; val: INTEGER): INTEGER;
  (*|xxxxxixxxxxximm4ximm reg  imm8  |
    |                   3            |
    val = imm4:i:imm3:imm8*)
  BEGIN
    RETURN val DIV C12 MOD C4*C16 + val DIV C11 MOD C1*C26 + 
           val DIV C8 MOD C3*C12 + reg*C8 + val MOD C8
  END formatImm16;

  PROCEDURE thumbSwap(w: INTEGER): INTEGER;
  BEGIN
    RETURN w DIV 100H MOD 100H*1000000H
      + w MOD 100H*10000H
      + w DIV 1000000H MOD 100H*100H
      + w DIV 10000H MOD 100H
  END thumbSwap;
    
  (* Get unaligned words *)
  PROCEDURE GetWordAt(adr: INTEGER): INTEGER;
    VAR b1, b2, b3, b4: BYTE;
  BEGIN
    SYSTEM.GET(adr, b4); SYSTEM.GET(adr+1, b3); SYSTEM.GET(adr+2, b2); SYSTEM.GET(adr+3, b1);
    RETURN 0+b4+100H*(b3+100H*(b2+100H*b1))
  END GetWordAt;
  
  (* Put unaligned words *)
  PROCEDURE PutWordAt(adr, val: INTEGER);
    VAR b1, b2, b3, b4: BYTE;
  BEGIN
    b4 := val MOD 100H; val := val DIV 100H;
    b3 := val MOD 100H; val := val DIV 100H;
    b2 := val MOD 100H; val := val DIV 100H;
    b1 := val MOD 100H;
    SYSTEM.PUT(adr, b4); SYSTEM.PUT(adr+1, b3); SYSTEM.PUT(adr+2, b2); SYSTEM.PUT(adr+3, b1)
  END PutWordAt;
  
  PROCEDURE ThisFile(name: ARRAY OF CHAR): Files.File;
    VAR i: INTEGER;
      filename: ModuleName;
  BEGIN i := 0;
    WHILE name[i] # 0X DO filename[i] := name[i]; INC(i) END ;
    filename[i] := "."; filename[i+1] := "m"; filename[i+2] := "4"; filename[i+3] := "c"; filename[i+4] := 0X;
    RETURN Files.Old(filename)
  END ThisFile;

  PROCEDURE error(n: INTEGER; name: ARRAY OF CHAR);
  BEGIN res := n; importing := name
  END error;

  PROCEDURE Check(s: ARRAY OF CHAR);
    VAR i: INTEGER; ch: CHAR;
  BEGIN ch := s[0]; res := 1; i := 1;
    IF (ch >= "A") & (ch <= "Z") OR (ch >= "a") & (ch <= "z") THEN
      REPEAT ch := s[i]; INC(i)
      UNTIL ~((ch >= "0") & (ch <= "9") OR (ch >= "A") & (ch <= "Z")
        OR (ch >= "a") & (ch <= "z") OR (ch = ".")) OR (i = 32);
      IF (i < 32) & (ch = 0X) THEN res := 0 END
    END
  END Check;

  PROCEDURE Load*(name: ARRAY OF CHAR; VAR newmod: Module);
    (*search module in list; if not found, load module.
      res = 0: already present or loaded; res = 2: file not available; res = 3: key conflict;
      res = 4: bad file version; res = 5: corrupted file; res = 7: no space*)
    VAR mod!, impmod!: Module;
      i, n, key, impkey, mno, nofimps, size: INTEGER;
      p, u, v, w: INTEGER;  (*addresses*)
      b: BYTE;
      ch: CHAR;
      shrinkable: BOOLEAN;
      body: Command;
      fixorgP, fixorgD, fixorgT: INTEGER;
      disp, adr, inst, pno, vno, dest, offset, trpbase, noftrps: INTEGER;
      name1, impname: ModuleName;
      F!: Files.File; R!: Files.Rider;
      import!: ARRAY 16 OF Module;
  BEGIN mod := root; error(0, name); nofimps := 0; shrinkable := FALSE;
    WHILE (mod # NIL) & (name # mod.name) DO mod := mod.next END ;
    IF mod = NIL THEN (*load*)
      Check(name);
      IF res = 0 THEN F := ThisFile(name) ELSE F := NIL END ;
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, key); Files.Read(R, ch);
        Files.ReadInt(R, size); importing := name1;
        IF ch = versionkey THEN
          Files.ReadString(R, impname);   (*imports*)
          WHILE (impname[0] # 0X) & (res = 0) DO
            Files.ReadInt(R, impkey);
            Load(impname, impmod); import[nofimps] := impmod; importing := name1;
            IF res = 0 THEN
              IF impmod.key = impkey THEN INC(impmod.refcnt); INC(nofimps)
              ELSE error(3, name1); imported := impname
              END
            END ;
            Files.ReadString(R, impname)
          END
        ELSE error(2, name1)
        END
      ELSE error(1, name)
      END ;
      IF res = 0 THEN (*search for a hole in the list allocate and link*)
        INC(size, DescSize); mod := root;
        WHILE (mod # NIL) & ~((mod.name[0] = 0X) & (mod.size >= size)) DO mod := mod.next END ;
        IF mod = NIL THEN (*no large enough hole was found*)
          IF AllocPtr + size < limit THEN (*allocate*)
            shrinkable := TRUE;
            p := AllocPtr; mod := SYSTEM.VAL(Module, p);
            AllocPtr := (p + size + 3) DIV 4 * 4; mod.size := AllocPtr - p; mod.num := root.num + 1;
            mod.next := root; root := mod
          ELSE error(7, name1)
          END
        ELSE (*fill hole*) p := SYSTEM.VAL(INTEGER, mod)
        END
      END ; 
      IF res = 0 THEN (*read file*)
        INC(p, DescSize); (*allocate descriptor*)
        mod.name := name; mod.key := key; mod.refcnt := 0;
        mod.data := p;  (*data*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n, 4) END ;  (*type descriptors*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO SYSTEM.PUT(p, 0); INC(p, 4); DEC(n, 4) END ;  (*variable space*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.Read(R, ch); SYSTEM.PUT(p, ch); INC(p); DEC(n) END ;   (*strings*)
        mod.code := p;  (*program*)
        Files.ReadInt(R, n); (*In Cortex M4 implementation, program size is counted in bytes*)
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n, 4) END ;  (*program code*)
        mod.imp := p;  (*copy imports*)
        i := 0;
        WHILE i < nofimps DO
          SYSTEM.PUT(p, import[i]); INC(p, 4); INC(i)
        END ;
        mod.cmd := p;  (*commands*) Files.Read(R, ch);
        WHILE ch # 0X DO
          REPEAT SYSTEM.PUT(p, ch); INC(p); Files.Read(R, ch) UNTIL ch = 0X;
          REPEAT SYSTEM.PUT(p, 0X); INC(p) UNTIL p MOD 4 = 0;
          Files.ReadInt(R, n); SYSTEM.PUT(p, n); INC(p, 4); Files.Read(R, ch)
        END ;
        REPEAT SYSTEM.PUT(p, 0X); INC(p) UNTIL p MOD 4 = 0;
        mod.ent := p;  (*entries*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n) END ;
        mod.ptr := p;  (*pointer references*)
        Files.ReadInt(R, w);
        WHILE w >= 0 DO SYSTEM.PUT(p, mod.data + w); INC(p, 4); Files.ReadInt(R, w) END ;
        SYSTEM.PUT(p, 0); INC(p, 4);
        Files.ReadInt(R, fixorgP); Files.ReadInt(R, fixorgD); Files.ReadInt(R, fixorgT);
        Files.ReadInt(R, w); body := SYSTEM.VAL(Command, mod.code + w + 1);
        Files.Read(R, ch);
        IF ch # "O" THEN (*corrupted file*)  mod := NIL; error(4, name) END
      END ;
      IF res = 0 THEN (*fixup of BL*)
        noftrps := 0; trpbase := p; (*trampoline area*)
        adr := mod.code + fixorgP;
        WHILE adr # mod.code DO
          inst := GetWordAt(adr);
          inst := thumbSwap(inst); (*Put bytes in the right order*)
          mno := inst DIV 10000000H MOD 10H;
          pno := inst DIV 100000H MOD 100H;
          disp := inst MOD 100000H*2;
          SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
          SYSTEM.GET(impmod.ent + pno*4, dest); dest := dest + impmod.code;
          (*dest contains the absolute address of the called procedure*)
          offset := dest - adr - 4; (* Offset in bytes *)
          IF (offset < -16777216) OR (offset >= 16777216) THEN
            (*The destination is out of reachable range. Install trampoline AKA veneer code in ARM world*)
            i := 0; u := trpbase;
            SYSTEM.GET(u+4, w);
            WHILE (i < noftrps) & (dest # w) DO INC(u, 8); SYSTEM.GET(u+4, w); INC(i) END;
            IF i >= noftrps THEN (*Create trampoline, u is aligned to 4 bytes boundary*)
              (*0DFF800F0H is object code for ldr pc, [pc] when pc MOD 4 = 0*)
              INC(noftrps); SYSTEM.PUT(u, 0DFF800F0H); SYSTEM.PUT(u+4, dest+1)
            END;
            dest := u; (*branch to trampoline*)
            offset := dest - adr - 4 (* Offset in bytes *)
          END;
          PutWordAt(adr, thumbSwap(BL + formatEvenImm25(offset)));
          adr := adr - disp
        END ;
        INC(p, noftrps*8);
        (*fixup of MOV/MOVT*)
        adr := mod.code + fixorgD;
        WHILE adr # mod.code DO
          inst := GetWordAt(adr);
          inst := thumbSwap(inst); (*Put bytes in the right order*)
          pno := inst DIV 10000000H MOD 10H; (*destination register*)
          mno := inst DIV 1000000H MOD 10H;
          disp := inst MOD 1000000H*2;
          inst := GetWordAt(adr+4);
          inst := thumbSwap(inst); (*Put bytes in the right order*)
          IF mno = 0 THEN (*global*)
            dest := mod.data + inst MOD 1000000H
          ELSE (*import*)  vno := inst MOD 100H;
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(impmod.ent + vno*4, offset);
            IF ODD(inst DIV 100H) THEN dest := impmod.code + offset + 1 (*thumb execution state*)
            ELSE dest := impmod.data + offset END
          END;
          PutWordAt(adr, thumbSwap(MOVIT3 + formatImm16(pno, dest MOD 10000H)));
          PutWordAt(adr+4, thumbSwap(MOVT + formatImm16(pno, dest DIV 10000H MOD 10000H)));
          adr := adr - disp
        END ;
        (*fixup of type descriptors*)
        adr := mod.data + fixorgT*4;
        WHILE adr # mod.data DO
          SYSTEM.GET(adr, inst);
          mno := inst DIV 1000000H MOD 10H;
          vno := inst DIV 1000H MOD 1000H;
          disp := inst MOD 1000H;
          IF mno = 0 THEN (*global*) inst := mod.data + vno
          ELSE (*import*)
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(impmod.ent + vno*4, offset);
            inst := impmod.data + offset
          END ;
          SYSTEM.PUT(adr, inst); adr := adr - disp*4
        END ;
        body;   (*initialize module*)
        IF shrinkable & (AllocPtr > p) THEN DEC(mod.size, AllocPtr - p); AllocPtr := p END (*remove trampoline unused space*)
      ELSIF res >= 3 THEN importing := name;
        WHILE nofimps > 0 DO DEC(nofimps); DEC(import[nofimps].refcnt) END
      END 
    END ;
    newmod :=  mod
  END Load;

  PROCEDURE ThisCommand*(mod: Module; name: ARRAY OF CHAR): Command;
    VAR k, adr, w: INTEGER; ch: CHAR;
      s: ARRAY 32 OF CHAR;
  BEGIN res := 5; w := 0;
    IF mod # NIL THEN
      adr := mod.cmd; SYSTEM.GET(adr, ch);
      WHILE (ch # 0X) & (res # 0) DO k := 0; (*read command name*)
        REPEAT s[k] := ch; INC(k); INC(adr); SYSTEM.GET(adr, ch) UNTIL ch = 0X;
        s[k] := 0X;
        REPEAT INC(adr) UNTIL adr MOD 4 = 0;
        SYSTEM.GET(adr, k); INC(adr, 4);
        IF s = name THEN res := 0; w := mod.code + k + 1 (*thumb execution state*) ELSE SYSTEM.GET(adr, ch) END
      END
    END
    RETURN SYSTEM.VAL(Command, w)
  END ThisCommand;

  PROCEDURE Free*(name: ARRAY OF CHAR);
    VAR mod!, imp!: Module; p, q: INTEGER;
  BEGIN mod := root; res := 0;
    WHILE (mod # NIL) & (mod.name # name) DO mod := mod.next END ;
    IF mod # NIL THEN
      IF mod.refcnt = 0 THEN
        mod.name[0] := 0X; p := mod.imp; q := mod.cmd;
        WHILE p < q DO SYSTEM.GET(p, imp); DEC(imp.refcnt); INC(p, 4) END;
        WHILE root.name[0] = 0X DO (*deallocate freed modules at end of module space*)
          AllocPtr := SYSTEM.VAL(INTEGER, root); root := root.next
        END
      ELSE res := 1
      END
    END
  END Free;

  PROCEDURE Init;
  BEGIN
    SYSTEM.GET(Kernel.VarORG0+16, AllocPtr); SYSTEM.GET(Kernel.VarORG0+20, root); 
    SYSTEM.GET(Kernel.VarORG0+28, limit) (*The end of the module space is the beginning of the heap*)
  END Init;

BEGIN Init; Load("Oberon", M);
    LED(res); REPEAT UNTIL FALSE  (*only if load fails*)
END Modules.

OM4Tool.DecObj Modules.m4c
decode Modules.m4c
Modules A730849C   2   4604
imports:
	Kernel FC60F94D
	Files 5B83E95D
type descriptors
 00000080 FFFFFFFF FFFFFFFF FFFFFFFF 00000020 FFFFFFFF
strings
Oberon||
data    84
code
commands:
entries
 000010F0 00000000 00000000 00000008 0000000C 00000010 00000030 000003AA 00000E84 00000F84
pointer refs
     0     4
fixP =  00000A36
fixV =  0000110C
fixC =  000010F6
fixT =  00000000
entry =  000010F0
 00000000	     B084	SUB SP SP #16
 00000002	     B401	PUSH R0
 00000004	     B500	PUSH LR
 00000006	     9801	LDR R0 [ SP + 4 ]
 00000008	     1040	ASRS R0 R0 #1
 0000000A	     9001	STR R0 [ SP + 4 ]
 0000000C	     9801	LDR R0 [ SP + 4 ]
 0000000E	     15C0	ASRS R0 R0 #23
 00000010	 F36F005F	BFC R0 #1 #31
 00000014	 F88D000C	STRB R0 [  SP + 12 ]
 00000018	     9801	LDR R0 [ SP + 4 ]
 0000001A	 F36F50DF	BFC R0 #23 #9
 0000001E	     9001	STR R0 [ SP + 4 ]
 00000020	     9801	LDR R0 [ SP + 4 ]
 00000022	     1580	ASRS R0 R0 #22
 00000024	 F36F005F	BFC R0 #1 #31
 00000028	 F88D000D	STRB R0 [  SP + 13 ]
 0000002C	     9801	LDR R0 [ SP + 4 ]
 0000002E	 F36F509F	BFC R0 #22 #10
 00000032	     9001	STR R0 [ SP + 4 ]
 00000034	     9801	LDR R0 [ SP + 4 ]
 00000036	     1540	ASRS R0 R0 #21
 00000038	 F36F005F	BFC R0 #1 #31
 0000003C	 F88D000E	STRB R0 [  SP + 14 ]
 00000040	     9801	LDR R0 [ SP + 4 ]
 00000042	 F36F505F	BFC R0 #21 #11
 00000046	     9001	STR R0 [ SP + 4 ]
 00000048	 F89D000C	LDRB R0 [ SP + 12 ]
 0000004C	     2800	CMP R0 #0
 0000004E	 F040800C	BNE #24, goes to  0000006A
 00000052	 F89D000D	LDRB R0 [ SP + 13 ]
 00000056	 F1D00001	RSBS R0 R0 #1
 0000005A	 F88D000D	STRB R0 [  SP + 13 ]
 0000005E	 F89D000E	LDRB R0 [ SP + 14 ]
 00000062	 F1D00001	RSBS R0 R0 #1
 00000066	 F88D000E	STRB R0 [  SP + 14 ]
 0000006A	     9801	LDR R0 [ SP + 4 ]
 0000006C	     12C0	ASRS R0 R0 #11
 0000006E	 F36F209F	BFC R0 #10 #22
 00000072	     9004	STR R0 [ SP + 16 ]
 00000074	     9801	LDR R0 [ SP + 4 ]
 00000076	 F36F20DF	BFC R0 #11 #21
 0000007A	     9005	STR R0 [ SP + 20 ]
 0000007C	 F89D000C	LDRB R0 [ SP + 12 ]
 00000080	     0680	LSLS R0 R0 #26
 00000082	     9905	LDR R1 [ SP + 20 ]
 00000084	     1808	ADDS R0 R1 R0
 00000086	     9904	LDR R1 [ SP + 16 ]
 00000088	     0409	LSLS R1 R1 #16
 0000008A	     1840	ADDS R0 R0 R1
 0000008C	 F89D100D	LDRB R1 [ SP + 13 ]
 00000090	     0349	LSLS R1 R1 #13
 00000092	     1840	ADDS R0 R0 R1
 00000094	 F89D100E	LDRB R1 [ SP + 14 ]
 00000098	     02C9	LSLS R1 R1 #11
 0000009A	     1840	ADDS R0 R0 R1
 0000009C	 F85DEB04	LDR LR [ SP ] + 4
 000000A0	     B005	ADD SP SP #20
 000000A2	     4770	BX LR
 000000A4	     B403	PUSH R0 R1
 000000A6	     B500	PUSH LR
 000000A8	     9802	LDR R0 [ SP + 8 ]
 000000AA	     1300	ASRS R0 R0 #12
 000000AC	 F36F101F	BFC R0 #4 #28
 000000B0	     0400	LSLS R0 R0 #16
 000000B2	     9902	LDR R1 [ SP + 8 ]
 000000B4	     12C9	ASRS R1 R1 #11
 000000B6	 F36F015F	BFC R1 #1 #31
 000000BA	     0689	LSLS R1 R1 #26
 000000BC	     1840	ADDS R0 R0 R1
 000000BE	     9902	LDR R1 [ SP + 8 ]
 000000C0	     1209	ASRS R1 R1 #8
 000000C2	 F36F01DF	BFC R1 #3 #29
 000000C6	     0309	LSLS R1 R1 #12
 000000C8	     1840	ADDS R0 R0 R1
 000000CA	 F89D1004	LDRB R1 [ SP + 4 ]
 000000CE	     0209	LSLS R1 R1 #8
 000000D0	     1840	ADDS R0 R0 R1
 000000D2	     9902	LDR R1 [ SP + 8 ]
 000000D4	 F36F211F	BFC R1 #8 #24
 000000D8	     1840	ADDS R0 R0 R1
 000000DA	 F85DEB04	LDR LR [ SP ] + 4
 000000DE	     B002	ADD SP SP #8
 000000E0	     4770	BX LR
 000000E2	     B401	PUSH R0
 000000E4	     B500	PUSH LR
 000000E6	     9801	LDR R0 [ SP + 4 ]
 000000E8	     1200	ASRS R0 R0 #8
 000000EA	 F36F201F	BFC R0 #8 #24
 000000EE	     0600	LSLS R0 R0 #24
 000000F0	     9901	LDR R1 [ SP + 4 ]
 000000F2	 F36F211F	BFC R1 #8 #24
 000000F6	     0409	LSLS R1 R1 #16
 000000F8	     1840	ADDS R0 R0 R1
 000000FA	     9901	LDR R1 [ SP + 4 ]
 000000FC	     1609	ASRS R1 R1 #24
 000000FE	 F36F211F	BFC R1 #8 #24
 00000102	     0209	LSLS R1 R1 #8
 00000104	     1840	ADDS R0 R0 R1
 00000106	     9901	LDR R1 [ SP + 4 ]
 00000108	     1409	ASRS R1 R1 #16
 0000010A	 F36F211F	BFC R1 #8 #24
 0000010E	     1840	ADDS R0 R0 R1
 00000110	 F85DEB04	LDR LR [ SP ] + 4
 00000114	     B001	ADD SP SP #4
 00000116	     4770	BX LR
 00000118	     B081	SUB SP SP #4
 0000011A	     B401	PUSH R0
 0000011C	     B500	PUSH LR
 0000011E	     9801	LDR R0 [ SP + 4 ]
 00000120	     7800	LDRB R0 [ R0 + 0 ]
 00000122	 F88D000B	STRB R0 [  SP + 11 ]
 00000126	     9801	LDR R0 [ SP + 4 ]
 00000128	     1C40	ADDS R0 R0 #1
 0000012A	     7800	LDRB R0 [ R0 + 0 ]
 0000012C	 F88D000A	STRB R0 [  SP + 10 ]
 00000130	     9801	LDR R0 [ SP + 4 ]
 00000132	     1C80	ADDS R0 R0 #2
 00000134	     7800	LDRB R0 [ R0 + 0 ]
 00000136	 F88D0009	STRB R0 [  SP + 9 ]
 0000013A	     9801	LDR R0 [ SP + 4 ]
 0000013C	     1CC0	ADDS R0 R0 #3
 0000013E	     7800	LDRB R0 [ R0 + 0 ]
 00000140	 F88D0008	STRB R0 [  SP + 8 ]
 00000144	 F89D000B	LDRB R0 [ SP + 11 ]
 00000148	 F89D1008	LDRB R1 [ SP + 8 ]
 0000014C	     0209	LSLS R1 R1 #8
 0000014E	 F89D2009	LDRB R2 [ SP + 9 ]
 00000152	     1851	ADDS R1 R2 R1
 00000154	     0209	LSLS R1 R1 #8
 00000156	 F89D200A	LDRB R2 [ SP + 10 ]
 0000015A	     1851	ADDS R1 R2 R1
 0000015C	     0209	LSLS R1 R1 #8
 0000015E	     1840	ADDS R0 R0 R1
 00000160	 F85DEB04	LDR LR [ SP ] + 4
 00000164	     B002	ADD SP SP #8
 00000166	     4770	BX LR
 00000168	     B081	SUB SP SP #4
 0000016A	     B403	PUSH R0 R1
 0000016C	     B500	PUSH LR
 0000016E	     9802	LDR R0 [ SP + 8 ]
 00000170	 F36F201F	BFC R0 #8 #24
 00000174	 F88D000F	STRB R0 [  SP + 15 ]
 00000178	     9802	LDR R0 [ SP + 8 ]
 0000017A	     1200	ASRS R0 R0 #8
 0000017C	     9002	STR R0 [ SP + 8 ]
 0000017E	     9802	LDR R0 [ SP + 8 ]
 00000180	 F36F201F	BFC R0 #8 #24
 00000184	 F88D000E	STRB R0 [  SP + 14 ]
 00000188	     9802	LDR R0 [ SP + 8 ]
 0000018A	     1200	ASRS R0 R0 #8
 0000018C	     9002	STR R0 [ SP + 8 ]
 0000018E	     9802	LDR R0 [ SP + 8 ]
 00000190	 F36F201F	BFC R0 #8 #24
 00000194	 F88D000D	STRB R0 [  SP + 13 ]
 00000198	     9802	LDR R0 [ SP + 8 ]
 0000019A	     1200	ASRS R0 R0 #8
 0000019C	     9002	STR R0 [ SP + 8 ]
 0000019E	     9802	LDR R0 [ SP + 8 ]
 000001A0	 F36F201F	BFC R0 #8 #24
 000001A4	 F88D000C	STRB R0 [  SP + 12 ]
 000001A8	     9801	LDR R0 [ SP + 4 ]
 000001AA	 F89D100F	LDRB R1 [ SP + 15 ]
 000001AE	     7001	STRB R1 [ R0 + 0 ]
 000001B0	     9801	LDR R0 [ SP + 4 ]
 000001B2	     1C40	ADDS R0 R0 #1
 000001B4	 F89D100E	LDRB R1 [ SP + 14 ]
 000001B8	     7001	STRB R1 [ R0 + 0 ]
 000001BA	     9801	LDR R0 [ SP + 4 ]
 000001BC	     1C80	ADDS R0 R0 #2
 000001BE	 F89D100D	LDRB R1 [ SP + 13 ]
 000001C2	     7001	STRB R1 [ R0 + 0 ]
 000001C4	     9801	LDR R0 [ SP + 4 ]
 000001C6	     1CC0	ADDS R0 R0 #3
 000001C8	 F89D100C	LDRB R1 [ SP + 12 ]
 000001CC	     7001	STRB R1 [ R0 + 0 ]
 000001CE	 F85DEB04	LDR LR [ SP ] + 4
 000001D2	     B003	ADD SP SP #12
 000001D4	     4770	BX LR
 000001D6	     B089	SUB SP SP #36
 000001D8	     B403	PUSH R0 R1
 000001DA	     B500	PUSH LR
 000001DC	     2000	MOVS R0 #0
 000001DE	     9003	STR R0 [ SP + 12 ]
 000001E0	     9803	LDR R0 [ SP + 12 ]
 000001E2	     9902	LDR R1 [ SP + 8 ]
 000001E4	     4288	CMP R0 R1
 000001E6	     BF28	IT CS
 000001E8	 EC01A181	TrapCS 1 at pos 3352
 000001EC	     9901	LDR R1 [ SP + 4 ]
 000001EE	     1808	ADDS R0 R1 R0
 000001F0	     7800	LDRB R0 [ R0 + 0 ]
 000001F2	     2800	CMP R0 #0
 000001F4	 F0008014	BEQ #40, goes to  00000220
 000001F8	     9803	LDR R0 [ SP + 12 ]
 000001FA	     2820	CMP R0 #32
 000001FC	     BF28	IT CS
 000001FE	 EC01A2C1	TrapCS 1 at pos 3372
 00000202	     4468	ADD R0 SP R0
 00000204	     9903	LDR R1 [ SP + 12 ]
 00000206	     9A02	LDR R2 [ SP + 8 ]
 00000208	     4291	CMP R1 R2
 0000020A	     BF28	IT CS
 0000020C	 EC01A371	TrapCS 1 at pos 3383
 00000210	     9A01	LDR R2 [ SP + 4 ]
 00000212	     1851	ADDS R1 R2 R1
 00000214	     7809	LDRB R1 [ R1 + 0 ]
 00000216	     7401	STRB R1 [ R0 + 16 ]
 00000218	     9803	LDR R0 [ SP + 12 ]
 0000021A	     1C40	ADDS R0 R0 #1
 0000021C	     9003	STR R0 [ SP + 12 ]
 0000021E	     E7DF	B #-66, goes to  000001E0
 00000220	     9803	LDR R0 [ SP + 12 ]
 00000222	     2820	CMP R0 #32
 00000224	     BF28	IT CS
 00000226	 EC01A551	TrapCS 1 at pos 3413
 0000022A	     4468	ADD R0 SP R0
 0000022C	     212E	MOVS R1 #46
 0000022E	     7401	STRB R1 [ R0 + 16 ]
 00000230	     9803	LDR R0 [ SP + 12 ]
 00000232	     1C40	ADDS R0 R0 #1
 00000234	     2820	CMP R0 #32
 00000236	     BF28	IT CS
 00000238	 EC01A6B1	TrapCS 1 at pos 3435
 0000023C	     4468	ADD R0 SP R0
 0000023E	     216D	MOVS R1 #109
 00000240	     7401	STRB R1 [ R0 + 16 ]
 00000242	     9803	LDR R0 [ SP + 12 ]
 00000244	     1C80	ADDS R0 R0 #2
 00000246	     2820	CMP R0 #32
 00000248	     BF28	IT CS
 0000024A	 EC01B011	TrapCS 1 at pos 3457
 0000024E	     4468	ADD R0 SP R0
 00000250	     2134	MOVS R1 #52
 00000252	     7401	STRB R1 [ R0 + 16 ]
 00000254	     9803	LDR R0 [ SP + 12 ]
 00000256	     1CC0	ADDS R0 R0 #3
 00000258	     2820	CMP R0 #32
 0000025A	     BF28	IT CS
 0000025C	 EC01B171	TrapCS 1 at pos 3479
 00000260	     4468	ADD R0 SP R0
 00000262	     2163	MOVS R1 #99
 00000264	     7401	STRB R1 [ R0 + 16 ]
 00000266	     9803	LDR R0 [ SP + 12 ]
 00000268	     1D00	ADDS R0 R0 #4
 0000026A	     2820	CMP R0 #32
 0000026C	     BF28	IT CS
 0000026E	 EC01B2D1	TrapCS 1 at pos 3501
 00000272	     4468	ADD R0 SP R0
 00000274	     2100	MOVS R1 #0
 00000276	     7401	STRB R1 [ R0 + 16 ]
 00000278	     A804	ADD R0 SP #16
 0000027A	     2120	MOVS R1 #32
 0000027C	 2020013E	BL Mod(  2) proc(2)
 00000280	 F85DEB04	LDR LR [ SP ] + 4
 00000284	     B00B	ADD SP SP #44
 00000286	     4770	BX LR
 00000288	     B407	PUSH R0 R1 R2
 0000028A	     B500	PUSH LR
 0000028C	     9801	LDR R0 [ SP + 4 ]
 0000028E	 10000147	MOV R1 lower 16-bits base(0), next at  00000000
 00000292	 0000000C	MOVT R1 higher 16-bits var + 12
 00000296	     6008	STR R0 [  R1 + 0 ]
 00000298	 00000005	MOV R0 lower 16-bits base(0), next at  0000028E
 0000029C	 00000010	MOVT R0 higher 16-bits var + 16
 000002A0	     9902	LDR R1 [ SP + 8 ]
 000002A2	     9A03	LDR R2 [ SP + 12 ]
 000002A4	     2A00	CMP R2 #0
 000002A6	     D00B	BEQ #22, goes to  000002C0
 000002A8	     1CD2	ADDS R2 R2 #3
 000002AA	     1092	ASRS R2 R2 #2
 000002AC	     2A08	CMP R2 #8
 000002AE	     BFC8	IT GT
 000002B0	 EC01C423	TrapGT 3 at pos 3650
 000002B4	 F8513B04	LDR R3 [ R1 ] + 4
 000002B8	 F8403B04	STR R3 [  R0 ] + 4
 000002BC	     1E52	SUBS R2 R2 #1
 000002BE	     D1F9	BNE #-14, goes to  000002B4
 000002C0	 F85DEB04	LDR LR [ SP ] + 4
 000002C4	     B003	ADD SP SP #12
 000002C6	     4770	BX LR
 000002C8	     B082	SUB SP SP #8
 000002CA	     B403	PUSH R0 R1
 000002CC	     B500	PUSH LR
 000002CE	     2000	MOVS R0 #0
 000002D0	     9902	LDR R1 [ SP + 8 ]
 000002D2	     4288	CMP R0 R1
 000002D4	     BF28	IT CS
 000002D6	 EC01D201	TrapCS 1 at pos 3744
 000002DA	     9901	LDR R1 [ SP + 4 ]
 000002DC	     1808	ADDS R0 R1 R0
 000002DE	     7800	LDRB R0 [ R0 + 0 ]
 000002E0	 F88D0010	STRB R0 [  SP + 16 ]
 000002E4	     2001	MOVS R0 #1
 000002E6	 10000027	MOV R1 lower 16-bits base(0), next at  00000298
 000002EA	 0000000C	MOVT R1 higher 16-bits var + 12
 000002EE	     6008	STR R0 [  R1 + 0 ]
 000002F0	     2001	MOVS R0 #1
 000002F2	     9003	STR R0 [ SP + 12 ]
 000002F4	 F89D0010	LDRB R0 [ SP + 16 ]
 000002F8	     2841	CMP R0 #65
 000002FA	 F2C08005	BLT #10, goes to  00000308
 000002FE	 F89D0010	LDRB R0 [ SP + 16 ]
 00000302	     285A	CMP R0 #90
 00000304	 F340800A	BLE #20, goes to  0000031C
 00000308	 F89D0010	LDRB R0 [ SP + 16 ]
 0000030C	     2861	CMP R0 #97
 0000030E	 F2C08048	BLT #144, goes to  000003A2
 00000312	 F89D0010	LDRB R0 [ SP + 16 ]
 00000316	     287A	CMP R0 #122
 00000318	 F3008043	BGT #134, goes to  000003A2
 0000031C	     9803	LDR R0 [ SP + 12 ]
 0000031E	     9902	LDR R1 [ SP + 8 ]
 00000320	     4288	CMP R0 R1
 00000322	     BF28	IT CS
 00000324	 EC01E0E1	TrapCS 1 at pos 3854
 00000328	     9901	LDR R1 [ SP + 4 ]
 0000032A	     1808	ADDS R0 R1 R0
 0000032C	     7800	LDRB R0 [ R0 + 0 ]
 0000032E	 F88D0010	STRB R0 [  SP + 16 ]
 00000332	     9803	LDR R0 [ SP + 12 ]
 00000334	     1C40	ADDS R0 R0 #1
 00000336	     9003	STR R0 [ SP + 12 ]
 00000338	 F89D0010	LDRB R0 [ SP + 16 ]
 0000033C	     2830	CMP R0 #48
 0000033E	 F2C08005	BLT #10, goes to  0000034C
 00000342	 F89D0010	LDRB R0 [ SP + 16 ]
 00000346	     2839	CMP R0 #57
 00000348	 F3408019	BLE #50, goes to  0000037E
 0000034C	 F89D0010	LDRB R0 [ SP + 16 ]
 00000350	     2841	CMP R0 #65
 00000352	 F2C08005	BLT #10, goes to  00000360
 00000356	 F89D0010	LDRB R0 [ SP + 16 ]
 0000035A	     285A	CMP R0 #90
 0000035C	 F340800F	BLE #30, goes to  0000037E
 00000360	 F89D0010	LDRB R0 [ SP + 16 ]
 00000364	     2861	CMP R0 #97
 00000366	 F2C08005	BLT #10, goes to  00000374
 0000036A	 F89D0010	LDRB R0 [ SP + 16 ]
 0000036E	     287A	CMP R0 #122
 00000370	 F3408005	BLE #10, goes to  0000037E
 00000374	 F89D0010	LDRB R0 [ SP + 16 ]
 00000378	     282E	CMP R0 #46
 0000037A	 F0408003	BNE #6, goes to  00000384
 0000037E	     9803	LDR R0 [ SP + 12 ]
 00000380	     2820	CMP R0 #32
 00000382	     D1CB	BNE #-106, goes to  0000031C
 00000384	     9803	LDR R0 [ SP + 12 ]
 00000386	     2820	CMP R0 #32
 00000388	 F280800B	BGE #22, goes to  000003A2
 0000038C	 F89D0010	LDRB R0 [ SP + 16 ]
 00000390	     2800	CMP R0 #0
 00000392	 F0408006	BNE #12, goes to  000003A2
 00000396	     2000	MOVS R0 #0
 00000398	 10000059	MOV R1 lower 16-bits base(0), next at  000002E6
 0000039C	 0000000C	MOVT R1 higher 16-bits var + 12
 000003A0	     6008	STR R0 [  R1 + 0 ]
 000003A2	 F85DEB04	LDR LR [ SP ] + 4
 000003A6	     B004	ADD SP SP #16
 000003A8	     4770	BX LR
 000003AA	     B0C2	SUB SP SP #264
 000003AC	     B407	PUSH R0 R1 R2
 000003AE	     B500	PUSH LR
 000003B0	 0000000C	MOV R0 lower 16-bits base(0), next at  00000398
 000003B4	 00000000	MOVT R0 higher 16-bits var + 0
 000003B8	     6800	LDR R0 [ R0 + 0 ]
 000003BA	     9004	STR R0 [ SP + 16 ]
 000003BC	     2000	MOVS R0 #0
 000003BE	     9901	LDR R1 [ SP + 4 ]
 000003C0	     9A02	LDR R2 [ SP + 8 ]
 000003C2	 F7FFFF61	BL #-318, goes to  00000288
 000003C6	     2000	MOVS R0 #0
 000003C8	     900B	STR R0 [ SP + 44 ]
 000003CA	     2000	MOVS R0 #0
 000003CC	 F88D0046	STRB R0 [  SP + 70 ]
 000003D0	     9804	LDR R0 [ SP + 16 ]
 000003D2	     2800	CMP R0 #0
 000003D4	 F0008018	BEQ #48, goes to  00000408
 000003D8	     9804	LDR R0 [ SP + 16 ]
 000003DA	     2800	CMP R0 #0
 000003DC	     BF08	IT EQ
 000003DE	 EC026214	TrapEQ 4 at pos 4897
 000003E2	     9901	LDR R1 [ SP + 4 ]
 000003E4	 F8112B01	LDRB R2 [  R1 ] + 1
 000003E8	 F8103B01	LDRB R3 [  R0 ] + 1
 000003EC	     429A	CMP R2 R3
 000003EE	     D101	BNE #2, goes to  000003F4
 000003F0	     2A00	CMP R2 #0
 000003F2	     D1F7	BNE #-18, goes to  000003E4
 000003F4	 F0008008	BEQ #16, goes to  00000408
 000003F8	     9804	LDR R0 [ SP + 16 ]
 000003FA	     2800	CMP R0 #0
 000003FC	     BF08	IT EQ
 000003FE	 EC026354	TrapEQ 4 at pos 4917
 00000402	     6A00	LDR R0 [ R0 + 32 ]
 00000404	     9004	STR R0 [ SP + 16 ]
 00000406	     E7E3	B #-58, goes to  000003D0
 00000408	     9804	LDR R0 [ SP + 16 ]
 0000040A	     2800	CMP R0 #0
 0000040C	 F0408533	BNE #2662, goes to  00000E76
 00000410	     9801	LDR R0 [ SP + 4 ]
 00000412	     9902	LDR R1 [ SP + 8 ]
 00000414	 F7FFFF58	BL #-336, goes to  000002C8
 00000418	 00000034	MOV R0 lower 16-bits base(0), next at  000003B0
 0000041C	 0000000C	MOVT R0 higher 16-bits var + 12
 00000420	     6800	LDR R0 [ R0 + 0 ]
 00000422	     2800	CMP R0 #0
 00000424	 F0408007	BNE #14, goes to  00000436
 00000428	     9801	LDR R0 [ SP + 4 ]
 0000042A	     9902	LDR R1 [ SP + 8 ]
 0000042C	 F7FFFED3	BL #-602, goes to  000001D6
 00000430	     902F	STR R0 [ SP + 188 ]
 00000432	 F000B802	B #4, goes to  0000043A
 00000436	     2000	MOVS R0 #0
 00000438	     902F	STR R0 [ SP + 188 ]
 0000043A	     982F	LDR R0 [ SP + 188 ]
 0000043C	     2800	CMP R0 #0
 0000043E	 F00080B8	BEQ #368, goes to  000005B2
 00000442	     A830	ADD R0 SP #192
 00000444	 12000222	MOV R1 lower 16-bits base(2), next at  00000000
 00000448	 00000001	MOVT R1 higher 16-bits const(1)
 0000044C	     9A2F	LDR R2 [ SP + 188 ]
 0000044E	     2300	MOVS R3 #0
 00000450	 20B000EA	BL Mod(  2) proc(11)
 00000454	     A830	ADD R0 SP #192
 00000456	 12000009	MOV R1 lower 16-bits base(2), next at  00000444
 0000045A	 00000001	MOVT R1 higher 16-bits const(1)
 0000045E	     AA1F	ADD R2 SP #124
 00000460	     2320	MOVS R3 #32
 00000462	 21400009	BL Mod(  2) proc(20)
 00000466	     A830	ADD R0 SP #192
 00000468	 12000009	MOV R1 lower 16-bits base(2), next at  00000456
 0000046C	 00000001	MOVT R1 higher 16-bits const(1)
 00000470	     AA08	ADD R2 SP #32
 00000472	 21100008	BL Mod(  2) proc(17)
 00000476	     A830	ADD R0 SP #192
 00000478	 12000008	MOV R1 lower 16-bits base(2), next at  00000468
 0000047C	 00000001	MOVT R1 higher 16-bits const(1)
 00000480	 F10D0245	ADD R2 SP #69
 00000484	 21000009	BL Mod(  2) proc(16)
 00000488	     A830	ADD R0 SP #192
 0000048A	 12000009	MOV R1 lower 16-bits base(2), next at  00000478
 0000048E	 00000001	MOVT R1 higher 16-bits const(1)
 00000492	     AA0C	ADD R2 SP #48
 00000494	 21100008	BL Mod(  2) proc(17)
 00000498	 00000040	MOV R0 lower 16-bits base(0), next at  00000418
 0000049C	 00000010	MOVT R0 higher 16-bits var + 16
 000004A0	     A91F	ADD R1 SP #124
 000004A2	     2208	MOVS R2 #8
 000004A4	 F8513B04	LDR R3 [ R1 ] + 4
 000004A8	 F8403B04	STR R3 [  R0 ] + 4
 000004AC	     1E52	SUBS R2 R2 #1
 000004AE	     D1F9	BNE #-14, goes to  000004A4
 000004B0	 F89D0045	LDRB R0 [ SP + 69 ]
 000004B4	     2801	CMP R0 #1
 000004B6	 F0408075	BNE #234, goes to  000005A4
 000004BA	     A830	ADD R0 SP #192
 000004BC	 12000019	MOV R1 lower 16-bits base(2), next at  0000048A
 000004C0	 00000001	MOVT R1 higher 16-bits const(1)
 000004C4	     AA27	ADD R2 SP #156
 000004C6	     2320	MOVS R3 #32
 000004C8	 2140001A	BL Mod(  2) proc(20)
 000004CC	 F89D009C	LDRB R0 [ SP + 156 ]
 000004D0	     2800	CMP R0 #0
 000004D2	 F0008065	BEQ #202, goes to  000005A0
 000004D6	 0000001F	MOV R0 lower 16-bits base(0), next at  00000498
 000004DA	 0000000C	MOVT R0 higher 16-bits var + 12
 000004DE	     6800	LDR R0 [ R0 + 0 ]
 000004E0	     2800	CMP R0 #0
 000004E2	 F040805D	BNE #186, goes to  000005A0
 000004E6	     A830	ADD R0 SP #192
 000004E8	 12000016	MOV R1 lower 16-bits base(2), next at  000004BC
 000004EC	 00000001	MOVT R1 higher 16-bits const(1)
 000004F0	     AA09	ADD R2 SP #36
 000004F2	 21100015	BL Mod(  2) proc(17)
 000004F6	     A827	ADD R0 SP #156
 000004F8	     2120	MOVS R1 #32
 000004FA	     AA05	ADD R2 SP #20
 000004FC	 F7FFFF55	BL #-342, goes to  000003AA
 00000500	     980B	LDR R0 [ SP + 44 ]
 00000502	     2810	CMP R0 #16
 00000504	     BF28	IT CS
 00000506	 EC02A371	TrapCS 1 at pos 5431
 0000050A	 EB0D0080	ADD R0 SP R0 LSL #2
 0000050E	     9905	LDR R1 [ SP + 20 ]
 00000510	 F8C010D8	STR R1 [  R0 + 216 ]
 00000514	 0000001F	MOV R0 lower 16-bits base(0), next at  000004D6
 00000518	 00000010	MOVT R0 higher 16-bits var + 16
 0000051C	     A91F	ADD R1 SP #124
 0000051E	     2208	MOVS R2 #8
 00000520	 F8513B04	LDR R3 [ R1 ] + 4
 00000524	 F8403B04	STR R3 [  R0 ] + 4
 00000528	     1E52	SUBS R2 R2 #1
 0000052A	     D1F9	BNE #-14, goes to  00000520
 0000052C	 0000000C	MOV R0 lower 16-bits base(0), next at  00000514
 00000530	 0000000C	MOVT R0 higher 16-bits var + 12
 00000534	     6800	LDR R0 [ R0 + 0 ]
 00000536	     2800	CMP R0 #0
 00000538	 F0408028	BNE #80, goes to  0000058C
 0000053C	     9805	LDR R0 [ SP + 20 ]
 0000053E	     2800	CMP R0 #0
 00000540	     BF08	IT EQ
 00000542	 EC02B0E4	TrapEQ 4 at pos 5518
 00000546	     6A40	LDR R0 [ R0 + 36 ]
 00000548	     9909	LDR R1 [ SP + 36 ]
 0000054A	     4288	CMP R0 R1
 0000054C	 F040800D	BNE #26, goes to  0000056A
 00000550	     9805	LDR R0 [ SP + 20 ]
 00000552	     2800	CMP R0 #0
 00000554	     BF08	IT EQ
 00000556	 EC02B2E4	TrapEQ 4 at pos 5550
 0000055A	     6B01	LDR R1 [ R0 + 48 ]
 0000055C	     1C49	ADDS R1 R1 #1
 0000055E	     6301	STR R1 [  R0 + 48 ]
 00000560	     980B	LDR R0 [ SP + 44 ]
 00000562	     1C40	ADDS R0 R0 #1
 00000564	     900B	STR R0 [ SP + 44 ]
 00000566	 F000B811	B #34, goes to  0000058C
 0000056A	     2003	MOVS R0 #3
 0000056C	     A91F	ADD R1 SP #124
 0000056E	     2220	MOVS R2 #32
 00000570	 F7FFFE8A	BL #-748, goes to  00000288
 00000574	 00000024	MOV R0 lower 16-bits base(0), next at  0000052C
 00000578	 00000030	MOVT R0 higher 16-bits var + 48
 0000057C	     A927	ADD R1 SP #156
 0000057E	     2208	MOVS R2 #8
 00000580	 F8513B04	LDR R3 [ R1 ] + 4
 00000584	 F8403B04	STR R3 [  R0 ] + 4
 00000588	     1E52	SUBS R2 R2 #1
 0000058A	     D1F9	BNE #-14, goes to  00000580
 0000058C	     A830	ADD R0 SP #192
 0000058E	 12000053	MOV R1 lower 16-bits base(2), next at  000004E8
 00000592	 00000001	MOVT R1 higher 16-bits const(1)
 00000596	     AA27	ADD R2 SP #156
 00000598	     2320	MOVS R3 #32
 0000059A	 21400054	BL Mod(  2) proc(20)
 0000059E	     E795	B #-214, goes to  000004CC
 000005A0	 F000B805	B #10, goes to  000005AE
 000005A4	     2002	MOVS R0 #2
 000005A6	     A91F	ADD R1 SP #124
 000005A8	     2220	MOVS R2 #32
 000005AA	 F7FFFE6D	BL #-806, goes to  00000288
 000005AE	 F000B805	B #10, goes to  000005BC
 000005B2	     2001	MOVS R0 #1
 000005B4	     9901	LDR R1 [ SP + 4 ]
 000005B6	     9A02	LDR R2 [ SP + 8 ]
 000005B8	 F7FFFE66	BL #-820, goes to  00000288
 000005BC	 00000024	MOV R0 lower 16-bits base(0), next at  00000574
 000005C0	 0000000C	MOVT R0 higher 16-bits var + 12
 000005C4	     6800	LDR R0 [ R0 + 0 ]
 000005C6	     2800	CMP R0 #0
 000005C8	 F040808B	BNE #278, goes to  000006E2
 000005CC	     980C	LDR R0 [ SP + 48 ]
 000005CE	     3050	ADDS R0 R0 #80
 000005D0	     900C	STR R0 [ SP + 48 ]
 000005D2	 0000000B	MOV R0 lower 16-bits base(0), next at  000005BC
 000005D6	 00000000	MOVT R0 higher 16-bits var + 0
 000005DA	     6800	LDR R0 [ R0 + 0 ]
 000005DC	     9004	STR R0 [ SP + 16 ]
 000005DE	     9804	LDR R0 [ SP + 16 ]
 000005E0	     2800	CMP R0 #0
 000005E2	 F000801B	BEQ #54, goes to  0000061C
 000005E6	     9804	LDR R0 [ SP + 16 ]
 000005E8	     2800	CMP R0 #0
 000005EA	     BF08	IT EQ
 000005EC	 EC02E3B4	TrapEQ 4 at pos 5947
 000005F0	     7800	LDRB R0 [ R0 + 0 ]
 000005F2	     2800	CMP R0 #0
 000005F4	 F040800A	BNE #20, goes to  0000060C
 000005F8	     9804	LDR R0 [ SP + 16 ]
 000005FA	     2800	CMP R0 #0
 000005FC	     BF08	IT EQ
 000005FE	 EC02E504	TrapEQ 4 at pos 5968
 00000602	     6AC0	LDR R0 [ R0 + 44 ]
 00000604	     990C	LDR R1 [ SP + 48 ]
 00000606	     4288	CMP R0 R1
 00000608	 F2808008	BGE #16, goes to  0000061C
 0000060C	     9804	LDR R0 [ SP + 16 ]
 0000060E	     2800	CMP R0 #0
 00000610	     BF08	IT EQ
 00000612	 EC02E6D4	TrapEQ 4 at pos 5997
 00000616	     6A00	LDR R0 [ R0 + 32 ]
 00000618	     9004	STR R0 [ SP + 16 ]
 0000061A	     E7E0	B #-64, goes to  000005DE
 0000061C	     9804	LDR R0 [ SP + 16 ]
 0000061E	     2800	CMP R0 #0
 00000620	 F040805D	BNE #186, goes to  000006DE
 00000624	 00000029	MOV R0 lower 16-bits base(0), next at  000005D2
 00000628	 00000008	MOVT R0 higher 16-bits var + 8
 0000062C	     6800	LDR R0 [ R0 + 0 ]
 0000062E	     990C	LDR R1 [ SP + 48 ]
 00000630	     1840	ADDS R0 R0 R1
 00000632	 10000007	MOV R1 lower 16-bits base(0), next at  00000624
 00000636	 00000050	MOVT R1 higher 16-bits var + 80
 0000063A	     6809	LDR R1 [ R1 + 0 ]
 0000063C	     4288	CMP R0 R1
 0000063E	 F2808047	BGE #142, goes to  000006D0
 00000642	     2001	MOVS R0 #1
 00000644	 F88D0046	STRB R0 [  SP + 70 ]
 00000648	 0000000B	MOV R0 lower 16-bits base(0), next at  00000632
 0000064C	 00000008	MOVT R0 higher 16-bits var + 8
 00000650	     6800	LDR R0 [ R0 + 0 ]
 00000652	     900D	STR R0 [ SP + 52 ]
 00000654	     980D	LDR R0 [ SP + 52 ]
 00000656	     9004	STR R0 [ SP + 16 ]
 00000658	     980D	LDR R0 [ SP + 52 ]
 0000065A	     990C	LDR R1 [ SP + 48 ]
 0000065C	     1840	ADDS R0 R0 R1
 0000065E	     1CC0	ADDS R0 R0 #3
 00000660	     1080	ASRS R0 R0 #2
 00000662	     0080	LSLS R0 R0 #2
 00000664	 1000000E	MOV R1 lower 16-bits base(0), next at  00000648
 00000668	 00000008	MOVT R1 higher 16-bits var + 8
 0000066C	     6008	STR R0 [  R1 + 0 ]
 0000066E	     9804	LDR R0 [ SP + 16 ]
 00000670	     2800	CMP R0 #0
 00000672	     BF08	IT EQ
 00000674	 EC0307B4	TrapEQ 4 at pos 6267
 00000678	 1000000A	MOV R1 lower 16-bits base(0), next at  00000664
 0000067C	 00000008	MOVT R1 higher 16-bits var + 8
 00000680	     6809	LDR R1 [ R1 + 0 ]
 00000682	     9A0D	LDR R2 [ SP + 52 ]
 00000684	     1A89	SUBS R1 R1 R2
 00000686	     62C1	STR R1 [  R0 + 44 ]
 00000688	     9804	LDR R0 [ SP + 16 ]
 0000068A	     2800	CMP R0 #0
 0000068C	     BF08	IT EQ
 0000068E	 EC031144	TrapEQ 4 at pos 6292
 00000692	 1000000D	MOV R1 lower 16-bits base(0), next at  00000678
 00000696	 00000000	MOVT R1 higher 16-bits var + 0
 0000069A	     6809	LDR R1 [ R1 + 0 ]
 0000069C	     2900	CMP R1 #0
 0000069E	     BF08	IT EQ
 000006A0	 EC031204	TrapEQ 4 at pos 6304
 000006A4	     6A89	LDR R1 [ R1 + 40 ]
 000006A6	     1C49	ADDS R1 R1 #1
 000006A8	     6281	STR R1 [  R0 + 40 ]
 000006AA	     9804	LDR R0 [ SP + 16 ]
 000006AC	     2800	CMP R0 #0
 000006AE	     BF08	IT EQ
 000006B0	 EC0313A4	TrapEQ 4 at pos 6330
 000006B4	 10000011	MOV R1 lower 16-bits base(0), next at  00000692
 000006B8	 00000000	MOVT R1 higher 16-bits var + 0
 000006BC	     6809	LDR R1 [ R1 + 0 ]
 000006BE	     6201	STR R1 [  R0 + 32 ]
 000006C0	     9804	LDR R0 [ SP + 16 ]
 000006C2	 10000007	MOV R1 lower 16-bits base(0), next at  000006B4
 000006C6	 00000000	MOVT R1 higher 16-bits var + 0
 000006CA	     6008	STR R0 [  R1 + 0 ]
 000006CC	 F000B805	B #10, goes to  000006DA
 000006D0	     2007	MOVS R0 #7
 000006D2	     A91F	ADD R1 SP #124
 000006D4	     2220	MOVS R2 #32
 000006D6	 F7FFFDD7	BL #-1106, goes to  00000288
 000006DA	 F000B802	B #4, goes to  000006E2
 000006DE	     9804	LDR R0 [ SP + 16 ]
 000006E0	     900D	STR R0 [ SP + 52 ]
 000006E2	 00000010	MOV R0 lower 16-bits base(0), next at  000006C2
 000006E6	 0000000C	MOVT R0 higher 16-bits var + 12
 000006EA	     6800	LDR R0 [ R0 + 0 ]
 000006EC	     2800	CMP R0 #0
 000006EE	 F04081B0	BNE #864, goes to  00000A52
 000006F2	     980D	LDR R0 [ SP + 52 ]
 000006F4	     3050	ADDS R0 R0 #80
 000006F6	     900D	STR R0 [ SP + 52 ]
 000006F8	     9804	LDR R0 [ SP + 16 ]
 000006FA	     2800	CMP R0 #0
 000006FC	     BF08	IT EQ
 000006FE	 EC033354	TrapEQ 4 at pos 6581
 00000702	     9901	LDR R1 [ SP + 4 ]
 00000704	     9A02	LDR R2 [ SP + 8 ]
 00000706	     2A00	CMP R2 #0
 00000708	     D00B	BEQ #22, goes to  00000722
 0000070A	     1CD2	ADDS R2 R2 #3
 0000070C	     1092	ASRS R2 R2 #2
 0000070E	     2A08	CMP R2 #8
 00000710	     BFC8	IT GT
 00000712	 EC0333E3	TrapGT 3 at pos 6590
 00000716	 F8513B04	LDR R3 [ R1 ] + 4
 0000071A	 F8403B04	STR R3 [  R0 ] + 4
 0000071E	     1E52	SUBS R2 R2 #1
 00000720	     D1F9	BNE #-14, goes to  00000716
 00000722	     9804	LDR R0 [ SP + 16 ]
 00000724	     2800	CMP R0 #0
 00000726	     BF08	IT EQ
 00000728	 EC033464	TrapEQ 4 at pos 6598
 0000072C	     9908	LDR R1 [ SP + 32 ]
 0000072E	     6241	STR R1 [  R0 + 36 ]
 00000730	     9804	LDR R0 [ SP + 16 ]
 00000732	     2800	CMP R0 #0
 00000734	     BF08	IT EQ
 00000736	 EC033594	TrapEQ 4 at pos 6617
 0000073A	     2100	MOVS R1 #0
 0000073C	     6301	STR R1 [  R0 + 48 ]
 0000073E	     9804	LDR R0 [ SP + 16 ]
 00000740	     2800	CMP R0 #0
 00000742	     BF08	IT EQ
 00000744	 EC033704	TrapEQ 4 at pos 6640
 00000748	     990D	LDR R1 [ SP + 52 ]
 0000074A	     6341	STR R1 [  R0 + 52 ]
 0000074C	     A830	ADD R0 SP #192
 0000074E	 120000E0	MOV R1 lower 16-bits base(2), next at  0000058E
 00000752	 00000001	MOVT R1 higher 16-bits const(1)
 00000756	     AA07	ADD R2 SP #28
 00000758	 211000DF	BL Mod(  2) proc(17)
 0000075C	     9807	LDR R0 [ SP + 28 ]
 0000075E	     2800	CMP R0 #0
 00000760	 F3408012	BLE #36, goes to  00000788
 00000764	     A830	ADD R0 SP #192
 00000766	 1200000C	MOV R1 lower 16-bits base(2), next at  0000074E
 0000076A	 00000001	MOVT R1 higher 16-bits const(1)
 0000076E	     AA10	ADD R2 SP #64
 00000770	 2110000C	BL Mod(  2) proc(17)
 00000774	     980D	LDR R0 [ SP + 52 ]
 00000776	     9910	LDR R1 [ SP + 64 ]
 00000778	     6001	STR R1 [  R0 + 0 ]
 0000077A	     980D	LDR R0 [ SP + 52 ]
 0000077C	     1D00	ADDS R0 R0 #4
 0000077E	     900D	STR R0 [ SP + 52 ]
 00000780	     9807	LDR R0 [ SP + 28 ]
 00000782	     1F00	SUBS R0 R0 #4
 00000784	     9007	STR R0 [ SP + 28 ]
 00000786	     E7E9	B #-46, goes to  0000075C
 00000788	     A830	ADD R0 SP #192
 0000078A	 12000012	MOV R1 lower 16-bits base(2), next at  00000766
 0000078E	 00000001	MOVT R1 higher 16-bits const(1)
 00000792	     AA07	ADD R2 SP #28
 00000794	 21100012	BL Mod(  2) proc(17)
 00000798	     9807	LDR R0 [ SP + 28 ]
 0000079A	     2800	CMP R0 #0
 0000079C	 F340800A	BLE #20, goes to  000007B4
 000007A0	     980D	LDR R0 [ SP + 52 ]
 000007A2	     2100	MOVS R1 #0
 000007A4	     6001	STR R1 [  R0 + 0 ]
 000007A6	     980D	LDR R0 [ SP + 52 ]
 000007A8	     1D00	ADDS R0 R0 #4
 000007AA	     900D	STR R0 [ SP + 52 ]
 000007AC	     9807	LDR R0 [ SP + 28 ]
 000007AE	     1F00	SUBS R0 R0 #4
 000007B0	     9007	STR R0 [ SP + 28 ]
 000007B2	     E7F1	B #-30, goes to  00000798
 000007B4	     A830	ADD R0 SP #192
 000007B6	 12000016	MOV R1 lower 16-bits base(2), next at  0000078A
 000007BA	 00000001	MOVT R1 higher 16-bits const(1)
 000007BE	     AA07	ADD R2 SP #28
 000007C0	 21100016	BL Mod(  2) proc(17)
 000007C4	     9807	LDR R0 [ SP + 28 ]
 000007C6	     2800	CMP R0 #0
 000007C8	 F3408014	BLE #40, goes to  000007F4
 000007CC	     A830	ADD R0 SP #192
 000007CE	 1200000C	MOV R1 lower 16-bits base(2), next at  000007B6
 000007D2	 00000001	MOVT R1 higher 16-bits const(1)
 000007D6	 F10D0245	ADD R2 SP #69
 000007DA	 2100000D	BL Mod(  2) proc(16)
 000007DE	     980D	LDR R0 [ SP + 52 ]
 000007E0	 F89D1045	LDRB R1 [ SP + 69 ]
 000007E4	     7001	STRB R1 [ R0 + 0 ]
 000007E6	     980D	LDR R0 [ SP + 52 ]
 000007E8	     1C40	ADDS R0 R0 #1
 000007EA	     900D	STR R0 [ SP + 52 ]
 000007EC	     9807	LDR R0 [ SP + 28 ]
 000007EE	     1E40	SUBS R0 R0 #1
 000007F0	     9007	STR R0 [ SP + 28 ]
 000007F2	     E7E7	B #-50, goes to  000007C4
 000007F4	     9804	LDR R0 [ SP + 16 ]
 000007F6	     2800	CMP R0 #0
 000007F8	     BF08	IT EQ
 000007FA	 EC0370F4	TrapEQ 4 at pos 7055
 000007FE	     990D	LDR R1 [ SP + 52 ]
 00000800	     6381	STR R1 [  R0 + 56 ]
 00000802	     A830	ADD R0 SP #192
 00000804	 1200001B	MOV R1 lower 16-bits base(2), next at  000007CE
 00000808	 00000001	MOVT R1 higher 16-bits const(1)
 0000080C	     AA07	ADD R2 SP #28
 0000080E	 2110001A	BL Mod(  2) proc(17)
 00000812	     9807	LDR R0 [ SP + 28 ]
 00000814	     2800	CMP R0 #0
 00000816	 F3408012	BLE #36, goes to  0000083E
 0000081A	     A830	ADD R0 SP #192
 0000081C	 1200000C	MOV R1 lower 16-bits base(2), next at  00000804
 00000820	 00000001	MOVT R1 higher 16-bits const(1)
 00000824	     AA10	ADD R2 SP #64
 00000826	 2110000C	BL Mod(  2) proc(17)
 0000082A	     980D	LDR R0 [ SP + 52 ]
 0000082C	     9910	LDR R1 [ SP + 64 ]
 0000082E	     6001	STR R1 [  R0 + 0 ]
 00000830	     980D	LDR R0 [ SP + 52 ]
 00000832	     1D00	ADDS R0 R0 #4
 00000834	     900D	STR R0 [ SP + 52 ]
 00000836	     9807	LDR R0 [ SP + 28 ]
 00000838	     1F00	SUBS R0 R0 #4
 0000083A	     9007	STR R0 [ SP + 28 ]
 0000083C	     E7E9	B #-46, goes to  00000812
 0000083E	     9804	LDR R0 [ SP + 16 ]
 00000840	     2800	CMP R0 #0
 00000842	     BF08	IT EQ
 00000844	 EC0387C4	TrapEQ 4 at pos 7292
 00000848	     990D	LDR R1 [ SP + 52 ]
 0000084A	     63C1	STR R1 [  R0 + 60 ]
 0000084C	     2000	MOVS R0 #0
 0000084E	     9006	STR R0 [ SP + 24 ]
 00000850	     9806	LDR R0 [ SP + 24 ]
 00000852	     990B	LDR R1 [ SP + 44 ]
 00000854	     4288	CMP R0 R1
 00000856	 F2808012	BGE #36, goes to  0000087E
 0000085A	     9806	LDR R0 [ SP + 24 ]
 0000085C	     2810	CMP R0 #16
 0000085E	     BF28	IT CS
 00000860	 EC039631	TrapCS 1 at pos 7395
 00000864	 EB0D0080	ADD R0 SP R0 LSL #2
 00000868	     990D	LDR R1 [ SP + 52 ]
 0000086A	 F8D000D8	LDR R0 [ R0 + 216 ]
 0000086E	     6008	STR R0 [  R1 + 0 ]
 00000870	     980D	LDR R0 [ SP + 52 ]
 00000872	     1D00	ADDS R0 R0 #4
 00000874	     900D	STR R0 [ SP + 52 ]
 00000876	     9806	LDR R0 [ SP + 24 ]
 00000878	     1C40	ADDS R0 R0 #1
 0000087A	     9006	STR R0 [ SP + 24 ]
 0000087C	     E7E8	B #-48, goes to  00000850
 0000087E	     9804	LDR R0 [ SP + 16 ]
 00000880	     2800	CMP R0 #0
 00000882	     BF08	IT EQ
 00000884	 EC03A154	TrapEQ 4 at pos 7445
 00000888	     990D	LDR R1 [ SP + 52 ]
 0000088A	     6401	STR R1 [  R0 + 64 ]
 0000088C	     A830	ADD R0 SP #192
 0000088E	 12000039	MOV R1 lower 16-bits base(2), next at  0000081C
 00000892	 00000001	MOVT R1 higher 16-bits const(1)
 00000896	 F10D0245	ADD R2 SP #69
 0000089A	 2100003A	BL Mod(  2) proc(16)
 0000089E	 F89D0045	LDRB R0 [ SP + 69 ]
 000008A2	     2800	CMP R0 #0
 000008A4	 F0008037	BEQ #110, goes to  00000916
 000008A8	     980D	LDR R0 [ SP + 52 ]
 000008AA	 F89D1045	LDRB R1 [ SP + 69 ]
 000008AE	     7001	STRB R1 [ R0 + 0 ]
 000008B0	     980D	LDR R0 [ SP + 52 ]
 000008B2	     1C40	ADDS R0 R0 #1
 000008B4	     900D	STR R0 [ SP + 52 ]
 000008B6	     A830	ADD R0 SP #192
 000008B8	 12000015	MOV R1 lower 16-bits base(2), next at  0000088E
 000008BC	 00000001	MOVT R1 higher 16-bits const(1)
 000008C0	 F10D0245	ADD R2 SP #69
 000008C4	 21000015	BL Mod(  2) proc(16)
 000008C8	 F89D0045	LDRB R0 [ SP + 69 ]
 000008CC	     2800	CMP R0 #0
 000008CE	     D1EB	BNE #-42, goes to  000008A8
 000008D0	     980D	LDR R0 [ SP + 52 ]
 000008D2	     2100	MOVS R1 #0
 000008D4	     7001	STRB R1 [ R0 + 0 ]
 000008D6	     980D	LDR R0 [ SP + 52 ]
 000008D8	     1C40	ADDS R0 R0 #1
 000008DA	     900D	STR R0 [ SP + 52 ]
 000008DC	     980D	LDR R0 [ SP + 52 ]
 000008DE	 F36F009F	BFC R0 #2 #30
 000008E2	     2800	CMP R0 #0
 000008E4	     D1F4	BNE #-24, goes to  000008D0
 000008E6	     A830	ADD R0 SP #192
 000008E8	 12000018	MOV R1 lower 16-bits base(2), next at  000008B8
 000008EC	 00000001	MOVT R1 higher 16-bits const(1)
 000008F0	     AA07	ADD R2 SP #28
 000008F2	 21100017	BL Mod(  2) proc(17)
 000008F6	     980D	LDR R0 [ SP + 52 ]
 000008F8	     9907	LDR R1 [ SP + 28 ]
 000008FA	     6001	STR R1 [  R0 + 0 ]
 000008FC	     980D	LDR R0 [ SP + 52 ]
 000008FE	     1D00	ADDS R0 R0 #4
 00000900	     900D	STR R0 [ SP + 52 ]
 00000902	     A830	ADD R0 SP #192
 00000904	 1200000E	MOV R1 lower 16-bits base(2), next at  000008E8
 00000908	 00000001	MOVT R1 higher 16-bits const(1)
 0000090C	 F10D0245	ADD R2 SP #69
 00000910	 2100000F	BL Mod(  2) proc(16)
 00000914	     E7C3	B #-122, goes to  0000089E
 00000916	     980D	LDR R0 [ SP + 52 ]
 00000918	     2100	MOVS R1 #0
 0000091A	     7001	STRB R1 [ R0 + 0 ]
 0000091C	     980D	LDR R0 [ SP + 52 ]
 0000091E	     1C40	ADDS R0 R0 #1
 00000920	     900D	STR R0 [ SP + 52 ]
 00000922	     980D	LDR R0 [ SP + 52 ]
 00000924	 F36F009F	BFC R0 #2 #30
 00000928	     2800	CMP R0 #0
 0000092A	     D1F4	BNE #-24, goes to  00000916
 0000092C	     9804	LDR R0 [ SP + 16 ]
 0000092E	     2800	CMP R0 #0
 00000930	     BF08	IT EQ
 00000932	 EC03D084	TrapEQ 4 at pos 7816
 00000936	     990D	LDR R1 [ SP + 52 ]
 00000938	     6441	STR R1 [  R0 + 68 ]
 0000093A	     A830	ADD R0 SP #192
 0000093C	 1200001C	MOV R1 lower 16-bits base(2), next at  00000904
 00000940	 00000001	MOVT R1 higher 16-bits const(1)
 00000944	     AA07	ADD R2 SP #28
 00000946	 2110001B	BL Mod(  2) proc(17)
 0000094A	     9807	LDR R0 [ SP + 28 ]
 0000094C	     2800	CMP R0 #0
 0000094E	 F3408012	BLE #36, goes to  00000976
 00000952	     A830	ADD R0 SP #192
 00000954	 1200000C	MOV R1 lower 16-bits base(2), next at  0000093C
 00000958	 00000001	MOVT R1 higher 16-bits const(1)
 0000095C	     AA10	ADD R2 SP #64
 0000095E	 2110000C	BL Mod(  2) proc(17)
 00000962	     980D	LDR R0 [ SP + 52 ]
 00000964	     9910	LDR R1 [ SP + 64 ]
 00000966	     6001	STR R1 [  R0 + 0 ]
 00000968	     980D	LDR R0 [ SP + 52 ]
 0000096A	     1D00	ADDS R0 R0 #4
 0000096C	     900D	STR R0 [ SP + 52 ]
 0000096E	     9807	LDR R0 [ SP + 28 ]
 00000970	     1E40	SUBS R0 R0 #1
 00000972	     9007	STR R0 [ SP + 28 ]
 00000974	     E7E9	B #-46, goes to  0000094A
 00000976	     9804	LDR R0 [ SP + 16 ]
 00000978	     2800	CMP R0 #0
 0000097A	     BF08	IT EQ
 0000097C	 EC03E1E4	TrapEQ 4 at pos 7966
 00000980	     990D	LDR R1 [ SP + 52 ]
 00000982	     6481	STR R1 [  R0 + 72 ]
 00000984	     A830	ADD R0 SP #192
 00000986	 12000019	MOV R1 lower 16-bits base(2), next at  00000954
 0000098A	 00000001	MOVT R1 higher 16-bits const(1)
 0000098E	     AA10	ADD R2 SP #64
 00000990	 21100019	BL Mod(  2) proc(17)
 00000994	     9810	LDR R0 [ SP + 64 ]
 00000996	     2800	CMP R0 #0
 00000998	 F2C08016	BLT #44, goes to  000009C8
 0000099C	     9804	LDR R0 [ SP + 16 ]
 0000099E	     2800	CMP R0 #0
 000009A0	     BF08	IT EQ
 000009A2	 EC03F084	TrapEQ 4 at pos 8072
 000009A6	     6B40	LDR R0 [ R0 + 52 ]
 000009A8	     9910	LDR R1 [ SP + 64 ]
 000009AA	     1840	ADDS R0 R0 R1
 000009AC	     990D	LDR R1 [ SP + 52 ]
 000009AE	     6008	STR R0 [  R1 + 0 ]
 000009B0	     980D	LDR R0 [ SP + 52 ]
 000009B2	     1D00	ADDS R0 R0 #4
 000009B4	     900D	STR R0 [ SP + 52 ]
 000009B6	     A830	ADD R0 SP #192
 000009B8	 12000019	MOV R1 lower 16-bits base(2), next at  00000986
 000009BC	 00000001	MOVT R1 higher 16-bits const(1)
 000009C0	     AA10	ADD R2 SP #64
 000009C2	 21100019	BL Mod(  2) proc(17)
 000009C6	     E7E5	B #-54, goes to  00000994
 000009C8	     980D	LDR R0 [ SP + 52 ]
 000009CA	     2100	MOVS R1 #0
 000009CC	     6001	STR R1 [  R0 + 0 ]
 000009CE	     980D	LDR R0 [ SP + 52 ]
 000009D0	     1D00	ADDS R0 R0 #4
 000009D2	     900D	STR R0 [ SP + 52 ]
 000009D4	     A830	ADD R0 SP #192
 000009D6	 1200000F	MOV R1 lower 16-bits base(2), next at  000009B8
 000009DA	 00000001	MOVT R1 higher 16-bits const(1)
 000009DE	     AA13	ADD R2 SP #76
 000009E0	 2110000F	BL Mod(  2) proc(17)
 000009E4	     A830	ADD R0 SP #192
 000009E6	 12000008	MOV R1 lower 16-bits base(2), next at  000009D6
 000009EA	 00000001	MOVT R1 higher 16-bits const(1)
 000009EE	     AA14	ADD R2 SP #80
 000009F0	 21100008	BL Mod(  2) proc(17)
 000009F4	     A830	ADD R0 SP #192
 000009F6	 12000008	MOV R1 lower 16-bits base(2), next at  000009E6
 000009FA	 00000001	MOVT R1 higher 16-bits const(1)
 000009FE	     AA15	ADD R2 SP #84
 00000A00	 21100008	BL Mod(  2) proc(17)
 00000A04	     A830	ADD R0 SP #192
 00000A06	 12000008	MOV R1 lower 16-bits base(2), next at  000009F6
 00000A0A	 00000001	MOVT R1 higher 16-bits const(1)
 00000A0E	     AA10	ADD R2 SP #64
 00000A10	 21100008	BL Mod(  2) proc(17)
 00000A14	     9804	LDR R0 [ SP + 16 ]
 00000A16	     2800	CMP R0 #0
 00000A18	     BF08	IT EQ
 00000A1A	 EC040734	TrapEQ 4 at pos 8307
 00000A1E	     6B80	LDR R0 [ R0 + 56 ]
 00000A20	     9910	LDR R1 [ SP + 64 ]
 00000A22	     1840	ADDS R0 R0 R1
 00000A24	     1C40	ADDS R0 R0 #1
 00000A26	     9012	STR R0 [ SP + 72 ]
 00000A28	     A830	ADD R0 SP #192
 00000A2A	 12000012	MOV R1 lower 16-bits base(2), next at  00000A06
 00000A2E	 00000001	MOVT R1 higher 16-bits const(1)
 00000A32	 F10D0245	ADD R2 SP #69
 00000A36	 21000013	BL Mod(  2) proc(16)
 00000A3A	 F89D0045	LDRB R0 [ SP + 69 ]
 00000A3E	     284F	CMP R0 #79
 00000A40	 F0008007	BEQ #14, goes to  00000A52
 00000A44	     2000	MOVS R0 #0
 00000A46	     9004	STR R0 [ SP + 16 ]
 00000A48	     2004	MOVS R0 #4
 00000A4A	     9901	LDR R1 [ SP + 4 ]
 00000A4C	     9A02	LDR R2 [ SP + 8 ]
 00000A4E	 F7FFFC1B	BL #-1994, goes to  00000288
 00000A52	 000001B8	MOV R0 lower 16-bits base(0), next at  000006E2
 00000A56	 0000000C	MOVT R0 higher 16-bits var + 12
 00000A5A	     6800	LDR R0 [ R0 + 0 ]
 00000A5C	     2800	CMP R0 #0
 00000A5E	 F04081D6	BNE #940, goes to  00000E0E
 00000A62	     2000	MOVS R0 #0
 00000A64	     901E	STR R0 [ SP + 120 ]
 00000A66	     980D	LDR R0 [ SP + 52 ]
 00000A68	     901D	STR R0 [ SP + 116 ]
 00000A6A	     9804	LDR R0 [ SP + 16 ]
 00000A6C	     2800	CMP R0 #0
 00000A6E	     BF08	IT EQ
 00000A70	 EC042664	TrapEQ 4 at pos 8550
 00000A74	     6B80	LDR R0 [ R0 + 56 ]
 00000A76	     9913	LDR R1 [ SP + 76 ]
 00000A78	     1840	ADDS R0 R0 R1
 00000A7A	     9017	STR R0 [ SP + 92 ]
 00000A7C	     9804	LDR R0 [ SP + 16 ]
 00000A7E	     2800	CMP R0 #0
 00000A80	     BF08	IT EQ
 00000A82	 EC0430E4	TrapEQ 4 at pos 8590
 00000A86	     9917	LDR R1 [ SP + 92 ]
 00000A88	     6B80	LDR R0 [ R0 + 56 ]
 00000A8A	     4281	CMP R1 R0
 00000A8C	 F0008091	BEQ #290, goes to  00000BB2
 00000A90	     9817	LDR R0 [ SP + 92 ]
 00000A92	 F7FFFB41	BL #-2430, goes to  00000118
 00000A96	     9018	STR R0 [ SP + 96 ]
 00000A98	     9818	LDR R0 [ SP + 96 ]
 00000A9A	 F7FFFB22	BL #-2492, goes to  000000E2
 00000A9E	     9018	STR R0 [ SP + 96 ]
 00000AA0	     9818	LDR R0 [ SP + 96 ]
 00000AA2	     1700	ASRS R0 R0 #28
 00000AA4	 F36F101F	BFC R0 #4 #28
 00000AA8	     900A	STR R0 [ SP + 40 ]
 00000AAA	     9818	LDR R0 [ SP + 96 ]
 00000AAC	     1500	ASRS R0 R0 #20
 00000AAE	 F36F201F	BFC R0 #8 #24
 00000AB2	     9019	STR R0 [ SP + 100 ]
 00000AB4	     9818	LDR R0 [ SP + 96 ]
 00000AB6	 F36F501F	BFC R0 #20 #12
 00000ABA	     0040	LSLS R0 R0 #1
 00000ABC	     9016	STR R0 [ SP + 88 ]
 00000ABE	     9804	LDR R0 [ SP + 16 ]
 00000AC0	     2800	CMP R0 #0
 00000AC2	     BF08	IT EQ
 00000AC4	 EC045134	TrapEQ 4 at pos 8851
 00000AC8	     990A	LDR R1 [ SP + 40 ]
 00000ACA	     1E49	SUBS R1 R1 #1
 00000ACC	     0089	LSLS R1 R1 #2
 00000ACE	     6BC0	LDR R0 [ R0 + 60 ]
 00000AD0	     1840	ADDS R0 R0 R1
 00000AD2	     6800	LDR R0 [ R0 + 0 ]
 00000AD4	     9005	STR R0 [ SP + 20 ]
 00000AD6	     9805	LDR R0 [ SP + 20 ]
 00000AD8	     2800	CMP R0 #0
 00000ADA	     BF08	IT EQ
 00000ADC	 EC045494	TrapEQ 4 at pos 8905
 00000AE0	     9919	LDR R1 [ SP + 100 ]
 00000AE2	     0089	LSLS R1 R1 #2
 00000AE4	     6C40	LDR R0 [ R0 + 68 ]
 00000AE6	     1840	ADDS R0 R0 R1
 00000AE8	     6800	LDR R0 [ R0 + 0 ]
 00000AEA	     901B	STR R0 [ SP + 108 ]
 00000AEC	     9805	LDR R0 [ SP + 20 ]
 00000AEE	     2800	CMP R0 #0
 00000AF0	     BF08	IT EQ
 00000AF2	 EC045744	TrapEQ 4 at pos 8948
 00000AF6	     991B	LDR R1 [ SP + 108 ]
 00000AF8	     6B80	LDR R0 [ R0 + 56 ]
 00000AFA	     1808	ADDS R0 R1 R0
 00000AFC	     901B	STR R0 [ SP + 108 ]
 00000AFE	     981B	LDR R0 [ SP + 108 ]
 00000B00	     9917	LDR R1 [ SP + 92 ]
 00000B02	     1A40	SUBS R0 R0 R1
 00000B04	     1F00	SUBS R0 R0 #4
 00000B06	     901C	STR R0 [ SP + 112 ]
 00000B08	     981C	LDR R0 [ SP + 112 ]
 00000B0A	 F1B04F7F	CMP R0 #-16777216
 00000B0E	 F2C08005	BLT #10, goes to  00000B1C
 00000B12	     981C	LDR R0 [ SP + 112 ]
 00000B14	 F1B07F80	CMP R0 #16777216
 00000B18	 F2C08036	BLT #108, goes to  00000B88
 00000B1C	     2000	MOVS R0 #0
 00000B1E	     9006	STR R0 [ SP + 24 ]
 00000B20	     981D	LDR R0 [ SP + 116 ]
 00000B22	     900E	STR R0 [ SP + 56 ]
 00000B24	     980E	LDR R0 [ SP + 56 ]
 00000B26	     1D00	ADDS R0 R0 #4
 00000B28	     6800	LDR R0 [ R0 + 0 ]
 00000B2A	     9010	STR R0 [ SP + 64 ]
 00000B2C	     9806	LDR R0 [ SP + 24 ]
 00000B2E	     991E	LDR R1 [ SP + 120 ]
 00000B30	     4288	CMP R0 R1
 00000B32	 F2808010	BGE #32, goes to  00000B56
 00000B36	     981B	LDR R0 [ SP + 108 ]
 00000B38	     9910	LDR R1 [ SP + 64 ]
 00000B3A	     4288	CMP R0 R1
 00000B3C	 F000800B	BEQ #22, goes to  00000B56
 00000B40	     980E	LDR R0 [ SP + 56 ]
 00000B42	     3008	ADDS R0 R0 #8
 00000B44	     900E	STR R0 [ SP + 56 ]
 00000B46	     980E	LDR R0 [ SP + 56 ]
 00000B48	     1D00	ADDS R0 R0 #4
 00000B4A	     6800	LDR R0 [ R0 + 0 ]
 00000B4C	     9010	STR R0 [ SP + 64 ]
 00000B4E	     9806	LDR R0 [ SP + 24 ]
 00000B50	     1C40	ADDS R0 R0 #1
 00000B52	     9006	STR R0 [ SP + 24 ]
 00000B54	     E7EA	B #-44, goes to  00000B2C
 00000B56	     9806	LDR R0 [ SP + 24 ]
 00000B58	     991E	LDR R1 [ SP + 120 ]
 00000B5A	     4288	CMP R0 R1
 00000B5C	 F2C0800D	BLT #26, goes to  00000B7A
 00000B60	     981E	LDR R0 [ SP + 120 ]
 00000B62	     1C40	ADDS R0 R0 #1
 00000B64	     901E	STR R0 [ SP + 120 ]
 00000B66	     980E	LDR R0 [ SP + 56 ]
 00000B68	     21F0	MOVS R1 #240
 00000B6A	 F6CD71F8	MOVT R1 #57336
 00000B6E	     6001	STR R1 [  R0 + 0 ]
 00000B70	     980E	LDR R0 [ SP + 56 ]
 00000B72	     1D00	ADDS R0 R0 #4
 00000B74	     991B	LDR R1 [ SP + 108 ]
 00000B76	     1C49	ADDS R1 R1 #1
 00000B78	     6001	STR R1 [  R0 + 0 ]
 00000B7A	     980E	LDR R0 [ SP + 56 ]
 00000B7C	     901B	STR R0 [ SP + 108 ]
 00000B7E	     981B	LDR R0 [ SP + 108 ]
 00000B80	     9917	LDR R1 [ SP + 92 ]
 00000B82	     1A40	SUBS R0 R0 R1
 00000B84	     1F00	SUBS R0 R0 #4
 00000B86	     901C	STR R0 [ SP + 112 ]
 00000B88	     9817	LDR R0 [ SP + 92 ]
 00000B8A	     B401	PUSH R0
 00000B8C	     981D	LDR R0 [ SP + 116 ]
 00000B8E	 F7FFFA37	BL #-2962, goes to  00000000
 00000B92	 F24D0100	MOV R1 #53248
 00000B96	 F2CF0100	MOVT R1 #61440
 00000B9A	     1808	ADDS R0 R1 R0
 00000B9C	 F7FFFAA1	BL #-2750, goes to  000000E2
 00000BA0	     4601	MOV R1 R0
 00000BA2	     BC01	POP R0
 00000BA4	 F7FFFAE0	BL #-2624, goes to  00000168
 00000BA8	     9817	LDR R0 [ SP + 92 ]
 00000BAA	     9916	LDR R1 [ SP + 88 ]
 00000BAC	     1A40	SUBS R0 R0 R1
 00000BAE	     9017	STR R0 [ SP + 92 ]
 00000BB0	     E764	B #-312, goes to  00000A7C
 00000BB2	     981E	LDR R0 [ SP + 120 ]
 00000BB4	     00C0	LSLS R0 R0 #3
 00000BB6	     990D	LDR R1 [ SP + 52 ]
 00000BB8	     1809	ADDS R1 R1 R0
 00000BBA	     910D	STR R1 [ SP + 52 ]
 00000BBC	     9804	LDR R0 [ SP + 16 ]
 00000BBE	     2800	CMP R0 #0
 00000BC0	     BF08	IT EQ
 00000BC2	 EC04D7F4	TrapEQ 4 at pos 9983
 00000BC6	     6B80	LDR R0 [ R0 + 56 ]
 00000BC8	     9914	LDR R1 [ SP + 80 ]
 00000BCA	     1840	ADDS R0 R0 R1
 00000BCC	     9017	STR R0 [ SP + 92 ]
 00000BCE	     9804	LDR R0 [ SP + 16 ]
 00000BD0	     2800	CMP R0 #0
 00000BD2	     BF08	IT EQ
 00000BD4	 EC04E274	TrapEQ 4 at pos 10023
 00000BD8	     9917	LDR R1 [ SP + 92 ]
 00000BDA	     6B80	LDR R0 [ R0 + 56 ]
 00000BDC	     4281	CMP R1 R0
 00000BDE	 F0008092	BEQ #292, goes to  00000D06
 00000BE2	     9817	LDR R0 [ SP + 92 ]
 00000BE4	 F7FFFA98	BL #-2768, goes to  00000118
 00000BE8	     9018	STR R0 [ SP + 96 ]
 00000BEA	     9818	LDR R0 [ SP + 96 ]
 00000BEC	 F7FFFA79	BL #-2830, goes to  000000E2
 00000BF0	     9018	STR R0 [ SP + 96 ]
 00000BF2	     9818	LDR R0 [ SP + 96 ]
 00000BF4	     1700	ASRS R0 R0 #28
 00000BF6	 F36F101F	BFC R0 #4 #28
 00000BFA	     9019	STR R0 [ SP + 100 ]
 00000BFC	     9818	LDR R0 [ SP + 96 ]
 00000BFE	     1600	ASRS R0 R0 #24
 00000C00	 F36F101F	BFC R0 #4 #28
 00000C04	     900A	STR R0 [ SP + 40 ]
 00000C06	     9818	LDR R0 [ SP + 96 ]
 00000C08	 F36F601F	BFC R0 #24 #8
 00000C0C	     0040	LSLS R0 R0 #1
 00000C0E	     9016	STR R0 [ SP + 88 ]
 00000C10	     9817	LDR R0 [ SP + 92 ]
 00000C12	     1D00	ADDS R0 R0 #4
 00000C14	 F7FFFA80	BL #-2816, goes to  00000118
 00000C18	     9018	STR R0 [ SP + 96 ]
 00000C1A	     9818	LDR R0 [ SP + 96 ]
 00000C1C	 F7FFFA61	BL #-2878, goes to  000000E2
 00000C20	     9018	STR R0 [ SP + 96 ]
 00000C22	     980A	LDR R0 [ SP + 40 ]
 00000C24	     2800	CMP R0 #0
 00000C26	 F040800D	BNE #26, goes to  00000C44
 00000C2A	     9804	LDR R0 [ SP + 16 ]
 00000C2C	     2800	CMP R0 #0
 00000C2E	     BF08	IT EQ
 00000C30	 EC051534	TrapEQ 4 at pos 10451
 00000C34	     9918	LDR R1 [ SP + 96 ]
 00000C36	 F36F611F	BFC R1 #24 #8
 00000C3A	     6B40	LDR R0 [ R0 + 52 ]
 00000C3C	     1840	ADDS R0 R0 R1
 00000C3E	     901B	STR R0 [ SP + 108 ]
 00000C40	 F000B836	B #108, goes to  00000CB0
 00000C44	     9818	LDR R0 [ SP + 96 ]
 00000C46	 F36F201F	BFC R0 #8 #24
 00000C4A	     901A	STR R0 [ SP + 104 ]
 00000C4C	     9804	LDR R0 [ SP + 16 ]
 00000C4E	     2800	CMP R0 #0
 00000C50	     BF08	IT EQ
 00000C52	 EC052374	TrapEQ 4 at pos 10551
 00000C56	     990A	LDR R1 [ SP + 40 ]
 00000C58	     1E49	SUBS R1 R1 #1
 00000C5A	     0089	LSLS R1 R1 #2
 00000C5C	     6BC0	LDR R0 [ R0 + 60 ]
 00000C5E	     1840	ADDS R0 R0 R1
 00000C60	     6800	LDR R0 [ R0 + 0 ]
 00000C62	     9005	STR R0 [ SP + 20 ]
 00000C64	     9805	LDR R0 [ SP + 20 ]
 00000C66	     2800	CMP R0 #0
 00000C68	     BF08	IT EQ
 00000C6A	 EC0526F4	TrapEQ 4 at pos 10607
 00000C6E	     991A	LDR R1 [ SP + 104 ]
 00000C70	     0089	LSLS R1 R1 #2
 00000C72	     6C40	LDR R0 [ R0 + 68 ]
 00000C74	     1840	ADDS R0 R0 R1
 00000C76	     6800	LDR R0 [ R0 + 0 ]
 00000C78	     901C	STR R0 [ SP + 112 ]
 00000C7A	     9818	LDR R0 [ SP + 96 ]
 00000C7C	     1200	ASRS R0 R0 #8
 00000C7E	 EA5F0070	RORS R0 R0 #1
 00000C82	 F140800C	BPL #24, goes to  00000C9E
 00000C86	     9805	LDR R0 [ SP + 20 ]
 00000C88	     2800	CMP R0 #0
 00000C8A	     BF08	IT EQ
 00000C8C	 EC0533C4	TrapEQ 4 at pos 10684
 00000C90	     6B80	LDR R0 [ R0 + 56 ]
 00000C92	     991C	LDR R1 [ SP + 112 ]
 00000C94	     1840	ADDS R0 R0 R1
 00000C96	     1C40	ADDS R0 R0 #1
 00000C98	     901B	STR R0 [ SP + 108 ]
 00000C9A	 F000B809	B #18, goes to  00000CB0
 00000C9E	     9805	LDR R0 [ SP + 20 ]
 00000CA0	     2800	CMP R0 #0
 00000CA2	     BF08	IT EQ
 00000CA4	 EC054084	TrapEQ 4 at pos 10760
 00000CA8	     6B40	LDR R0 [ R0 + 52 ]
 00000CAA	     991C	LDR R1 [ SP + 112 ]
 00000CAC	     1840	ADDS R0 R0 R1
 00000CAE	     901B	STR R0 [ SP + 108 ]
 00000CB0	     9817	LDR R0 [ SP + 92 ]
 00000CB2	     B401	PUSH R0
 00000CB4	     981A	LDR R0 [ SP + 104 ]
 00000CB6	     991C	LDR R1 [ SP + 112 ]
 00000CB8	 F36F411F	BFC R1 #16 #16
 00000CBC	 F7FFF9F2	BL #-3100, goes to  000000A4
 00000CC0	     2100	MOVS R1 #0
 00000CC2	 F2CF2140	MOVT R1 #62016
 00000CC6	     1808	ADDS R0 R1 R0
 00000CC8	 F7FFFA0B	BL #-3050, goes to  000000E2
 00000CCC	     4601	MOV R1 R0
 00000CCE	     BC01	POP R0
 00000CD0	 F7FFFA4A	BL #-2924, goes to  00000168
 00000CD4	     9817	LDR R0 [ SP + 92 ]
 00000CD6	     1D00	ADDS R0 R0 #4
 00000CD8	     B401	PUSH R0
 00000CDA	     981A	LDR R0 [ SP + 104 ]
 00000CDC	     991C	LDR R1 [ SP + 112 ]
 00000CDE	     1409	ASRS R1 R1 #16
 00000CE0	 F36F411F	BFC R1 #16 #16
 00000CE4	 F7FFF9DE	BL #-3140, goes to  000000A4
 00000CE8	     2100	MOVS R1 #0
 00000CEA	 F2CF21C0	MOVT R1 #62144
 00000CEE	     1808	ADDS R0 R1 R0
 00000CF0	 F7FFF9F7	BL #-3090, goes to  000000E2
 00000CF4	     4601	MOV R1 R0
 00000CF6	     BC01	POP R0
 00000CF8	 F7FFFA36	BL #-2964, goes to  00000168
 00000CFC	     9817	LDR R0 [ SP + 92 ]
 00000CFE	     9916	LDR R1 [ SP + 88 ]
 00000D00	     1A40	SUBS R0 R0 R1
 00000D02	     9017	STR R0 [ SP + 92 ]
 00000D04	     E763	B #-314, goes to  00000BCE
 00000D06	     9804	LDR R0 [ SP + 16 ]
 00000D08	     2800	CMP R0 #0
 00000D0A	     BF08	IT EQ
 00000D0C	 EC056394	TrapEQ 4 at pos 11065
 00000D10	     9915	LDR R1 [ SP + 84 ]
 00000D12	     0089	LSLS R1 R1 #2
 00000D14	     6B40	LDR R0 [ R0 + 52 ]
 00000D16	     1840	ADDS R0 R0 R1
 00000D18	     9017	STR R0 [ SP + 92 ]
 00000D1A	     9804	LDR R0 [ SP + 16 ]
 00000D1C	     2800	CMP R0 #0
 00000D1E	     BF08	IT EQ
 00000D20	 EC056634	TrapEQ 4 at pos 11107
 00000D24	     9917	LDR R1 [ SP + 92 ]
 00000D26	     6B40	LDR R0 [ R0 + 52 ]
 00000D28	     4281	CMP R1 R0
 00000D2A	 F0008049	BEQ #146, goes to  00000DC0
 00000D2E	     9817	LDR R0 [ SP + 92 ]
 00000D30	     6800	LDR R0 [ R0 + 0 ]
 00000D32	     9018	STR R0 [ SP + 96 ]
 00000D34	     9818	LDR R0 [ SP + 96 ]
 00000D36	     1600	ASRS R0 R0 #24
 00000D38	 F36F101F	BFC R0 #4 #28
 00000D3C	     900A	STR R0 [ SP + 40 ]
 00000D3E	     9818	LDR R0 [ SP + 96 ]
 00000D40	     1300	ASRS R0 R0 #12
 00000D42	 F36F301F	BFC R0 #12 #20
 00000D46	     901A	STR R0 [ SP + 104 ]
 00000D48	     9818	LDR R0 [ SP + 96 ]
 00000D4A	 F36F301F	BFC R0 #12 #20
 00000D4E	     9016	STR R0 [ SP + 88 ]
 00000D50	     980A	LDR R0 [ SP + 40 ]
 00000D52	     2800	CMP R0 #0
 00000D54	 F040800B	BNE #22, goes to  00000D6E
 00000D58	     9804	LDR R0 [ SP + 16 ]
 00000D5A	     2800	CMP R0 #0
 00000D5C	     BF08	IT EQ
 00000D5E	 EC058364	TrapEQ 4 at pos 11318
 00000D62	     6B40	LDR R0 [ R0 + 52 ]
 00000D64	     991A	LDR R1 [ SP + 104 ]
 00000D66	     1840	ADDS R0 R0 R1
 00000D68	     9018	STR R0 [ SP + 96 ]
 00000D6A	 F000B820	B #64, goes to  00000DAE
 00000D6E	     9804	LDR R0 [ SP + 16 ]
 00000D70	     2800	CMP R0 #0
 00000D72	     BF08	IT EQ
 00000D74	 EC058754	TrapEQ 4 at pos 11381
 00000D78	     990A	LDR R1 [ SP + 40 ]
 00000D7A	     1E49	SUBS R1 R1 #1
 00000D7C	     0089	LSLS R1 R1 #2
 00000D7E	     6BC0	LDR R0 [ R0 + 60 ]
 00000D80	     1840	ADDS R0 R0 R1
 00000D82	     6800	LDR R0 [ R0 + 0 ]
 00000D84	     9005	STR R0 [ SP + 20 ]
 00000D86	     9805	LDR R0 [ SP + 20 ]
 00000D88	     2800	CMP R0 #0
 00000D8A	     BF08	IT EQ
 00000D8C	 EC0592D4	TrapEQ 4 at pos 11437
 00000D90	     991A	LDR R1 [ SP + 104 ]
 00000D92	     0089	LSLS R1 R1 #2
 00000D94	     6C40	LDR R0 [ R0 + 68 ]
 00000D96	     1840	ADDS R0 R0 R1
 00000D98	     6800	LDR R0 [ R0 + 0 ]
 00000D9A	     901C	STR R0 [ SP + 112 ]
 00000D9C	     9805	LDR R0 [ SP + 20 ]
 00000D9E	     2800	CMP R0 #0
 00000DA0	     BF08	IT EQ
 00000DA2	 EC0595F4	TrapEQ 4 at pos 11487
 00000DA6	     6B40	LDR R0 [ R0 + 52 ]
 00000DA8	     991C	LDR R1 [ SP + 112 ]
 00000DAA	     1840	ADDS R0 R0 R1
 00000DAC	     9018	STR R0 [ SP + 96 ]
 00000DAE	     9817	LDR R0 [ SP + 92 ]
 00000DB0	     9918	LDR R1 [ SP + 96 ]
 00000DB2	     6001	STR R1 [  R0 + 0 ]
 00000DB4	     9816	LDR R0 [ SP + 88 ]
 00000DB6	     0080	LSLS R0 R0 #2
 00000DB8	     9917	LDR R1 [ SP + 92 ]
 00000DBA	     1A08	SUBS R0 R1 R0
 00000DBC	     9017	STR R0 [ SP + 92 ]
 00000DBE	     E7AC	B #-168, goes to  00000D1A
 00000DC0	     9812	LDR R0 [ SP + 72 ]
 00000DC2	     4780	BLX R0
 00000DC4	 F89D0046	LDRB R0 [ SP + 70 ]
 00000DC8	     2800	CMP R0 #0
 00000DCA	 F000801E	BEQ #60, goes to  00000E0A
 00000DCE	 000001BE	MOV R0 lower 16-bits base(0), next at  00000A52
 00000DD2	 00000008	MOVT R0 higher 16-bits var + 8
 00000DD6	     6800	LDR R0 [ R0 + 0 ]
 00000DD8	     990D	LDR R1 [ SP + 52 ]
 00000DDA	     4288	CMP R0 R1
 00000DDC	 F3408015	BLE #42, goes to  00000E0A
 00000DE0	     9804	LDR R0 [ SP + 16 ]
 00000DE2	     2800	CMP R0 #0
 00000DE4	     BF08	IT EQ
 00000DE6	 EC05B1A4	TrapEQ 4 at pos 11674
 00000DEA	 1000000E	MOV R1 lower 16-bits base(0), next at  00000DCE
 00000DEE	 00000008	MOVT R1 higher 16-bits var + 8
 00000DF2	     6809	LDR R1 [ R1 + 0 ]
 00000DF4	     9A0D	LDR R2 [ SP + 52 ]
 00000DF6	     1A89	SUBS R1 R1 R2
 00000DF8	     6AC2	LDR R2 [ R0 + 44 ]
 00000DFA	     1A52	SUBS R2 R2 R1
 00000DFC	     62C2	STR R2 [  R0 + 44 ]
 00000DFE	     980D	LDR R0 [ SP + 52 ]
 00000E00	 1000000B	MOV R1 lower 16-bits base(0), next at  00000DEA
 00000E04	 00000008	MOVT R1 higher 16-bits var + 8
 00000E08	     6008	STR R0 [  R1 + 0 ]
 00000E0A	 F000B834	B #104, goes to  00000E76
 00000E0E	 00000007	MOV R0 lower 16-bits base(0), next at  00000E00
 00000E12	 0000000C	MOVT R0 higher 16-bits var + 12
 00000E16	     6800	LDR R0 [ R0 + 0 ]
 00000E18	     2803	CMP R0 #3
 00000E1A	 F2C0802C	BLT #88, goes to  00000E76
 00000E1E	 00000008	MOV R0 lower 16-bits base(0), next at  00000E0E
 00000E22	 00000010	MOVT R0 higher 16-bits var + 16
 00000E26	     9901	LDR R1 [ SP + 4 ]
 00000E28	     9A02	LDR R2 [ SP + 8 ]
 00000E2A	     2A00	CMP R2 #0
 00000E2C	     D00B	BEQ #22, goes to  00000E46
 00000E2E	     1CD2	ADDS R2 R2 #3
 00000E30	     1092	ASRS R2 R2 #2
 00000E32	     2A08	CMP R2 #8
 00000E34	     BFC8	IT GT
 00000E36	 EC05C0C3	TrapGT 3 at pos 11788
 00000E3A	 F8513B04	LDR R3 [ R1 ] + 4
 00000E3E	 F8403B04	STR R3 [  R0 ] + 4
 00000E42	     1E52	SUBS R2 R2 #1
 00000E44	     D1F9	BNE #-14, goes to  00000E3A
 00000E46	     980B	LDR R0 [ SP + 44 ]
 00000E48	     2800	CMP R0 #0
 00000E4A	 F3408014	BLE #40, goes to  00000E76
 00000E4E	     980B	LDR R0 [ SP + 44 ]
 00000E50	     1E40	SUBS R0 R0 #1
 00000E52	     900B	STR R0 [ SP + 44 ]
 00000E54	     980B	LDR R0 [ SP + 44 ]
 00000E56	     2810	CMP R0 #16
 00000E58	     BF28	IT CS
 00000E5A	 EC05C4B1	TrapCS 1 at pos 11851
 00000E5E	 EB0D0080	ADD R0 SP R0 LSL #2
 00000E62	 F8D000D8	LDR R0 [ R0 + 216 ]
 00000E66	     2800	CMP R0 #0
 00000E68	     BF08	IT EQ
 00000E6A	 EC05C524	TrapEQ 4 at pos 11858
 00000E6E	     6B01	LDR R1 [ R0 + 48 ]
 00000E70	     1E49	SUBS R1 R1 #1
 00000E72	     6301	STR R1 [  R0 + 48 ]
 00000E74	     E7E7	B #-50, goes to  00000E46
 00000E76	     9804	LDR R0 [ SP + 16 ]
 00000E78	     9903	LDR R1 [ SP + 12 ]
 00000E7A	     6008	STR R0 [  R1 + 0 ]
 00000E7C	 F85DEB04	LDR LR [ SP ] + 4
 00000E80	     B045	ADD SP SP #276
 00000E82	     4770	BX LR
 00000E84	     B08C	SUB SP SP #48
 00000E86	     B407	PUSH R0 R1 R2
 00000E88	     B500	PUSH LR
 00000E8A	     2005	MOVS R0 #5
 00000E8C	 10000037	MOV R1 lower 16-bits base(0), next at  00000E1E
 00000E90	 0000000C	MOVT R1 higher 16-bits var + 12
 00000E94	     6008	STR R0 [  R1 + 0 ]
 00000E96	     2000	MOVS R0 #0
 00000E98	     9006	STR R0 [ SP + 24 ]
 00000E9A	     9801	LDR R0 [ SP + 4 ]
 00000E9C	     2800	CMP R0 #0
 00000E9E	 F000806C	BEQ #216, goes to  00000F7A
 00000EA2	     9801	LDR R0 [ SP + 4 ]
 00000EA4	     2800	CMP R0 #0
 00000EA6	     BF08	IT EQ
 00000EA8	 EC05E574	TrapEQ 4 at pos 12119
 00000EAC	     6C00	LDR R0 [ R0 + 64 ]
 00000EAE	     9005	STR R0 [ SP + 20 ]
 00000EB0	     9805	LDR R0 [ SP + 20 ]
 00000EB2	     7800	LDRB R0 [ R0 + 0 ]
 00000EB4	 F88D001C	STRB R0 [  SP + 28 ]
 00000EB8	 F89D001C	LDRB R0 [ SP + 28 ]
 00000EBC	     2800	CMP R0 #0
 00000EBE	 F000805C	BEQ #184, goes to  00000F7A
 00000EC2	 0000001B	MOV R0 lower 16-bits base(0), next at  00000E8C
 00000EC6	 0000000C	MOVT R0 higher 16-bits var + 12
 00000ECA	     6800	LDR R0 [ R0 + 0 ]
 00000ECC	     2800	CMP R0 #0
 00000ECE	 F0008054	BEQ #168, goes to  00000F7A
 00000ED2	     2000	MOVS R0 #0
 00000ED4	     9004	STR R0 [ SP + 16 ]
 00000ED6	     9804	LDR R0 [ SP + 16 ]
 00000ED8	     2820	CMP R0 #32
 00000EDA	     BF28	IT CS
 00000EDC	 EC05F441	TrapCS 1 at pos 12228
 00000EE0	     4468	ADD R0 SP R0
 00000EE2	 F89D101C	LDRB R1 [ SP + 28 ]
 00000EE6	 F8801020	STRB R1 [  R0 + 32 ]
 00000EEA	     9804	LDR R0 [ SP + 16 ]
 00000EEC	     1C40	ADDS R0 R0 #1
 00000EEE	     9004	STR R0 [ SP + 16 ]
 00000EF0	     9805	LDR R0 [ SP + 20 ]
 00000EF2	     1C40	ADDS R0 R0 #1
 00000EF4	     9005	STR R0 [ SP + 20 ]
 00000EF6	     9805	LDR R0 [ SP + 20 ]
 00000EF8	     7800	LDRB R0 [ R0 + 0 ]
 00000EFA	 F88D001C	STRB R0 [  SP + 28 ]
 00000EFE	 F89D001C	LDRB R0 [ SP + 28 ]
 00000F02	     2800	CMP R0 #0
 00000F04	     D1E7	BNE #-50, goes to  00000ED6
 00000F06	     9804	LDR R0 [ SP + 16 ]
 00000F08	     2820	CMP R0 #32
 00000F0A	     BF28	IT CS
 00000F0C	 EC0600D1	TrapCS 1 at pos 12301
 00000F10	     4468	ADD R0 SP R0
 00000F12	     2100	MOVS R1 #0
 00000F14	 F8801020	STRB R1 [  R0 + 32 ]
 00000F18	     9805	LDR R0 [ SP + 20 ]
 00000F1A	     1C40	ADDS R0 R0 #1
 00000F1C	     9005	STR R0 [ SP + 20 ]
 00000F1E	     9805	LDR R0 [ SP + 20 ]
 00000F20	 F36F009F	BFC R0 #2 #30
 00000F24	     2800	CMP R0 #0
 00000F26	     D1F7	BNE #-18, goes to  00000F18
 00000F28	     9805	LDR R0 [ SP + 20 ]
 00000F2A	     6800	LDR R0 [ R0 + 0 ]
 00000F2C	     9004	STR R0 [ SP + 16 ]
 00000F2E	     9805	LDR R0 [ SP + 20 ]
 00000F30	     1D00	ADDS R0 R0 #4
 00000F32	     9005	STR R0 [ SP + 20 ]
 00000F34	     A808	ADD R0 SP #32
 00000F36	     9902	LDR R1 [ SP + 8 ]
 00000F38	 F8102B01	LDRB R2 [  R0 ] + 1
 00000F3C	 F8113B01	LDRB R3 [  R1 ] + 1
 00000F40	     429A	CMP R2 R3
 00000F42	     D101	BNE #2, goes to  00000F48
 00000F44	     2A00	CMP R2 #0
 00000F46	     D1F7	BNE #-18, goes to  00000F38
 00000F48	 F0408012	BNE #36, goes to  00000F70
 00000F4C	     2000	MOVS R0 #0
 00000F4E	 10000046	MOV R1 lower 16-bits base(0), next at  00000EC2
 00000F52	 0000000C	MOVT R1 higher 16-bits var + 12
 00000F56	     6008	STR R0 [  R1 + 0 ]
 00000F58	     9801	LDR R0 [ SP + 4 ]
 00000F5A	     2800	CMP R0 #0
 00000F5C	     BF08	IT EQ
 00000F5E	 EC0611B4	TrapEQ 4 at pos 12443
 00000F62	     6B80	LDR R0 [ R0 + 56 ]
 00000F64	     9904	LDR R1 [ SP + 16 ]
 00000F66	     1840	ADDS R0 R0 R1
 00000F68	     1C40	ADDS R0 R0 #1
 00000F6A	     9006	STR R0 [ SP + 24 ]
 00000F6C	 F000B804	B #8, goes to  00000F78
 00000F70	     9805	LDR R0 [ SP + 20 ]
 00000F72	     7800	LDRB R0 [ R0 + 0 ]
 00000F74	 F88D001C	STRB R0 [  SP + 28 ]
 00000F78	     E79E	B #-196, goes to  00000EB8
 00000F7A	     9806	LDR R0 [ SP + 24 ]
 00000F7C	 F85DEB04	LDR LR [ SP ] + 4
 00000F80	     B00F	ADD SP SP #60
 00000F82	     4770	BX LR
 00000F84	     B084	SUB SP SP #16
 00000F86	     B403	PUSH R0 R1
 00000F88	     B500	PUSH LR
 00000F8A	 0000001E	MOV R0 lower 16-bits base(0), next at  00000F4E
 00000F8E	 00000000	MOVT R0 higher 16-bits var + 0
 00000F92	     6800	LDR R0 [ R0 + 0 ]
 00000F94	     9003	STR R0 [ SP + 12 ]
 00000F96	     2000	MOVS R0 #0
 00000F98	 10000007	MOV R1 lower 16-bits base(0), next at  00000F8A
 00000F9C	 0000000C	MOVT R1 higher 16-bits var + 12
 00000FA0	     6008	STR R0 [  R1 + 0 ]
 00000FA2	     9803	LDR R0 [ SP + 12 ]
 00000FA4	     2800	CMP R0 #0
 00000FA6	 F0008018	BEQ #48, goes to  00000FDA
 00000FAA	     9803	LDR R0 [ SP + 12 ]
 00000FAC	     2800	CMP R0 #0
 00000FAE	     BF08	IT EQ
 00000FB0	 EC063364	TrapEQ 4 at pos 12726
 00000FB4	     9901	LDR R1 [ SP + 4 ]
 00000FB6	 F8102B01	LDRB R2 [  R0 ] + 1
 00000FBA	 F8113B01	LDRB R3 [  R1 ] + 1
 00000FBE	     429A	CMP R2 R3
 00000FC0	     D101	BNE #2, goes to  00000FC6
 00000FC2	     2A00	CMP R2 #0
 00000FC4	     D1F7	BNE #-18, goes to  00000FB6
 00000FC6	 F0008008	BEQ #16, goes to  00000FDA
 00000FCA	     9803	LDR R0 [ SP + 12 ]
 00000FCC	     2800	CMP R0 #0
 00000FCE	     BF08	IT EQ
 00000FD0	 EC063514	TrapEQ 4 at pos 12753
 00000FD4	     6A00	LDR R0 [ R0 + 32 ]
 00000FD6	     9003	STR R0 [ SP + 12 ]
 00000FD8	     E7E3	B #-58, goes to  00000FA2
 00000FDA	     9803	LDR R0 [ SP + 12 ]
 00000FDC	     2800	CMP R0 #0
 00000FDE	 F0008061	BEQ #194, goes to  000010A4
 00000FE2	     9803	LDR R0 [ SP + 12 ]
 00000FE4	     2800	CMP R0 #0
 00000FE6	     BF08	IT EQ
 00000FE8	 EC064014	TrapEQ 4 at pos 12801
 00000FEC	     6B00	LDR R0 [ R0 + 48 ]
 00000FEE	     2800	CMP R0 #0
 00000FF0	 F0408052	BNE #164, goes to  00001098
 00000FF4	     9803	LDR R0 [ SP + 12 ]
 00000FF6	     2800	CMP R0 #0
 00000FF8	     BF08	IT EQ
 00000FFA	 EC0641B4	TrapEQ 4 at pos 12827
 00000FFE	     2100	MOVS R1 #0
 00001000	     7001	STRB R1 [ R0 + 0 ]
 00001002	     9803	LDR R0 [ SP + 12 ]
 00001004	     2800	CMP R0 #0
 00001006	     BF08	IT EQ
 00001008	 EC064324	TrapEQ 4 at pos 12850
 0000100C	     6BC0	LDR R0 [ R0 + 60 ]
 0000100E	     9005	STR R0 [ SP + 20 ]
 00001010	     9803	LDR R0 [ SP + 12 ]
 00001012	     2800	CMP R0 #0
 00001014	     BF08	IT EQ
 00001016	 EC064404	TrapEQ 4 at pos 12864
 0000101A	     6C00	LDR R0 [ R0 + 64 ]
 0000101C	     9006	STR R0 [ SP + 24 ]
 0000101E	     9805	LDR R0 [ SP + 20 ]
 00001020	     9906	LDR R1 [ SP + 24 ]
 00001022	     4288	CMP R0 R1
 00001024	 F280800F	BGE #30, goes to  00001046
 00001028	     9805	LDR R0 [ SP + 20 ]
 0000102A	     6800	LDR R0 [ R0 + 0 ]
 0000102C	     9004	STR R0 [ SP + 16 ]
 0000102E	     9804	LDR R0 [ SP + 16 ]
 00001030	     2800	CMP R0 #0
 00001032	     BF08	IT EQ
 00001034	 EC0647B4	TrapEQ 4 at pos 12923
 00001038	     6B01	LDR R1 [ R0 + 48 ]
 0000103A	     1E49	SUBS R1 R1 #1
 0000103C	     6301	STR R1 [  R0 + 48 ]
 0000103E	     9805	LDR R0 [ SP + 20 ]
 00001040	     1D00	ADDS R0 R0 #4
 00001042	     9005	STR R0 [ SP + 20 ]
 00001044	     E7EB	B #-42, goes to  0000101E
 00001046	 00000057	MOV R0 lower 16-bits base(0), next at  00000F98
 0000104A	 00000000	MOVT R0 higher 16-bits var + 0
 0000104E	     6800	LDR R0 [ R0 + 0 ]
 00001050	     2800	CMP R0 #0
 00001052	     BF08	IT EQ
 00001054	 EC065244	TrapEQ 4 at pos 12964
 00001058	     7800	LDRB R0 [ R0 + 0 ]
 0000105A	     2800	CMP R0 #0
 0000105C	 F040801A	BNE #52, goes to  00001094
 00001060	 0000000D	MOV R0 lower 16-bits base(0), next at  00001046
 00001064	 00000000	MOVT R0 higher 16-bits var + 0
 00001068	     6800	LDR R0 [ R0 + 0 ]
 0000106A	 10000005	MOV R1 lower 16-bits base(0), next at  00001060
 0000106E	 00000008	MOVT R1 higher 16-bits var + 8
 00001072	     6008	STR R0 [  R1 + 0 ]
 00001074	 00000005	MOV R0 lower 16-bits base(0), next at  0000106A
 00001078	 00000000	MOVT R0 higher 16-bits var + 0
 0000107C	     6800	LDR R0 [ R0 + 0 ]
 0000107E	     2800	CMP R0 #0
 00001080	     BF08	IT EQ
 00001082	 EC066264	TrapEQ 4 at pos 13094
 00001086	     6A00	LDR R0 [ R0 + 32 ]
 00001088	 1000000A	MOV R1 lower 16-bits base(0), next at  00001074
 0000108C	 00000000	MOVT R1 higher 16-bits var + 0
 00001090	     6008	STR R0 [  R1 + 0 ]
 00001092	     E7D8	B #-80, goes to  00001046
 00001094	 F000B806	B #12, goes to  000010A4
 00001098	     2001	MOVS R0 #1
 0000109A	 10000009	MOV R1 lower 16-bits base(0), next at  00001088
 0000109E	 0000000C	MOVT R1 higher 16-bits var + 12
 000010A2	     6008	STR R0 [  R1 + 0 ]
 000010A4	 F85DEB04	LDR LR [ SP ] + 4
 000010A8	     B006	ADD SP SP #24
 000010AA	     4770	BX LR
 000010AC	     B500	PUSH LR
 000010AE	 F2410010	MOV R0 #4112
 000010B2	 F2CD0020	MOVT R0 #53280
 000010B6	     6800	LDR R0 [ R0 + 0 ]
 000010B8	 1000000F	MOV R1 lower 16-bits base(0), next at  0000109A
 000010BC	 00000008	MOVT R1 higher 16-bits var + 8
 000010C0	     6008	STR R0 [  R1 + 0 ]
 000010C2	 F2410014	MOV R0 #4116
 000010C6	 F2CD0020	MOVT R0 #53280
 000010CA	     6800	LDR R0 [ R0 + 0 ]
 000010CC	 1000000A	MOV R1 lower 16-bits base(0), next at  000010B8
 000010D0	 00000000	MOVT R1 higher 16-bits var + 0
 000010D4	     6008	STR R0 [  R1 + 0 ]
 000010D6	 F241001C	MOV R0 #4124
 000010DA	 F2CD0020	MOVT R0 #53280
 000010DE	     6800	LDR R0 [ R0 + 0 ]
 000010E0	 1000000A	MOV R1 lower 16-bits base(0), next at  000010CC
 000010E4	 00000050	MOVT R1 higher 16-bits var + 80
 000010E8	     6008	STR R0 [  R1 + 0 ]
 000010EA	 F85DEB04	LDR LR [ SP ] + 4
 000010EE	     4770	BX LR
 000010F0	     B500	PUSH LR
 000010F2	 F7FFFFDB	BL #-74, goes to  000010AC
 000010F6	 00000366	MOV R0 lower 16-bits base(0), next at  00000A2A
 000010FA	 00000018	MOVT R0 higher 16-bits const + 24
 000010FE	     2107	MOVS R1 #7
 00001100	 20000010	MOV R2 lower 16-bits base(0), next at  000010E0
 00001104	 00000004	MOVT R2 higher 16-bits var + 4
 00001108	 F7FFF94F	BL #-3426, goes to  000003AA
 0000110C	 00000006	MOV R0 lower 16-bits base(0), next at  00001100
 00001110	 0000000C	MOVT R0 higher 16-bits var + 12
 00001114	     6800	LDR R0 [ R0 + 0 ]
 00001116	     DF01	SVC #1
 00001118	     E7FE	B #-4, goes to  00001118
 0000111A	 F85DEB04	LDR LR [ SP ] + 4
 0000111E	     4770	BX LR
