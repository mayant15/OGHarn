CREATE TABLE t1(a,b,c);
INSERT INTO t1(a,b,c)
VALUES(1,2,3),(7,8,9),(4,5,6),(10,1,10),(4,8,10),(1,10,100);
ANALYZE;
DELETE FROM sqlite_stat1;
INSERT INTO sqlite_stat1(tbl,idx,stat)VALUES('t1','t1',''),('t1','t1b','');
ANALYZE sqlite_master;
SELECT*,'0'FROM t1 WHERE a BETWEEN 3 AND 8 ORDER BY c;
