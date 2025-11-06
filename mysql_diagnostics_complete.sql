USE `healthcheck`;
-- MySQL Diagnostic Information Collection Script (Galera Detection Fixed)
-- Uses SHOW GLOBAL VARIABLES for wsrep_on check (compatible with MariaDB & MySQL <8.0)

DELIMITER $$

-- Helper: Safe Conditional SHOW
DROP PROCEDURE IF EXISTS SafeCondShow $$
CREATE PROCEDURE SafeCondShow(IN stmt_type VARCHAR(20), IN pattern VARCHAR(255), IN cond_version VARCHAR(50))
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET done = TRUE;
    
    IF cond_version = '' OR VERSION() LIKE CONCAT(cond_version, '%') THEN
        SET @sql = CONCAT('SHOW ', stmt_type, ' LIKE ''', pattern, '''');
        PREPARE s FROM @sql;
        IF done = FALSE THEN
            EXECUTE s;
        END IF;
        DEALLOCATE PREPARE s;
    END IF;
END $$

-- Helper: Ultra-Safe SHOW with version check
DROP PROCEDURE IF EXISTS UltraSafeShow $$
CREATE PROCEDURE UltraSafeShow(IN cmd TEXT, IN min_version VARCHAR(10))
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET done = TRUE;
    
    SET @major = SUBSTRING_INDEX(VERSION(), '.', 1);
    SET @minor = SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '.', 2), '.', -1);
    
    IF (min_version = '' OR 
        (@major > CAST(SUBSTRING_INDEX(min_version, '.', 1) AS UNSIGNED)) OR
        (@major = CAST(SUBSTRING_INDEX(min_version, '.', 1) AS UNSIGNED) AND 
         @minor >= CAST(SUBSTRING_INDEX(min_version, '.', -1) AS UNSIGNED))) THEN
        
        SET @safe_cmd = cmd;
        PREPARE s FROM @safe_cmd;
        IF done = FALSE THEN
            EXECUTE s;
        ELSE
            SELECT CONCAT('SKIPPED: ', cmd, ' (insufficient privileges or not supported)') AS Warning;
        END IF;
        DEALLOCATE PREPARE s;
    ELSE
        SELECT CONCAT('SKIPPED: ', cmd, ' (requires MySQL ', min_version, '+)') AS Note;
    END IF;
END $$

DELIMITER ;

/* === Host & Execution Information === */
SELECT '--- Host and Execution Information ---' AS Section;
SELECT 
    USER() AS `Current_User`,
    CURRENT_USER() AS `Authenticated_User`,
    CONNECTION_ID() AS `Connection_ID`,
    @@hostname AS `Server_Hostname`,
    @@port AS `Server_Port`,
    DATABASE() AS `Current_Database`,
    VERSION() AS `Server_Version`,
    NOW() AS `Execution_Timestamp_UTC`;

/* === Server Version & Edition === */
SELECT '--- Server Version and Edition ---' AS Section;
SELECT 
    VERSION() AS `Full_Version`,
    @@version_comment AS `Edition_Comment`,
    CASE 
        WHEN @@version_comment LIKE '%Enterprise%' THEN 'MySQL Enterprise Edition'
        WHEN @@version_comment LIKE '%Community%' THEN 'MySQL Community Edition'
        WHEN @@version_comment LIKE '%MariaDB%' THEN 'MariaDB'
        WHEN @@version_comment LIKE '%Percona%' THEN 'Percona Server'
        WHEN @@version_comment LIKE '%Azure%' THEN 'MySQL on Azure'
        ELSE 'Custom or Unknown Fork'
    END AS `Detected_Edition`,
    @@version_compile_os AS `Compile_OS`,
    @@version_compile_machine AS `Compile_Architecture`;

/* === Key Global Variables === */
SELECT '--- Key Global Variables ---' AS Section;
CALL SafeCondShow('GLOBAL VARIABLES', 'version%', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'innodb%', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'max_connections', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'thread%', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'log_error', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'binlog%', '');

/* === Global Status Metrics === */
SELECT '--- Global Status Metrics ---' AS Section;
CALL SafeCondShow('GLOBAL STATUS', 'Uptime', '');
CALL SafeCondShow('GLOBAL STATUS', 'Connections', '');
CALL SafeCondShow('GLOBAL STATUS', 'Threads%', '');
CALL SafeCondShow('GLOBAL STATUS', 'Innodb%', '');
CALL SafeCondShow('GLOBAL STATUS', 'Aborted%', '');

/* === Plugins === */
SELECT '--- Installed Plugins ---' AS Section;
CALL UltraSafeShow('SHOW PLUGINS', '');

/* === Storage Engines === */
SELECT '--- Storage Engines ---' AS Section;
CALL UltraSafeShow('SHOW ENGINES', '');

/* === Database Sizes === */
SELECT '--- Database Sizes ---' AS Section;
SELECT 
    table_schema AS `Database`,
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS `Size_MB`
FROM information_schema.tables 
GROUP BY table_schema
ORDER BY `Size_MB` DESC;

/* === Object Counts === */
SELECT '--- Object Counts per Database ---' AS Section;
SELECT 'Tables and Views' AS `Object_Type`, table_schema AS `Database`, COUNT(*) AS `Count` 
FROM information_schema.tables GROUP BY table_schema;
SELECT 'Routines' AS `Object_Type`, routine_schema AS `Database`, COUNT(*) AS `Count` 
FROM information_schema.routines GROUP BY routine_schema;
SELECT 'Triggers' AS `Object_Type`, trigger_schema AS `Database`, COUNT(*) AS `Count` 
FROM information_schema.triggers GROUP BY trigger_schema;
SELECT 'Events' AS `Object_Type`, event_schema AS `Database`, COUNT(*) AS `Count` 
FROM information_schema.events GROUP BY event_schema;

/* === Tables Without Primary Key === */
SELECT '--- Tables Without Primary Key ---' AS Section;
SELECT 
    table_schema AS `Database`,
    table_name AS `Table`,
    engine AS `Engine`
FROM information_schema.tables t
WHERE table_type = 'BASE TABLE'
  AND table_schema NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
  AND NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_schema = t.table_schema
      AND tc.table_name = t.table_name
      AND tc.constraint_type = 'PRIMARY KEY'
  )
ORDER BY table_schema, table_name;

/* === Replication Configuration === */
SELECT '--- Replication Configuration ---' AS Section;
CALL SafeCondShow('GLOBAL VARIABLES', 'log_bin%', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'binlog_format', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'server_id', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'gtid_mode', '8.');
CALL SafeCondShow('GLOBAL VARIABLES', 'enforce_gtid_consistency', '8.');

/* === Replication Master Status (SHOW BINARY LOG STATUS for pre-5.0) === */
SELECT '--- Replication Master Status ---' AS Section;
SET @major = SUBSTRING_INDEX(VERSION(), '.', 1);
SET @master_cmd = IF(@major >= 5, 'SHOW MASTER STATUS', 'SHOW BINARY LOG STATUS');
CALL UltraSafeShow(@master_cmd, '');

/* === Replication Slave/Replica Status === */
SELECT '--- Replication Slave/Replica Status ---' AS Section;
SET @cmd = IF(@major >= 8, 'SHOW REPLICA STATUS', 'SHOW SLAVE STATUS');
CALL UltraSafeShow(@cmd, '5.0');

/* === Replication Channels (5.7+) === */
SELECT '--- Replication Channels (5.7+) ---' AS Section;
CALL UltraSafeShow('SELECT CHANNEL_NAME, HOST, PORT, USER FROM performance_schema.replication_connection_configuration', '5.7');

/* === GTID Executed Set (8.0+) - Single Line Safe === */
SELECT '--- GTID Executed Set (8.0+) ---' AS Section;
CALL UltraSafeShow('SELECT REPLACE(@@global.gtid_executed, CHAR(10), '' | '') AS GTID_Executed_Set', '8.0');

/* === MariaDB Galera Status (Safe wsrep_on Check via SHOW) === */
SELECT '--- MariaDB Galera Status ---' AS Section 
WHERE @@version_comment LIKE '%MariaDB%';

-- Check if wsrep_on exists using SHOW
CALL UltraSafeShow('SHOW GLOBAL VARIABLES LIKE ''wsrep_on''', '');

