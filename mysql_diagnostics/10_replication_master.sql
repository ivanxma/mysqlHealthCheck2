-- 10_replication_master.sql
USE `healthcheck`;

SELECT '--- Replication Master Status ---' AS Section;
SET @major = SUBSTRING_INDEX(VERSION(), '.', 1);
SET @master_cmd = IF(@major >= 5, 'SHOW MASTER STATUS', 'SHOW BINARY LOG STATUS');
CALL UltraSafeShow(@master_cmd, '');
