-- 09_replication_group_replication.sql
-- Group Replication Diagnostics (MySQL 5.7+ / 8.0+)
-- Works on MySQL Community/Enterprise, Percona, MariaDB (if using GR)

USE `healthcheck`;

-- === Group Replication Status Header ===
SELECT '--- Group Replication Status ---' AS Section;

-- === Group Replication Variables ===
SELECT '--- Group Replication Variables ---' AS Section;
CALL UltraSafeShow('SHOW GLOBAL VARIABLES LIKE ''group_replication%''', '5.7');
CALL UltraSafeShow('SHOW GLOBAL VARIABLES LIKE ''plugin_load%''', '');

-- === Group Replication Status ===
SELECT '--- Group Replication Runtime Status ---' AS Section;
CALL UltraSafeShow('SHOW STATUS LIKE ''group_replication%''', '5.7');

-- === Member List (performance_schema) ===
SELECT '--- Group Members (performance_schema) ---' AS Section;
CALL UltraSafeShow('
SELECT 
    MEMBER_ID,
    MEMBER_HOST,
    MEMBER_PORT,
    MEMBER_STATE,
    MEMBER_ROLE,
    MEMBER_VERSION
FROM performance_schema.replication_group_members
', '5.7');

-- === Group View ID & Primary Member ===
SELECT '--- Group View & Primary Member ---' AS Section;
CALL UltraSafeShow('
SELECT 
    VARIABLE_VALUE AS Current_View_ID
FROM performance_schema.global_status 
WHERE VARIABLE_NAME = ''group_replication_view_id''
', '5.7');

CALL UltraSafeShow('
SELECT 
    VARIABLE_VALUE AS Primary_Member_UUID
FROM performance_schema.global_status 
WHERE VARIABLE_NAME = ''group_replication_primary_member''
', '5.7');

-- === Recovery & Queue Sizes ===
SELECT '--- Recovery & Queue Health ---' AS Section;
CALL UltraSafeShow('
SELECT 
    VARIABLE_NAME,
    VARIABLE_VALUE
FROM performance_schema.global_status 
WHERE VARIABLE_NAME IN (
        ''group_replication_applier_queue_size'',
        ''group_replication_recovery_channel_status'',
        ''group_replication_transactions_waiting''
    )
', '5.7');

-- === Certification Info ===
SELECT '--- Certification Info ---' AS Section;
CALL UltraSafeShow('
SELECT 
    VARIABLE_NAME,
    VARIABLE_VALUE
FROM performance_schema.global_status 
WHERE VARIABLE_NAME LIKE ''group_replication_certification%''
', '5.7');
