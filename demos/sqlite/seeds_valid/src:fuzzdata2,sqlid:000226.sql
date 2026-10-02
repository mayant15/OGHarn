CREATE TABLE t0(a);
INSERT INTO t0 VALUES('0');
PRAGMA full_column_names=on;
SELECT rowid, * FROM t0;
