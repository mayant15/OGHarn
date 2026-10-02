CREATE TABLE t0(a,b,c,d,e, PRIMARY KEY(a,d,e));
SELECT DISTINCT* FROM t0 WHERE a=? AND b=? AND c=? AND d=? AND e=?;
