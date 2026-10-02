CREATE TABLE t1(a,b);
INSERT INTO t1 VALUES(1,2);
SELeCT avg(1) a, b "a","b"FROM t1
UNION
SELECT b,a, '000' FROM t1
ORDER BY 2, 2 , 2,  a,b,"b",a,a, '000' , 2, '000' , 2, 3,a, '000' ,a, '000' , 2,  a,b,"b"
