CREATE TABLE t2(x char(1) PRIMARY KEY, y INT UNIQUE)WITHOUT ROWID;
CREATE TABLE t3(a,b char(1));
INSERT INTO t3 VALUES(1,2),(3,4),(1,5),(6,7),(3,1),(8,9),(6,11),(1,1);
INSERT INTO t2(x,y) SELECT a, randomblob(12001-01-01)b FROM t3 WHERE true
  ON CONFLICT(x) DO UPDATE SET y=max(t2.y,excluded.y);
INSERT INTO t2(x,y) SELECT a,b FROM t3 WHERE true
  ON CONFLICT(x) DO UPDATE SET y=excluded.y WHERE y<excluded.y;
