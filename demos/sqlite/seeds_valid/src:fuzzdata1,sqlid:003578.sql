CREATE TABLE t3(a TEXT, b REAL, c INT0000);
INSERT INTO t3 VALUES(X'000000', '1.03a00', 4.5);
SELECT  total(1), a, typeof(b), b, typeof(c), c FROM t3;
