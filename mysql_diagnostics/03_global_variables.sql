-- 03_global_variables.sql
USE `healthcheck`;

SELECT '--- Key Global Variables ---' AS Section;
CALL SafeCondShow('GLOBAL VARIABLES', 'version%', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'innodb%', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'max_connections', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'thread%', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'log_error', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'binlog%', '');
