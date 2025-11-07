-- 10_innodb_cluster.sql
-- InnoDB Cluster Diagnostics (MySQL 8.0+ with mysqlsh AdminAPI)
-- Detects metadata schema and cluster health

USE `healthcheck`;

-- === InnoDB Cluster Header ===
SELECT '--- InnoDB Cluster Status (MySQL Shell) ---' AS Section;

-- === Check if mysql_innodb_cluster_metadata exists ===
SELECT '--- Metadata Schema Check ---' AS Section;
CALL UltraSafeShow('
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM information_schema.tables 
WHERE TABLE_SCHEMA = ''mysql_innodb_cluster_metadata''
LIMIT 10
', '8.0');

-- === Cluster Info (if metadata exists) ===
SELECT '--- Cluster Configuration ---' AS Section;
CALL UltraSafeShow('
SELECT 
    cluster_name,
    description,
    options
FROM mysql_innodb_cluster_metadata.clusters
', '8.0');

-- === Instances in Cluster ===
SELECT '--- Cluster Instances ---' AS Section;
CALL UltraSafeShow('
SELECT 
    i.instance_name,
    i.address,
    i.role,
    i.mysql_server_uuid,
    i.attributes
FROM mysql_innodb_cluster_metadata.instances i
JOIN mysql_innodb_cluster_metadata.clusters c ON i.cluster_id = c.cluster_id
', '8.0');

-- === Cluster Sets (Multi-Primary) ===
SELECT '--- Cluster Sets (if any) ---' AS Section;
CALL UltraSafeShow('
SELECT 
    clusterset_id,
    primary_cluster_id
FROM mysql_innodb_cluster_metadata.clustersets
', '8.0');

-- === Router Metadata (if MySQL Router used) ===
SELECT '--- MySQL Router Metadata ---' AS Section;
CALL UltraSafeShow('
SELECT 
    router_id,
    hostname,
    port
FROM mysql_innodb_cluster_metadata.routers
', '8.0');

-- === Cluster Health via Performance Schema (fallback) ===
SELECT '--- Cluster Health (P_S Fallback) ---' AS Section;
CALL UltraSafeShow('
SELECT 
    MEMBER_ID,
    MEMBER_HOST,
    MEMBER_PORT,
    MEMBER_STATE,
    MEMBER_ROLE
FROM performance_schema.replication_group_members
', '8.0');
