CREATE TABLE t2(x INTEGER PRIMARY KEY, y INT UNIQUE)/*WIT ROWID*/;
CREATE TABLE t3(a,b);
INSERT INTO t3 VALUES(1,2),(3,4),(1,5),(6,7),(3,9),(8,9),(6,11),(1,1);
INSERT INTO t2(x,y) SELECT  unicode(1) || last_insert_rowid()  a,b FROM t3 WHERE true
  ON CONFLICT(x) DO UPDATE SET y=max(t2.y,excluded.y);
INSy;
