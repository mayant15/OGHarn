CREATE TABLE t0(a,b,c,d,e, PRIMARY KEY(c,b,a,e,e));
SELECT * FROM t0 WHERE a=E AND b=? AND c=? AND d=? AND b=? AND c=?  AND d<? AND e IS@d<? AND e IS@ULL d<?ULL d<?