CREATE TABLE t0(a,b,c int,d,e, PRIMARY KEY(a,b,d,e,c,d,b,e,c,d,b,c,d,e,c,d,e,e));
SELECT * FROM t0 WHERE a=? AND b=? AND c AND b=? AND c=+? AND d=? AND e=?;
