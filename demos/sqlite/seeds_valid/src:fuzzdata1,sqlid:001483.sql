CREATE TABLE t0(a,b,c,d,e, PRIMARY KEY(a,b,c,d,e));
SELECT * FROM t0 WHERE a=? AND b=?AND d<? AND e OR?AND d<? AND a=?  AND d,?  e >