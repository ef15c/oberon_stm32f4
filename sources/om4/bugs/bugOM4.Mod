MODULE bugOM4;
  IMPORT Kernel, Log := SystemLog;

  VAR I: RECORD a, b: BYTE END;

  PROCEDURE p*;
    VAR i: INTEGER;
  BEGIN i := LDREX(I.b); (*request exclusive access to variable I*)
    INC(i); (*Kernel.Delayms(1);*)
    IF STREX(I.b, i) THEN Log.DebugInt("success I", I.b, 1)
    ELSE Log.DebugInt("failure I", I.b, 1)
    END
  END p;

END bugOM4.

Oberon.Batch
  OM4P.Compile bugOM4.Mod/s~
  System.Free bugOM4~
~
bugOM4.p

OM4Tool.DecObj bugOM4.m4c
decode bugOM4.m4c
bugOM4 438B51FB   2    196
imports:
	Kernel B86A8CBD
	SystemLog 010F4765
	Math 7B5147FE
type descriptors

strings
success I|||failure I|||
data     4
code
commands:
	p 00000000
entries
 00000074 00000000
pointer refs

fixP =  00000068
fixV =  00000058
fixC =  0000004E
fixT =  00000000
entry =  00000074
 00000000       122	     B081	SUB SP SP #4
 00000002       122	     B500	PUSH LR
 00000004       143	 00000002	MOV R0 lower 16-bits base(0), next at  00000000
 00000008       143	 00000001	MOVT R0 higher 16-bits var + 1
 0000000C       143	 E8D00F4F	LDREXB R0 [ R0 ]
 00000010       143	     9001	STR R0 [ SP + 4 ]
 00000012       198	     9801	LDR R0 [ SP + 4 ]
 00000014       198	     1C40	ADDS R0 R0 #1
 00000016       198	     9001	STR R0 [ SP + 4 ]
 00000018       244	     9801	LDR R0 [ SP + 4 ]
 0000001A       244	 1000000B	MOV R1 lower 16-bits base(0), next at  00000004
 0000001E       244	 00000001	MOVT R1 higher 16-bits var + 1
 00000022       244	 E8C10F42	STREXB R2 R0 [ R1 ]
 00000026       244	     2A00	CMP R2 #0
 00000028       244	 F0408011	BNE #34, goes to  0000004E
 0000002C       273	 00000016	MOV R0 lower 16-bits base(0), next at  00000000
 00000030       273	 00000000	MOVT R0 higher 16-bits const + 0
 00000034       273	     210A	MOVS R1 #10
 00000036       278	 2000000E	MOV R2 lower 16-bits base(0), next at  0000001A
 0000003A       278	 00000001	MOVT R2 higher 16-bits var + 1
 0000003E       278	     7812	LDRB R2 [ R2 + 0 ]
 00000040       278	 F34273C0	SBFX R3 R2 #31 #1
 00000044       281	     2401	MOVS R4 #1
 00000046       287	 20200023	BL Mod(  2) proc(2)
 0000004A       292	 F000B80F	B #30, goes to  0000006C
 0000004E       316	 00000011	MOV R0 lower 16-bits base(0), next at  0000002C
 00000052       316	 0000000C	MOVT R0 higher 16-bits const + 12
 00000056       316	     210A	MOVS R1 #10
 00000058       321	 20000011	MOV R2 lower 16-bits base(0), next at  00000036
 0000005C       321	 00000001	MOVT R2 higher 16-bits var + 1
 00000060       321	     7812	LDRB R2 [ R2 + 0 ]
 00000062       321	 F34273C0	SBFX R3 R2 #31 #1
 00000066       324	     2401	MOVS R4 #1
 00000068       330	 20200011	BL Mod(  2) proc(2)
 0000006C       336	 F85DEB04	LDR LR [ SP ] + 4
 00000070       336	     B001	ADD SP SP #4
 00000072       336	     4770	BX LR
 00000074       344	     B500	PUSH LR
 00000076       354	 F85DEB04	LDR LR [ SP ] + 4
 0000007A       354	     4770	BX LR
