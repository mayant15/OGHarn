CREATE TABLE tabc(a,b,c);
INSERT INTO tabc VALUES(1,2,3);
CREATE TABLE txyz(x,y,z);
INSERT INTO txyz VALUES(4,5,6);
CREATE TABLE tb0th(a,b,c,x,y,z);
INSERT INTO tb0th VALUES(1,2,3,4,5,10);
CREATE VIEW v0 AS SELECT tabC.a, txyZ.x, *
FROM tabc, txyz ORDER BY 1 LIMIT 1;
 SELECT tabC.a, txyZ.x, tb0Th.a, tb0tH.c, *
FROM tabc, txyz, tb0th GROUP BY 3 LIMIT 1;
