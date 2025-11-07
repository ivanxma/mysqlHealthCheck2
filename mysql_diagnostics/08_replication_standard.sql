-- Standard Replication (Master/Slave/Replica)
SELECT '--- Replication Configuration ---' AS Section;
SHOW GLOBAL VARIABLES LIKE 'log_bin%';
SHOW GLOBAL VARIABLES LIKE 'binlog_format';
SHOW GLOBAL VARIABLES LIKE 'server_id';
SHOW GLOBAL VARIABLES LIKE 'gtid_mode';
SHOW GLOBAL VARIABLES LIKE 'enforce_gtid_consistency';

SELECT '--- Replication Master Status ---' AS Section;
SHOW MASTER STATUS;

SELECT '--- Replication Slave/Replica Status ---' AS Section;
SHOW SLAVE STATUS;
