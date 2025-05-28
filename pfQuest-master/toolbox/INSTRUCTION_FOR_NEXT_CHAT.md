# Инструкция для завершения адаптации pfQuest extractor для AzerothCore

## Контекст проекта
Адаптируем Lua-скрипт `extractor.lua` из pfQuest для работы с AzerothCore (WotLK 3.3.5a). Скрипт извлекает данные из базы данных сервера и создает файлы для аддона pfQuest.

## Местоположение файлов
- **Основной скрипт**: `C:\Users\user\Desktop\azerothcore-wotlk\pfQuest-master\toolbox\extractor.lua`
- **Вывод данных**: `C:\Users\user\Desktop\azerothcore-wotlk\pfQuest-master\toolbox\output\`
- **База данных**: `acore_world` (MySQL, localhost:3306, пользователь: acore/acore)
- **DBC данные**: `C:\Users\user\Desktop\azerothcore-wotlk\pfQuest-master\toolbox\DBC\wotlk\`

## ✅ Что уже сделано и работает

### 1. Базовая функциональность восстановлена
- Все функции совместимости с Lua 5.1 добавлены
- Подключение к базе данных работает
- DBC данные загружены: AreaTrigger_wotlk (1097), WorldMapArea_wotlk (103), FactionTemplate_wotlk (829), AreaTable_wotlk (2283), SkillLine_wotlk (150)

### 2. Координаты работают ✅
- Функции `GetCreatureCoords()` и `GetGameObjectCoords()` исправлены для AzerothCore
- Используются правильные поля: `creature.id1`, `position_x`, `position_y`, `map`, `zoneId`, `areaId`
- Debug показал координаты добавляются: `DEBUG: Added coord for ID 3: 19.59,50.65 zone=0`

### 3. Секции успешно работают
- **Units** ✅ - координаты работают, units-wotlk.lua содержит >1M строк с координатами всех 29947 существ
- **Objects** ✅ - координаты работают, 1116 строк с координатами объектов
- **Areatrigger** ✅ - 774 записи из areatrigger_teleport + DBC данные
- **Quests** ✅ - 2041 строка с квестами
- **Meta** ✅ - флайтмастеры работают (175 записей)
- **Локализация** ✅ - имена существ на всех языках (29947 записей)

### 4. Оптимизация выполнена
- Убраны все debug prints из координатных функций
- Убраны все LIMIT (1000 для существ, 500 для предметов, 50 для координат)
- config.debug = false установлен

## ❌ КРИТИЧНЫЕ ПРОБЛЕМЫ которые нужно исправить

### ПРОБЛЕМА 1: init.lua сломана
```
Текущий результат: pfDB = table: 00BF52E0
Должно быть: полная структура pfDB с данными
ПРИЧИНА: Функция serialize() работает неправильно
```

### ПРОБЛЕМА 2: zones-wotlk.lua пустая
```
Текущий результат: pfDB["zones"]["data-wotlk"] = {}
ПРИЧИНА: Warning "Failed to query zones from DBC tables" - таблица AreaTable_wotlk не читается
```

### ПРОБЛЕМА 3: items-wotlk.lua содержит пустые записи
```
Текущий результат: [100] = {}, [10000] = {}, [10001] = {}
ПРИЧИНА: Данные предметов не заполняются (нет информации о дропе, шансах)
```

## 🚀 ПРИОРИТЕТ: Добавить быстрый режим для разработки

**ОБЯЗАТЕЛЬНО сделать первым шагом** для ускорения тестирования:

```lua
-- В начало extractor.lua добавить:
local FAST_MODE = true  -- true = быстро (100 записей), false = полная экстракция

-- В units секции изменить:
local query = mysql:execute('SELECT * FROM creature_template GROUP BY creature_template.entry ORDER BY creature_template.entry' .. (FAST_MODE and ' LIMIT 100' or ''))

-- В items секции изменить:
local query = mysql:execute('SELECT entry, name FROM item_template ORDER BY entry ASC' .. (FAST_MODE and ' LIMIT 50' or ''))
```

## 🎯 Что нужно сделать

### ШАГ 1: Добавить FAST_MODE (КРИТИЧНО для разработки)
- Установить FAST_MODE = true для быстрого тестирования
- Добавить условные LIMIT во все SQL запросы

### ШАГ 2: Исправить serialize() функцию
- Найти функцию serialize() в extractor.lua
- Исправить чтобы init.lua содержал данные вместо ссылки на таблицу

### ШАG 3: Исправить зоны (zones)
- Исправить запрос к AreaTable_wotlk таблице
- Убрать Warning "Failed to query zones from DBC tables"

### ШАГ 4: Заполнить данные предметов (items)
- Добавить информацию о дропе с мобов
- Добавить шансы дропа
- Убрать пустые записи

## 📋 Команды для работы

```bash
cd C:\Users\user\Desktop\azerothcore-wotlk\pfQuest-master\toolbox

# Загрузка DBC (если нужно):
lua load_dbc.lua

# Запуск экстракции:
lua extractor.lua

# Быстрая проверка (после добавления FAST_MODE = true):
lua extractor.lua  # займет 1-2 минуты вместо 10-20 минут
```

## ⚠️ Важные замечания
- НЕ менять код без добавления FAST_MODE - иначе каждый тест займет 10+ минут
- DEBUG: Added coord убраны из логов (слишком много вывода)
- Координаты УЖЕ работают - основная проблема в сериализации и заполнении данных
- При установке FAST_MODE = false получится полная экстракция всех 29947 существ

## 📍 Текущий статус
**Частично работает**: координаты извлекаются, но данные неправильно сериализуются в финальные файлы. Нужны исправления в serialize() и загрузке зон/предметов.
