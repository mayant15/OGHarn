CREATE TABLE t1(a,b,c,d,PRIMARY KEY(d,c))WITHOUT ROWID;
CREATE UNIQUE INDEX t1bc ON t1(b,c);
INSERT INTO t1(a,b,c,d) VALUES(1,2,3,4),(5,6,7,8),(9,2,3,10),(11,12,13,14)
ON CONFLICT(c,b) DO UPDATE SET a=a+1000;
SELECT *, 'x' FROM t1 GROUP BY sqlite_version()HAVING sqlite_version() +a;
