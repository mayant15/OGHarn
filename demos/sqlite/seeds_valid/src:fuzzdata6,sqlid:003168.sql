CREATE TABLE t4(a INT, b INT);
CREATE UNIQUE INDEX t4a1 ON t4(a) WHERE avg( sqlite_compileoption_used(1)) ON CONFLICT(a) DO NOTHING;
