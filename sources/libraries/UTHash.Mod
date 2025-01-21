MODULE UTHash;
  (*
  Copyright (c) 2003-2022, Troy D. Hanson  https://troydhanson.github.io/uthash/
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
  OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.*)

  CONST SIGNATURE = 0A0111FE1H; BKT_CAPACITY_THRESH = 10; (* expand when bucket count reaches *)

  TYPE Hash* = POINTER TO HashDesc;

    Bucket = RECORD
      head: Hash;
      count: INTEGER;

      (* expand_mult is normally set to 0. In this situation, the max chain length
       * threshold is enforced at its default value, BKT_CAPACITY_THRESH. (If
       * the bucket's chain exceeds this length, bucket expansion is triggered).
       * However, setting expand_mult to a non-zero value delays bucket expansion
       * (that would be triggered by additions to this particular bucket)
       * until its chain length reaches a *multiple* of BKT_CAPACITY_THRESH.
       * (The multiplier is simply expand_mult+1). The whole idea of this
       * multiplier is to reduce bucket expansions, since they are expensive, in
       * situations where we know that a particular bucket tends to be overused.
       * It is better to let its chain length grow to a longer yet-still-bounded
       * value, than to do an O(n) bucket expansion too often.
       *)
      expand_mult: INTEGER
    END;

    Table = POINTER TO TableDesc;
    TableDesc = RECORD
      num_items: INTEGER;
      tail: Hash; (* tail in app order, for fast append *)

     (* in an ideal situation (all buckets used equally), no bucket would have
      * more than ceil(#items/#buckets) items. that's the ideal chain length.*)
      ideal_chain_maxlen: INTEGER;

      (* nonideal_items is the number of items in the hash whose chain position
       * exceeds the ideal chain maxlen. these items pay the penalty for an uneven
       * hash distribution; reaching them in a chain traversal takes >ideal steps*)
      nonideal_items: INTEGER;

      (* ineffective expands occur when a bucket doubling was performed, but
       * afterward, more than half the items in the hash had nonideal chain
       * positions. If this happens on two consecutive expansions we inhibit any
       * further expansion, as it's not helping; this happens when the hash
       * function isn't a good fit for the key domain. When expansion is inhibited
       * the hash will still work, albeit no longer in constant time.*)
      nof_ineff_expands: INTEGER; noexpand: BOOLEAN;

      signature: INTEGER (* used only to find hash tables in external analysis *)
    END;

    Table32 = POINTER TO Table32Desc;
    Table32Desc = RECORD(TableDesc) buckets: ARRAY 32 OF Bucket END;
    Table64 = POINTER TO Table32Desc;
    Table64Desc = RECORD(TableDesc) buckets: ARRAY 64 OF Bucket END;

    Handle = RECORD
      tbl: Table;
      prev, (* prev element in app order  *) next (* next element in app order *): Hash;
      prev_in_bkt (* previous element in bucket order *), next_in_bkt (* next element in bucket order *): Hash;
      keylen (* enclosing struct's key len *), hashv (* result of hash-fcn(key) *): INTEGER
    END;

    HashDesc* = RECORD hh: Handle END;

    HashProc* = PROCEDURE(key: HashDesc): INTEGER;
    EqualProc* = PROCEDURE(a, b: HashDesc): BOOLEAN;

    LongintHashDesc* = RECORD(HashDesc) key*: LONGINT END;
    LongintHash* = POINTER TO LongintHashDesc;

  PROCEDURE JEN_MIX(a,b,c: INTEGER);
  BEGIN
    DEC(a, b); DEC(a, c); a := ORD(TOSET(a) / TOSET(LSR(c, 13)));
    DEC(b, c); DEC(b, a); b := ORD(TOSET(b) / TOSET(LSL(a, 8)));
    DEC(c, a); DEC(c, b); c := ORD(TOSET(c) / TOSET(LSR(b, 13)));
    DEC(a, b); DEC(a, c); a := ORD(TOSET(a) / TOSET(LSR(c, 12)));
    DEC(b, c); DEC(b, a); b := ORD(TOSET(b) / TOSET(LSL(a, 16)));
    DEC(c, a); DEC(c, b); c := ORD(TOSET(c) / TOSET(LSR(b, 5)));
    DEC(a, b); DEC(a, c); a := ORD(TOSET(a) / TOSET(LSR(c, 3)));
    DEC(b, c); DEC(b, a); b := ORD(TOSET(b) / TOSET(LSL(a, 10)));
    DEC(c, a); DEC(c, b); c := ORD(TOSET(c) / TOSET(LSR(b, 15))) 
  END JEN_MIX;

  PROCEDURE HASH_VALUE*(key: ARRAY OF BYTE; VAR hashv: INTEGER);
    VAR _hj_i, _hj_j, _hj_k, _hj_l: INTEGER;
  BEGIN hashv := 0FEEDBEEFH; _hj_i := 09E3779B9H; _hj_j := _hj_i;
    _hj_k := LEN(key); _hj_l := 0;
    WHILE _hj_k >= 12 DO
      INC(_hj_i, key[_hj_l] + LSL(key[_hj_l+1], 8) + LSL(key[_hj_l+2], 16) + LSL(key[_hj_l+3], 24 ));
      INC(_hj_j, key[_hj_l+4] + LSL(key[_hj_l+5], 8) + LSL(key[_hj_l+6], 16) + LSL(key[_hj_l+7], 24 ));
      INC(hashv, key[_hj_l+8] + LSL(key[_hj_l+9], 8) + LSL(key[_hj_l+10], 16) + LSL(key[_hj_l+11], 24));

      JEN_MIX(_hj_i, _hj_j, hashv);

      INC(_hj_l, 12);
      DEC(_hj_k, 12)
    END;
    INC(hashv, LEN(key));
    IF _hj_k >= 11 THEN INC(hashv, LSL(key[_hj_l+10], 24)) END;
    IF _hj_k >= 10 THEN INC(hashv, LSL(key[_hj_l+9], 16)) END;
    IF _hj_k >= 9 THEN INC(hashv, LSL(key[_hj_l+8], 8)) END;
    IF _hj_k >= 8 THEN INC(_hj_j, LSL(key[_hj_l+7], 24)) END;
    IF _hj_k >= 7 THEN INC(_hj_j, LSL(key[_hj_l+6], 16)) END;
    IF _hj_k >= 6 THEN INC(_hj_j, LSL(key[_hj_l+5], 8)) END;
    IF _hj_k >= 5 THEN INC(_hj_j, key[_hj_l+4]) END;
    IF _hj_k >= 4 THEN INC(_hj_i, LSL(key[_hj_l+3], 24)) END;
    IF _hj_k >= 3 THEN INC(_hj_i, LSL(key[_hj_l+2], 16)) END;
    IF _hj_k >= 2 THEN INC(_hj_i, LSL(key[_hj_l+1], 8)) END;
    IF _hj_k >= 1 THEN INC(_hj_i, key[_hj_l]) END;
    JEN_MIX(_hj_i, _hj_j, hashv)
  END HASH_VALUE;

  PROCEDURE HASH_TO_BKT(hashv, num_bkts: INTEGER): INTEGER;
    RETURN ORD(TOSET(hashv)*TOSET((num_bkts) - 1))
  END HASH_TO_BKT;

  PROCEDURE FIND_IN_BKT(tbl: Table; bucket: Bucket; key: HashDesc; hashval: INTEGER; isEqual: EqualProc): Hash;
    VAR out! : Hash; found: BOOLEAN;
    (* iterate over items in a known bucket to find desired item *)
  BEGIN out := bucket.head; found := FALSE;
    WHILE ~found & (out # NIL) DO
      IF (out.hh.hashv = hashval) & isEqual(out^, key) THEN found := TRUE
      ELSE out := out.hh.next_in_bkt
      END
    END

    RETURN out
  END FIND_IN_BKT;

  PROCEDURE FIND_BYHASHVALUE(head: Hash; key: HashDesc; hashval: INTEGER; isEqual: EqualProc): Hash;
    VAR out!: Hash; hf_bkt: INTEGER; tbl!: Table;
  BEGIN out := NIL;
    IF head # NIL THEN tbl := head.hh.tbl;
      CASE tbl OF
        Table32: hf_bkt := HASH_TO_BKT(hashval, LEN(tbl.buckets));
          out := FIND_IN_BKT(head.hh.tbl, tbl.buckets[_hf_bkt ], key, hashval, isEqual)
      | Table64: hf_bkt := HASH_TO_BKT(hashval, LEN(tbl.buckets));
          out := FIND_IN_BKT(head.hh.tbl, tbl.buckets[_hf_bkt ], key, hashval, isEqual)
      | Table: ASSERT(FALSE)
      END
    END

    RETURN out
  END FIND_BYHASHVALUE;

  PROCEDURE  FIND*(head: Hash; key: HashDesc; getHash: HashProc; isEqual: EqualProc): Hash;
    VAR out!: Hash; _hf_hashv: INTEGER;
  BEGIN out := NIL;
    IF head # NIL THEN
      _hf_hashv := getHash(key);
      out := FIND_BYHASHVALUE(head, key, _hf_hashv, isEqual);
    END

    RETURN out
  END FIND;

  PROCEDURE getLongintHash*(key: HashDesc): INTEGER;
    VAR _hj_i, _hj_j, hashv: INTEGER;
  BEGIN hashv := 0FEEDBEEFH; _hj_i := 09E3779B9H; _hj_j := _hj_i;
    CASE key OF
      LongintHashDesc: 
        INC(hashv, 8);
        INC(_hj_j, LSR(key.key, 32)); INC(_hj_i, key.key);
        JEN_MIX(_hj_i, _hj_j, hashv)
    | HashDesc: ASSERT(FALSE)
    END

    RETURN hashv
  END getLongintHash;

  PROCEDURE isLongintEqual(a, b: HashDesc): BOOLEAN;
    VAR r: BOOLEAN;
  BEGIN
    CASE a OF
      LongintHashDesc: r := a.key = b(LongintHashDesc).key
    | HashDesc: ASSERT(FALSE)
    END

    RETURN r
  END isLongintEqual;

  PROCEDURE  FIND_LONGINT*(head: LongintHash; key: LONGINT): LongintHash;
    VAR k!: LongintHashDesc; f!: Hash;
  BEGIN k.key := key; f := FIND(head, k, getLongintHash, isLongintEqual)

    RETURN f(LongintHash)
  END FIND_LONGINT;

  PROCEDURE MAKE_TABLE(head: Hash);
    VAR tbl!: Table32;
  BEGIN NEW(tbl); head.hh.tbl := tbl; tbl.tail := head; tbl.signature := SIGNATURE
  END MAKE_TABLE;

  PROCEDURE APPEND_LIST(head, add: Hash);
    VAR ptail!: Hash;
  BEGIN add.hh.next := NIL; ptail := head.hh.tbl.tail; add.hh.prev := ptail;
    ptail.hh.next := add; head.hh.tbl.tail := add
  END APPEND_LIST;

  (** Bucket expansion has the effect of doubling the number of buckets
   * and redistributing the items into the new buckets. Ideally the
   * items will distribute more or less evenly into the new buckets
   * (the extent to which this is true is a measure of the quality of
   * the hash function as it applies to the key domain).
   *
   * With the items distributed into more buckets, the chain length
   * (item count) in each bucket is reduced. Thus by expanding buckets
   * the hash keeps a bound on the chain length. This bounded chain
   * length is the essence of how a hash provides constant time lookup.
   *
   * The calculation of tbl.ideal_chain_maxlen below deserves some
   * explanation. First, keep in mind that we're calculating the ideal
   * maximum chain length based on the *new* (doubled) bucket count.
   * In fractions this is just n/b (n=number of items, b=new num buckets).
   * Since the ideal chain length is an integer, we want to calculate
   * ceil(n/b). We don't depend on floating point arithmetic in this
   * hash, so to calculate ceil(n/b) with integers we could write
   *
   *      ceil(n/b) = (n/b) + ((n%b)?1:0) = ((n+(b-1))/b)
   *
   *)

  PROCEDURE EXPAND_BUCKETS(hh: Handle);
    VAR tbl!: Table; tbl64!: Table64;

    PROCEDURE expandTable(tbl: Table; bkts: ARRAY OF Bucket; newTbl: Table; VAR newBkts: ARRAY OF Bucket);
      VAR he_bkt, _he_bkt_i: INTEGER;
        he_t!, he_nxt!: Hash;

        PROCEDURE addToNewBucket(newTbl: Table; _he_t: Hash; VAR newBkt: Bucket);
        BEGIN INC(newBkt.count);
          IF newBkt.count > newTbl.ideal_chain_maxlen THEN INC(newTbl.nonideal_items);
            IF newBkt.count > newBkt.expand_mult * newTbl.ideal_chain_maxlen THEN INC(newBkt.expand_mult) END
          END;
          _he_t.hh.prev_in_bkt := NIL; _he_t.hh.next_in_bkt := newBkt.head;
          IF newBkt.head # NIL THEN newBkt.head.hh.prev_in_bkt := _he_t END;
          newBkt.head := _he_t
        END addToNewBucket;

    BEGIN newTbl.ideal_chain_maxlen :=  (tbl.num_items + (LEN(newBkts) - 1)) DIV LEN(newBkts);
    newTbl.nonideal_items := 0;
    FOR _he_bkt_i := 0 TO LEN(bkts)-1 DO _he_t := bkts[ _he_bkt_i ].head;
      WHILE _he_t # NIL DO _he_nxt := _he_t.hh.next;
        _he_bkt := HASH_TO_BKT(_he_t.hh.hashv, LEN(newBkts));
        addToNewBucket(newTbl, _he_t, newBkts[_he_bkt]);
        _he_t := _he_nxt
      END
    END;
    IF newTbl.nonideal_items > newTbl.num_items DIV 2 THEN INC(newTbl.nof_ineff_expands) ELSE newTbl.nof_ineff_expands := 0 END;
    newTbl.noexpand := newTbl.nof_ineff_expands > 1;
    END expandTable;
  BEGIN tbl := hh.tbl;
    CASE tbl OF
      Table32: NEW(tbl64); expandTable(tbl, tbl.buckets, tbl64, tbl64.buckets)
    | Table64: ASSERT(FALSE)
    | Table: ASSERT(FALSE)
    END
  END EXPAND_BUCKETS;

  PROCEDURE ADD_TO_BKT(VAR bkt: Bucket; add: Hash);
    (* add an item to a bucket *)
  BEGIN INC(bkt.count); add.hh.next_in_bkt := bkt.head; add.hh.prev_in_bkt := NIL;
    IF bkt.head # NIL THEN bkt.head.hh.prev_in_bkt := add END; bkt.head := add;
    IF (bkt.count >= (bkt.expand_mult + 1)*BKT_CAPACITY_THRESH) & ~add.hh.tbl.noexpand THEN
      EXPAND_BUCKETS(add.hh)
    END
  END ADD_TO_BKT;

  PROCEDURE ADD_TO_TABLE(head: Hash; hashval: INTEGER; add: Hash);
    VAR _ha_bkt: INTEGER; tbl!: Table;
  BEGIN tbl := head.hh.tbl; INC(tbl.num_items);
    CASE tbl OF
      Table32: _ha_bkt := HASH_TO_BKT(hashval, LEN(tbl.buckets));
        ADD_TO_BKT(tbl.buckets[_ha_bkt], add)
    | Table64: _ha_bkt := HASH_TO_BKT(hashval, LEN(tbl.buckets));
        ADD_TO_BKT(tbl.buckets[_ha_bkt], add)
    | Table: ASSERT(FALSE)
    END
  END ADD_TO_TABLE;

  PROCEDURE ADD_BYHASHVALUE(VAR head: Hash; hashval: INTEGER; add: Hash);
  BEGIN add.hh.hashv := hashval;
    IF head = NIL THEN add.hh.next := NIL; add.hh.prev := NIL;
      MAKE_TABLE(add); head := add
    ELSE add.hh.tbl := head.hh.tbl; APPEND_LIST(head, add)
    END;
    ADD_TO_TABLE(head, hashval, add);
  END ADD_BYHASHVALUE;

  PROCEDURE ADD*(VAR head: Hash; add: Hash; getHash: HashProc);
    VAR _ha_hashv: INTEGER;
  BEGIN _ha_hashv := getHash(add^); ADD_BYHASHVALUE(head, _ha_hashv, add)
  END ADD;

  PROCEDURE ADD_LONGINT*(VAR head: LongintHash; add: LongintHash);
    VAR h!: Hash;
  BEGIN h := head; ADD(h, add, getLongintHash); head := h(LongintHash);
  END ADD_LONGINT;

END UTHash.

OM4P2.Compile UTHash.Mod/s ~
