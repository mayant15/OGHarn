PRAGMA short_column_names=OFF;
PRAGMA full_column_names (1);
CREATE VIEW v0 AS SELECT t000.a, t000.x, *
FROM t000, t000 ORDER BY 1 LIMIT 1 
