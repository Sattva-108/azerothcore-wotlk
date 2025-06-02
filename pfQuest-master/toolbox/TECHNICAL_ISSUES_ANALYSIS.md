# TECHNICAL ISSUES ANALYSIS - АНАЛИЗ ТЕХНИЧЕСКИХ ПРОБЛЕМ

## 🎯 ОСНОВНАЯ ПРОБЛЕМА: QUEST VISIBILITY ZONES

### **СИМПТОМЫ:**
- Квесты отображаются в правильных координатах
- НО на неправильных картах зон
- Пример: квесты Mulgore видны на карте Barrens, но не наоборот

### **ROOT CAUSE ANALYSIS:**

#### **1. ZONE DETECTION LOGIC:**
```lua
-- Текущая логика в extractor.lua:
if db_area_id > 0 then
    final_zone = db_area_id  -- Razor Hill (362)
    if no_boundaries_for_area then
        final_zone = parent_zone  -- Durotar (14)
        use_parent_boundaries = true
        display_zone = parent_zone  -- ПОКАЗЫВАЕТ DUROTAR
    end
end
```

#### **2. ПРОБЛЕМА В DISPLAY_ZONE:**
- **Координаты рассчитываются:** относительно parent zone (Durotar)
- **Но показываются как:** parent zone (Durotar)
- **pfQuest ищет карту:** для Durotar, находит
- **НО другие NPC** попадают в неправильные зоны через spatial lookup

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

## 🎯 NEXT STEPS RECOMMENDATION

1. **Implement zone overrides** для известных проблемных quest NPCs
2. **Expand zone boundaries** на 15-20% для лучшего spatial coverage
3. **Add proximity fallback** для NPC вне всех зон
4. **Validate против live server** GPS данных для sample quest locations
