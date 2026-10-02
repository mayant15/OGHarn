SELECT typeof(group_concat(x''))
FROM (SELECT $ç AS x UNION ALL SELECT (group_concat(x''))
);
