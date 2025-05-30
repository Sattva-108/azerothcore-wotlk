-- pfQuest SQL Field Test (Simplified)
-- Проверяет правильное поле связи между creature и creature_template

package.path = package.path .. ';./lua-sql-mysql/src/?.lua;./sha1/?.lua'

-- Загружаем luasql.mysql
luasql = require("luasql.mysql")

print("🔍 pfQuest SQL Field Test")
print("==========================")

-- Простые настройки подключения (настрой под свою базу)
local db_config = {
    host = "127.0.0.1",
    port = 3306,
    username = "root",
    password = "",  -- впиши пароль если есть
    database = "acore_world"
}

print("База: " .. db_config.database)
print("Хост: " .. db_config.host .. ":" .. db_config.port)
print("Пользователь: " .. db_config.username)

-- Подключение к базе
print("")
print("📡 Подключение к базе...")

local env = luasql.mysql()
if not env then
    print("❌ Не удалось создать MySQL environment")
    return
end

-- Подключаемся
local mysql = env:connect(db_config.database, db_config.username, db_config.password, db_config.host, db_config.port)

if not mysql then
    print("❌ Не удалось подключиться к базе данных!")
    print("🔧 Проверь настройки выше в скрипте")
    env:close()
    return
end

print("✅ Подключение успешно!")
print("")

-- Функция для получения одного значения
local function get_count(query)
    local cursor = mysql:execute(query)
    if cursor then
        local result = {}
        cursor:fetch(result, "a")
        cursor:close()
        return tonumber(result.count) or 0
    end
    return 0
end

-- Функция для получения первой строки
local function get_first_row(query)
    local cursor = mysql:execute(query)
    if cursor then
        local result = {}
        cursor:fetch(result, "a")
        cursor:close()
        return result
    end
    return nil
end

print("📊 СТРУКТУРА ТАБЛИЦ:")
print("====================")

-- Проверяем поля creature
print("Ключевые поля таблицы creature:")
local cursor = mysql:execute("DESCRIBE creature")
if cursor then
    local row = {}
    while cursor:fetch(row, "a") do
        local field = row.Field
        if field and (field:match("id") or field:match("entry") or field:match("guid")) then
            print(string.format("  ➤ %s (%s)", field, row.Type or "unknown"))
        end
        row = {}
    end
    cursor:close()
else
    print("❌ Не удалось получить структуру creature")
end

print("")

-- Тесты связей
print("🧪 ТЕСТЫ СВЯЗЕЙ:")
print("=================")

local tests = {
    {name = "creature.entry = creature_template.entry", field = "entry"},
    {name = "creature.id = creature_template.entry", field = "id"}
}

-- Проверяем есть ли поле id1
local id1_cursor = mysql:execute("SELECT id1 FROM creature LIMIT 1")
if id1_cursor then
    id1_cursor:close()
    table.insert(tests, {name = "creature.id1 = creature_template.entry", field = "id1"})
end

-- Выполняем тесты
local results = {}
for i, test in ipairs(tests) do
    local query = string.format([[
        SELECT COUNT(*) as count
        FROM creature c
        JOIN creature_template ct ON c.%s = ct.entry
    ]], test.field)

    local count = get_count(query)
    results[test.field] = count

    print(string.format("%d. %s: %d связей", i, test.name, count))
end

print("")

-- Конкретные примеры
print("🎯 ПРИМЕРЫ ДАННЫХ:")
print("==================")

-- Проверяем creature_template entry=1
local ct1 = get_first_row("SELECT entry, name FROM creature_template WHERE entry = 1")
if ct1 and ct1.name then
    print(string.format("creature_template entry=1: '%s'", ct1.name))

    -- Ищем спавны по каждому полю
    for field, _ in pairs(results) do
        local count = get_count(string.format("SELECT COUNT(*) as count FROM creature WHERE %s = 1", field))
        print(string.format("  Спавнов с %s=1: %d", field, count))
    end
else
    print("creature_template entry=1: не найден")
end

print("")

-- Статистика
print("📈 СТАТИСТИКА:")
print("===============")

local total_creatures = get_count("SELECT COUNT(*) as count FROM creature")
local total_templates = get_count("SELECT COUNT(*) as count FROM creature_template")
local creatures_with_coords = get_count("SELECT COUNT(*) as count FROM creature WHERE position_x IS NOT NULL AND position_y IS NOT NULL")

print(string.format("Всего существ: %d", total_creatures))
print(string.format("Всего шаблонов: %d", total_templates))
print(string.format("Существ с координатами: %d", creatures_with_coords))

print("")

-- Анализ и рекомендации
print("🎯 АНАЛИЗ И РЕКОМЕНДАЦИИ:")
print("==========================")

-- Находим поле с максимальным количеством связей
local best_field = nil
local best_count = 0

for field, count in pairs(results) do
    if count > best_count then
        best_field = field
        best_count = count
    end
end

if best_field and best_count > 0 then
    print(string.format("✅ РЕКОМЕНДАЦИЯ: Используй поле '%s' (%d связей)", best_field, best_count))
    print("")
    print("📝 ИСПРАВЛЕНИЕ в extractor.lua:")
    print(string.format("   Найди строку ~625: WHERE creature.id = ]] .. id .. [["))
    print(string.format("   Замени на:         WHERE creature.%s = ]] .. id .. [[", best_field))

    -- Показываем пример рабочего запроса
    if best_count > 0 then
        print("")
        print("🧪 ПРИМЕР РАБОЧЕГО ЗАПРОСА:")
        local example = get_first_row(string.format([[
            SELECT c.guid, c.%s, c.position_x, c.position_y, c.map, ct.name
            FROM creature c
            JOIN creature_template ct ON c.%s = ct.entry
            WHERE ct.entry = 1
            LIMIT 1
        ]], best_field, best_field))

        if example and example.name then
            print(string.format("   Существо: %s (%s=%s)", example.name, best_field, example[best_field] or "unknown"))
            print(string.format("   Координаты: %.2f, %.2f на карте %s",
                tonumber(example.position_x) or 0,
                tonumber(example.position_y) or 0,
                example.map or 0))
        end
    end

else
    print("❌ ПРОБЛЕМА: Нет рабочих связей между таблицами!")
    print("")
    print("🔧 ВОЗМОЖНЫЕ ПРИЧИНЫ:")
    print("   - База данных пуста")
    print("   - Неправильная структура таблиц")
    print("   - Проблемы с настройками подключения")
end

-- Закрываем соединения
mysql:close()
env:close()

print("")
print("✅ SQL проверка завершена!")
print("")
print("🚀 СЛЕДУЮЩИЕ ШАГИ:")
if best_field then
    print("1. Исправь поле в extractor.lua на '" .. best_field .. "'")
    print("2. Запусти: lua extractor.lua")
    print("3. Проверь output/units.lua на наличие координат")
    print("4. Если координаты есть - копируй: transfer_files.bat")
    print("5. Перезапусти WoW и проверь: /pftest")
else
    print("1. Проверь настройки базы данных в начале скрипта")
    print("2. Убедись что база данных содержит данные")
    print("3. Попробуй подключиться через HeidiSQL для проверки")
end
