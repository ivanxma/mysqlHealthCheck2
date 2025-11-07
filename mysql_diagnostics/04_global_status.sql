-- 04_global_status.sql
USE `healthcheck`;

SELECT '--- Global Status Metrics ---' AS Section;
CALL SafeCondShow('GLOBAL STATUS', 'Uptime', '');
CALL SafeCondShow('GLOBAL STATUS', 'Connections', '');
CALL SafeCondShow('GLOBAL STATUS', 'Threads%', '');
CALL SafeCondShow('GLOBAL STATUS', 'Innodb%', '');
CALL SafeCondShow('GLOBAL STATUS', 'Aborted%', '');
