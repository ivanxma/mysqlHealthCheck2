-- Tables Without Primary Key
SELECT '--- Tables Without Primary Key ---' AS Section;
SELECT 
    table_schema AS `Database`,
    table_name AS `Table`,
    engine AS `Engine`
FROM information_schema.tables t
WHERE table_type = 'BASE TABLE'
  AND table_schema NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
  AND NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_schema = t.table_schema
      AND tc.table_name = t.table_name
      AND tc.constraint_type = 'PRIMARY KEY'
  )
ORDER BY table_schema, table_name;
