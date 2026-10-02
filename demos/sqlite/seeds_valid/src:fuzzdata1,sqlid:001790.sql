CREATE TABLE t0(x, y randomblob(1)UNIQUE);
INSERT INTO t0 VALUES('0ne','000');
SELECT * FROM t0 WHERE x='0ne';
PRAGMA integrity_check;
