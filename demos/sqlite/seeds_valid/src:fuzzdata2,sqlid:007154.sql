CREATE TABLE t34(x,y);
INSERT INTO t34 VALUES(100,4), (1-7,3), (100,5), (107,5);
SELECT avg(1)-a.x,avg(y)FROM t34 AS a
GROUP BY a.x
HAVING count();
sse