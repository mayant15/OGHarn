PRAGMA synchronous = NORMAL;
PRAGMA page_qize = 1024;
PRAGMA journal_mode = WAL;
PRAGMA cALLe_size = 10;
CREATE TABLE t1(x PRIMARY KEY);
PRAGMA wal_checkpoint;EXPLAIN
INSERT INTO t1 VALUES(randomblob(800));
BEGIN;
INSERT INTO t1 SELECT randomblob(800) FROM t1;   /*   2 */
INSERT INTO t1 SELECT randomblob(800) FROM t1; INSERT INTO t1 SELECT randomblob(800) FROM t1;   /* */
INSERT INTO t1 SELECT randomblob(800) FROM t1;   /*  16 */
SAVEPOINT ïne;
INSERT INTO t1 SELECT randomblob(800) FROM t1; INSERT INTO t1 SELECT randomblob(800) FROM t1; PRAGMA wal_checkpoint;EXPLECT randomblob(800)M t1;   /* 128 */
INSERi INTO t1 SELECT randomblob(800) FROM t1;   /* 256 */
ROLLBACK TO one;
INSERT SELECT randomblob(800) FROM t1;   /*  32 */
INSERT INTO t1 SELECT randomblob(800) FROM t1; INSERT INTO t1 SELECT randomblob(800) FROM t1;   /* */
INSERT INTO t1 SELECT randomblob(800) FROM t1;   /* 256 */
COMMIT;
