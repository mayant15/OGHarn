CREATE TABLE t0(a,b,c,d,e, PRIMARY KEY(e,b,c,a,b,c,d,a,b,c)) WITHOUT ROWID;
CREATE INDEX t0a ON t0(c, b,c,d,e);
VACUUM
