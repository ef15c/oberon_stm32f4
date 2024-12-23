(**
 * The MIT License (MIT)
 * 
 * Copyright (c) 2015-2018 Nicholas Fraser
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 * 
 *)

(*
 * This is the MPack 1.0 amalgamation package.
 *
 * http://github.com/ludocode/mpack
 *)

MODULE mpack;
  IMPORT SYSTEM;

  CONST LO = 2;

    (**
     * Defines the type of a MessagePack tag.
     *
     * Note that extension types, both user defined and built-in, are represented
     * in tags as @ref type_ext. The value for an extension type is stored
     * separately.
     *)
    type_missing* = 0; (**< Special type indicating a missing optional value. *)
    type_nil* = 1;         (**< A null value. *)
    type_bool* = 2;        (**< A boolean (true or false.) *)
    type_int* = 3;         (**< A 64-bit signed integer. *)
    type_uint* = 4;        (**< A 64-bit unsigned integer. *)
    type_str* = 7;         (**< A string. *)
    type_array* = 8;       (**< An array of MessagePack objects. *)
    type_map* = 9;         (**< An ordered map of key/value pairs of MessagePack objects. *)

    (**
     * Error states for MPack objects.
     *
     * When a reader, writer, or tree is in an error state, all subsequent calls
     * are ignored and their return values are nil/zero. You should check whether
     * the source is in an error state before using such values.
     *)
    ok* = 0; (**< No error. *)
    error_io* = 2; (**< The reader or writer failed to fill or flush, or some other file or socket error occurred. *)
    error_invalid* = 3; (**< The data read is not valid MessagePack. *)
    error_unsupported* = 4; (***< The data read is not supported by this configuration of MPack. (See @ref MPACK_EXTENSIONS.) *)
    error_type* = 5; (**< The type or value range did not match what was expected by the caller. *)
    error_too_big* = 6; (**< A read or write was bigger than the maximum size allowed for that operation. *)
    error_memory* = 7; (**< An allocation failure occurred. *)
    error_bug* = 8; (***< The MPack API was used incorrectly. (This will always assert in debug mode.) *)
    error_data* = 9; (**< The contained data is not valid. *)
    error_eof* = 10; (**< The reader failed to read because of file or socket EOF *)

  TYPE
    Type = BYTE; Error = INTEGER;

    (**
     * An MPack tag is a MessagePack object header. It is a variant type
     * representing any kind of object, and includes the length of compound types
     * (e.g. map, array, string) or the value of non-compound types (e.g. boolean,
     * integer, float.)
     *
     * If the type is compound (str, bin, ext, array or map), the contained
     * elements or bytes are stored separately.
     *
     * This structure is opaque; its fields should not be accessed outside
     * of MPack.
     *)

    Tag* = RECORD
      type: Type; (*< The type of value. *)

      v0, v1, v2, v3: INTEGER (* The value for non-compound types. *)
    END;

    Integer64 = RECORD v: ARRAY 4 OF INTEGER END;
    Int64 = POINTER TO Integer64;

    Writer* = POINTER TO WriterDesc;

    (**
     * The MPack writer's flush function to flush the buffer to the output stream.
     * It should flag an appropriate error on the writer if flushing fails (usually
     * error_io or error_memory.)
     *
     * The specified context for callbacks is at writer->context.
     *)
    WriterFlush* = PROCEDURE(VAR writer: Writer; buffer: PBYTE; count: INTEGER);

    (**
     * An error handler function to be called when an error is flagged on
     * the writer.
     *
     * The error handler will only be called once on the first error flagged;
     * any subsequent writes and errors are ignored, and the writer is
     * permanently in that error state.
     *
     *)
    WriterError* = PROCEDURE (VAR writer: Writer; error: Error);

    (**
     * A teardown function to be called when the writer is destroyed.
     *)
    WriterTeardown* = PROCEDURE(VAR writer: Writer);

    (**
     * A buffered MessagePack encoder.
     *
     * The encoder wraps an existing buffer and, optionally, a flush function.
     * This allows efficiently encoding to an in-memory buffer or to a stream.
     *
     * All write operations are synchronous; they will block until the
     * data is fully written, or an error occurs.
     *)
    WriterDesc* = RECORD
      flush: WriterFlush; (** Function to write bytes to the output stream *)
      error_fn: WriterError; (* Function to call on error *)
      teardown: WriterTeardown; (* Function to teardown the context on destroy *)
      context: INTEGER; (* Context for writer callbacks *)

      buffer , current, end: PBYTE;  (* Byte buffer, current position within the buffer and the end of the buffer *)
      error: Error; (* Error state *)

      (* Reserved. You can use this space to allocate a custom
       * context in order to reduce heap allocations. *)
      reserved: ARRAY 2 OF INTEGER
    END;

    Reader* = POINTER TO ReaderDesc;

    (**
     * The MPack reader's fill function. It should fill the buffer with at
     * least one byte and at most the given @c count, returning the number
     * of bytes written to the buffer.
     *
     * In case of error, it should flag an appropriate error on the reader
     * (usually @ref error_io), or simply return zero. If zero is
     * returned, error_io is raised.
     *
     * @note When reading from a stream, you should only copy and return
     * the bytes that are immediately available. It is always safe to return
     * less than the requested count as long as some non-zero number of bytes
     * are read; if more bytes are needed, the read function will simply be
     * called again.
     *
     * @see reader_context()
     *)
    ReaderFill* = PROCEDURE(VAR reader: Reader; buffer: PBYTE; count: INTEGER);

    (**
     * The MPack reader's skip function. It should discard the given number
     * of bytes from the source (for example by seeking forward.)
     *
     * In case of error, it should flag an appropriate error on the reader.
     *
     * @see reader_context()
     *)
    ReaderSkip* = PROCEDURE(VAR reader: Reader; count: INTEGER);

    (**
     * An error handler function to be called when an error is flagged on
     * the reader.
     *
     * The error handler will only be called once on the first error flagged;
     * any subsequent reads and errors are ignored, and the reader is
     * permanently in that error state.
     *)
    ReaderError* = PROCEDURE(reader: Reader; error: Error);

    (**
     * A teardown function to be called when the reader is destroyed.
     *)
    ReaderTeardown* = PROCEDURE(VAR reader: Reader);

    (**
     * A buffered MessagePack decoder.
     *
     * The decoder wraps an existing buffer and, optionally, a fill function.
     * This allows efficiently decoding data from existing memory buffers, files,
     * streams, etc.
     *
     * All read operations are synchronous; they will block until the
     * requested data is fully read, or an error occurs.
     *
     * This structure is opaque; its fields should not be accessed outside
     * of MPack.
     *)
    ReaderDesc* = RECORD
      context: INTEGER; (* Context for reader callbacks *)
      fill: ReaderFill; (* Function to read bytes into the buffer *)
      error_fn: ReaderError; (** Function to call on error *)
      teardown: ReaderTeardown; (* Function to teardown the context on destroy *)
      skip: ReaderSkip; (* Function to skip bytes from the source *)

      buffer: PBYTE; (* Writeable byte buffer *)
      size: INTEGER; (* Size of the buffer *)

      data, end: PBYTE; (* Current data pointer (in the buffer, if it is used) and the end of available data (in the buffer, if it is used) *)

      error: Error (* Error state *)
    END;

  VAR TAG_ZERO: Tag;

  PROCEDURE copy_rev(s, d, c: INTEGER*);
  BEGIN INC(s, c);
    WHILE c > 0 DO DEC(s); SYSTEM.VAL(PBYTE, d)^ := SYSTEM.VAL(PBYTE,s)^; INC(d); DEC(c) END
  END copy_rev;

  PROCEDURE load_i8(d: INTEGER*; s: INTEGER*);
    VAR c, v0: INTEGER*;
  BEGIN v0 := SYSTEM.VAL(PBYTE,s)^; SYSTEM.VAL(PBYTE, d)^ := v0; INC(d);
    IF v0 < 0 THEN FOR c := 2 TO 8 DO SYSTEM.VAL(PBYTE, d)^ := 0FFH; INC(d) END END
  END load_i8;

  PROCEDURE load_i16(d: INTEGER*; s: INTEGER*);
    VAR c, v0: INTEGER*;
  BEGIN v0 := SYSTEM.VAL(PBYTE,s)^; 
    SYSTEM.VAL(PBYTE, d)^ := v0; INC(d); SYSTEM.VAL(PBYTE, d)^ := SYSTEM.VAL(PBYTE,s)^; INC(d);
    IF v0 < 0 THEN FOR c := 3 TO 8 DO SYSTEM.VAL(PBYTE, d)^ := 0FFH; INC(d) END END
  END load_i16;

  PROCEDURE load_iN(d: INTEGER*; s, n: INTEGER*);
    VAR c: INTEGER*; v0: INTEGER*;
  BEGIN c := n; v0 := SYSTEM.VAL(PBYTE,s)^; INC(SYSTEM.VAL(INTEGER, s), c);
    WHILE c > 0 DO DEC(s); SYSTEM.VAL(PBYTE, d)^ := SYSTEM.VAL(PBYTE,s)^; INC(d); DEC(c) END;
    IF v0 < 0 THEN FOR c := n+1 TO 8 DO SYSTEM.VAL(PBYTE, d)^ := 0FFH; INC(d) END END
  END load_iN;

  PROCEDURE memset(dest: PINTEGER*; val, count: INTEGER*);
  BEGIN WHILE count > 0 DO dest^ := val; INC(SYSTEM.VAL(INTEGER, dest), 2); DEC(count, 2) END;
  END memset;

  PROCEDURE parse_tag(VAR reader: ReaderDesc; VAR tag: Tag): INTEGER;
    VAR type, th: Type; count: INTEGER; data!: PBYTE;
  BEGIN ASSERT(reader.error = ok); count := 0; data := reader.data;
    type := data^; INC(SYSTEM.VAL(INTEGER, data)); th := type; CLRC; RRC(th); RRA(th, 3);

    IF th < 8 (* positive fixnum ( num < 127) *) THEN tag.type := type_uint; tag.v0 := type; count := 1
    ELSIF (th = 0EH) OR (th = 0FH) (* negative fixnum *) THEN tag.type := type_int; tag.v0 := type; tag.v1 := -1; tag.v2 := -1; tag.v3 := -1; count := 1
    ELSIF th = 8 (* fixmap *) THEN tag.type := type_map; tag.v0 := ORD(TOSET(type) - {4..15}); count := 1
    ELSIF th = 9 (* fixarray *) THEN tag.type := type_array; tag.v0 := ORD(TOSET(type) - {4..15}); count := 1
    ELSIF (th = 0AH) OR (th = 0BH) (* fixstr *) THEN tag.type := type_str; tag.v0 := ORD(TOSET(type) - {5..15}); count := 1
    ELSE (* not one of the common infix types *)
      (* handle individual type tags *)
      IF type = 0C0H (* nil *) THEN tag.type := type_nil; count := 1
      ELSIF (type = 0C2H) OR (type = 0C3H)  (* bool *) THEN tag.type := type_bool; tag.v0 := ORD(ODD(type)); count := 1
      ELSIF type = 0CCH (* uint8 *) THEN tag.type := type_uint; tag.v0 := data^; count := 2
      ELSIF type = 0CDH (* uint16 *) THEN tag.type := type_uint;
        copy_rev(SYSTEM.VAL(INTEGER, data), SYSTEM.ADR(tag.v0), 2); count := 3
      ELSIF type = 0CEH (* uint32 *) THEN tag.type := type_uint;
        copy_rev(SYSTEM.VAL(INTEGER, data), SYSTEM.ADR(tag.v0), 4); count := 5
      ELSIF type = 0CFH (* uint64 *) THEN tag.type := type_uint;
        copy_rev(SYSTEM.VAL(INTEGER, data), SYSTEM.ADR(tag.v0), 8); count := 9
      ELSIF type = 0D0H (* int8 *) THEN tag.type := type_int;
        load_i8(SYSTEM.ADR(tag.v0), SYSTEM.VAL(INTEGER, data)); count := 2
      ELSIF type =  0D1H (* int16 *) THEN tag.type := type_int;
        load_i16(SYSTEM.ADR(tag.v0), SYSTEM.VAL(INTEGER, data)); count := 3
      ELSIF type = 0D2H (* int32 *) THEN tag.type := type_int;
        load_iN(SYSTEM.ADR(tag.v0), SYSTEM.VAL(INTEGER, data), 4); count := 5
      ELSIF type = 0D3H (* int64 *) THEN tag.type := type_int;
        copy_rev(SYSTEM.VAL(INTEGER, data), SYSTEM.ADR(tag.v0), 8); count := 9
      END
    END

    RETURN count
  END parse_tag;

  (**
   * Initializes an MPack reader to parse a pre-loaded contiguous chunk of data. The
   * reader does not assume ownership of the data.
   *
   * @param reader The MPack reader.
   * @param data The data to parse.
   * @param count The number of bytes pointed to by data.
   *)
  PROCEDURE reader_init_data*(VAR reader: ReaderDesc; data: ARRAY OF CHAR);
  BEGIN
    memset(SYSTEM.VAL(PINTEGER, SYSTEM.ADR(reader)), 0, SYSTEM.SIZE(ReaderDesc));
    reader.data := SYSTEM.VAL(PBYTE, SYSTEM.ADR(data));
    reader.end := SYSTEM.VAL(PBYTE, SYSTEM.ADR(data) + LEN(data))
  END reader_init_data;

  PROCEDURE read_tag*(VAR reader: ReaderDesc; VAR tag: Tag);
    VAR count: INTEGER;
  BEGIN tag := TAG_ZERO; count := parse_tag(reader, tag);
    IF count = 0 THEN tag.type := type_nil ELSE INC(SYSTEM.VAL(INTEGER, reader.data), count) END
  END read_tag;

  (**
   * Gets the type of a tag.
   *)
  PROCEDURE tag_type*(tag: Tag*): Type;
    RETURN tag.type
  END tag_type;

  (**
   * Gets the number of key-value pairs in a map tag.
   *
   * This asserts that the type in the tag is @ref type_map. (No check is
   * performed if modue Traps is not imported.)
   *
   * @see type_map
   *)
  PROCEDURE tag_map_count*(tag: Tag*): INTEGER;
  BEGIN ASSERT(tag.type = type_map);
    RETURN SYSTEM.VAL(PINTEGER, SYSTEM.ADR(tag.v0))^
  END tag_map_count;

  (**
   * Reads bytes from a string, binary blob or extension object, copying
   * them into the given buffer.
   *
   * A str, bin or ext must have been opened by a call to read_tag()
   * which yielded one of these types, or by a call to an expect function
   * such as expect_str() or expect_bin().
   *
   * If an error occurs, the buffer contents are undefined.
   *
   * This can be called multiple times for a single str, bin or ext
   * to read the data in chunks. The total data read must add up
   * to the size of the object.
   *
   * @param reader The MPack reader
   * @param p The buffer in which to copy the bytes
   * @param count The number of bytes to read
   *)
  PROCEDURE read_bytes*(VAR reader: ReaderDesc*; p: PBYTE*; count: INTEGER*);
    VAR nbm: INTEGER*;
  BEGIN nbm := count; INC(nbm); CLRC; RRC(nbm); SYSTEM.COPY(SYSTEM.VAL(INTEGER, reader.data), SYSTEM.VAL(INTEGER, p), nbm);
    INC(SYSTEM.VAL(INTEGER, reader.data), count)
  END read_bytes;

  (**
   * Gets the length in bytes of a str-type tag.
   *
   * This asserts that the type in the tag is @ref type_str. (No check is
   * performed if module Traps is not imported.)
   *
   * @see type_str
   *)
  PROCEDURE tag_str_length*(tag: Tag*): INTEGER;
  BEGIN ASSERT(tag.type = type_str);
    RETURN SYSTEM.VAL(PINTEGER, SYSTEM.ADR(tag.v0))^
  END tag_str_length;

  (**
   * Gets the boolean value of a bool-type tag. The tag must be of type @ref
   * type_bool.
   *
   * This asserts that the type in the tag is type_bool. (No check is
   * performed if module Traps is not imported.)
   *)
  PROCEDURE tag_bool_value*(tag: Tag*): BOOLEAN;
  BEGIN ASSERT(tag.type = type_bool);
    RETURN SYSTEM.VAL(BOOLEAN, tag.v0)
  END tag_bool_value;

  (**
   * Gets the unsigned 16bit integer value of a uint-type tag.
   *
   * This asserts that the type in the tag is type_uint. (No check is
   * performed if module Traps is not imported.)
   *
   * @warning This does not convert between signed and unsigned tags! A positive
   * integer may be stored in a tag as either @ref type_int or @ref
   * type_uint. You must check the type first; this can only be used if the
   * type is @ref type_uint.
   *
   * @see type_uint
   *)
  PROCEDURE tag_uint16_value*(tag: Tag*): INTEGER;
  BEGIN ASSERT(tag.type = type_uint)
    RETURN SYSTEM.VAL(PINTEGER, SYSTEM.ADR(tag.v0))^
  END tag_uint16_value;

  (**
   * Cleans up the MPack reader, ensuring that all compound elements
   * have been completely read. Returns the final error state of the
   * reader.
   *
   * This will assert in tracking mode if the reader is not in an error
   * state and has any incomplete reads. If you want to cancel reading
   * in the middle of a document, you need to flag an error on the reader
   * before destroying it (such as error_data).
   *
   * @see read_tag()
   * @see reader_flag_error()
   * @see error_data
   *)
  PROCEDURE reader_destroy*(VAR reader: ReaderDesc): Error;
  BEGIN (* clean up tracking, asserting if we're not already in an error state *)
    IF reader.teardown # NIL THEN reader.teardown(SYSTEM.VAL(Reader, SYSTEM.ADR(reader))) END;
    reader.teardown := NIL

    RETURN reader.error
  END reader_destroy;

  PROCEDURE writer_clear(VAR writer: WriterDesc*);
  BEGIN
    writer.flush := NIL;
    writer.error_fn := NIL;
    writer.teardown := NIL;
    writer.context := 0;

    writer.buffer := NIL;
    writer.current := NIL;
    writer.end := NIL;
    writer.error := ok;
  END writer_clear;

  (**
   * Initializes an MPack writer with the given buffer. The writer
   * does not assume ownership of the buffer.
   *
   * Trying to write past the end of the buffer will result in error_too_big
   * unless a flush function is set with writer_set_flush(). To use the data
   * without flushing, call writer_buffer_used() to determine the number of
   * bytes written.
   *
   * @param writer The MPack writer.
   * @param buffer The buffer into which to write MessagePack data.
   * @param size The size of the buffer.
   *)
  PROCEDURE writer_init*(VAR writer: WriterDesc; buffer: ARRAY OF CHAR);
  BEGIN
    writer_clear(writer);
    writer.buffer := SYSTEM.VAL(PBYTE, SYSTEM.ADR(buffer));
    writer.current := SYSTEM.VAL(PBYTE, SYSTEM.ADR(buffer));
    writer.end := SYSTEM.VAL(PBYTE, SYSTEM.ADR(buffer) + LEN(buffer))
  END writer_init;

  (**
   * Sets the flush function to write out the data when the buffer is full.
   *
   * If no flush function is used, trying to write past the end of the
   * buffer will result in error_too_big.
   *
   * This should normally be used with writer_set_context() to register
   * a custom pointer to pass to the flush function.
   *
   * @param writer The MPack writer.
   * @param flush The function to write out data from the buffer.
   *
   * @see writer_context()
   *)
  PROCEDURE writer_set_flush*(VAR writer: WriterDesc*; flush: WriterFlush*);
  BEGIN
    writer.flush := flush
  END writer_set_flush;

  (**
   * Opens a map.
   *
   * `count * 2` elements must follow, and finish_map() must be called
   * when done.
   *
   * Remember that while map elements in MessagePack are implicitly ordered,
   * they are not ordered in JSON. If you need elements to be read back
   * in the order they are written, consider use an array instead.
   *
   * @see finish_map()
   *)
  PROCEDURE start_map*(VAR writer: WriterDesc*; count: BYTE*);
  BEGIN ASSERT(count < 80H); writer.current^ := 80H + count; INC(SYSTEM.VAL(INTEGER, writer.current))
  END start_map;

  PROCEDURE start_str_notrackfix(VAR writer: WriterDesc*; count: INTEGER*);
  BEGIN
    IF count <= 31 THEN writer.current^ := 0A0H + count; INC(SYSTEM.VAL(INTEGER, writer.current)) END
  END start_str_notrackfix;

  PROCEDURE strlen(s: ARRAY OF CHAR*): INTEGER;
    VAR l: INTEGER*;
  BEGIN l := 0; WHILE (l < LEN(s)) & (s[l] # 0X) DO INC(l) END

    RETURN l
  END strlen;

  (* Writes encoded bytes to the buffer, flushing if necessary. *)
  PROCEDURE write_native(VAR writer: WriterDesc*; str: ARRAY OF CHAR*);
    VAR i: INTEGER*;
  BEGIN i := 0; WHILE str[i] # 0X DO writer.current^ := ORD(str[i]); INC(SYSTEM.VAL(INTEGER, writer.current)); INC(i) END
  END write_native;

  (**
   * Writes a string.
   *
   * To stream a string in chunks, use start_str() instead.
   *
   * MPack does not care about the underlying encoding, but UTF-8 is highly
   * recommended, especially for compatibility with JSON. You should consider
   * calling write_utf8() instead, especially if you will be reading
   * it back as UTF-8.
   *
   * You should not call finish_str() after calling this; this
   * performs both start and finish.
   *)
  PROCEDURE write_str*(VAR writer: WriterDesc; str: ARRAY OF CHAR);
  BEGIN
    start_str_notrackfix(writer, strlen(str));
    write_native(writer, str);
  END write_str;

  (** Writes a boolean. *)
  PROCEDURE write_bool*(VAR writer: WriterDesc*; value: BOOLEAN*);
  BEGIN writer.current^ :=  0C2H + ORD(value); INC(SYSTEM.VAL(INTEGER, writer.current))
  END write_bool;

  (**
   * Returns the number of bytes currently stored in the buffer. This
   * may be less than the total number of bytes written if bytes have
   * been flushed to an underlying stream.
   *)
  PROCEDURE writer_buffer_used*(writer: WriterDesc): INTEGER;
    RETURN SYSTEM.VAL(INTEGER, writer.current) - SYSTEM.VAL(INTEGER, writer.buffer)
  END writer_buffer_used;

  (**
   * Flushes any buffered data to the underlying stream.
   *
   * If write tracking is enabled, this will break and flag @ref
   * error_bug if the writer has any open compound types, ensuring
   * that no compound types are still open. This prevents a "missing
   * finish" bug from causing a never-ending message.
   *
   * If the writer is connected to a socket and you are keeping it open,
   * you will want to call this after writing a message (or set of
   * messages) so that the data is actually sent.
   *
   * It is not necessary to call this if you are not keeping the writer
   * open afterwards. You can just call `writer_destroy()`, and it
   * will flush before cleaning up.
   *
   * This will assert if no flush function is assigned to the writer.
   *)
  PROCEDURE writer_flush_message*(VAR writer: WriterDesc);
    VAR used: INTEGER;
  BEGIN
    (* This is a bit ugly; we reset used before calling flush so that
       a flush function can distinguish between flushing the buffer
       versus flushing external data. see growable_writer_flush() *)
    used := writer_buffer_used(writer);
    writer.current := writer.buffer;
    writer.flush(SYSTEM.VAL(Writer, SYSTEM.ADR(writer)), writer.buffer, used)
  END writer_flush_message;

  (** Writes an unsigned integer in the most efficient packing available up to 32 bits. *)
  PROCEDURE write_uint*(VAR writer: WriterDesc*; valh, vall: INTEGER*);
  BEGIN
    IF valh = 0 THEN
      IF (vall >= 0) & (vall <= 127) THEN writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current))
      ELSIF (vall >= 0) & (vall <= 0FFH) THEN writer.current^ := 0CCH; INC(SYSTEM.VAL(INTEGER, writer.current));
        writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current))
      ELSE writer.current^ := 0CDH; INC(SYSTEM.VAL(INTEGER, writer.current));
        SWPB(vall); writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current));
        SWPB(vall); writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current))
      END
    ELSE writer.current^ := 0CEH; INC(SYSTEM.VAL(INTEGER, writer.current));
        SWPB(valh); writer.current^ := valh; INC(SYSTEM.VAL(INTEGER, writer.current));
        SWPB(valh); writer.current^ := valh; INC(SYSTEM.VAL(INTEGER, writer.current));
        SWPB(vall); writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current));
        SWPB(vall); writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current))
    END
  END write_uint;

  (** Writes an integer in the most efficient packing available up to 32 bits. *)
  PROCEDURE write_int*(VAR writer: WriterDesc*; valh, vall: INTEGER*);
  BEGIN
    IF valh = -1 THEN (* negative int16 *)
      IF vall >= -32 THEN writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current))
      ELSIF vall >= 80H THEN writer.current^ := 0D0H; INC(SYSTEM.VAL(INTEGER, writer.current));
        writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current))
      ELSE writer.current^ := 0D1H; INC(SYSTEM.VAL(INTEGER, writer.current));
        SWPB(vall); writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current));
        SWPB(vall); writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current))
      END
    ELSIF valh = 0 THEN (* positive int16 *)
      IF vall < 80H THEN writer.current^ := 0D0H; INC(SYSTEM.VAL(INTEGER, writer.current));
        writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current))
      ELSE writer.current^ := 0D1H; INC(SYSTEM.VAL(INTEGER, writer.current));
        SWPB(vall); writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current));
        SWPB(vall); writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current))
      END
    ELSE writer.current^ := 0D2H; INC(SYSTEM.VAL(INTEGER, writer.current));
        SWPB(valh); writer.current^ := valh; INC(SYSTEM.VAL(INTEGER, writer.current));
        SWPB(valh); writer.current^ := valh; INC(SYSTEM.VAL(INTEGER, writer.current));
        SWPB(vall); writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current));
        SWPB(vall); writer.current^ := vall; INC(SYSTEM.VAL(INTEGER, writer.current))
    END
  END write_int;


END mpack.
