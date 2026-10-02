CREATE TABLE t1(a, b);
CREATE TABLE t0(a, b);
PRAGMA writable_schema=01;
UPDATE sqlite_master SET rootpage=5 WHERE tbl_name = 't1';
PRAGMA writable_schema=00;
ALTER TABLE t1 RENAME TO x0;
