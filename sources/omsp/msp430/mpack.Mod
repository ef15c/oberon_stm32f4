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
    type := data^; INC(SYSTEM.VAL(INTEGER, data)); th := type; RRA(th, 4);

    IF th < 8 (* positive fixnum ( num < 127) *) THEN tag.type := type_uint; tag.v0 := type; count := 1
    ELSIF (th = 0EH) OR (th = 0FH) (* negative fixnum *) THEN tag.type := type_int; tag.v0 := type; tag.v1 := 0FFH; tag.v2 := 0FFH; tag.v3 := 0FFH; count := 1
    ELSIF th = 8 (* fixmap *) THEN tag.type := type_map; tag.v0 := ORD(TOSET(type) - {4..7}); count := 1
    ELSIF th = 9 (* fixarray *) THEN tag.type := type_array; tag.v0 := ORD(TOSET(type) - {4..7}); count := 1
    ELSIF (th = 0AH) OR (th = 0BH) (* fixstr *) THEN tag.type := type_str; tag.v0 := ORD(TOSET(type) - {5..7}); count := 1
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
  BEGIN INC(count); RRA(count, 1); SYSTEM.COPY(SYSTEM.VAL(INTEGER, reader.data), SYSTEM.VAL(INTEGER, p), count);
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

OMSPTool.DecSym mpack.sms
decode mpack.sms
mpack 4B28E872  1
   1 type_missing [^4]       0
   1 type_nil [^4]       1
   1 type_bool [^4]       2
   1 type_int [^4]       3
   1 type_uint [^4]       4
   1 type_str [^4]       7
   1 type_array [^4]       8
   1 type_map [^4]       9
   1 ok [^4]       0
   1 error_io [^4]       2
   1 error_invalid [^4]       3
   1 error_unsupported [^4]       4
   1 error_type [^4]       5
   1 error_too_big [^4]       6
   1 error_memory [^4]       7
   1 error_bug [^4]       8
   1 error_data [^4]       9
   1 error_eof [^4]      10
   5 Tag [19  form = 13  size = 10 [^9]{  exno = 1  extlev = 0 {}]()
   5 Writer [20  form = 7  size = 2 [21  form = 13  size = 20 [^9]{  exno = 2  extlev = 0 { --  12 --  10 --   8}]]()
   5 WriterFlush [22  form = 10  size = 2 [^9] UR FFF0( class = 2 [^4] class = 2 [^14] class = 3 [^20])]()
   5 WriterError [23  form = 10  size = 2 [^9] UR FFF0( class = 2 [^4] class = 3 [^20])]()
   5 WriterTeardown [24  form = 10  size = 2 [^9] UR FFF0( class = 3 [^20])]()
   5 WriterDesc [^21]( ->  20)
   5 Reader [25  form = 7  size = 2 [26  form = 13  size = 20 [^9]{  exno = 3  extlev = 0 { --  16 --  14 --  10}]]()
   5 ReaderFill [27  form = 10  size = 2 [^9] UR FFF0( class = 2 [^4] class = 2 [^14] class = 3 [^25])]()
   5 ReaderSkip [28  form = 10  size = 2 [^9] UR FFF0( class = 2 [^4] class = 3 [^25])]()
   5 ReaderError [29  form = 10  size = 2 [^9] UR FFF0( class = 2 [^4] class = 2 [^25])]()
   5 ReaderTeardown [30  form = 10  size = 2 [^9] UR FFF0( class = 3 [^25])]()
   5 ReaderDesc [^26]( ->  25)
   1 reader_init_data [0  form = 10  size = 2 [^9] UR C0F0( class = 3# [0  form = 12  size = 4 [^3]  len = -1] class = 3 [^26])]       4
   1 read_tag [0  form = 10  size = 2 [^9] UR E3F0( class = 3 [^19] class = 3 [^26])]       5
   1 tag_type [0  form = 10  size = 2 [^1] leaf UR 0070( class = 3# R5 [^19])]       6
   1 tag_map_count [0  form = 10  size = 2 [^4] leaf UR 0070( class = 3# R5 [^19])]       7
   1 read_bytes [0  form = 10  size = 2 [^9] leaf UR 07F0( class = 2 R7 [^4] class = 2 R6 [^14] class = 3 R4 [^26])]       8
   1 tag_str_length [0  form = 10  size = 2 [^4] leaf UR 0070( class = 3# R5 [^19])]       9
   1 tag_bool_value [0  form = 10  size = 2 [^2] leaf UR 0070( class = 3# R5 [^19])]      10
   1 tag_uint16_value [0  form = 10  size = 2 [^4] leaf UR 0070( class = 3# R5 [^19])]      11
   1 reader_destroy [0  form = 10  size = 2 [^4] UR FFF0( class = 3 [^26])]      12
   1 writer_init [0  form = 10  size = 2 [^9] UR C030( class = 3# [0  form = 12  size = 4 [^3]  len = -1] class = 3 [^21])]      13
   1 writer_set_flush [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^22] class = 3 R4 [^21])]      14
   1 start_map [0  form = 10  size = 2 [^9] leaf UR 01F0( class = 2 R6 [^1] class = 3 R4 [^21])]      15
   1 write_str [0  form = 10  size = 2 [^9] UR 07F0( class = 3# [0  form = 12  size = 4 [^3]  len = -1] class = 3 [^21])]      16
   1 write_bool [0  form = 10  size = 2 [^9] leaf UR 01F0( class = 2 R6 [^2] class = 3 R4 [^21])]      17
   1 writer_buffer_used [0  form = 10  size = 2 [^4] UR C000( class = 3# [^21])]      18
   1 writer_flush_message [0  form = 10  size = 2 [^9] UR FFF0( class = 3 [^21])]      19
   1 write_uint [0  form = 10  size = 2 [^9] leaf UR 01F0( class = 2 R7 [^4] class = 2 R6 [^4] class = 3 R4 [^21])]      20
   1 write_int [0  form = 10  size = 2 [^9] leaf UR 01F0( class = 2 R7 [^4] class = 2 R6 [^4] class = 3 R4 [^21])]      21

OMSPTool.DecObj mpack.mpc
decode mpack.mpc
mpack 4B28E872 Flash  1896
imports:
type descriptors
 000A FFFF FFFF FFFF 0008 FFFF FFFF FFFF 0014 FFFF FFFF FFFF 0014 FFFF FFFF FFFF
data    10
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0746 k 0000 k 0010 k 0018 c 0346 c 0370 c 03BE c 03C2 c 03CA c 03E8 c 03F0 c 03F6 c 03FE c 044C c 047E c 0484 c 04EC c 0524 c 0538 c 054A c 058C c 0646
fixup procedures chains
 0334     0	 0000
 02BA     0	 0016
 02E0     0	 0038
 030A     0	 0062
 0352     0	 0098
 039A     0	 00AA
 0456     0	 042A
 050C     0	 0498
 0502     0	 04B4
 0520     0	 04CA
 0556     0	 0538
fixup handlers chains
fixup data chains
 0374     0	 0000
fixup constants chains
fixup types chains
entry =  0746
code  1864
; PROCEDURE copy_rev(s, d, c: INTEGER*);
 0000	     5604	ADD R6,R4
 0002	     4307	MOV #0,R7
 0004	     9607	CMP R6,R7
 0006	     3406	JGE $+14, goes to  0014
 0008	     8314	SUB #1,R4
 000A	     44E5	MOV.B @R4,0(R5)
 000C	     0000
 000E	     5315	ADD #1,R5
 0010	     8316	SUB #1,R6
 0012	     3FF7	JMP $-16, goes to  0002
 0014	     4130	RET
; PROCEDURE load_i8(d: INTEGER*; s: INTEGER*);
 0016	     4568	MOV.B @R5,R8
 0018	     4807	MOV R8,R7
 001A	     47C4	MOV.B R7,0(R4)
 001C	     0000
 001E	     5314	ADD #1,R4
 0020	     9307	CMP #0,R7
 0022	     3409	JGE $+20, goes to  0036
 0024	     4326	MOV #2,R6
 0026	     4238	MOV #8,R8
 0028	     9608	CMP R6,R8
 002A	     3805	JL $+12, goes to  0036
 002C	     43F4	MOV.B #-1,0(R4)
 002E	     0000
 0030	     5314	ADD #1,R4
 0032	     5316	ADD #1,R6
 0034	     3FF8	JMP $-14, goes to  0026
 0036	     4130	RET
 ; PROCEDURE load_i16(d: INTEGER*; s: INTEGER*);
 0038	     4568	MOV.B @R5,R8
 003A	     4807	MOV R8,R7
 003C	     47C4	MOV.B R7,0(R4)
 003E	     0000
 0040	     5314	ADD #1,R4
 0042	     45E4	MOV.B @R5,0(R4)
 0044	     0000
 0046	     5314	ADD #1,R4
 0048	     9307	CMP #0,R7
 004A	     340A	JGE $+22, goes to  0060
 004C	     4036	MOV #3,R6
 004E	     0003
 0050	     4238	MOV #8,R8
 0052	     9608	CMP R6,R8
 0054	     3805	JL $+12, goes to  0060
 0056	     43F4	MOV.B #-1,0(R4)
 0058	     0000
 005A	     5314	ADD #1,R4
 005C	     5316	ADD #1,R6
 005E	     3FF8	JMP $-14, goes to  0050
 0060	     4130	RET
; PROCEDURE load_iN(d: INTEGER*; s, n: INTEGER*);
 0062	     4607	MOV R6,R7
 0064	     4569	MOV.B @R5,R9
 0066	     4908	MOV R9,R8
 0068	     5705	ADD R7,R5
 006A	     4309	MOV #0,R9
 006C	     9709	CMP R7,R9
 006E	     3406	JGE $+14, goes to  007C
 0070	     8315	SUB #1,R5
 0072	     45E4	MOV.B @R5,0(R4)
 0074	     0000
 0076	     5314	ADD #1,R4
 0078	     8317	SUB #1,R7
 007A	     3FF7	JMP $-16, goes to  006A
 007C	     9308	CMP #0,R8
 007E	     340B	JGE $+24, goes to  0096
 0080	     4609	MOV R6,R9
 0082	     5319	ADD #1,R9
 0084	     4907	MOV R9,R7
 0086	     4239	MOV #8,R9
 0088	     9709	CMP R7,R9
 008A	     3805	JL $+12, goes to  0096
 008C	     43F4	MOV.B #-1,0(R4)
 008E	     0000
 0090	     5314	ADD #1,R4
 0092	     5317	ADD #1,R7
 0094	     3FF8	JMP $-14, goes to  0086
 0096	     4130	RET
 PROCEDURE memset(dest: PINTEGER*; val, count: INTEGER*);
 0098	     4307	MOV #0,R7
 009A	     9607	CMP R6,R7
 009C	     3405	JGE $+12, goes to  00A8
 009E	     4584	MOV R5,0(R4)
 00A0	     0000
 00A2	     5324	ADD #2,R4
 00A4	     8326	SUB #2,R6
 00A6	     3FF8	JMP $-14, goes to  0098
 00A8	     4130	RET
; PROCEDURE parse_tag(VAR reader: ReaderDesc; VAR tag: Tag): INTEGER;
 00AA	     8031	SUB #6,SP
 00AC	     0006
 00AE	     4381	MOV #0,2(SP)
 00B0	     0002
 00B2	     411F	MOV 12(SP),R15
 00B4	     000C
 00B6	     4F91	MOV 14(R15),4(SP)
 00B8	     000E
 00BA	     0004
 00BC	     411F	MOV 4(SP),R15
 00BE	     0004
 00C0	     4FE1	MOV.B @R15,0(SP)
 00C2	     0000
 00C4	     5391	ADD #1,4(SP)
 00C6	     0004
 00C8	     41E1	MOV.B @SP,1(SP)
 00CA	     0001
 00CC	     1151	RRA.B 1(SP)
 00CE	     0001
 00D0	     1151	RRA.B 1(SP)
 00D2	     0001
 00D4	     1151	RRA.B 1(SP)
 00D6	     0001
 00D8	     1151	RRA.B 1(SP)
 00DA	     0001
 00DC	     92F1	CMP.B #8,1(SP)
 00DE	     0001
 00E0	     340C	JGE $+26, goes to  00FA
 00E2	     411F	MOV 8(SP),R15
 00E4	     0008
 00E6	     42EF	MOV.B #4,0(R15)
 00E8	     0000
 00EA	     416F	MOV.B @SP,R15
 00EC	     411E	MOV 8(SP),R14
 00EE	     0008
 00F0	     4F8E	MOV R15,2(R14)
 00F2	     0002
 00F4	     4391	MOV #1,2(SP)
 00F6	     0002
 00F8	     3D21	JMP $+580, goes to  033C
 00FA	     90F1	CMP.B #14,1(SP)
 00FC	     000E
 00FE	     0001
 0100	     2404	JEQ $+10, goes to  010A
 0102	     90F1	CMP.B #15,1(SP)
 0104	     000F
 0106	     0001
 0108	     201C	JNE $+58, goes to  0142
 010A	     411F	MOV 8(SP),R15
 010C	     0008
 010E	     40FF	MOV.B #3,0(R15)
 0110	     0003
 0112	     0000
 0114	     416F	MOV.B @SP,R15
 0116	     411E	MOV 8(SP),R14
 0118	     0008
 011A	     4F8E	MOV R15,2(R14)
 011C	     0002
 011E	     411F	MOV 8(SP),R15
 0120	     0008
 0122	     40BF	MOV #255,4(R15)
 0124	     00FF
 0126	     0004
 0128	     411F	MOV 8(SP),R15
 012A	     0008
 012C	     40BF	MOV #255,6(R15)
 012E	     00FF
 0130	     0006
 0132	     411F	MOV 8(SP),R15
 0134	     0008
 0136	     40BF	MOV #255,8(R15)
 0138	     00FF
 013A	     0008
 013C	     4391	MOV #1,2(SP)
 013E	     0002
 0140	     3CFD	JMP $+508, goes to  033C
 0142	     92F1	CMP.B #8,1(SP)
 0144	     0001
 0146	     200F	JNE $+32, goes to  0166
 0148	     411F	MOV 8(SP),R15
 014A	     0008
 014C	     40FF	MOV.B #9,0(R15)
 014E	     0009
 0150	     0000
 0152	     412F	MOV @SP,R15
 0154	     C03F	BIC #240,R15
 0156	     00F0
 0158	     411E	MOV 8(SP),R14
 015A	     0008
 015C	     4F8E	MOV R15,2(R14)
 015E	     0002
 0160	     4391	MOV #1,2(SP)
 0162	     0002
 0164	     3CEB	JMP $+472, goes to  033C
 0166	     90F1	CMP.B #9,1(SP)
 0168	     0009
 016A	     0001
 016C	     200E	JNE $+30, goes to  018A
 016E	     411F	MOV 8(SP),R15
 0170	     0008
 0172	     42FF	MOV.B #8,0(R15)
 0174	     0000
 0176	     412F	MOV @SP,R15
 0178	     C03F	BIC #240,R15
 017A	     00F0
 017C	     411E	MOV 8(SP),R14
 017E	     0008
 0180	     4F8E	MOV R15,2(R14)
 0182	     0002
 0184	     4391	MOV #1,2(SP)
 0186	     0002
 0188	     3CD9	JMP $+436, goes to  033C
 018A	     90F1	CMP.B #10,1(SP)
 018C	     000A
 018E	     0001
 0190	     2404	JEQ $+10, goes to  019A
 0192	     90F1	CMP.B #11,1(SP)
 0194	     000B
 0196	     0001
 0198	     200F	JNE $+32, goes to  01B8
 019A	     411F	MOV 8(SP),R15
 019C	     0008
 019E	     40FF	MOV.B #7,0(R15)
 01A0	     0007
 01A2	     0000
 01A4	     412F	MOV @SP,R15
 01A6	     C03F	BIC #224,R15
 01A8	     00E0
 01AA	     411E	MOV 8(SP),R14
 01AC	     0008
 01AE	     4F8E	MOV R15,2(R14)
 01B0	     0002
 01B2	     4391	MOV #1,2(SP)
 01B4	     0002
 01B6	     3CC2	JMP $+390, goes to  033C
 01B8	     90F1	CMP.B #192,0(SP)
 01BA	     00C0
 01BC	     0000
 01BE	     2007	JNE $+16, goes to  01CE
 01C0	     411F	MOV 8(SP),R15
 01C2	     0008
 01C4	     43DF	MOV.B #1,0(R15)
 01C6	     0000
 01C8	     4391	MOV #1,2(SP)
 01CA	     0002
 01CC	     3CB7	JMP $+368, goes to  033C
 01CE	     90F1	CMP.B #194,0(SP)
 01D0	     00C2
 01D2	     0000
 01D4	     2404	JEQ $+10, goes to  01DE
 01D6	     90F1	CMP.B #195,0(SP)
 01D8	     00C3
 01DA	     0000
 01DC	     2011	JNE $+36, goes to  0200
 01DE	     411F	MOV 8(SP),R15
 01E0	     0008
 01E2	     43EF	MOV.B #2,0(R15)
 01E4	     0000
 01E6	     B3D1	BIT.B #1,0(SP)
 01E8	     0000
 01EA	     2402	JEQ $+6, goes to  01F0
 01EC	     431F	MOV #1,R15
 01EE	     3C01	JMP $+4, goes to  01F2
 01F0	     430F	MOV #0,R15
 01F2	     411E	MOV 8(SP),R14
 01F4	     0008
 01F6	     4F8E	MOV R15,2(R14)
 01F8	     0002
 01FA	     4391	MOV #1,2(SP)
 01FC	     0002
 01FE	     3C9E	JMP $+318, goes to  033C
 0200	     90F1	CMP.B #204,0(SP)
 0202	     00CC
 0204	     0000
 0206	     200E	JNE $+30, goes to  0224
 0208	     411F	MOV 8(SP),R15
 020A	     0008
 020C	     42EF	MOV.B #4,0(R15)
 020E	     0000
 0210	     411F	MOV 4(SP),R15
 0212	     0004
 0214	     4F6F	MOV.B @R15,R15
 0216	     411E	MOV 8(SP),R14
 0218	     0008
 021A	     4F8E	MOV R15,2(R14)
 021C	     0002
 021E	     43A1	MOV #2,2(SP)
 0220	     0002
 0222	     3C8C	JMP $+282, goes to  033C
 0224	     90F1	CMP.B #205,0(SP)
 0226	     00CD
 0228	     0000
 022A	     2010	JNE $+34, goes to  024C
 022C	     411F	MOV 8(SP),R15
 022E	     0008
 0230	     42EF	MOV.B #4,0(R15)
 0232	     0000
 0234	     4114	MOV 4(SP),R4
 0236	     0004
 0238	     4115	MOV 8(SP),R5
 023A	     0008
 023C	     5325	ADD #2,R5
 023E	     4326	MOV #2,R6
 0240	     12B0	CALL #0
 0242	     0000
 0244	     40B1	MOV #3,2(SP)
 0246	     0003
 0248	     0002
 024A	     3C78	JMP $+242, goes to  033C
 024C	     90F1	CMP.B #206,0(SP)
 024E	     00CE
 0250	     0000
 0252	     2010	JNE $+34, goes to  0274
 0254	     411F	MOV 8(SP),R15
 0256	     0008
 0258	     42EF	MOV.B #4,0(R15)
 025A	     0000
 025C	     4114	MOV 4(SP),R4
 025E	     0004
 0260	     4115	MOV 8(SP),R5
 0262	     0008
 0264	     5325	ADD #2,R5
 0266	     4226	MOV #4,R6
 0268	     12B0	CALL #578
 026A	     0242
 026C	     40B1	MOV #5,2(SP)
 026E	     0005
 0270	     0002
 0272	     3C64	JMP $+202, goes to  033C
 0274	     90F1	CMP.B #207,0(SP)
 0276	     00CF
 0278	     0000
 027A	     2010	JNE $+34, goes to  029C
 027C	     411F	MOV 8(SP),R15
 027E	     0008
 0280	     42EF	MOV.B #4,0(R15)
 0282	     0000
 0284	     4114	MOV 4(SP),R4
 0286	     0004
 0288	     4115	MOV 8(SP),R5
 028A	     0008
 028C	     5325	ADD #2,R5
 028E	     4236	MOV #8,R6
 0290	     12B0	CALL #618
 0292	     026A
 0294	     40B1	MOV #9,2(SP)
 0296	     0009
 0298	     0002
 029A	     3C50	JMP $+162, goes to  033C
 029C	     90F1	CMP.B #208,0(SP)
 029E	     00D0
 02A0	     0000
 02A2	     200F	JNE $+32, goes to  02C2
 02A4	     411F	MOV 8(SP),R15
 02A6	     0008
 02A8	     40FF	MOV.B #3,0(R15)
 02AA	     0003
 02AC	     0000
 02AE	     4114	MOV 8(SP),R4
 02B0	     0008
 02B2	     5324	ADD #2,R4
 02B4	     4115	MOV 4(SP),R5
 02B6	     0004
 02B8	     12B0	CALL #0
 02BA	     0000
 02BC	     43A1	MOV #2,2(SP)
 02BE	     0002
 02C0	     3C3D	JMP $+124, goes to  033C
 02C2	     90F1	CMP.B #209,0(SP)
 02C4	     00D1
 02C6	     0000
 02C8	     2010	JNE $+34, goes to  02EA
 02CA	     411F	MOV 8(SP),R15
 02CC	     0008
 02CE	     40FF	MOV.B #3,0(R15)
 02D0	     0003
 02D2	     0000
 02D4	     4114	MOV 8(SP),R4
 02D6	     0008
 02D8	     5324	ADD #2,R4
 02DA	     4115	MOV 4(SP),R5
 02DC	     0004
 02DE	     12B0	CALL #0
 02E0	     0000
 02E2	     40B1	MOV #3,2(SP)
 02E4	     0003
 02E6	     0002
 02E8	     3C29	JMP $+84, goes to  033C
 02EA	     90F1	CMP.B #210,0(SP)
 02EC	     00D2
 02EE	     0000
 02F0	     2011	JNE $+36, goes to  0314
 02F2	     411F	MOV 8(SP),R15
 02F4	     0008
 02F6	     40FF	MOV.B #3,0(R15)
 02F8	     0003
 02FA	     0000
 02FC	     4114	MOV 8(SP),R4
 02FE	     0008
 0300	     5324	ADD #2,R4
 0302	     4115	MOV 4(SP),R5
 0304	     0004
 0306	     4226	MOV #4,R6
 0308	     12B0	CALL #0
 030A	     0000
 030C	     40B1	MOV #5,2(SP)
 030E	     0005
 0310	     0002
 0312	     3C14	JMP $+42, goes to  033C
 0314	     90F1	CMP.B #211,0(SP)
 0316	     00D3
 0318	     0000
 031A	     2010	JNE $+34, goes to  033C
 031C	     411F	MOV 8(SP),R15
 031E	     0008
 0320	     40FF	MOV.B #3,0(R15)
 0322	     0003
 0324	     0000
 0326	     4114	MOV 4(SP),R4
 0328	     0004
 032A	     4115	MOV 8(SP),R5
 032C	     0008
 032E	     5325	ADD #2,R5
 0330	     4236	MOV #8,R6
 0332	     12B0	CALL #658
 0334	     0292
 0336	     40B1	MOV #9,2(SP)
 0338	     0009
 033A	     0002
 033C	     411F	MOV 2(SP),R15
 033E	     0002
 0340	     5031	ADD #6,SP
 0342	     0006
 0344	     4130	RET
; PROCEDURE reader_init_data*(VAR reader: ReaderDesc; data: ARRAY OF CHAR);
 0346	     4114	MOV 6(SP),R4
 0348	     0006
 034A	     4305	MOV #0,R5
 034C	     4036	MOV #20,R6
 034E	     0014
 0350	     12B0	CALL #0
 0352	     0000
 0354	     411F	MOV 6(SP),R15
 0356	     0006
 0358	     419F	MOV 2(SP),14(R15)
 035A	     0002
 035C	     000E
 035E	     411F	MOV 2(SP),R15
 0360	     0002
 0362	     511F	ADD 4(SP),R15
 0364	     0004
 0366	     411E	MOV 6(SP),R14
 0368	     0006
 036A	     4F8E	MOV R15,16(R14)
 036C	     0010
 036E	     4130	RET
; PROCEDURE read_tag*(VAR reader: ReaderDesc; VAR tag: Tag);
 0370	     8321	SUB #2,SP
 0372	     403F	MOV #0,R15
 0374	     0000
 0376	     411E	MOV 4(SP),R14
 0378	     0004
 037A	     403D	MOV #5,R13
 037C	     0005
 037E	     4FBE	MOV @R15+,0(R14)
 0380	     0000
 0382	     532E	ADD #2,R14
 0384	     831D	SUB #1,R13
 0386	     23FB	JNE $-8, goes to  037E
 0388	     1211	PUSH 12(SP)
 038A	     000C
 038C	     1211	PUSH 12(SP)
 038E	     000C
 0390	     1211	PUSH 12(SP)
 0392	     000C
 0394	     1211	PUSH 12(SP)
 0396	     000C
 0398	     12B0	CALL #0
 039A	     0000
 039C	     5231	ADD #8,SP
 039E	     4F81	MOV R15,0(SP)
 03A0	     0000
 03A2	     9381	CMP #0,0(SP)
 03A4	     0000
 03A6	     2005	JNE $+12, goes to  03B2
 03A8	     411F	MOV 4(SP),R15
 03AA	     0004
 03AC	     43DF	MOV.B #1,0(R15)
 03AE	     0000
 03B0	     3C04	JMP $+10, goes to  03BA
 03B2	     411F	MOV 8(SP),R15
 03B4	     0008
 03B6	     51AF	ADD @SP,14(R15)
 03B8	     000E
 03BA	     5321	ADD #2,SP
 03BC	     4130	RET
; PROCEDURE tag_type*(tag: Tag*): Type;
 03BE	     4564	MOV.B @R5,R4
 03C0	     4130	RET
; PROCEDURE tag_map_count*(tag: Tag*): INTEGER;
 03C2	     4504	MOV R5,R4
 03C4	     5324	ADD #2,R4
 03C6	     4424	MOV @R4,R4
 03C8	     4130	RET
; PROCEDURE read_bytes*(VAR reader: ReaderDesc*; p: PBYTE*; count: INTEGER*);
 03CA	     5317	ADD #1,R7
 03CC	     1107	RRA R7
 03CE	     4708	MOV R7,R8
 03D0	     2408	JEQ $+18, goes to  03E2
 03D2	     4419	MOV 14(R4),R9
 03D4	     000E
 03D6	     460A	MOV R6,R10
 03D8	     49BA	MOV @R9+,0(R10)
 03DA	     0000
 03DC	     532A	ADD #2,R10
 03DE	     8318	SUB #1,R8
 03E0	     23FB	JNE $-8, goes to  03D8
 03E2	     5784	ADD R7,14(R4)
 03E4	     000E
 03E6	     4130	RET
; PROCEDURE tag_str_length*(tag: Tag*): INTEGER;
 03E8	     4504	MOV R5,R4
 03EA	     5324	ADD #2,R4
 03EC	     4424	MOV @R4,R4
 03EE	     4130	RET
; PROCEDURE tag_bool_value*(tag: Tag*): BOOLEAN;
 03F0	     4554	MOV.B 2(R5),R4
 03F2	     0002
 03F4	     4130	RET
; PROCEDURE tag_uint16_value*(tag: Tag*): INTEGER;
 03F6	     4504	MOV R5,R4
 03F8	     5324	ADD #2,R4
 03FA	     4424	MOV @R4,R4
 03FC	     4130	RET
; PROCEDURE reader_destroy*(VAR reader: ReaderDesc): Error;
 03FE	     411F	MOV 2(SP),R15
 0400	     0002
 0402	     938F	CMP #0,6(R15)
 0404	     0006
 0406	     2408	JEQ $+18, goes to  0418
 0408	     410F	MOV SP,R15
 040A	     532F	ADD #2,R15
 040C	     120F	PUSH R15
 040E	     411E	MOV 4(SP),R14
 0410	     0004
 0412	     129E	CALL 6(R14)
 0414	     0006
 0416	     5321	ADD #2,SP
 0418	     411F	MOV 2(SP),R15
 041A	     0002
 041C	     438F	MOV #0,6(R15)
 041E	     0006
 0420	     411F	MOV 2(SP),R15
 0422	     0002
 0424	     4F1F	MOV 18(R15),R15
 0426	     0012
 0428	     4130	RET
; PROCEDURE writer_clear(VAR writer: WriterDesc*);
 042A	     4384	MOV #0,0(R4)
 042C	     0000
 042E	     4384	MOV #0,2(R4)
 0430	     0002
 0432	     4384	MOV #0,4(R4)
 0434	     0004
 0436	     4384	MOV #0,6(R4)
 0438	     0006
 043A	     4384	MOV #0,8(R4)
 043C	     0008
 043E	     4384	MOV #0,10(R4)
 0440	     000A
 0442	     4384	MOV #0,12(R4)
 0444	     000C
 0446	     4384	MOV #0,14(R4)
 0448	     000E
 044A	     4130	RET
; PROCEDURE writer_init*(VAR writer: WriterDesc; buffer: ARRAY OF CHAR);
 044C	     4114	MOV 6(SP),R4
 044E	     0006
 0450	     4115	MOV 8(SP),R5
 0452	     0008
 0454	     12B0	CALL #0
 0456	     0000
 0458	     411F	MOV 6(SP),R15
 045A	     0006
 045C	     419F	MOV 2(SP),8(R15)
 045E	     0002
 0460	     0008
 0462	     411F	MOV 6(SP),R15
 0464	     0006
 0466	     419F	MOV 2(SP),10(R15)
 0468	     0002
 046A	     000A
 046C	     411F	MOV 2(SP),R15
 046E	     0002
 0470	     511F	ADD 4(SP),R15
 0472	     0004
 0474	     411E	MOV 6(SP),R14
 0476	     0006
 0478	     4F8E	MOV R15,12(R14)
 047A	     000C
 047C	     4130	RET
; PROCEDURE writer_set_flush*(VAR writer: WriterDesc; flush: WriterFlush*);
 047E	     4684	MOV R6,0(R4)
 0480	     0000
 0482	     4130	RET
; PROCEDURE start_map*(VAR writer: WriterDesc*; count: BYTE*);
 0484	     4417	MOV 10(R4),R7
 0486	     000A
 0488	     4038	MOV #128,R8
 048A	     0080
 048C	     5608	ADD R6,R8
 048E	     48C7	MOV.B R8,0(R7)
 0490	     0000
 0492	     5394	ADD #1,10(R4)
 0494	     000A
 0496	     4130	RET
; PROCEDURE start_str_notrackfix(VAR writer: WriterDesc*; count: INTEGER*);
 0498	     4037	MOV #31,R7
 049A	     001F
 049C	     9607	CMP R6,R7
 049E	     3809	JL $+20, goes to  04B2
 04A0	     4417	MOV 10(R4),R7
 04A2	     000A
 04A4	     4038	MOV #160,R8
 04A6	     00A0
 04A8	     5608	ADD R6,R8
 04AA	     48C7	MOV.B R8,0(R7)
 04AC	     0000
 04AE	     5394	ADD #1,10(R4)
 04B0	     000A
 04B2	     4130	RET
; PROCEDURE strlen(s: ARRAY OF CHAR): INTEGER;
 04B4	     4304	MOV #0,R4
 04B6	     9604	CMP R6,R4
 04B8	     3407	JGE $+16, goes to  04C8
 04BA	     4407	MOV R4,R7
 04BC	     5507	ADD R5,R7
 04BE	     93C7	CMP.B #0,0(R7)
 04C0	     0000
 04C2	     2402	JEQ $+6, goes to  04C8
 04C4	     5314	ADD #1,R4
 04C6	     3FF7	JMP $-16, goes to  04B6
 04C8	     4130	RET
; PROCEDURE write_native(VAR writer: WriterDesc*; str: ARRAY OF CHAR*);
 04CA	     4308	MOV #0,R8
 04CC	     4809	MOV R8,R9
 04CE	     5609	ADD R6,R9
 04D0	     93C9	CMP.B #0,0(R9)
 04D2	     0000
 04D4	     240A	JEQ $+22, goes to  04EA
 04D6	     4419	MOV 10(R4),R9
 04D8	     000A
 04DA	     480A	MOV R8,R10
 04DC	     560A	ADD R6,R10
 04DE	     4AE9	MOV.B @R10,0(R9)
 04E0	     0000
 04E2	     5394	ADD #1,10(R4)
 04E4	     000A
 04E6	     5318	ADD #1,R8
 04E8	     3FF1	JMP $-28, goes to  04CC
 04EA	     4130	RET
; PROCEDURE write_str*(VAR writer: WriterDesc; str: ARRAY OF CHAR);
 04EC	     4114	MOV 6(SP),R4
 04EE	     0006
 04F0	     4115	MOV 8(SP),R5
 04F2	     0008
 04F4	     1205	PUSH R5
 04F6	     1204	PUSH R4
 04F8	     4115	MOV 6(SP),R5
 04FA	     0006
 04FC	     4116	MOV 8(SP),R6
 04FE	     0008
 0500	     12B0	CALL #0
 0502	     0000
 0504	     4406	MOV R4,R6
 0506	     4134	POP R4
 0508	     4135	POP R5
 050A	     12B0	CALL #0
 050C	     0000
 050E	     4114	MOV 6(SP),R4
 0510	     0006
 0512	     4115	MOV 8(SP),R5
 0514	     0008
 0516	     4116	MOV 2(SP),R6
 0518	     0002
 051A	     4117	MOV 4(SP),R7
 051C	     0004
 051E	     12B0	CALL #0
 0520	     0000
 0522	     4130	RET
 0524	     4417	MOV 10(R4),R7
 0526	     000A
 0528	     4038	MOV #194,R8
 052A	     00C2
 052C	     5608	ADD R6,R8
 052E	     48C7	MOV.B R8,0(R7)
 0530	     0000
 0532	     5394	ADD #1,10(R4)
 0534	     000A
 0536	     4130	RET
 0538	     411F	MOV 2(SP),R15
 053A	     0002
 053C	     4F1F	MOV 10(R15),R15
 053E	     000A
 0540	     411E	MOV 2(SP),R14
 0542	     0002
 0544	     8E1F	SUB 8(R14),R15
 0546	     0008
 0548	     4130	RET
 054A	     8321	SUB #2,SP
 054C	     1211	PUSH 8(SP)
 054E	     0008
 0550	     1211	PUSH 8(SP)
 0552	     0008
 0554	     12B0	CALL #0
 0556	     0000
 0558	     5221	ADD #4,SP
 055A	     4F81	MOV R15,0(SP)
 055C	     0000
 055E	     411F	MOV 4(SP),R15
 0560	     0004
 0562	     411E	MOV 4(SP),R14
 0564	     0004
 0566	     4E9F	MOV 8(R14),10(R15)
 0568	     0008
 056A	     000A
 056C	     410F	MOV SP,R15
 056E	     522F	ADD #4,R15
 0570	     120F	PUSH R15
 0572	     411F	MOV 8(SP),R15
 0574	     0008
 0576	     121F	PUSH 8(R15)
 0578	     0008
 057A	     1211	PUSH 6(SP)
 057C	     0006
 057E	     411E	MOV 10(SP),R14
 0580	     000A
 0582	     12AE	CALL @R14
 0584	     5031	ADD #6,SP
 0586	     0006
 0588	     5321	ADD #2,SP
 058A	     4130	RET
 058C	     9306	CMP #0,R6
 058E	     2037	JNE $+112, goes to  05FE
 0590	     9307	CMP #0,R7
 0592	     380B	JL $+24, goes to  05AA
 0594	     4038	MOV #127,R8
 0596	     007F
 0598	     9708	CMP R7,R8
 059A	     3807	JL $+16, goes to  05AA
 059C	     4418	MOV 10(R4),R8
 059E	     000A
 05A0	     47C8	MOV.B R7,0(R8)
 05A2	     0000
 05A4	     5394	ADD #1,10(R4)
 05A6	     000A
 05A8	     3C29	JMP $+84, goes to  05FC
 05AA	     9307	CMP #0,R7
 05AC	     3812	JL $+38, goes to  05D2
 05AE	     4038	MOV #255,R8
 05B0	     00FF
 05B2	     9708	CMP R7,R8
 05B4	     380E	JL $+30, goes to  05D2
 05B6	     4418	MOV 10(R4),R8
 05B8	     000A
 05BA	     40F8	MOV.B #204,0(R8)
 05BC	     00CC
 05BE	     0000
 05C0	     5394	ADD #1,10(R4)
 05C2	     000A
 05C4	     4418	MOV 10(R4),R8
 05C6	     000A
 05C8	     47C8	MOV.B R7,0(R8)
 05CA	     0000
 05CC	     5394	ADD #1,10(R4)
 05CE	     000A
 05D0	     3C15	JMP $+44, goes to  05FC
 05D2	     4418	MOV 10(R4),R8
 05D4	     000A
 05D6	     40F8	MOV.B #205,0(R8)
 05D8	     00CD
 05DA	     0000
 05DC	     5394	ADD #1,10(R4)
 05DE	     000A
 05E0	     1087	SWPB R7
 05E2	     4418	MOV 10(R4),R8
 05E4	     000A
 05E6	     47C8	MOV.B R7,0(R8)
 05E8	     0000
 05EA	     5394	ADD #1,10(R4)
 05EC	     000A
 05EE	     1087	SWPB R7
 05F0	     4418	MOV 10(R4),R8
 05F2	     000A
 05F4	     47C8	MOV.B R7,0(R8)
 05F6	     0000
 05F8	     5394	ADD #1,10(R4)
 05FA	     000A
 05FC	     3C23	JMP $+72, goes to  0644
 05FE	     4418	MOV 10(R4),R8
 0600	     000A
 0602	     40F8	MOV.B #206,0(R8)
 0604	     00CE
 0606	     0000
 0608	     5394	ADD #1,10(R4)
 060A	     000A
 060C	     1086	SWPB R6
 060E	     4418	MOV 10(R4),R8
 0610	     000A
 0612	     46C8	MOV.B R6,0(R8)
 0614	     0000
 0616	     5394	ADD #1,10(R4)
 0618	     000A
 061A	     1086	SWPB R6
 061C	     4418	MOV 10(R4),R8
 061E	     000A
 0620	     46C8	MOV.B R6,0(R8)
 0622	     0000
 0624	     5394	ADD #1,10(R4)
 0626	     000A
 0628	     1087	SWPB R7
 062A	     4418	MOV 10(R4),R8
 062C	     000A
 062E	     47C8	MOV.B R7,0(R8)
 0630	     0000
 0632	     5394	ADD #1,10(R4)
 0634	     000A
 0636	     1087	SWPB R7
 0638	     4418	MOV 10(R4),R8
 063A	     000A
 063C	     47C8	MOV.B R7,0(R8)
 063E	     0000
 0640	     5394	ADD #1,10(R4)
 0642	     000A
 0644	     4130	RET
 0646	     9336	CMP #-1,R6
 0648	     2031	JNE $+100, goes to  06AC
 064A	     9037	CMP #-32,R7
 064C	     FFE0
 064E	     3807	JL $+16, goes to  065E
 0650	     4418	MOV 10(R4),R8
 0652	     000A
 0654	     47C8	MOV.B R7,0(R8)
 0656	     0000
 0658	     5394	ADD #1,10(R4)
 065A	     000A
 065C	     3C26	JMP $+78, goes to  06AA
 065E	     9037	CMP #128,R7
 0660	     0080
 0662	     380E	JL $+30, goes to  0680
 0664	     4418	MOV 10(R4),R8
 0666	     000A
 0668	     40F8	MOV.B #208,0(R8)
 066A	     00D0
 066C	     0000
 066E	     5394	ADD #1,10(R4)
 0670	     000A
 0672	     4418	MOV 10(R4),R8
 0674	     000A
 0676	     47C8	MOV.B R7,0(R8)
 0678	     0000
 067A	     5394	ADD #1,10(R4)
 067C	     000A
 067E	     3C15	JMP $+44, goes to  06AA
 0680	     4418	MOV 10(R4),R8
 0682	     000A
 0684	     40F8	MOV.B #209,0(R8)
 0686	     00D1
 0688	     0000
 068A	     5394	ADD #1,10(R4)
 068C	     000A
 068E	     1087	SWPB R7
 0690	     4418	MOV 10(R4),R8
 0692	     000A
 0694	     47C8	MOV.B R7,0(R8)
 0696	     0000
 0698	     5394	ADD #1,10(R4)
 069A	     000A
 069C	     1087	SWPB R7
 069E	     4418	MOV 10(R4),R8
 06A0	     000A
 06A2	     47C8	MOV.B R7,0(R8)
 06A4	     0000
 06A6	     5394	ADD #1,10(R4)
 06A8	     000A
 06AA	     3C4C	JMP $+154, goes to  0744
 06AC	     9306	CMP #0,R6
 06AE	     2027	JNE $+80, goes to  06FE
 06B0	     9037	CMP #128,R7
 06B2	     0080
 06B4	     340E	JGE $+30, goes to  06D2
 06B6	     4418	MOV 10(R4),R8
 06B8	     000A
 06BA	     40F8	MOV.B #208,0(R8)
 06BC	     00D0
 06BE	     0000
 06C0	     5394	ADD #1,10(R4)
 06C2	     000A
 06C4	     4418	MOV 10(R4),R8
 06C6	     000A
 06C8	     47C8	MOV.B R7,0(R8)
 06CA	     0000
 06CC	     5394	ADD #1,10(R4)
 06CE	     000A
 06D0	     3C15	JMP $+44, goes to  06FC
 06D2	     4418	MOV 10(R4),R8
 06D4	     000A
 06D6	     40F8	MOV.B #209,0(R8)
 06D8	     00D1
 06DA	     0000
 06DC	     5394	ADD #1,10(R4)
 06DE	     000A
 06E0	     1087	SWPB R7
 06E2	     4418	MOV 10(R4),R8
 06E4	     000A
 06E6	     47C8	MOV.B R7,0(R8)
 06E8	     0000
 06EA	     5394	ADD #1,10(R4)
 06EC	     000A
 06EE	     1087	SWPB R7
 06F0	     4418	MOV 10(R4),R8
 06F2	     000A
 06F4	     47C8	MOV.B R7,0(R8)
 06F6	     0000
 06F8	     5394	ADD #1,10(R4)
 06FA	     000A
 06FC	     3C23	JMP $+72, goes to  0744
 06FE	     4418	MOV 10(R4),R8
 0700	     000A
 0702	     40F8	MOV.B #210,0(R8)
 0704	     00D2
 0706	     0000
 0708	     5394	ADD #1,10(R4)
 070A	     000A
 070C	     1086	SWPB R6
 070E	     4418	MOV 10(R4),R8
 0710	     000A
 0712	     46C8	MOV.B R6,0(R8)
 0714	     0000
 0716	     5394	ADD #1,10(R4)
 0718	     000A
 071A	     1086	SWPB R6
 071C	     4418	MOV 10(R4),R8
 071E	     000A
 0720	     46C8	MOV.B R6,0(R8)
 0722	     0000
 0724	     5394	ADD #1,10(R4)
 0726	     000A
 0728	     1087	SWPB R7
 072A	     4418	MOV 10(R4),R8
 072C	     000A
 072E	     47C8	MOV.B R7,0(R8)
 0730	     0000
 0732	     5394	ADD #1,10(R4)
 0734	     000A
 0736	     1087	SWPB R7
 0738	     4418	MOV 10(R4),R8
 073A	     000A
 073C	     47C8	MOV.B R7,0(R8)
 073E	     0000
 0740	     5394	ADD #1,10(R4)
 0742	     000A
 0744	     4130	RET
 0746	     4130	RET
