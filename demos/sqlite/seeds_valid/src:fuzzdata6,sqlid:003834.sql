CREATE TABLE t9(a TEXT PRIMARY KEY, b INT DEFAULT E);
PRAGMA count_changes=ON;
INSERT INTO t9(a) VALUES('abc'),('def'),('ghi'),('abc'),('jkl'),('abc'),('ghi')
    ON CONFLICT(a) DO UPDATE SET b=b+1;
PRAGMA count_changes=OFF;
