# TECHNICAL ISSUES ANALYSIS - АНАЛИЗ ТЕХНИЧЕСКИХ ПРОБЛЕМ (UPDATED)

## 🎯 ОСНОВНАЯ ПРОБЛЕМА: QUEST VISIBILITY ZONES (UPDATED POST-HYBRID)

### **СИМПТОМЫ (AFTER HYBRID SYSTEM):**
- Квесты все еще отображаются в неправильных зонах (quest "pricking" continues)
- NPCs правильно получают зоны из database, но квесты прилепляются к ближайшим зонам
- Координаты в основном правильные, но остаются edge cases (100,0 / 0,100)

### **NEW ROOT CAUSE DISCOVERED: IDENTICAL HIT RECTS**

#### **CRITICAL ISSUE: pfDB["zones"]["data"] Structure**
```lua
[14] = { 14, 100, 100, 50, 50 },  -- Durotar: width=100, height=100, centerX=50, centerY=50
[17] = { 17, 100, 100, 50, 50 },  -- Barrens: IDENTICAL dimensions
[1637] = { 1637, 100, 100, 50, 50 }, -- Orgrimmar: IDENTICAL dimensions
```

**ALL ZONES APPEAR IDENTICAL TO PFQUEST ADDON!**

#### **ROOT CAUSE CHAIN:**
1. **Zones extraction generates dummy hit rects** instead of real zone dimensions
2. **pfQuest cannot differentiate zone sizes** - all zones appear as 100x100 squares
3. **Quest attachment logic confused** - without proper zone boundaries, quests attach to nearest zones
4. **Coordinate mapping unreliable** - hit rects don't match actual zone shapes

### **PREVIOUS ROOT CAUSE ANALYSIS (PARTIALLY ADDRESSED):**

#### **1. ZONE DETECTION LOGIC (IMPROVED BY HYBRID):**
```lua
-- Current hybrid logic:
if zone_id and zone_id > 0 then
    final_zone = zone_id  -- Database priority
elseif area_id and area_id > 0 then
    final_zone = area_id  -- Area fallback
elseif worldmap_zone then
    final_zone = worldmap_zone -- Spatial detection
else
    final_zone = 14 -- Safe fallback
end
```

#### **2. COORDINATE CONVERSION (MOSTLY WORKING):**
- GPS formula works correctly for most zones
- WorldMapArea boundaries properly utilized
- Edge coordinates (100,0) still occur but reduced

## 🔍 ДЕТАЛЬНЫЙ АНАЛИЗ ПРОБЛЕМ

### **1. CREATURE TABLE DATA GAPS:**
```sql
-- Много NPC имеют:
db_zone: 0, db_area: 0
-- Вместо правильных значений типа:
db_zone: 14, db_area: 362
```

**ПРИЧИНЫ:**
- Incomplete data в acore_world.creature
- Или NPC spawns не были правильно zone-tagged

### **2. SPATIAL LOOKUP FAILURES:**
```lua
-- Spatial query:
SELECT areatableID FROM WorldMapArea_wotlk
WHERE mapID = 1
  AND x_min < npc_x AND x_max > npc_x
  AND y_min < npc_y AND y_max > npc_y
```

**ПРОБЛЕМЫ:**
- **NPC coordinates:** -300, -5000 (около Durotar)
- **Spatial result:** zone 357 (Feralas) ❌
- **Правильно должно быть:** zone 14 (Durotar) ✅

### **3. DBC BOUNDARIES ACCURACY:**
- Границы зон в WorldMapArea.dbc могут быть неточными
- Или не покрывать все NPC spawns в реальной игре
- Overlapping zones создают ambiguity

## 🛠️ ВОЗМОЖНЫЕ РЕШЕНИЯ

### **1. УЛУЧШЕНИЕ ZONE DETECTION:**

**A. Proximity-based fallback:**
```lua
-- Если spatial lookup fails, найти ближайшую зону
local nearest_zone = find_nearest_zone_by_distance(npc_x, npc_y)
```

