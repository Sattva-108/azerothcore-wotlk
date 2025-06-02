# TOOLBOX INVENTORY - ПОЛНАЯ ОПИСЬ ФАЙЛОВ

## 📁 СТРУКТУРА ПАПКИ TOOLBOX

### **🔧 ОСНОВНЫЕ ИНСТРУМЕНТЫ:**
- `extractor.lua` - ГЛАВНЫЙ ФАЙЛ: генерирует координаты NPC/объектов для pfQuest
- `load-client-data.sh` - парсер DBC→SQL: конвертирует клиентские DBC в SQL
- `client-data.sql` - результат парсинга: таблицы WorldMapArea_wotlk, AreaTable_wotlk и др.

### **📊 ИСХОДНЫЕ ДАННЫЕ:**
- `DBC/wotlk/` - DBC файлы клиента WoW 3.3.5:
  - `WorldMapArea.dbc.csv` - границы зон (LocLeft,LocRight,LocTop,LocBottom)
  - `AreaTable.dbc.csv` - иерархия зон (зона→родительская зона)
  - `WorldMapOverlay.dbc.csv` - субзоны и их позиционирование

### **📋 КОНФИГУРАЦИЯ:**
- `Makefile` - автоматизация процесса генерации данных
- `load_dbc.lua` - загрузчик DBC данных в Lua
- `transfer_files.bat` - копирование файлов в аддон

### **📁 БАЗЫ ДАННЫХ:**
- `db/enUS/` - локализованные данные квестов/NPC/объектов

### **📤 ВЫХОДНЫЕ ДАННЫЕ:**
- `output/` - результат работы extractor.lua:
  - `units.lua` - координаты NPC
  - `quests.lua` - данные квестов
  - `objects.lua` - координаты объектов
  - `zones.lua` - информация о зонах

### **🗺️ КАРТЫ:**
- `maps/` - изображения карт зон (0.png = Eastern Kingdoms, 1.png = Kalimdor, etc)

### **🔧 УТИЛИТЫ:**
- `compressdb.sh` - сжатие базы данных
- `make-translations.sh` - генерация переводов
- `old/` - старые версии файлов
- `pngLua/` - библиотека для работы с PNG
- `pfquest_diagnostic.lua` - диагностические инструменты

## 🔄 ПРОЦЕСС ГЕНЕРАЦИИ ДАННЫХ

### **1. DBC → SQL (load-client-data.sh):**
```
WorldMapArea.dbc.csv → WorldMapArea_wotlk (границы зон)
AreaTable.dbc.csv → AreaTable_wotlk (иерархия зон)
```

### **2. SQL → LUA (extractor.lua):**
```
acore_world.creature + WorldMapArea_wotlk → output/units.lua
acore_world.gameobject + WorldMapArea_wotlk → output/objects.lua
```

### **3. LUA → ADDON (transfer_files.bat):**
```
output/*.lua → pfQuest/db/enUS/*.lua
```

## 📊 СТАТИСТИКА ПРОЕКТА
- **Квестов в базе:** 9464
- **NPC с координатами:** 17365 из 29948
- **Рабочих квестов:** 8006
- **Зон:** 74
