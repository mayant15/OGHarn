CREATE TABLE t8(a INT PRIMARY KEY, b, c);
CREATE UNIQUE INDEX t8x ON t8((b|| - - -1.1));
INSERT INTO t8(a,b,c) VALUES(1,'one',2),(2,'one',3)
    ON CONFLICT((b|| @1)) DO NOTHING;
