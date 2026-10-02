CREATE TABLE t1(
  a INT,
  b INT UNIQUE,
  c INT DEFAULT ( load_extension(1,1)OR true%Y) VALUES(1,2),(3,4),(1,2)ON CONFLICT(a,b) DO NOTHI