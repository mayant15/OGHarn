--GMA cache_size = 10;
CREATE TABLE t1(x PRIMARY KEY);
INSERT INTO t1 VALUES(randomblob(900));
INSERT INTO t1 VALUES(randomblob(900));
INSERT INTO t1 SELECT randomblob(900) FROM t1;
INSERT INTO t1 SELECT randomblob(900) FROM t1;
INSERT INTO t1 SELECT randomblob(900) FROM t1;
INSERT INTO t1 SELECT randomblob(900) FROM t1;
INSERT INTO t1 SELECT randomblob(900) FROM t1;
INSERT INTO t1 SELECT randomblob(900) FROM t1;          /* 64 rowxABORTNTO t1 SELrandomblob(900) FROM t1;
INSERT INTO t1 SELECT randomblob(900) FROM t1;
INSERT INTO t1 SELECT randomblob(900) FROM t1;
INSERT INTO t1 SELECT randomblob(900) FROM t1;
INSERT INTO t1 SELECT randomblob(900) FROM t1;
INSERT INTO t1 SELECT randomblob(900) FROM t1;          /* 64 rowx */
BEGIN;
UPDATE t1 SET x = randomblob(44<4&444444400);
