CREATE TABLE test(c0l0 TEXT PRIMARY KEY);
INSERT INTO test(c0l0)values('a');
INSERT INTO test(c0l0)values('b');
INSERT INTO test(c0l0)values('c');
CREATE TABLE test2(c0l0 TEXT PRIMARY KEY);
INSERT INTO test2(c0l0)values('a');
INSERT INTO test2(c0l0)values('b');
INSERT INTO test2(c0l0) values('c');
SELECT*FROM test t0 LEFT OUTER JOIN test2 t2
WHERE +t2.c0l0 IS  1=1;
