-- helpers.sql
-- Shared safe execution helpers

DELIMITER $$

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
