# ФИНАЛЬНОЕ ИССЛЕДОВАНИЕ: ПОЛНЫЙ SCOPE ZONES.LUA - 2,283 AREAID

**Дата:** 5 июня 2025
**Проект:** AzerothCore WotLK + pfQuest addon
**Папка:** `C:\Users\user\Desktop\azerothcore-wotlk`

---

## КРИТИЧЕСКИЕ ОТКРЫТИЯ И SCOPE

### Структурная Проблема
- **pfQuest ожидает:** areaId как primary index в zones.lua
- **Мы генерируем:** zoneId как primary index
- **Реальный scope:** 2,283 areaId в WotLK (не 63)

### Database Analysis Results
```sql
-- Всего areaId в WotLK: 2,283
-- areaId с NPCs: 63
-- Критические зоны с контентом:
areaId 9   → zoneId 12  (Elwynn Forest) - 291 creatures
areaId 77  → zoneId 1   (Dun Morogh)    - 1436 creatures
areaId 148 → zoneId 14  (Durotar)       - 76 creatures
areaId 219 → zoneId 40  (Westfall)      - 1629 creatures
```

### Предыдущие Research Файлы (toolbox)
- `Jules.txt` - display_zone логика, coordinate transformation
- `Cursor.txt` - GPS формулы, hit rect проблемы
- `Claude.txt` - adaptive GPS approach, performance metrics
- `HIT_RECTS_RESEARCH_SUMMARY.md` - technical specs, SQL fixes
- `BRANCHED_HITRECTS_PLAN.md` - fallback стратегии
- `FINAL_EXECUTABLE_HITRECTS_PLAN.md` - consolidated plan (устарел)

### Работающая Структура (old-DB reference)
```lua
[362] = { 14, 9.48, 11.98, 54.64, 42.66 }, -- areaId → zoneId, real hit rects
[363] = { 14, 9.98, 15.72, 44.41, 66.99 },
```

---

## ОГРАНИЧЕНИЯ РЕШЕНИЯ

**❌ НЕ МОЖЕМ:**
- Модифицировать pfQuest addon (сторонний код)
- Изменять AzerothCore исходники

**✅ МОЖЕМ ТОЛЬКО:**
- Модифицировать toolbox/extractor.lua
- SQL запросы через HeidiSQL
- Генерировать данные в toolbox/output/

---

## ТЕХНИЧЕСКОЕ ЗАДАНИЕ

**Цель:** Создать zones.lua с areaId-based структурой для 2,283 зон

**Требования:**
1. **Full coverage:** Все 2,283 areaId из AreaTable_wotlk
2. **Priority system:** Реальные hit rects для 63 зон с контентом
3. **Fallback values:** Dummy/calculated values для остальных 2,220 зон
4. **Performance:** Генерация за разумное время (<30 минут)
5. **Compatibility:** Работа с текущим pfQuest без модификаций

**Доступные DBC данные:**
- `DBC/wotlk/enUS/AreaTable.dbc.csv` - все areaId и parent zones
- `DBC/wotlk/WorldMapOverlay.dbc.csv` - hit rectangle данные
- `DBC/wotlk/WorldMapArea.dbc.csv` - zone boundaries

**Database данные:**
- creature table с areaId/zoneId для 63 зон
- SQL corrections из предыдущих research

---

## ЗАПРОС BRANCHED ПЛАНА

**Создай EXECUTABLE branched план который:**

1. **Решает полный scope** 2,283 areaId generation
2. **Использует findings** из 5 предыдущих research файлов
3. **Обеспечивает fallback** стратегии для guaranteed success
4. **Оптимизирует время** выполнения (2-6 часов максимум)
5. **Включает validation** и rollback процедуры

**Branched структура с приоритетами:**
- Branch 1: Быстрое решение для критических 63 зон
- Branch 2: Full generation всех 2,283 с DBC integration
- Branch 3: Enhanced approach с GPS improvements
- Branch 4: Emergency fallback с guaranteed success

**Каждый branch должен содержать:**
- Точные step-by-step инструкции
- Конкретные изменения кода с номерами строк
- SQL команды для HeidiSQL
- Success criteria и validation tests
- Rollback процедуры

**Expected результат:** pfQuest с правильным quest attachment и coordinate accuracy через исправленную zones.lua структуру.
