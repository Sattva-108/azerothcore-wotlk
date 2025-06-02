# AZEROTHCORE ZONE DETECTION SEARCH PLAN

## 🎯 ЧТО ИСКАТЬ В AZEROTHCORE

### 1. **Zone/Area ID Assignment**
- `Creature::GetZoneId()` - как creature получает свой zoneId
- `Creature::GetAreaId()` - как creature получает свой areaId
- `Map::GetZoneAndAreaId()` - основная функция определения зоны по координатам
- `Map::GetAreaId()` - определение area по x,y,z
- `Map::GetZoneId()` - определение zone по x,y,z

### 2. **Coordinate Systems**
- `Map::GetZoneCoordinates()` - конвертация world → zone coords
- `Map::Zone2MapCoordinates()` - конвертация zone → world coords
- `Map::Map2ZoneCoordinates()` - конвертация map → zone coords
- `ZoneCoordinates` struct/class - структура хранения зональных координат

### 3. **DBC/DB2 Loading**
- `LoadDBCStores()` - загрузка DBC файлов
- `sWorldMapAreaStore` - хранилище WorldMapArea.dbc
- `sAreaTableStore` - хранилище AreaTable.dbc
- `WorldMapAreaEntry` struct - структура записи WorldMapArea
- `AreaTableEntry` struct - структура записи AreaTable

### 4. **Quest System Zone Logic**
- `Quest::GetZoneOrSort()` - как квесты определяют свои зоны
- `Quest::IsAllowedInZone()` - проверка доступности квеста в зоне
- `QuestTemplate` - структура с zone/area данными квеста

### 5. **Spatial Queries**
- `GridDefines.h` - определения grid системы
- `CellImpl.h` - cell/grid координатная система
- `TerrainMgr` - terrain/zone management
- `VMapManager` - возможно содержит zone boundaries

### 6. **Database Schema**
- `creature` table structure - как хранятся zoneId/areaId
- `quest_template` - zone/area поля квестов
- `worldmaparea` table (если есть в БД)
- `areatable` table (если есть в БД)

### 7. **GPS Command Implementation**
- `cs_misc.cpp` - `.gps` команда
- `HandleGPSCommand()` - реализация GPS команды
- Формула конвертации координат в GPS

### 8. **Zone Hierarchy**
- Parent/Child zone relationships
- `AreaTable::GetParentAreaId()`
- Zone inheritance logic
- Subzone → Zone mapping

### 9. **Coordinate Conversion Formulas**
- `TERRAIN_MAP_SIZE` constant
- `MAP_RESOLUTION` constant
- `SIZE_OF_GRIDS` constant
- Grid/Cell calculation formulas

### 10. **pfQuest Integration Points**
- Как pfQuest определяет на какой карте показывать маркер
- Логика выбора карты по zone ID
- Mapping между zone ID и map файлами

## 🔍 КЛЮЧЕВЫЕ ФАЙЛЫ ДЛЯ ПОИСКА

### Core Files:
- `src/server/game/Maps/Map.cpp`
- `src/server/game/Maps/Map.h`
- `src/server/game/Maps/MapManager.cpp`
- `src/server/game/Grids/GridDefines.h`
- `src/server/game/DataStores/DBCStores.cpp`
- `src/server/game/DataStores/DBCStructure.h`

### Command Files:
- `src/server/scripts/Commands/cs_misc.cpp`
- `src/server/scripts/Commands/cs_gm.cpp`

### Entity Files:
- `src/server/game/Entities/Creature/Creature.cpp`
- `src/server/game/Entities/GameObject/GameObject.cpp`
- `src/server/game/Entities/Player/Player.cpp`

### Quest Files:
- `src/server/game/Quests/QuestDef.h`
- `src/server/game/Quests/QuestDef.cpp`

## 📝 SEARCH PATTERNS

```bash
# Zone determination
grep -r "GetZoneId\|GetAreaId" --include="*.cpp" --include="*.h"
grep -r "GetZoneAndAreaId" --include="*.cpp" --include="*.h"
grep -r "Map2Zone\|Zone2Map" --include="*.cpp" --include="*.h"

# DBC structures
grep -r "WorldMapAreaEntry\|AreaTableEntry" --include="*.h"
grep -r "sWorldMapAreaStore\|sAreaTableStore" --include="*.cpp"

# GPS implementation
grep -r "HandleGPSCommand\|\.gps" --include="*.cpp"

# Coordinate systems
grep -r "TERRAIN_MAP_SIZE\|MAP_RESOLUTION" --include="*.h"
grep -r "GridCoord\|CellCoord" --include="*.h"
```

## 🎯 ГЛАВНЫЕ ВОПРОСЫ

1. **Как AzerothCore определяет zone по world координатам?**
2. **Какая связь между zoneId, areaId и mapId?**
3. **Как subzones (areas) связаны с parent zones?**
4. **Почему creature.zoneId и creature.areaId пустые в БД?**
5. **Как pfQuest выбирает на какой карте показывать NPC?**
