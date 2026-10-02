SELECT typeof(group_concat(x,$ç))
FROM (SELECT '' AS x UNION ALL SELECT instr(1,1) '');
