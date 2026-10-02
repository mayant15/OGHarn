PRAGMA auto_vacuum=2;
CREATE TABLE t1(a);
CREATE TABLE t0(a);
DROP TABLE t1;
PRAGMA integrity_check;
