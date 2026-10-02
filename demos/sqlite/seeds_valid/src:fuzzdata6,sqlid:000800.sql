  CREATE TABLE t1(a INTEGER PRIMARY KEY, b int, c char2001-01-01N CONFLICT(a) DO UPDATE SET b=excluded.b, c=t1.c+1 WHERE t1.b<exed.b;