**B. Coordinate range expansion:**
```lua
-- Расширить границы зон на 10-20% для лучшего покрытия
expanded_bounds = {
    x_min = x_min - (x_max - x_min) * 0.1,
    x_max = x_max + (x_max - x_min) * 0.1,
    -- аналогично для y
}
```

### **2. ИСПРАВЛЕНИЕ CREATURE DATA:**

**A. Batch update missing zone data:**
```sql
UPDATE creature SET
zoneId = (SELECT appropriate_zone_from_coordinates),
areaId = (SELECT appropriate_area_from_coordinates)
WHERE zoneId = 0 OR areaId = 0;
```

**B. Manual zone overrides:**
```lua
-- В extractor.lua добавить manual overrides для известных проблемных NPC
local zone_overrides = {
    [3128] = {zone = 14, area = 362},  -- Force Durotar for quest 784 NPCs
    [3129] = {zone = 14, area = 362},
    [3192] = {zone = 14, area = 362},
}
```

### **3. ZONE BOUNDARY CORRECTIONS:**

**A. Manual boundary adjustments:**
```sql
-- Расширить границы Durotar для покрытия всех quest NPC
UPDATE WorldMapArea_wotlk
SET x_min = x_min - 500, y_min = y_min - 500
WHERE areatableID = 14;
```

**B. Alternative zone data sources:**
- Использовать WorldMapOverlay для более точных sub-zone boundaries
- Извлечь границы из live server data

## 📊 IMPACT ANALYSIS

### **ТЕКУЩЕЕ СОСТОЯНИЕ:**
- **Working quests:** 8006/9464 (85%)
- **Visible on correct maps:** ~50-60% (оценка)

### **AFTER FIXES:**
- **Ожидаемое улучшение:** до 90-95%
- **Приоритет:** zone detection > coordinate accuracy (уже решено)

## 🎯 NEXT STEPS RECOMMENDATION (UPDATED POST-HYBRID)

### **PRIORITY 1: FIX HIT RECTS EXTRACTION**
1. **Research zones extraction logic** in extractor.lua - find where `{ zoneId, 100, 100, 50, 50 }` is generated
2. **Calculate real zone dimensions** from WorldMapArea boundaries:
   ```sql
   -- Calculate zone width/height from boundaries
   SELECT areatableID,
          (x_max - x_min) as zone_width,
          (y_max - y_min) as zone_height,
          (x_min + x_max)/2 as center_x,
          (y_min + y_max)/2 as center_y
   FROM WorldMapArea_wotlk;
   ```
3. **Update zones generation** to use real dimensions instead of dummy values

### **PRIORITY 2: RESEARCH PFQUEST HIT RECTS USAGE**
1. **Analyze pfQuest addon code** - understand how it interprets `pfDB["zones"]["data"]`
2. **Determine hit rects purpose**:
   - Zone size calculations?
   - Coordinate transformations?
   - Quest attachment logic?
3. **Document current behavior** - why pfQuest works with identical hit rects

### **PRIORITY 3: COORDINATE FORMULA ALIGNMENT**
1. **Test coordinate accuracy** with real hit rects vs dummy values
2. **Adapt GPS formula** if needed to work with calculated zone dimensions
3. **Validate edge coordinates** (100,0 / 0,100) resolution

### **ALTERNATIVE APPROACH: AZEROTHCORE NATIVE ZONE DETECTION**
If hit rects approach fails, research AzerothCore source:
1. **Map::GetZoneAndAreaId()** - how core determines zones from coordinates
2. **Creature zone assignment logic** - how NPCs get their zoneId values
3. **Implement native zone detection** in extractor to match core behavior exactly

### **LONG-TERM RESEARCH**
1. **pfQuest quest attachment algorithm** - understand why quests "prick" to wrong zones
2. **Zone priority systems** - how pfQuest determines quest visibility per zone
3. **Coordinate transformation chain** - full pipeline from world coords to display
