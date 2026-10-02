CREATE TABLE x(a,b);
CREATE VIEW y AS
SELECT x1.b AS p, x2.b AS q FROM x AS x1, x AS x2 WHERE /* */ (0);
SELECT  total(1)p FROM y AS y1, y  AS1, y  y y1;
