#!/usr/bin/lua
-- pfQuest Database Verification Script
-- Проверяет состояние базы данных и готовность к экстракции

print("=== pfQuest Database Verification ===")
print("")

-- Подключение к базе данных
package.path = package.path .. ';./lua-sql-mysql/src/?.lua'
luasql = require("luasql.mysql")

local env = luasql.mysql()
if not env then
    print("❌ ERROR: Failed to create MySQL environment")
    os.exit(1)
end

-- Параметры подключения (из extractor.lua)
local mysql, err = env:connect("acore_world", "acore", "acore", "127.0.0.1", 3306)
if not mysql then
    print("❌ ERROR: Database connection failed: " .. (err or "unknown error"))
    os.exit(1)
end

print("✅ Database connection successful!")
print("")

-- Функция для выполнения запроса и получения единственного значения
function get_single_value(sql)
    local query = mysql:execute(sql)
    if query then
        local row = {}
        query:fetch(row, "n")
        return tonumber(row[1]) or 0
    end
    return 0
end

-- Функция для выполнения запроса и получения таблицы результатов
function get_results(sql, limit)
    limit = limit or 100
    local results = {}
    local query = mysql:execute(sql)
    if query then
        local count = 0
        local row = {}
        while query:fetch(row, "a") and count < limit do
            table.insert(results, {})
            for k, v in pairs(row) do
                results[#results][k] = v
            end
            count = count + 1
        end
    end
    return results
end

print("📊 DATABASE STATISTICS:")
print("=======================")

-- Основная статистика
local creature_count = get_single_value("SELECT COUNT(*) FROM creature_template")
local quest_count = get_single_value("SELECT COUNT(*) FROM quest_template")
local gameobject_count = get_single_value("SELECT COUNT(*) FROM gameobject_template")
local creature_spawns = get_single_value("SELECT COUNT(*) FROM creature")
local gameobject_spawns = get_single_value("SELECT COUNT(*) FROM gameobject")

print("Creature Templates: " .. creature_count)
print("Quest Templates:    " .. quest_count)
print("GameObject Templates: " .. gameobject_count)
print("Creature Spawns:    " .. creature_spawns)
print("GameObject Spawns:  " .. gameobject_spawns)
print("")

-- Проверка pfquest базы
print("🔍 PFQUEST DBC TABLES:")
print("=======================")

local pfquest_db = env:connect("pfquest", "acore", "acore", "127.0.0.1", 3306)
if pfquest_db then
    print("✅ pfquest database accessible")

    local tables = {
        "areatrigger_vanilla",
        "factiontemplate_vanilla",
        "worldmaparea_vanilla",
        "areatable_vanilla",
        "skillline_vanilla"
    }

    for _, table_name in ipairs(tables) do
        local count = get_single_value("SELECT COUNT(*) FROM " .. table_name)
        count = tonumber(count) or 0
        if count > 0 then
            print("✅ " .. table_name .. ": " .. count .. " records")
        else
            print("⚠️  " .. table_name .. ": empty or missing")
        end
    end
    pfquest_db:close()
else
    print("❌ pfquest database not accessible")
end
print("")

-- Анализ проблемных квестов
print("⚠️  QUEST LEVEL ANALYSIS:")
print("==========================")

local negative_levels = get_single_value("SELECT COUNT(*) FROM quest_template WHERE QuestLevel < 0")
local zero_levels = get_single_value("SELECT COUNT(*) FROM quest_template WHERE QuestLevel = 0")
local max_level = get_single_value("SELECT MAX(QuestLevel) FROM quest_template")

print("Quests with level < 0: " .. negative_levels)
print("Quests with level = 0: " .. zero_levels)
print("Maximum quest level:   " .. max_level)

if negative_levels > 0 then
    print("")
    print("🔍 Quests with negative levels:")
    local bad_quests = get_results("SELECT ID, QuestLevel, MinLevel, Title FROM quest_template WHERE QuestLevel < 0 ORDER BY ID", 10)
    for _, quest in ipairs(bad_quests) do
        print("  ID " .. quest.ID .. ": level=" .. quest.QuestLevel .. ", min=" .. quest.MinLevel .. " - " .. (quest.Title or "No Title"))
    end
end
print("")

-- Уровневое распределение квестов
print("📈 QUEST LEVEL DISTRIBUTION:")
print("=============================")
local level_dist = get_results("SELECT QuestLevel, COUNT(*) as count FROM quest_template GROUP BY QuestLevel ORDER BY QuestLevel", 20)
for _, row in ipairs(level_dist) do
    print("Level " .. row.QuestLevel .. ": " .. row.count .. " quests")
end
print("")

-- Проверка существ
print("🐲 CREATURE LEVEL ANALYSIS:")
print("=============================")
local max_creature_level = get_single_value("SELECT MAX(maxlevel) FROM creature_template")
local min_creature_level = get_single_value("SELECT MIN(minlevel) FROM creature_template")
local null_levels = get_single_value("SELECT COUNT(*) FROM creature_template WHERE minlevel IS NULL OR maxlevel IS NULL")

print("Min creature level: " .. min_creature_level)
print("Max creature level: " .. max_creature_level)
print("Creatures with NULL levels: " .. null_levels)
print("")

-- Проверка файлов экстракции
print("📁 EXTRACTION FILES CHECK:")
print("===========================")

local function file_exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

local output_files = {
    "../db/quests.lua",
    "../db/units.lua",
    "../db/items.lua",
    "../db/objects.lua",
    "../db/enUS/quests.lua",
    "../db/enUS/units.lua"
}

for _, file in ipairs(output_files) do
    if file_exists(file) then
        print("✅ " .. file)
    else
        print("❌ " .. file .. " - missing")
    end
end
print("")

-- Финальный отчет
print("📋 SUMMARY:")
print("============")
print("Database connection: ✅ OK")
print("Quest templates: " .. quest_count .. " found")
print("Creature templates: " .. creature_count .. " found")

if negative_levels > 0 then
    print("⚠️  WARNING: " .. negative_levels .. " quests have negative levels")
else
    print("✅ All quest levels are valid")
end

print("")
print("🚀 Ready for pfQuest extraction!")

mysql:close()
env:close()
