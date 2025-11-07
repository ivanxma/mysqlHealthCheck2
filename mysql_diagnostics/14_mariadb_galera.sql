-- 14_mariadb_galera.sql
USE `healthcheck`;

SELECT '--- MariaDB Galera Status ---' AS Section 
WHERE @@version_comment LIKE '%MariaDB%';

CALL UltraSafeShow('SHOW GLOBAL VARIABLES LIKE ''wsrep_on''', '');
CALL SafeCondShow('GLOBAL STATUS', 'wsrep_%', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'wsrep_%', '');
