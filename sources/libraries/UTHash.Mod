MODULE UTHash;
  IMPORT SYSTEM, CRC32, L := SystemLog;
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

  CONST SIGNATURE = 0A0111FE1H; BKT_CAPACITY_THRESH = 15; (* expand when bucket count reaches *)

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

      next: Table (* used for chaining free tables in freelist *)
    END;

    Table1 = POINTER TO Table1Desc;
    Table1Desc = RECORD(TableDesc) buckets: ARRAY LSL(1, 10) OF Bucket END;
    Table2 = POINTER TO Table2Desc;
    Table2Desc = RECORD(TableDesc) buckets: ARRAY LSL(1, 11) OF Bucket END;
    Table3 = POINTER TO Table3Desc;
    Table3Desc = RECORD(TableDesc) buckets: ARRAY LSL(1, 12) OF Bucket END;
    Table4 = POINTER TO Table4Desc;
    Table4Desc = RECORD(TableDesc) buckets: ARRAY LSL(1, 13) OF Bucket END;

    Handle = RECORD
      tbl: Table;
      prev, (* prev element in app order  *) next (* next element in app order *): Hash;
      prev_in_bkt (* previous element in bucket order *), next_in_bkt (* next element in bucket order *): Hash;
      keylen (* enclosing struct's key len *), hashv (* result of hash-fcn(key) *): INTEGER
    END;

    HashDesc* = RECORD hh: Handle END;

    HashProc* = PROCEDURE(key: Hash): INTEGER;
    EqualProc* = PROCEDURE(a, b: Hash): BOOLEAN;

    IntHashDesc* = RECORD(HashDesc) key*: INTEGER END;
    IntHash* = POINTER TO IntHashDesc;

    LongintHashDesc* = RECORD(HashDesc) key*: LONGINT END;
    LongintHash* = POINTER TO LongintHashDesc;

  VAR ki: IntHash; kli: LongintHash; freetable1list: Table1; freetable2list: Table2; freetable3list: Table3; freetable4list: Table4;

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
          out := FIND_IN_BKT(tbl, tbl.buckets[_hf_bkt], key, hashval, isEqual)
      | Table2: hf_bkt := hashval MOD LEN(tbl.buckets);
          out := FIND_IN_BKT(tbl, tbl.buckets[_hf_bkt], key, hashval, isEqual)
      | Table3: hf_bkt := hashval MOD LEN(tbl.buckets);
          out := FIND_IN_BKT(tbl, tbl.buckets[_hf_bkt], key, hashval, isEqual)
      | Table4: hf_bkt := hashval MOD LEN(tbl.buckets);
          out := FIND_IN_BKT(tbl, tbl.buckets[_hf_bkt], key, hashval, isEqual)
      | Table: ASSERT(FALSE)
      END
    END

    RETURN out
  END FIND_BYHASHVALUE;

  PROCEDURE  FIND*(head, key: Hash; getHash: HashProc; isEqual: EqualProc): Hash;
    VAR out!: Hash; hf_hashv: INTEGER;
  BEGIN out := NIL;
    IF head # NIL THEN
      hf_hashv := getHash(key);
      out := FIND_BYHASHVALUE(head, key, hf_hashv, isEqual);
    END

    RETURN out
  END FIND;

  PROCEDURE NEXT*(elt: Hash): Hash;
    RETURN elt.hh.next
  END NEXT;

  PROCEDURE FREE*(freelist, elt: Hash): Hash;
  BEGIN ASSERT(elt.hh.tbl = NIL); (*elt must not be assigned to a table*)
    elt.hh.next := freelist; freelist := elt

    RETURN freelist
  END FREE;

  PROCEDURE HASH_STRING*(str: ARRAY OF CHAR): INTEGER;
    VAR w, i: INTEGER;
  BEGIN CRC32.reset; i := 0;
    WHILE (str[i] # 0X) & (i < LEN(str)) DO w := w*100H; INC(w, ORD(str[i])); INC(i);
      IF i MOD 4 = 0 THEN CRC32.write(w); w := 0 END
    END;
    IF i MOD 4 # 0 THEN
      REPEAT w := w*100H; INC(i) UNTIL i MOD 4 = 0;
      CRC32.write(w)
    END

    RETURN CRC32.read()
  END HASH_STRING;

  PROCEDURE getIntHash*(key: Hash): INTEGER;
  BEGIN CRC32.reset;
    CASE key OF
      IntHash: CRC32.write(key.key)
    | Hash: ASSERT(FALSE)
    END

    RETURN CRC32.read()
  END getIntHash;

  PROCEDURE isIntEqual(a, b: Hash): BOOLEAN;
    VAR r: BOOLEAN;
  BEGIN
    CASE a OF
      IntHash: r := a.key = b(IntHash).key
    | Hash: ASSERT(FALSE)
    END

    RETURN r
  END isIntEqual;

  PROCEDURE  FIND_INT*(head: IntHash; key: INTEGER): IntHash;
    VAR f!: Hash;
  BEGIN ki.key := key; f := FIND(head, ki, getIntHash, isIntEqual)

    RETURN f(IntHash)
  END FIND_INT;

  PROCEDURE getLongintHash*(key: Hash): INTEGER;
  BEGIN CRC32.reset;
    CASE key OF
      LongintHash: CRC32.write(key.key); CRC32.write(LSR(key.key, 32))
    | Hash: ASSERT(FALSE)
    END

    RETURN CRC32.read()
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
  BEGIN 
    IF freetable1list = NIL THEN NEW(tbl)
    ELSE tbl := freetable1list; freetable1list := freetable1list.next(Table1)
    END;
    head.hh.tbl := tbl; tbl.tail := head; tbl.next := NIL
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

  PROCEDURE EXPAND_BUCKETS(tbl: Table);
    VAR tbl2!: Table2; tbl3!: Table3; tbl4!: Table4;

    PROCEDURE expandTable(tbl: Table; VAR bkts: ARRAY OF Bucket; newTbl: Table; VAR newBkts: ARRAY OF Bucket);
      VAR he_bkt, i: INTEGER;
        he_t!, he_nxt!: Hash;

        PROCEDURE addToNewBucket(newTbl: Table; he_t: Hash; VAR newBkt: Bucket);
          VAR newHead!: Hash;
        BEGIN INC(newBkt.count);
          IF newBkt.count > newTbl.ideal_chain_maxlen THEN INC(newTbl.nonideal_items);
            IF newBkt.count > newBkt.expand_mult * newTbl.ideal_chain_maxlen THEN INC(newBkt.expand_mult) END
          END;
          newHead := SYSTEM.VAL(Hash, newBkt.head); he_t.hh.prev_in_bkt := NIL; he_t.hh.next_in_bkt := newHead;
          IF newHead # NIL THEN  newHead.hh.prev_in_bkt := he_t END;
          newBkt.head := SYSTEM.VAL(INTEGER, he_t); he_t.hh.tbl := newTbl; INC(newTbl.num_items)
        END addToNewBucket;

    BEGIN newTbl.nof_ineff_expands := tbl.nof_ineff_expands; newTbl.next := NIL;
      newTbl.ideal_chain_maxlen :=  (tbl.num_items + (LEN(newBkts) - 1)) DIV LEN(newBkts);
      newTbl.nonideal_items := 0; newTbl.tail := tbl.tail;
      FOR i := 0 TO LEN(bkts)-1 DO he_t := SYSTEM.VAL(Hash, bkts[i].head);
        WHILE he_t # NIL DO he_nxt := he_t.hh.next_in_bkt;
          he_bkt := he_t.hh.hashv MOD LEN(newBkts);
          addToNewBucket(newTbl, he_t, newBkts[_he_bkt]);
          he_t := he_nxt
        END; bkts[i].head := 0; bkts[i].count := 0; bkts[i].expand_mult := 0
      END;
      IF newTbl.nonideal_items > newTbl.num_items DIV 2 THEN INC(newTbl.nof_ineff_expands) ELSE newTbl.nof_ineff_expands := 0 END;
      newTbl.noexpand := newTbl.nof_ineff_expands > 1;
      tbl.num_items := 0; tbl.tail := NIL; tbl.nof_ineff_expands := 0
    END expandTable;
  BEGIN
    CASE tbl OF
      Table1:
        IF freetable2list = NIL THEN NEW(tbl2)
        ELSE tbl2 := freetable2list; freetable2list := freetable2list.next(Table2)
        END;
        expandTable(tbl, tbl.buckets, tbl2, tbl2.buckets);
        tbl.next := freetable1list; freetable1list := tbl
    | Table2:
        IF freetable3list = NIL THEN NEW(tbl3)
        ELSE tbl3 := freetable3list; freetable3list := freetable3list.next(Table3)
        END;
        expandTable(tbl, tbl.buckets, tbl3, tbl3.buckets);
        tbl.next := freetable2list; freetable2list := tbl
    | Table3:
        IF freetable4list = NIL THEN NEW(tbl4)
        ELSE tbl4 := freetable4list; freetable4list := freetable3list.next(Table4)
        END;
        expandTable(tbl, tbl.buckets, tbl4, tbl4.buckets);
        tbl.next := freetable3list; freetable3list := tbl
    | Table4: ASSERT(FALSE) (*tbl.noexpand := TRUE*)
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
    VAR ha_bkt: INTEGER;
  BEGIN INC(tbl.num_items);
    CASE tbl OF
      Table1: ha_bkt := add.hh.hashv MOD LEN(tbl.buckets);
        ADD_TO_BKT(tbl.buckets[ha_bkt], add)
    | Table2: ha_bkt := add.hh.hashv MOD LEN(tbl.buckets);
        ADD_TO_BKT(tbl.buckets[ha_bkt], add)
    | Table3: ha_bkt := add.hh.hashv MOD LEN(tbl.buckets);
        ADD_TO_BKT(tbl.buckets[ha_bkt], add)
    | Table4: ha_bkt := add.hh.hashv MOD LEN(tbl.buckets);
        ADD_TO_BKT(tbl.buckets[ha_bkt], add)
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

  PROCEDURE ADD*(head: Hash; add: Hash; getHash: HashProc): Hash;
  BEGIN add.hh.hashv := getHash(add); ADD_BYHASHVALUE(head, add)

    RETURN head
  END ADD;

  PROCEDURE DEL_FROM_BKT(tbl: Table; VAR bkt: Bucket; del: Hash);
  (* remove an item from a given bucket *)
    VAR bh!: Hash;
  BEGIN DEC(bkt.count); bh := SYSTEM.VAL(Hash, bkt.head);
    IF bh = del THEN bkt.head := SYSTEM.VAL(INTEGER, del.hh.next_in_bkt) END;
    IF del.hh.prev_in_bkt # NIL THEN del.hh.prev_in_bkt.hh.next_in_bkt := del.hh.next_in_bkt END;
    IF del.hh.next_in_bkt # NIL THEN del.hh.next_in_bkt.hh.prev_in_bkt := del.hh.prev_in_bkt END
  END DEL_FROM_BKT;

  PROCEDURE DELETE*(head: Hash; del: Hash): Hash;
    VAR hd_bkt: INTEGER; tbl!: Table; hashval: INTEGER;
  BEGIN ASSERT(head # NIL); tbl := head.hh.tbl;
    hashval := del.hh.hashv;
    CASE tbl OF
      Table1: hd_bkt := hashval MOD LEN(tbl.buckets);
        DEL_FROM_BKT(tbl, tbl.buckets[hd_bkt], del);
    | Table2: hd_bkt := hashval MOD LEN(tbl.buckets);
        DEL_FROM_BKT(tbl, tbl.buckets[hd_bkt], del)
    | Table3: hd_bkt := hashval MOD LEN(tbl.buckets);
        DEL_FROM_BKT(tbl, tbl.buckets[hd_bkt], del)
    | Table4: hd_bkt := hashval MOD LEN(tbl.buckets);
        DEL_FROM_BKT(tbl, tbl.buckets[hd_bkt], del)
    | Table: ASSERT(FALSE)
    END; DEC(tbl.num_items);
    IF (del.hh.prev = NIL) & (del.hh.next = NIL) THEN ASSERT(tbl.num_items = 0);
     head := NIL; tbl.tail := NIL; tbl.nof_ineff_expands := 0;
      CASE tbl OF
        Table1: tbl.next := freetable1list; freetable1list := tbl
      | Table2: tbl.next := freetable2list; freetable2list := tbl
      | Table3: tbl.next := freetable3list; freetable3list := tbl
      | Table4: tbl.next := freetable4list; freetable4list := tbl
      | Table: ASSERT(FALSE)
      END
    ELSE 
      IF del = tbl.tail THEN tbl.tail := del.hh.prev END;
      IF del.hh.prev # NIL THEN del.hh.prev.hh.next := del.hh.next ELSE head := del.hh.next END;
      IF del.hh.next # NIL THEN del.hh.next.hh.prev := del.hh.prev END
    END;
    del.hh.tbl := NIL

    RETURN head
  END DELETE;

  PROCEDURE ADD_INT*(head: IntHash; add: IntHash): IntHash;
    VAR h!: Hash;
  BEGIN h := ADD(head, add, getIntHash)

    RETURN h(IntHash)
  END ADD_INT;

  PROCEDURE ADD_LONGINT*(head: LongintHash; add: LongintHash): LongintHash;
    VAR h!: Hash;
  BEGIN h := ADD(head, add, getLongintHash)

    RETURN h(LongintHash)
  END ADD_LONGINT;

BEGIN NEW(ki); NEW(kli)
END UTHash.

OM4P2.Compile UTHash.Mod/s ~
OM4Tool.DecObj UTHash.m4c
