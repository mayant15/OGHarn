CREATE TABLE t0(a,b,c int,d,e, PRIMARY KEY(a,a,a,c,c,b,c,c,c,c,b,c,d,e,e));
SELECT * FROM t0 WHERE a=? AND b=? AND c=? AND c<? AND a=?;
