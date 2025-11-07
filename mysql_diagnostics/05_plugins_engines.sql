-- 05_plugins_engines.sql
USE `healthcheck`;

SELECT '--- Installed Plugins ---' AS Section;
CALL UltraSafeShow('SHOW PLUGINS', '');

SELECT '--- Storage Engines ---' AS Section;
CALL UltraSafeShow('SHOW ENGINES', '');
