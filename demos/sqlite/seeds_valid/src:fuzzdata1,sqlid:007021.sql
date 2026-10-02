PRAGMA auto_vacuum = incremental;
PRAGMA page_size=1000;
PRAGMA journal_mode=off;
CREATE TABLE t1(a, b);
INSERT INTO t1 VALUES(zeroblob(9000), zeroblob(5000));
DELETE FROM t1;
PRAGMA incremental_vacuum;
