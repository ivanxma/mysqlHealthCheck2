-- 20_percona_specific.sql
USE `healthcheck`;

SELECT '--- Percona-Specific Diagnostics ---' AS Section WHERE @@version_comment LIKE '%Percona%';
CALL SafeCondShow('GLOBAL VARIABLES', 'xtradb%', '');
CALL SafeCondShow('GLOBAL STATUS', 'XtraDB%', '');
