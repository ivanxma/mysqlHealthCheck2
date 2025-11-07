-- Group Replication & InnoDB Cluster Diagnostics
SELECT '--- Group Replication / InnoDB Cluster Status ---' AS Section;

-- Group Replication Variables
SHOW GLOBAL VARIABLES LIKE 'group_replication%';
SHOW GLOBAL VARIABLES LIKE 'plugin_load%';

-- Group Replication Status
SHOW STATUS LIKE 'group_replication%';

-- Member State (MySQL 8.0+)
SELECT 
    MEMBER_ID, MEMBER_HOST, MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE
FROM performance_schema.replication_group_members;

-- Cluster Health
SELECT 
    VARIABLE_NAME, VARIABLE_VALUE
FROM performance_schema.global_status
WHERE VARIABLE_NAME IN (
    'group_replication_primary_member',
    'group_replication_recovery_channel_status',
    'group_replication_applier_queue_size'
);

-- InnoDB Cluster Metadata (if using Shell)
-- Requires mysqlsh access or metadata schema
-- Safe check
SELECT '--- InnoDB Cluster Metadata (if exists) ---' AS Section;
SHOW TABLES FROM mysql_innodb_cluster_metadata LIKE '%';
