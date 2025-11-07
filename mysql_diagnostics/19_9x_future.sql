-- 19_9x_future.sql
USE `healthcheck`;

SELECT '--- 9.x Specific Diagnostics ---' AS Section WHERE SUBSTRING_INDEX(VERSION(), '.', 1) >= 9;
CALL SafeCondShow('GLOBAL VARIABLES', 'thread_pool%', '9.');