-- If wsrep_on exists, show wsrep variables
CALL SafeCondShow('GLOBAL STATUS', 'wsrep_%', '');
CALL SafeCondShow('GLOBAL VARIABLES', 'wsrep_%', '');

/* === Pre-8.0 Diagnostics === */
SELECT '--- Pre-8.0 Specific Diagnostics ---' AS Section WHERE VERSION() LIKE '5.%';
CALL SafeCondShow('GLOBAL VARIABLES', 'query_cache%', '5.');
CALL SafeCondShow('GLOBAL STATUS', 'Qcache%', '5.');
SELECT 'Performance Schema Enabled' AS Note
WHERE VERSION() LIKE '5.%'
  AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'performance_schema');

/* === 8.0+ Diagnostics === */
SELECT '--- 8.0+ Specific Diagnostics ---' AS Section WHERE @major >= 8;
CALL SafeCondShow('GLOBAL VARIABLES', 'default_storage_engine', '8.');
CALL SafeCondShow('GLOBAL VARIABLES', 'mysqlx%', '8.');
CALL SafeCondShow('GLOBAL STATUS', 'Mysqlx%', '8.');

SELECT '--- Performance Schema Summary ---' AS Section WHERE @major >= 8;
SELECT VARIABLE_NAME, VARIABLE_VALUE
FROM performance_schema.global_status
WHERE @major >= 8 AND VARIABLE_NAME LIKE 'Innodb%_pages%' LIMIT 20;

