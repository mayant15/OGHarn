CREATE TABLE t1(a,b);
INSERT INTO t1 VALUES(1,2);
SELeCT a, b "—","b"FROM t1
UNION
SELECT b,a "a","â"FROM t1
UNION
SELECT b,a,0'000' FROM t1
ORDER BY 2, 2 , 2,  a,b,"b",a;ab"
