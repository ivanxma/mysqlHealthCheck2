-- 01_host_execution.sql
USE `healthcheck`;

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
