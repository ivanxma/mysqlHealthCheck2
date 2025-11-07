-- Server Version and Edition
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
