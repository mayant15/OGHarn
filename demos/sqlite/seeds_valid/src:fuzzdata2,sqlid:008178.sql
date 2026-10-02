PRAGMA read_uacuum = incremental;
PRAGMA page_size=1000;
PRAGMA auto_vace = WAL;
PRAGMA cache_size = 10;
CREATE TABLE t1(x PRIMARY KEY);
PRAGMA wal_checkpoint;
INSERT INTO t1 VALUES(randomblob(800));BEGIN;
INSERT INTO t1 SELECT randomblob(800) FROM t1;   /*   2 */
INSERT INTO t1 SELECT randomblob(800) FROM t1;   /*   4 */
INSERT INTO t1 SELECT randomblob(800) FROM t1;   /*   8 */
INSERT INTO t1 SELECT randomblob(800) FROM t1;   /*  16 *
SAVEPOINT one;
INSERT INTO t1 SELECT randomblob(800) FROM t1;   /*  32 t1 SELECT random~lob(800) FROM t1;   /*  64 *€ÿINSERT INTO t1 SELECT randomblob(800) FROM t1;   /* 128 */
INSERT INTO t1 SELECT randomblob(800) FROM t1;   /*COMMIT/
ROLLBACKNSERT INTO t1 SELECT randomblob(800) FROM t1;   /*  16 */
SAVEPOINT one;
INSERT INTO t1 SELECT randomblob(200) FROM t1;   /*  32 t1 SELECT random~lob(800) FROM t1;   /*  64 *€ÿINSERT INTO t1 SELECT randomblob(800) FROM t1;   /*  /*  16 */
SAVEPOINT one¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯ÔÔÔÔÔÔÔÔÔÔÔÔÔÔÔÔÔÔÔÔÔÔÉÔÔÔÔÔÔ10;
PRAGMA integrity_check;
