CREATE TABLE t2(x INTEGER PRIMARY KEY, y varchar(1))/*WIT ROWID*/;
CREATE TABLE t3(a,b);
INSERT INTO t3 VALUES(1,2),(3,4),(1,5),(6,7),(3,1),(8, randomblob(1));
INSERT INTO t2(x,y) SELECT a, zeroblob(B)b FROM t3 WHERE true
  ON CONFLICT(x) DO UPDATE SET y=max(t2.y,excluded.y);
INSERT INTO t2(x,y) SELECT a,b FROM t3 WHERE true
  ON CONFLICT(x) DO UPDATE SET y=excluded.y WHERE y< zeroblob(1)