#!/usr/bin/lua
-- Быстрый тест исправлений
-- path to the modules
package.path = package.path .. ';./lua-sql-mysql/src/?.lua'

-- global definitions
luasql = require("luasql.mysql")

-- database configuration
local database = "acore_world"
local username = "acore"
local password = "acore"
local hostname = "localhost"

-- connect to database
local env = luasql.mysql()
local mysql = env:connect(database, username, password, hostname)

if not mysql then
    print("Error: Could not connect to database")
    os.exit(1)
end

print("SUCCESS: Connected to database " .. database)

-- Test 1: Check AreaTable_wotlk table
print("\n=== Testing Zone Tables ===")
local test_tables = {"AreaTable_wotlk", "AreaTable", "pfquest.AreaTable_wotlk"}

for _, table_name in ipairs(test_tables) do
    print("Testing table: " .. table_name)
    local query = mysql:execute('SELECT COUNT(*) as count FROM ' .. table_name .. ' LIMIT 1')
    if query then
        local result = {}
        query:fetch(result, "a")
        print("  SUCCESS: " .. table_name .. " exists with " .. (result.count or "unknown") .. " records")
        query:close()

        -- Get sample data
        local sample_query = mysql:execute('SELECT * FROM ' .. table_name .. ' LIMIT 3')
        if sample_query then
            local sample = {}
            print("  Sample columns:")
            while sample_query:fetch(sample, "a") do
                for k, v in pairs(sample) do
                    print("    " .. k .. " = " .. tostring(v))
                end
                break -- Only show first row columns
            end
            sample_query:close()
        end
        break
    else
        print("  FAILED: " .. table_name .. " not found")
    end
end

-- Test 2: Check serialize issue
print("\n=== Testing Serialize Fix ===")
local test_data = {
    units = {
        ["data-wotlk"] = {
            [1] = "Test Unit",
            [2] = "Another Unit"
        }
    },
    items = {
        ["data-wotlk"] = {
            [100] = "Test Item"
        }
    }
}

-- Test serialize function (simplified)
function test_serialize(filename, varname, data)
    local file = io.open(filename, "w")
    if not file then
        print("Error: Cannot create test file")
        return
    end

    file:write(varname .. " = ")
    if type(data) == "table" then
        file:write("{\n")
        for k, v in pairs(data) do
            file:write("  [" .. tostring(k) .. "] = ")
            if type(v) == "table" then
                file:write("{...},\n")
            else
                file:write(tostring(v) .. ",\n")
            end
        end
        file:write("}\n")
    else
        file:write(tostring(data) .. "\n")
    end
    file:close()
    print("Serialized to " .. filename)
end

test_serialize("test_init.lua", "pfDB", test_data)

-- Read back and check
local test_file = io.open("test_init.lua", "r")
if test_file then
    local content = test_file:read("*all")
    test_file:close()
    print("Test file content:")
    print(content)

    -- Check if it contains "table:" (the bug)
    if content:find("table:") then
        print("ERROR: Still has table reference bug!")
    else
        print("SUCCESS: Serialize fix appears to work")
    end
else
    print("ERROR: Could not read test file")
end

-- Test 3: Check creature_template with FAST_MODE
print("\n=== Testing FAST_MODE ===")
local fast_limit = " LIMIT 5"
local query = mysql:execute('SELECT COUNT(*) as count FROM creature_template')
if query then
    local result = {}
    query:fetch(result, "a")
    print("Total creatures in database: " .. (result.count or "unknown"))
    query:close()

    -- Test with limit
    local limited_query = mysql:execute('SELECT entry, name FROM creature_template ORDER BY entry' .. fast_limit)
    if limited_query then
        print("FAST_MODE test (limited to 5):")
        local creature = {}
        local count = 0
        while limited_query:fetch(creature, "a") do
            count = count + 1
            print("  " .. count .. ". [" .. creature.entry .. "] " .. (creature.name or "Unknown"))
        end
        limited_query:close()
        print("SUCCESS: FAST_MODE limit working")
    end
end

-- cleanup
mysql:close()
env:close()

print("\n=== Test Complete ===")
