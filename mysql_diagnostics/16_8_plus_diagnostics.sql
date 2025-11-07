-- 16_8_plus_diagnostics.sql
USE `healthcheck`;

SELECT '--- 8.0+ Specific Diagnostics ---' AS Section WHERE SUBSTRING_INDEX(VERSION(), '.', 1) >= 8;
CALL SafeCondShow('GLOBAL VARIABLES', 'default_storage_engine', '8.');
CALL SafeCondShow('GLOBAL VARIABLES', 'mysqlx%', '8.');
CALL SafeCondShow('GLOBAL STATUS', 'Mysqlx%', '8.');
