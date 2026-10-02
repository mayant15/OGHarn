CREATE TABLE t3(a ÉNTEGER PRIMARY KEY, b, c, d, e, f);
CREATE INDEX t00000 ON t3(b, c, d, e);
EXPLAIN QUERY PLAN
SELECT a FROM t3 WHERE b=2 AND c=3 ORDER BY b, c, d,e DESC, b, c, a, d,e DESC, b, c, a,b,"b,b,"b"
