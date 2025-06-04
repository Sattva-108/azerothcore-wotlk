-- SQL PATCH: Fix missing areaId values using coordinate mapping
-- Run in HeidiSQL for AzerothCore database

-- Step 1: Update obvious mappings (starter zones)
UPDATE creature SET areaId = 9 WHERE zoneId = 12 AND areaId = 0;   -- Elwynn Forest → Northshire
UPDATE creature SET areaId = 77 WHERE zoneId = 1 AND areaId = 0;   -- Dun Morogh → Coldridge Valley
UPDATE creature SET areaId = 148 WHERE zoneId = 14 AND areaId = 0; -- Durotar → Valley of Trials
UPDATE creature SET areaId = 219 WHERE zoneId = 40 AND areaId = 0; -- Westfall → Westfall

-- Step 2: City mappings
UPDATE creature SET areaId = 1637 WHERE zoneId = 1637 AND areaId = 0; -- Orgrimmar
UPDATE creature SET areaId = 1519 WHERE zoneId = 1519 AND areaId = 0; -- Stormwind
UPDATE creature SET areaId = 1657 WHERE zoneId = 1657 AND areaId = 0; -- Darnassus

-- Step 3: Coordinate-based mapping for Durotar subareas
UPDATE creature SET areaId = 362 WHERE zoneId = 14 AND areaId = 0 AND position_x BETWEEN 800 AND 1200 AND position_y BETWEEN -4900 AND -4600; -- Valley of Trials
UPDATE creature SET areaId = 372 WHERE zoneId = 14 AND areaId = 0 AND position_x BETWEEN 300 AND 600 AND position_y BETWEEN -4200 AND -3900;   -- Razor Hill

-- Verify results
SELECT areaId, zoneId, COUNT(*) as count FROM creature WHERE zoneId IN (14, 12, 1, 40) GROUP BY areaId, zoneId ORDER BY zoneId, areaId;
