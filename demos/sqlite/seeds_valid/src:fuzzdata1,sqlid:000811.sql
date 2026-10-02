CREATE TABLE k0(x, y, FOREIGN KEY(x, y) REFERENCES s1(a, b));
PRAGMA foreign_key_check(k0);
