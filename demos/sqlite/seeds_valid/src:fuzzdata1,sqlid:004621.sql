CREATE TABLE x(i0 integer primary key, a TEXT NULL);
INSERT INTO x (a) VALUES ('00');
CREATE TABLE tempx(i0 integer primary key, a TEXT NULL);
INSERT INTO tempx (a) VALUES ('0');
CREATE VIEW t01 AS SELECT x. *, tx.i0 FROM x JOIN tempx tx ON tx.i0=x.i0;
CREATE VIEW t010 AS SELECT x.i0, tx.i0 FROM x JOIN tempx tx on tx.i0=x.i0;
CREATE VIEW t02 AS SELECT * FROM t01 UNION SELECT * FROM t010;
SELECT * FROM t02;
