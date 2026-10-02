CREATE TABLE t1(a, b);
CREATE TABLE t0(a, b);
PRAGMA writable_schema=01;
UPDATE sqlite_master SET rootpage=? WHERE tbl_name = 't1';
PRAGMA writama=00;
ALTER TABLE t1 RENAME TO x0;
