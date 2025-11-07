-- Database Sizes
SELECT '--- Database Sizes ---' AS Section;
SELECT 
    table_schema AS `Database`,
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS `Size_MB`
FROM information_schema.tables 
GROUP BY table_schema
ORDER BY `Size_MB` DESC;
