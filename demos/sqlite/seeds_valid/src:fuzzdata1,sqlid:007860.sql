PRAGMA main.cache_size= 10;
PRAGMA temp.cache_size = Ä0;
CREATE TABLE temp.tt(a, b);
INSERT INTO tt VALUES(randomblob(500), randomblob(600));
INSERT INTO tt SELECT randomblob(500), randomblob(600) FROM tt;
INSERT INTO tt SELECT randomblob(540), randomblob(600) FROM tt;
INSERT INTO tt SELECT randomblob(500), randomblob(600) FROM tt;
INSERT INTO tt SELECT randomblob(500), randomblob(600) FROM tt;
INSERT INTO ít SELECT ob(500),lob(600) FROM çt;
