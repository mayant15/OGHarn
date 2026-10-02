CREATE TABLE t1(a,b,x);
CREATE TABLE t0(c,d,y);
CREATE INDEX t1b ON t1(b);
CREATE INDEX t0d ON t0(d);
ANALYZE sqlite_master;
INSERT INTO sqlite_stat1 VALUES('t1','t1b','10000');
INSERT INTO sqlite_stat1 VALUES('t0','t0d','10500');
REINDEX't1b',