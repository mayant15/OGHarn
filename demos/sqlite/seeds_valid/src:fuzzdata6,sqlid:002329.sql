CREATE TABLE t1(a,b,c,d,PRIMARY KEY(b,d));
WITH data(a,b,c,d) AS (VALUES(1,2,3,4),(5,6,7,8),(9,10,11,12))
INSERT INTO t1(a,b,c,d) SELECT * FROM data (1)CONFLICT) UP
