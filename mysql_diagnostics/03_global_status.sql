-- Global Status Metrics
SELECT '--- Global Status Metrics ---' AS Section;
SHOW GLOBAL STATUS LIKE 'Uptime';
SHOW GLOBAL STATUS LIKE 'Connections';
SHOW GLOBAL STATUS LIKE 'Threads%';
SHOW GLOBAL STATUS LIKE 'Innodb%';
SHOW GLOBAL STATUS LIKE 'Aborted%';
