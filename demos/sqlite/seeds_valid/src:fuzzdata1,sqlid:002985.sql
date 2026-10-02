CREATE TABLE t1(x, y DEFAULT(-replace(1,1,1)));
INSERT INTO t1(x)VALUES(1);
SELECT x, length(y)%Y FROM t1;
