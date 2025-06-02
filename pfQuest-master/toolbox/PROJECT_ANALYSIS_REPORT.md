# PROJECT ANALYSIS REPORT - АНАЛИЗ ПРОДЕЛАННОЙ РАБОТЫ

## 🎯 ЗАДАЧА: ИСПРАВЛЕНИЕ КООРДИНАТ NPC В PFQUEST

### **ПРОБЛЕМА:**
NPC 3139 (Gar'Thok) показывался с координатами 100,0 вместо правильных ~52%,43%

### **ROOT CAUSE ANALYSIS:**

#### **1. ПРОБЛЕМА БЫЛА В COORDINATE MAPPING:**
- **CSV DBC:** LocLeft, LocRight, LocTop, LocBottom
- **AzerothCore struct:** y1, y2, x1, x2
- **НАША ОШИБКА:** неправильное соответствие полей

#### **2. КЛЮЧЕВЫЕ ОТКРЫТИЯ:**

**A. DBC Structure (от Cursor analysis):**
```cpp
struct WorldMapAreaEntry {
    uint32  map_id;     // 1
    uint32  area_id;    // 2
    float   y1;         // 4 ← LocLeft
    float   y2;         // 5 ← LocRight
    float   x1;         // 6 ← LocTop
    float   x2;         // 7 ← LocBottom
};
```

**B. GPS Formula (от Cursor analysis):**
```lua
-- GPS использует ПЕРЕКРЕСТНЫЕ координаты:
zone_x = (npc_y - LocLeft) / ((LocRight - LocLeft) / 100)   -- Y→ZoneX
zone_y = (npc_x - LocTop) / ((LocBottom - LocTop) / 100)    -- X→ZoneY
```

## 🔧 ИСПРАВЛЕНИЯ СДЕЛАННЫЕ

### **1. В extractor.lua:**

**ДО (неправильно):**
```lua
zone_x = ((x - x_min) / (x_max - x_min)) * 100
zone_y = ((y - y_min) / (y_max - y_min)) * 100
swap(zone_x, zone_y)
```

**ПОСЛЕ (правильно):**
```lua
-- Восстанавливаем оригинальные CSV значения:
DBC_LocLeft = x_max     -- -1962.5
DBC_LocRight = x_min    -- -7250
DBC_LocTop = y_max      -- 1808.333
DBC_LocBottom = y_min   -- -1716.667

-- GPS-matching формула:
zone_x = (y - DBC_LocLeft) / ((DBC_LocRight - DBC_LocLeft) / 100)
zone_y = (x - DBC_LocTop) / ((DBC_LocBottom - DBC_LocTop) / 100)
```

### **2. В load-client-data.sh:**
- Исправлена логика min/max для отрицательных чисел
- Добавлена надежная сортировка coordinates

## 📊 РЕЗУЛЬТАТЫ

### **ТОЧНОСТЬ КООРДИНАТ:**
- **GPS:** ZoneX: 51.948936, ZoneY: 43.499153
- **Наш extractor:** 51.948936, 43.499063
- **Точность:** >99.99% ✅

### **СТАТИСТИКА УСПЕХА:**
- **Рабочих квестов:** 8006 из 9464
- **NPC с координатами:** 17365 из 29948
- **Процент успеха:** ~85%

## 🔍 АНАЛИЗ ИСТОЧНИКОВ РЕШЕНИЯ

### **1. QODO RESEARCH:**
- Нашел точный алгоритм AzerothCore Map2ZoneCoordinates
- Определил что swap(x,y) делается в AzerothCore

### **2. CURSOR DEEP ANALYSIS:**
- Проанализировал DBCStructure.h и DBCStores.cpp
- Определил точное соответствие CSV→Struct полей
- Выявил что GPS использует перекрестные координаты (Y→ZoneX, X→ZoneY)

### **3. MANUAL TESTING:**
- Сравнение с GPS командой в игре
- Обратный расчет для проверки формул
- Итеративное улучшение точности

## 🚨 ОСТАВШИЕСЯ ПРОБЛЕМЫ

### **1. ZONE DETECTION:**
- Многие NPC имеют db_zone: 0, db_area: 0 в creature таблице
- Spatial lookup помещает их в неправильные зоны (например Feralas вместо Durotar)

### **2. QUEST VISIBILITY:**
- Квесты отображаются в правильных координатах, но на неправильных картах
- Пример: квесты Mulgore показываются на карте Barrens (правильные координаты, неправильная зона)

### **3. ZONE BOUNDARY ISSUES:**
- Возможно нужна корректировка границ зон в DBC данных
- Или альтернативная логика zone detection для orphaned NPC
