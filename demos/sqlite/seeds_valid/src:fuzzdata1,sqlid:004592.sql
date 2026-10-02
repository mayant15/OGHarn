CREATE TABLE x(a,b);
CREATE VIEW y AS
SELECT x2.b AS p, x2.b AS q FROM x AS x1, x AS x2 LIMIT likely(1);
CREATE VIEW z AS
SELECT y1.p, y2. *FROM y AS y1, y AS y2 WHERE y1.q=y2.q;
SELECT * from z;
