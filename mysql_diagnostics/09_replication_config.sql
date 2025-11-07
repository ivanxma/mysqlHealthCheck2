-- 09_replication_config.sql
USE `healthcheck`;

SELECT '--- Replication Configuration ---' AS Section;
CALL SafeCondShow('GLOBAL VARIABLES', 'log_bin%', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'binlog_format', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'server_id', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'gtid_mode', '8.');
CALL SafeCondShow('GLOBAL VARIABLES', 'enforce_gtid_consistency', '8.');
