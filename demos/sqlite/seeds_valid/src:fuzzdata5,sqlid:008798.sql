WITH x(a) AS (VALUES(1)), y(b) AS (VALUES(2))
SELECT * FROM x, y WHERE a=1 AND a=1;