-- Memory Summary (Safe)
SET @mem_col = (
    SELECT IF(
        EXISTS (SELECT 1 FROM information_schema.columns 
                WHERE table_schema = 'performance_schema' 
                  AND table_name = 'memory_summary_global_by_event_name' 
                  AND column_name = 'CURRENT_NUMBER_OF_BYTES_USED'),
        'CURRENT_NUMBER_OF_BYTES_USED',
        IF(
            EXISTS (SELECT 1 FROM information_schema.columns 
                    WHERE table_schema = 'performance_schema' 
                      AND table_name = 'memory_summary_global_by_event_name' 
                      AND column_name = 'CURRENT_ALLOC'),
            'CURRENT_ALLOC',
            NULL
        )
    )
);
SET @mem_sql = IF(@mem_col IS NOT NULL,
    CONCAT('SELECT EVENT_NAME, ', @mem_col, ' AS Memory_Used_Bytes FROM performance_schema.memory_summary_global_by_event_name ORDER BY ', @mem_col, ' DESC LIMIT 10'),
    'SELECT ''Memory summary not available'' AS Note'
);
PREPARE mem_stmt FROM @mem_sql;
EXECUTE mem_stmt;
DEALLOCATE PREPARE mem_stmt;

SELECT '--- Data Dictionary Tables ---' AS Section WHERE @major >= 8;
SELECT TABLE_NAME FROM information_schema.tables
WHERE @major >= 8 AND table_schema = 'mysql' AND table_name LIKE 'innodb%';

/* === 9.x Future-Proofing === */
SELECT '--- 9.x Specific Diagnostics ---' AS Section WHERE @major >= 9;
CALL SafeCondShow('GLOBAL VARIABLES', 'thread_pool%', '9.');

/* === Percona-Specific === */
SELECT '--- Percona-Specific Diagnostics ---' AS Section WHERE @@version_comment LIKE '%Percona%';
CALL SafeCondShow('GLOBAL VARIABLES', 'xtradb%', '');
CALL SafeCondShow('GLOBAL STATUS', 'XtraDB%', '');

/* === Cleanup === */
DROP PROCEDURE SafeCondShow;
DROP PROCEDURE UltraSafeShow;

SELECT '--- End of Diagnostics ---' AS Section;
