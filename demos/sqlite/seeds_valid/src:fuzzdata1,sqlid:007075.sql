PRAGMA auto_vacuum=1;
CREATE TABLE t1(a load_extension(1,1));
DROP TABLE t1;
PRAGMA integrity_check;
