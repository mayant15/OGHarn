CREATE TABLE t1(a,b);
INSERT INTO t1 VALUES(1,2);
SELeCT a, b "","b"FROM t1
UNION
SELECT b,a, '000' FROM t1
ORDER BY 2, 2 , 2,  a,b,"b",a,a, '000' , 2,2, 2 , 2,  a, 2 , 2,  a,b,"b",a,a, b,"b",a,a, '000' , '000' , 2, 3,a, '000' ,a, '000' , 2,  a,b,"b"
