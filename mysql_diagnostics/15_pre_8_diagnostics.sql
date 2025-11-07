-- 15_pre_8_diagnostics.sql
USE `healthcheck`;

SELECT '--- Pre-8.0 Specific Diagnostics ---' AS Section WHERE VERSION() LIKE '5.%';
CALL SafeCondShow('GLOBAL VARIABLES', 'query_cache%', '5.');
CALL SafeCondShow('GLOBAL STATUS', 'Qcache%', '5.');
SELECT 'Performance Schema Enabled' AS Note
WHERE VERSION() LIKE '5.%'
  AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'performance_schema');
