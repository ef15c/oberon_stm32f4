MODULE minihdlc;
  CONST MAX_FRAME_LENGTH = 64;
    OUT_OF_FRAME = 0; IN_FRAME = 1;

  (* HDLC Asynchronous framing *)
  FRAME_BOUNDARY_OCTET = 7EH; (*The frame boundary octet is 01111110, (7E in hexadecimal notation)*)
  CONTROL_ESCAPE_OCTET= 7DH; (*A "control escape octet", has the bit sequence '01111101', (7D hexadecimal)*)

  (*If either of these two octets appears in the transmitted data, an escape octet is sent,
   * followed by the original data octet with bit 5 inverted*)
  INVERT_OCTET = 20H;


  TYPE Instance* = POINTER TO InstanceDesc;
    SendcharProc* = PROCEDURE(me: Instance; data: BYTE);
    FrameHandlerProc* = PROCEDURE(me: Instance; frame_buffer: ARRAY OF BYTE; frame_langth: INTEGER);
    InstanceDesc* = RECORD
      sendchar_function: SendcharProc; frame_handler: FrameHandlerProc;
      escape_character: BOOLEAN; frame_position: INTEGER;
      receive_frame_buffer, frame_buffer*: ARRAY MAX_FRAME_LENGTH + 1 OF BYTE;
      frame_buffer_size*, state, context: INTEGER;
    END;

  PROCEDURE init*(me: Instance; sendchar_function: SendcharProc; frame_hander_function: FrameHandlerProc; ctx: INTEGER);
  BEGIN me.sendchar_function := sendchar_function; me.frame_handler := frame_hander_function; me.frame_position := 0;
    me.escape_character := FALSE; me.state := OUT_OF_FRAME; me.context := ctx
  END init;

  PROCEDURE char_receiver*(me: Instance; data: BYTE);
  (* Function to find valid HDLC frame from incoming data *)
  BEGIN
    IF data = FRAME_BOUNDARY_OCTET THEN (*FRAME FLAG*)
      IF me.escape_character THEN (*According to the protocol, this should never happen. We drop the data and reset the instance*)
        me.escape_character := FALSE; me.frame_position := 0; me.state := OUT_OF_FRAME
      ELSIF (me.state = IN_FRAME) & (me.frame_position > 0) THEN (*a valid end of frame is detected*)
        me.frame_handler(me, me.receive_frame_buffer, me.frame_position); (*Call the user defined function and pass frame to it *)
      END;
      me.frame_position := 0; me.state := IN_FRAME
    ELSIF data = CONTROL_ESCAPE_OCTET THEN me.escape_character := TRUE
    ELSE IF me.escape_character THEN me.escape_character := FALSE; XOR(data, INVERT_OCTET) END;
      me.receive_frame_buffer[me.frame_position] := data; INC(me.frame_position);
      IF me.frame_position = MAX_FRAME_LENGTH THEN me.frame_position := 0 END
    END
  END char_receiver;

  PROCEDURE open_frame*(me: Instance);
  BEGIN me.sendchar_function(me, FRAME_BOUNDARY_OCTET)
  END open_frame;

  PROCEDURE close_frame*(me: Instance);
  BEGIN me.sendchar_function(me, FRAME_BOUNDARY_OCTET)
  END close_frame;

  PROCEDURE write_byte_to_frame*(me: Instance; data: BYTE);
  BEGIN
    IF (data = CONTROL_ESCAPE_OCTET) OR (data = FRAME_BOUNDARY_OCTET) THEN
      me.sendchar_function(me, CONTROL_ESCAPE_OCTET); XOR(data, INVERT_OCTET)
    END;
    me.sendchar_function(me, data)
  END write_byte_to_frame;

  PROCEDURE write_buffer_to_frame*(me: Instance; buffer: ARRAY OF BYTE; length: INTEGER);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE i < length DO write_byte_to_frame(me, buffer[i]); INC(i) END
  END write_buffer_to_frame;

  PROCEDURE write_string_to_frame*(me: Instance; str: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := -1; REPEAT INC(i); write_byte_to_frame(me, ORD(str[i])) UNTIL str[i] = 0X
  END write_string_to_frame;

  PROCEDURE send_frame*(me: Instance; frame_buffer: ARRAY OF BYTE; frame_length: INTEGER);
    (*Wrap given data in HDLC frame and send it out byte at a time*)
  BEGIN open_frame(me); write_buffer_to_frame(me, frame_buffer, frame_length); close_frame(me)
  END send_frame;

  PROCEDURE buffer_push(me: Instance; data: BYTE);
  BEGIN
    IF me.frame_buffer_size < MAX_FRAME_LENGTH THEN
      me.frame_buffer[me.frame_buffer_size] := data; INC(me.frame_buffer_size)
    END
  END buffer_push;

  PROCEDURE init_frame_to_buffer*(me: Instance);
  BEGIN me.sendchar_function := buffer_push; me.frame_buffer_size := 0
  END init_frame_to_buffer;

  PROCEDURE send_frame_to_buffer*(me: Instance; frame_buffer: ARRAY OF BYTE; frame_length: INTEGER);
  BEGIN init_frame_to_buffer(me); send_frame(me, frame_buffer, frame_length)
  END send_frame_to_buffer;

END minihdlc.
