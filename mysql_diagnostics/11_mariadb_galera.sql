-- MariaDB Galera Cluster
SELECT '--- MariaDB Galera Status ---' AS Section;
SHOW STATUS LIKE 'wsrep_%';
SHOW VARIABLES LIKE 'wsrep_%';
