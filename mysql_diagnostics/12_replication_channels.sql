-- 12_replication_channels.sql
USE `healthcheck`;

SELECT '--- Replication Channels (5.7+) ---' AS Section;
CALL UltraSafeShow('SELECT CHANNEL_NAME, HOST, PORT, USER FROM performance_schema.replication_connection_configuration', '5.7');
