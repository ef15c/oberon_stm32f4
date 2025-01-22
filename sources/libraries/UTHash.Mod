MODULE UTHash;
  (*
  Copyright (c) 2003-2022, Troy D. Hanson  https://troydhanson.github.io/uthash/
  All rights reserved.

  Oberon adaptation by C. Schoffit 22.01.25
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
      head: INTEGER; (*pointer to hash hidden from GC*)
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

    Table1 = POINTER TO Table1Desc;
    Table1Desc = RECORD(TableDesc) buckets: ARRAY 1024 OF Bucket END;
    Table2 = POINTER TO Table2Desc;
    Table2Desc = RECORD(TableDesc) buckets: ARRAY 2048 OF Bucket END;

    Handle = RECORD
      tbl: Table;
      prev, (* prev element in app order  *) next (* next element in app order *): Hash;
      prev_in_bkt (* previous element in bucket order *), next_in_bkt (* next element in bucket order *): Hash;
      keylen (* enclosing struct's key len *), hashv (* result of hash-fcn(key) *): INTEGER
    END;

    HashDesc* = RECORD hh: Handle END;

    HashProc* = PROCEDURE(key: Hash): INTEGER;
    EqualProc* = PROCEDURE(a, b: Hash): BOOLEAN;

    LongintHashDesc* = RECORD(HashDesc) key*: LONGINT END;
    LongintHash* = POINTER TO LongintHashDesc;

  VAR kli: LongintHash;

  PROCEDURE JEN_MIX(VAR a,b,c: INTEGER);
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

  PROCEDURE FIND_IN_BKT(tbl: Table; bucket: Bucket; key: Hash; hashval: INTEGER; isEqual: EqualProc): Hash;
    VAR out! : Hash; found: BOOLEAN; count: INTEGER;
    (* iterate over items in a known bucket to find desired item *)
  BEGIN out := SYSTEM.VAL(Hash, bucket.head); found := FALSE; count := 0;
    WHILE ~found & (out # NIL) DO INC(count);
      IF (out.hh.hashv = hashval) & isEqual(out, key) THEN found := TRUE
      ELSE out := out.hh.next_in_bkt
      END
    END;
    ASSERT(found OR (count = bucket.count))

    RETURN out
  END FIND_IN_BKT;

  PROCEDURE FIND_BYHASHVALUE(head, key: Hash; hashval: INTEGER; isEqual: EqualProc): Hash;
    VAR out!: Hash; hf_bkt: INTEGER; tbl!: Table;
  BEGIN out := NIL;
    IF head # NIL THEN tbl := head.hh.tbl;
      CASE tbl OF
        Table1: hf_bkt := hashval MOD LEN(tbl.buckets);
          out := FIND_IN_BKT(head.hh.tbl, tbl.buckets[_hf_bkt], key, hashval, isEqual)
      | Table2: hf_bkt := hashval MOD LEN(tbl.buckets);
          out := FIND_IN_BKT(head.hh.tbl, tbl.buckets[_hf_bkt], key, hashval, isEqual)
      | Table: ASSERT(FALSE)
      END
    END

    RETURN out
  END FIND_BYHASHVALUE;

  PROCEDURE  FIND*(head, key: Hash; getHash: HashProc; isEqual: EqualProc): Hash;
    VAR out!: Hash; _hf_hashv: INTEGER;
  BEGIN out := NIL;
    IF head # NIL THEN
      _hf_hashv := getHash(key);
      out := FIND_BYHASHVALUE(head, key, _hf_hashv, isEqual);
    END

    RETURN out
  END FIND;

  PROCEDURE NEXT*(elt: Hash): Hash;
    RETURN elt.hh.next
  END NEXT;

  PROCEDURE SETNEXT*(elt, nxt: Hash);
  BEGIN elt.hh.next := nxt
  END SETNEXT;

  PROCEDURE getLongintHash*(key: Hash): INTEGER;
    VAR _hj_i, _hj_j, hashv: INTEGER;
  BEGIN hashv := 0FEEDBEEFH; _hj_i := 09E3779B9H; _hj_j := _hj_i;
    CASE key OF
      LongintHash:
        INC(hashv, 8);
        INC(_hj_j, LSR(key.key, 32)); INC(_hj_i, key.key);
        JEN_MIX(_hj_i, _hj_j, hashv)
    | Hash: ASSERT(FALSE)
    END

    RETURN hashv
  END getLongintHash;

  PROCEDURE isLongintEqual(a, b: Hash): BOOLEAN;
    VAR r: BOOLEAN;
  BEGIN
    CASE a OF
      LongintHash: r := a.key = b(LongintHash).key
    | Hash: ASSERT(FALSE)
    END

    RETURN r
  END isLongintEqual;

  PROCEDURE  FIND_LONGINT*(head: LongintHash; key: LONGINT): LongintHash;
    VAR f!: Hash;
  BEGIN kli.key := key; f := FIND(head, kli, getLongintHash, isLongintEqual)

    RETURN f(LongintHash)
  END FIND_LONGINT;

  PROCEDURE MAKE_TABLE(head: Hash);
    VAR tbl!: Table1;
  BEGIN NEW(tbl); head.hh.tbl := tbl; tbl.tail := head; tbl.signature := SIGNATURE
  END MAKE_TABLE;

  PROCEDURE APPEND_LIST(head, add: Hash);
    VAR ptail!: Hash;
  BEGIN add.hh.next := NIL; ptail := head.hh.tbl.tail; add.hh.prev := ptail;
    ptail.hh.next := add; head.hh.tbl.tail := add
  END APPEND_LIST;

(*
  PROCEDURE printBucket(bkt: Bucket);
    VAR h!: Hash;
  BEGIN L.DebugHex("Bucket count", bkt.count);
    h := SYSTEM.VAL(Hash, bkt.head); WHILE h # NIL DO L.DebugHex("Hash", ORD(h)); h := h.hh.next_in_bkt END
  END printBucket;

  PROCEDURE printBuckets(bkts: ARRAY OF Bucket);
    VAR i: INTEGER;
  BEGIN FOR i := 0 TO LEN(bkts) - 1 DO L.DebugHex("bucket idx", i); printBucket(bkts[i]) END
  END printBuckets;
 
  PROCEDURE printTable(tbl: Table);
  BEGIN L.DebugHex("Table", ORD(tbl));
    L.DebugHex("tbl.num_items", tbl.num_items);
    CASE tbl OF
      Table1: printBuckets(tbl.buckets)
    | Table2: printBuckets(tbl.buckets)
    END
  END printTable;
*)

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

  PROCEDURE EXPAND_BUCKETS(tbl: Table);
    VAR tbl2!: Table2;

    PROCEDURE expandTable(tbl: Table; bkts: ARRAY OF Bucket; newTbl: Table; VAR newBkts: ARRAY OF Bucket);
      VAR he_bkt, _he_bkt_i: INTEGER;
        he_t!, he_nxt!: Hash;

        PROCEDURE addToNewBucket(newTbl: Table; _he_t: Hash; VAR newBkt: Bucket);
          VAR newHead!: Hash;
        BEGIN INC(newBkt.count);
          IF newBkt.count > newTbl.ideal_chain_maxlen THEN INC(newTbl.nonideal_items);
            IF newBkt.count > newBkt.expand_mult * newTbl.ideal_chain_maxlen THEN INC(newBkt.expand_mult) END
          END;
          newHead := SYSTEM.VAL(Hash, newBkt.head); _he_t.hh.prev_in_bkt := NIL; _he_t.hh.next_in_bkt := newHead;
          IF newHead # NIL THEN  newHead.hh.prev_in_bkt := _he_t END;
          newBkt.head := SYSTEM.VAL(INTEGER, _he_t); _he_t.hh.tbl := newTbl; INC(newTbl.num_items)
        END addToNewBucket;

    BEGIN 
      newTbl.ideal_chain_maxlen :=  (tbl.num_items + (LEN(newBkts) - 1)) DIV LEN(newBkts);
      newTbl.nonideal_items := 0; newTbl.tail := tbl.tail;
      FOR _he_bkt_i := 0 TO LEN(bkts)-1 DO _he_t := SYSTEM.VAL(Hash, bkts[ _he_bkt_i ].head);
        WHILE _he_t # NIL DO _he_nxt := _he_t.hh.next_in_bkt;
          _he_bkt := _he_t.hh.hashv MOD LEN(newBkts);
          addToNewBucket(newTbl, _he_t, newBkts[_he_bkt]);
          _he_t := _he_nxt
        END
      END;
      IF newTbl.nonideal_items > newTbl.num_items DIV 2 THEN INC(newTbl.nof_ineff_expands) ELSE newTbl.nof_ineff_expands := 0 END;
      newTbl.noexpand := newTbl.nof_ineff_expands > 1;
    END expandTable;
  BEGIN
    CASE tbl OF
      Table1: NEW(tbl2); expandTable(tbl, tbl.buckets, tbl2, tbl2.buckets)
    | Table2: ASSERT(FALSE)
    | Table: ASSERT(FALSE)
    END
  END EXPAND_BUCKETS;

  PROCEDURE ADD_TO_BKT(VAR bkt: Bucket; add: Hash);
    (* add an item to a bucket *)
    VAR head!: Hash;
  BEGIN head := SYSTEM.VAL(Hash, bkt.head); INC(bkt.count); add.hh.next_in_bkt := head; add.hh.prev_in_bkt := NIL;
    IF head # NIL THEN head.hh.prev_in_bkt := add END; bkt.head := SYSTEM.VAL(INTEGER, add);
    IF (bkt.count >= (bkt.expand_mult + 1)*BKT_CAPACITY_THRESH) & ~add.hh.tbl.noexpand THEN
      EXPAND_BUCKETS(add.hh.tbl)
    END
  END ADD_TO_BKT;

  PROCEDURE ADD_TO_TABLE(tbl: Table; add: Hash);
    VAR _ha_bkt: INTEGER;
  BEGIN INC(tbl.num_items);
    CASE tbl OF
      Table1: _ha_bkt := add.hh.hashv MOD LEN(tbl.buckets);
        ADD_TO_BKT(tbl.buckets[_ha_bkt], add)
    | Table2: _ha_bkt := add.hh.hashv MOD LEN(tbl.buckets);
        ADD_TO_BKT(tbl.buckets[_ha_bkt], add)
    | Table: ASSERT(FALSE)
    END
  END ADD_TO_TABLE;

  PROCEDURE ADD_BYHASHVALUE(VAR head: Hash; add: Hash);
  BEGIN
    IF head = NIL THEN add.hh.next := NIL; add.hh.prev := NIL;
      MAKE_TABLE(add); head := add
    ELSE add.hh.tbl := head.hh.tbl; APPEND_LIST(head, add)
    END;
    ADD_TO_TABLE(head.hh.tbl, add)
  END ADD_BYHASHVALUE;

  PROCEDURE ADD*(VAR head: Hash; add: Hash; getHash: HashProc);
    VAR _ha_hashv: INTEGER;
  BEGIN add.hh.hashv := getHash(add); ADD_BYHASHVALUE(head, add)
  END ADD;

  PROCEDURE ADD_LONGINT*(VAR head: LongintHash; add: LongintHash);
    VAR h!: Hash;
  BEGIN h := head; ADD(h, add, getLongintHash); head := h(LongintHash)
  END ADD_LONGINT;

BEGIN NEW(kli)
END UTHash.

OM4P2.Compile UTHash.Mod/s ~
OM4Tool.DecObj UTHash.m4c
