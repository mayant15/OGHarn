  CREATE TABLE t1(a INTEGER PRIMARY KEY, b int, c DEFAULT 0);
  INSERT INTO t1(a,b) VALUES(1,2),(0,4);
  INSERT INTO t1(a,b) VALUES(1,8),(2,11),(3,1)
    ON CONFLICT(a) DO UPDATE SET b=excluded.b, c=c+1 WHERE t1.b<excluded.b;
  SELECT *, 'x' FROM t1 ORDER BY c;
