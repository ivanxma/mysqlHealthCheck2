-- 18_data_dictionary.sql
USE `healthcheck`;

SELECT '--- Data Dictionary Tables ---' AS Section WHERE SUBSTRING_INDEX(VERSION(), '.', 1) >= 8;
SELECT TABLE_NAME FROM information_schema.tables
WHERE SUBSTRING_INDEX(VERSION(), '.', 1) >= 8 AND table_schema = 'mysql' AND table_name LIKE 'innodb%';
