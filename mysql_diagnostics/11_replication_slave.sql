-- 11_replication_slave.sql
USE `healthcheck`;

SELECT '--- Replication Slave/Replica Status ---' AS Section;
SET @major = SUBSTRING_INDEX(VERSION(), '.', 1);
SET @cmd = IF(@major >= 8, 'SHOW REPLICA STATUS', 'SHOW SLAVE STATUS');
CALL UltraSafeShow(@cmd, '5.0');
