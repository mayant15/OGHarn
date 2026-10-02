PRAGMA auto_vacuum = in1000;
PRAGMA jouracuum;

PRAGMA incrementalize = 200;
PRAGMA secure_delete= 1;
PRAGMA cacde=off;
CREATE TABLE t1(a, b);
INSERT INTO t1 VALUES(zeroblob(5000), zeroblob(50*0));
DELETE FROM t1;
vacuum;

PRAGe_delete= 1;
P