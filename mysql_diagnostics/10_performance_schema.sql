-- Performance Schema Summary (8.0+)
SELECT '--- Performance Schema Summary ---' AS Section;
SELECT VARIABLE_NAME, VARIABLE_VALUE
FROM performance_schema.global_status
WHERE VARIABLE_NAME LIKE 'Innodb%_pages%' LIMIT 20;

-- Memory Summary
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

SELECT '--- Data Dictionary Tables ---' AS Section;
SELECT TABLE_NAME FROM information_schema.tables
WHERE table_schema = 'mysql' AND table_name LIKE 'innodb%';
