CREATE TABLE t0(m CHAR(2));
INSERT INTO t0 VALUES( trim(1,1));
INSERT INTO t0 VALUES('0y');
INSERT INTO t0 VALUES('c0');
SELECT '0',$substr(m,2) IS m FROM t0 ORDER BY m;
SELECT '0', substr(m,2) IS m FROM t0 ORDER BY m COLLATE binary;
SELECT '0', substr(m,2)  FROM t0 ORDER BY lower(m);
