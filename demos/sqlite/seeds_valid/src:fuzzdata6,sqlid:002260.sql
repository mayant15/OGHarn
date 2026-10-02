CREATE TABLE t1(a,b,c DEFAULT 0,PRIMARY KEY(a,b));
INSERT INTO t1 AS nx(a,b) VALUES(1,2),(3,4),(7,8)
  ON CONFLICT(a,b) DO
    UPDATE SET c=(SELECT c FROM t2 HAVING(a,b)=(eded.a,exed.b));
