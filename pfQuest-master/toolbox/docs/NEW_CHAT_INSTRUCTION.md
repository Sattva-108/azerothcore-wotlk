# ИНСТРУКЦИЯ ДЛЯ НОВОГО ЧАТА

## ПРОЕКТ
**AzerothCore WotLK + pfQuest addon quest attachment fix**
Путь: `C:\Users\user\Desktop\azerothcore-wotlk`
Цель: Исправить "прилипание" квестов к неправильным зонам

## КОРЕНЬ ПРОБЛЕМЫ
- pfQuest ожидает zones.lua с areaId-based структурой
- AzerothCore NPCs имеют areaId = 0 (не заполнено)
- pfQuest не может найти квесты по areaId

## ПЛАН BRANCHES (ОБНОВЛЕННЫЙ)
**📁 Файл плана:** `pfQuest-master/toolbox/AREAID_ZONES_RESEARCH_INSTRUCTION.md`

**Branch 0:** ⚠️ **КРИТИЧЕСКИЙ** - заполнить areaId в базе данных
**Branch 1:** ✅ Критические 63 зоны (готов, ждет Branch 0)
**Branch 4:** ✅ Emergency fallback (готов)
**Branch 2:** Full 2,283 зоны (после Branch 0)
**Branch 3:** GPS improvements (опционально)

## ЧТО СДЕЛАНО
✅ SQL fixes для zoneId (все NPCs)
✅ DBC интеграция (WorldMapOverlay hit rectangles)
✅ City mappings (Orgrimmar → zone 0)
✅ zones.lua генератор (2,283 зоны)

## БЛОКИРУЮЩАЯ ПРОБЛЕМА
**ALL creatures have areaId = 0**
- Тест: `SELECT areaId, COUNT(*) FROM creature GROUP BY areaId;`
- Результат: только areaId = 0
- Нужно: coordinate → areaId mapping из DBC данных

## БЫСТРЫЙ СТАРТ
1. **Прочитать план:** `AREAID_ZONES_RESEARCH_INSTRUCTION.md`
2. **Проанализировать DBC:** `DBC/wotlk/enUS/AreaTable.dbc.csv`
3. **Reference данные:** `old-DB/zones.lua` (working mappings)
4. **Создать SQL patch** для areaId population

## ТЕСТ КЕЙС
**Quest 835:** должен работать после areaId fix
- Questgiver NPC 3293 (Orgrimmar)
- Objectives NPCs 3117/3118 (Durotar subareas)

## ФАЙЛЫ
- `extractor.lua` - модифицирован ✅
- `output/zones.lua` - генерируется ✅
- `fix_areaids.sql` - нужен SQL patch

**Chat ID:** 48-feat-explore-azerothcore-project
**Commit:** cbd1f319b

## СЛЕДУЮЩИЙ ШАГ
**Решить Branch 0:** Создать systematic approach для coordinate → areaId mapping без "guessing"
