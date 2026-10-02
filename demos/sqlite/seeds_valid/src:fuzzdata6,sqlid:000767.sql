  CREATE TABLE t1(a INTEGER PRIMARY KEY, b int, c DEFAULT 0);
  INSERT INTO t1(a,b) WITH c(x) AS (values(1))  VALUES(1,2),(3,4);
  WITH nx(a,b) AS ( WITH c(x) AS (values(1)) VALUES(1,8),(2,11),(3,1),(2,15),(1,4),(1,99))
  INSERT INTO main.t1 AS t2(a,b) SELECT a, b FROM nx WHERE true
    ON CONFLICT(a) DO UPDATE SET b=excluded.b, c=t2.c+1 WHERE t2.b<excluded.b;
  SELECT *, 'x' FROM t1 ORDER BY a;
