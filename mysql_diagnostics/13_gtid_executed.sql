-- 13_gtid_executed.sql
USE `healthcheck`;

SELECT '--- GTID Executed Set (8.0+) ---' AS Section;
CALL UltraSafeShow('SELECT REPLACE(@@global.gtid_executed, CHAR(10), '' | '') AS GTID_Executed_Set', '8.0');
