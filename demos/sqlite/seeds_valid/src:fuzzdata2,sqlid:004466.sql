PRAGMA encoding=UTF8;
CREATE VIRTUAL TABLE f00 USING fts3(a,0,c);
SELECT name FROM sqlite_master WHERE name GLOB '?00[*' ORDER BY 1;
