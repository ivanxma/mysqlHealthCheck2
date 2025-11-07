-- 07_object_counts.sql
USE `healthcheck`;

SELECT '--- Object Counts per Database ---' AS Section;
SELECT 'Tables and Views' AS `Object_Type`, table_schema AS `Database`, COUNT(*) AS `Count` 
FROM information_schema.tables GROUP BY table_schema;

SELECT 'Routines' AS `Object_Type`, routine_schema AS `Database`, COUNT(*) AS `Count` 
FROM information_schema.routines GROUP BY routine_schema;

SELECT 'Triggers' AS `Object_Type`, trigger_schema AS `Database`, COUNT(*) AS `Count` 
FROM information_schema.triggers GROUP BY trigger_schema;

SELECT 'Events' AS `Object_Type`, event_schema AS `Database`, COUNT(*) AS `Count` 
FROM information_schema.events GROUP BY event_schema;
