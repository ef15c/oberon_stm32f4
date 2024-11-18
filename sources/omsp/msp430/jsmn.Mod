(* --COPYRIGHT--,BSD
 * Copyright (c) 2010 Serge A. Zaitsev
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * --/COPYRIGHT--*)

MODULE jsmn;
  IMPORT SYSTEM;

  CONST
  (**
   * JSON type identifier. Basic types are:
   *  o Object
   *  o Array
   *  o String
   *  o Other primitive: number, boolean (true/false) or null
   *)

    UNDEFINED* = 0;
    OBJECT* = 1;
    ARRAy* = 2;
    STRING* = 3;
    PRIMITIVE* = 4;

    (* Not enough tokens were provided *)
    ERROR_NOMEM* = -1;
    (* Invalid character inside JSON string *)
    ERROR_INVAL* = -2;
    (* The string is not a full JSON packet, more bytes expected *)
    ERROR_PART* = -3;

  TYPE Type* = BYTE;
    (**
     * JSON token description.
     * type     type (object, array, string etc.)
     * start    start position in JSON data string
     * end      end position in JSON data string
     *)

    Tok* = RECORD
      type*: Type;
     start*, end*, size*: INTEGER
    END;
    Token = POINTER TO Tok;

  (**
   * JSON parser. Contains an array of token blocks available. Also stores
   * the string being parsed now and current position in that string
   *)
    Parser* = RECORD
      pos, (* offset in the JSON string *)
      toknext, (* next token to allocate *)
      toksuper: INTEGER (* superior token node, e.g parent object or array *)
    END;

  (**
   * Create JSON parser over an array of tokens
   *)
  PROCEDURE init*(VAR parser: Parser*);
    (**
     * Creates a new parser based over a given  buffer with an array of tokens
     * available.
     *)
  BEGIN
    parser.pos := 0;
    parser.toknext := 0;
    parser.toksuper := -1
  END init;

  (**
   * Allocates a fresh unused token from the token pull.
   *)
  PROCEDURE alloc_token(VAR parser: Parser*; tokens: ARRAY OF Tok*): Token;
    VAR tok!: Token*;
  BEGIN
    IF parser.toknext >= LEN(tokens) THEN tok := NIL
    ELSE tok := SYSTEM.VAL(Token, SYSTEM.ADR(tokens[parser.toknext])); INC(parser.toknext);
      tok.start := -1; tok.end := -1; tok.size := 0
    END

    RETURN tok
  END alloc_token;

  (**
   * Fills token type and boundaries.
   *)
  PROCEDURE fill_token(VAR token: Token*; type: Type*; start, end: INTEGER*);
  BEGIN
    token.type := type;
    token.start := start;
    token.end := end;
    token.size := 0
  END fill_token;

  (**
   * Fills next token with JSON string.
   *)
  PROCEDURE parse_string(VAR parser: Parser; js: ARRAY OF CHAR; tokens: ARRAY OF Tok; pretend: BOOLEAN): INTEGER;
    VAR token!: Token; start: INTEGER; c: CHAR; rc, i: INTEGER;
  BEGIN rc := 1;
    start := parser.pos; INC(parser.pos); (* Skip starting quote *)
    WHILE (parser.pos < LEN(js)) & (js[parser.pos] # 0X) & (rc > 0) DO
      c := js[parser.pos];

      IF c = 22X THEN (* Quote: end of string *)
        IF pretend THEN rc := 0
        ELSE token := alloc_token(parser, tokens);
          IF token = NIL THEN parser.pos := start; rc := ERROR_NOMEM
          ELSE fill_token(token, STRING, start+1, parser.pos); rc := 0
          END
        END
      ELSIF (c = "\") & (parser.pos + 1 < LEN(js)) THEN (* Backslash: Quoted symbol expected *)
        INC(parser.pos);
        c := js[parser.pos];
        IF c = "u" THEN (* Allows escaped symbol \uXXXX *)
          INC(parser.pos); i := 0;
          WHILE (i < 4) & (parser.pos < LEN(js)) & (js[parser.pos] # 0X) & (rc >= 0) DO
            (* If it isn't a hex character we have an error *)
            IF (js[parser.pos] >= 30X) & (js[parser.pos] <= 39X) OR (* 0-9 *)
            (js[parser.pos] >= 41X) & (js[parser.pos] <= 46X) OR (* A-F *)
            (js[parser.pos] >= 61X) & (js[parser.pos] <= 66X) THEN (* a-f *)
              INC(parser.pos);
            ELSE parser.pos := start; rc := ERROR_INVAL
            END;
            INC(i)
          END;
          DEC(parser.pos)
          ELSIF (c # 22X) & (c # "/") & (c # "\") & (c # "b") & (c # "f") & (c # "r") & (c # "n") & (c # "t") THEN (* Unexpected symbol *)
            parser.pos := start; rc := ERROR_INVAL
          END
      END;
      IF rc > 0 THEN INC(parser.pos) END;
    END;
    IF rc > 0 THEN
      parser.pos := start;
      rc := ERROR_PART
    END

    RETURN rc
  END parse_string;

  (**
   * Fills next available token with JSON primitive.
   *)
  PROCEDURE parse_primitive(VAR parser: Parser; js: ARRAY OF CHAR; VAR tokens: ARRAY OF Tok; pretend: BOOLEAN): INTEGER;
    VAR token!: Token; start, rc: INTEGER; c: CHAR;
  BEGIN start := parser.pos; rc := 1;
    WHILE (parser.pos < LEN(js)) & (js[parser.pos] # 0X) & (rc > 0) DO
      c := js[parser.pos];
      IF (c = ":") OR (c = 9X) OR (c = 0DX) OR (c = 0AX) OR (c = " ") OR (c = ",") OR (c = "]") OR (c = "}") THEN rc := 0
      ELSIF (js[parser.pos] < 20X) OR (js[parser.pos] >= 07FX) THEN parser.pos := start; rc := ERROR_INVAL
      ELSE INC (parser.pos)
      END
    END;

    IF rc >= 0 THEN
      IF pretend THEN DEC(parser.pos); rc := 0
      ELSE
        token := alloc_token(parser, tokens);
        IF token = NIL THEN parser.pos := start; rc := ERROR_NOMEM
        ELSE fill_token(token, PRIMITIVE, start, parser.pos);
          DEC(parser.pos)
        END
      END
    END

    RETURN rc
  END parse_primitive;

  (**
   * Run JSON parser. It parses a JSON data string into and array of tokens, each describing
   * a single JSON object.
   *)
  PROCEDURE parse*(VAR parser: Parser; js: ARRAY OF CHAR; VAR tokens: ARRAY OF Tok; pretend: BOOLEAN): INTEGER;
    (**
     * Parse JSON string and fill tokens.
     *)
    VAR r, i, count: INTEGER;
      token!: Token;
      c: CHAR; type: Type; done: BOOLEAN;
  BEGIN
    count := parser.toknext;

    WHILE (parser.pos < LEN(js)) & (js[parser.pos] # 0X) DO
      c := js[parser.pos];
      IF (c = "{") OR (c = "[") THEN INC(count);
        IF ~pretend THEN token := alloc_token(parser, tokens);
          IF token = NIL THEN count := ERROR_NOMEM
          ELSE
            IF parser.toksuper # -1 THEN INC(tokens[parser.toksuper].size) END;
            IF c = "{" THEN token.type := OBJECT ELSE token.type := ARRAy END;
            token.start := parser.pos;
            parser.toksuper := parser.toknext - 1
          END
        END
      ELSIF (c = "}") OR (c = "]") THEN
        IF ~pretend THEN
          IF c = "}" THEN type := OBJECT ELSE type := ARRAy END;
          i := parser.toknext; done := FALSE;
          REPEAT
            DEC(i); token := SYSTEM.VAL(Token, SYSTEM.ADR(tokens[i]));
            IF (token.start # -1) & (token.end = -1) THEN
              IF token.type # type THEN count := ERROR_INVAL ELSE parser.toksuper := -1; token.end := parser.pos + 1 END;
              done := TRUE
            END
          UNTIL done OR (i = 0);
          IF ~done THEN count := ERROR_INVAL (* Error if unmatched closing bracket *) END;
          IF count >= 0 THEN done := FALSE;
            WHILE ~done & (i >= 0) DO
              token := SYSTEM.VAL(Token, SYSTEM.ADR(tokens[i]));
              IF (token.start # -1) & (token.end = -1) THEN parser.toksuper := i; i := 0; done := TRUE END;
              DEC(i)
            END
          END
        END
      ELSIF c = 22X (* " *) THEN r := parse_string(parser, js, tokens, pretend);
        IF r < 0 THEN count := r
        ELSE INC(count);
          IF (parser.toksuper # -1) & ~pretend THEN INC(tokens[parser.toksuper].size) END
        END
      ELSIF (c = 9X) OR (c = 0DX) OR (c = 0AX) OR (c = " ") THEN (* nothing to do *)
      ELSIF c = ":" THEN parser.toksuper := parser.toknext - 1
      ELSIF c = "," THEN
        IF ~pretend & (parser.toksuper # -1) & (tokens[parser.toksuper].type # ARRAy) & (tokens[parser.toksuper].type # OBJECT) THEN
          i := parser.toknext;
          REPEAT DEC(i);
            IF (tokens[i].type = ARRAy) OR (tokens[i].type = OBJECT) THEN
              IF (tokens[i].start # -1) & (tokens[i].end = -1) THEN parser.toksuper := i; i := 0 END
            END
          UNTIL i = 0 
        END
      ELSE (* In non-strict mode every unquoted value is a primitive *)
        r := parse_primitive(parser, js, tokens, pretend);
        IF r < 0 THEN count := r
        ELSE INC(count);
          IF (parser.toksuper # -1) & ~pretend THEN INC(tokens[parser.toksuper].size) END
        END
      END;
      INC(parser.pos)
    END;

    IF ~pretend & (count >= 0) THEN
      i := parser.toknext;
      REPEAT DEC(i);
        (* Unmatched opened object or array *)
        IF (tokens[i].start # -1) & (tokens[i].end = -1) THEN count := ERROR_PART; i := 0 END
      UNTIL i = 0
    END

    RETURN count
  END parse;

END jsmn.

OMSPTool.DecSym jsmn.sms
decode jsmn.sms
jsmn D164A2EC  1
   1 UNDEFINED [^4]       0
   1 OBJECT [^4]       1
   1 ARRAy [^4]       2
   1 STRING [^4]       3
   1 PRIMITIVE [^4]       4
   1 ERROR_NOMEM [^4]      -1
   1 ERROR_INVAL [^4]      -2
   1 ERROR_PART [^4]      -3
   5 Type [^1]()
   5 Tok [19  form = 13  size = 8 [^9]{  exno = 1  extlev = 0 { size [^4]   6 end [^4]   4 start [^4]   2 type [^1]   0}]()
   5 Parser [20  form = 13  size = 6 [^9]{  exno = 2  extlev = 0 {}]()
   1 init [0  form = 10  size = 2 [^9] leaf UR 0030( class = 3 R4 [^20])]       3
   1 parse [0  form = 10  size = 2 [^4] UR E3F0( class = 2 [^2] class = 3 [0  form = 12  size = 4 [^19]  len = -1] class = 3# [0  form = 12  size = 4 [^3]  len = -1] class = 3 [^20])]       4
