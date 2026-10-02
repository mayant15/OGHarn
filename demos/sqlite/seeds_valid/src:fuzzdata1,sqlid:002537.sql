CREATE TABLE t1(a,b);
CREATE INDEX t1a ON t1(a);
INSERT INTO t1 VALUES(1,0),(2,0),(3,0),(2,0),(NULL,0),(NULL,0);
PRAGMA writable_schema=ON;
UPDATE sqlite_master SET sql='CRa)'
WHERE name='t1a';
UPDATE sqlite_master SET sql='t"';
PRAGMA writable_schema=OFF;
ALTER TABLE t1 RENAME TO t1A;
Pk