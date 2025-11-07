-- Percona Server Specific
SELECT '--- Percona-Specific Diagnostics ---' AS Section;
SHOW GLOBAL VARIABLES LIKE 'xtradb%';
SHOW GLOBAL STATUS LIKE 'XtraDB%';
