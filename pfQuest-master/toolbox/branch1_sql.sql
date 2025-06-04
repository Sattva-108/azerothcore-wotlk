-- Branch 1: Critical Areas SQL Queries for HeidiSQL
-- Run these commands in HeidiSQL for AzerothCore database

-- 1. Create working table for critical zones (run first)
CREATE TEMPORARY TABLE critical_areas AS
SELECT DISTINCT
    c.area as areaId,
    c.zone as zoneId,
    COUNT(*) as npc_count,
    MIN(c.position_x) as min_x,
    MAX(c.position_x) as max_x,
    MIN(c.position_y) as min_y,
    MAX(c.position_y) as max_y
FROM creature c
WHERE c.area > 0 AND c.zone > 0
GROUP BY c.area, c.zone
HAVING COUNT(*) >= 10
ORDER BY npc_count DESC
LIMIT 63;

-- 2. Verify critical areas (run second to check)
SELECT
    areaId,
    zoneId,
    npc_count,
    ROUND((max_x - min_x), 2) as x_range,
    ROUND((max_y - min_y), 2) as y_range
FROM critical_areas
ORDER BY npc_count DESC
LIMIT 20;

-- 3. Coverage analysis (run third for stats)
SELECT
    COUNT(*) as total_critical_areas,
    COUNT(CASE WHEN npc_count >= 50 THEN 1 END) as high_density_areas,
    ROUND(AVG(npc_count), 2) as avg_npcs_per_area,
    MAX(npc_count) as max_npcs,
    MIN(npc_count) as min_npcs
FROM critical_areas;

-- 4. Zone mapping validation (run fourth)
SELECT DISTINCT
    zoneId,
    COUNT(DISTINCT areaId) as areas_in_zone,
    SUM(npc_count) as total_npcs_in_zone
FROM critical_areas
GROUP BY zoneId
ORDER BY total_npcs_in_zone DESC;
