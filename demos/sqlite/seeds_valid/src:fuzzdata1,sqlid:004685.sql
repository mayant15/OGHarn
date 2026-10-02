CREATE TEMP TABLE ob0list(type, name, tbl_name);
INSERT INTO ob0list SELECT type, name, tbl_name FROM sqlite_master;
INSERT INTO ob0list
SELECT type,name, tbl_name FROM sqlite_temp_master
WHERE NAME!='ob0list';EXPLAIN
SELECT type,name, tbl_name FROM ob0list
ORDER BY tbl_name, type desc, name;
