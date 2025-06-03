-- DEBUG: Test WorldMapArea boundaries for problematic NPCs
-- Проблемные координаты из анализа:

-- NPC 3139: coords (275, -4709) - DB zone 14, должна быть 17?
SELECT
    'NPC_3139' as test_case,
    275 as coord_x,
    -4709 as coord_y,
    areatableID as worldmaparea_zone,
    areaname_lang1 as zone_name,
    x_min, x_max, y_min, y_max
FROM WorldMapArea_wotlk
WHERE mapID = 1
  AND x_min < 275 AND x_max > 275
  AND y_min < -4709 AND y_max > -4709
  AND areatableID > 0
ORDER BY areatableID;

-- NPC 3293: coords (999, -4414) - DB zone 1637, должна быть 17?
SELECT
    'NPC_3293' as test_case,
    999 as coord_x,
    -4414 as coord_y,
    areatableID as worldmaparea_zone,
    areaname_lang1 as zone_name,
    x_min, x_max, y_min, y_max
FROM WorldMapArea_wotlk
WHERE mapID = 1
  AND x_min < 999 AND x_max > 999
  AND y_min < -4414 AND y_max > -4414
  AND areatableID > 0
ORDER BY areatableID;

-- NPC 3337: coords (303, -3686) - DB zone 14, должна быть 215?
SELECT
    'NPC_3337' as test_case,
    303 as coord_x,
    -3686 as coord_y,
    areatableID as worldmaparea_zone,
    areaname_lang1 as zone_name,
    x_min, x_max, y_min, y_max
FROM WorldMapArea_wotlk
WHERE mapID = 1
  AND x_min < 303 AND x_max > 303
  AND y_min < -3686 AND y_max > -3686
  AND areatableID > 0
ORDER BY areatableID;

-- COMPARISON: Что показывает database vs WorldMapArea
SELECT
    'DB_vs_WMA' as comparison,
    c.entry as npc_id,
    c.position_x,
    c.position_y,
    c.zoneId as database_zone,
    wma.areatableID as worldmaparea_zone,
    wma.areaname_lang1 as wma_zone_name
FROM creature c
LEFT JOIN WorldMapArea_wotlk wma ON (
    wma.mapID = c.map
    AND wma.x_min < c.position_x AND wma.x_max > c.position_x
    AND wma.y_min < c.position_y AND wma.y_max > c.position_y
    AND wma.areatableID > 0
)
WHERE c.entry IN (3139, 3293, 3337, 3429)
  AND c.map = 1
ORDER BY c.entry, wma.areatableID;

-- ZONE OVERLAP ANALYSIS: Найти перекрывающиеся зоны
SELECT DISTINCT
    'OVERLAP_CHECK' as analysis,
    w1.areatableID as zone1,
    w1.areaname_lang1 as zone1_name,
    w2.areatableID as zone2,
    w2.areaname_lang1 as zone2_name,
    'coordinates_275_-4709' as test_point
FROM WorldMapArea_wotlk w1
JOIN WorldMapArea_wotlk w2 ON (
    w1.mapID = w2.mapID
    AND w1.areatableID != w2.areatableID
    AND w1.x_min < 275 AND w1.x_max > 275
    AND w1.y_min < -4709 AND w1.y_max > -4709
    AND w2.x_min < 275 AND w2.x_max > 275
    AND w2.y_min < -4709 AND w2.y_max > -4709
)
WHERE w1.mapID = 1 AND w1.areatableID > 0 AND w2.areatableID > 0;
