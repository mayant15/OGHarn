CREATE TABLE x(a,b);
CREATE VIEW y AS
SELECT x1.b AS p, x2.b AS q FROM x AS x1, x AS x2 WHERE  (1)=x2.a;
CREATE VIEW z AS
SELECT y1.p, y2.p FROM y AS y1, y AS y2 WHERE likely(1);
SELECT * from z;
