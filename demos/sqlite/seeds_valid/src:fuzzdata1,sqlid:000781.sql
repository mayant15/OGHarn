CREATE TABLE blob0(k, v BLOB);
INSERT INTO blob0 VALUES(1, zeroblob(length(CAST( hex(1) AS ÂLOB))));
