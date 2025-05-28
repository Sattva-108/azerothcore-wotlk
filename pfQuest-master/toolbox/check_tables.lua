#!/usr/bin/lua

-- Script to check table structure in AzerothCore
luasql = require("luasql.mysql")

local env = luasql.mysql()
mysql = env:connect("acore_world", "acore", "acore", "127.0.0.1", 3306)

if not mysql then
  print("ERROR: Failed to connect to database")
  return
end

print("Checking AzerothCore table structures...")
print("=" .. string.rep("=", 50))

-- Check creature table structure
print("\n1. CREATURE table structure:")
local query = mysql:execute('DESCRIBE creature')
if query then
  local row = {}
  while query:fetch(row, "a") do
    print("  " .. (row.Field or row[1]) .. " - " .. (row.Type or row[2]))
  end
else
  print("  ERROR: Cannot describe creature table")
end

-- Check gameobject table structure
print("\n2. GAMEOBJECT table structure:")
local query = mysql:execute('DESCRIBE gameobject')
if query then
  local row = {}
  while query:fetch(row, "a") do
    print("  " .. (row.Field or row[1]) .. " - " .. (row.Type or row[2]))
  end
else
  print("  ERROR: Cannot describe gameobject table")
end

-- Check if DBC tables exist
print("\n3. DBC tables check:")
local dbc_tables = {"AreaTrigger_wotlk", "WorldMapArea_wotlk", "FactionTemplate_wotlk", "Lock_wotlk", "AreaTable_wotlk", "SkillLine_wotlk"}
for _, table_name in pairs(dbc_tables) do
  local query = mysql:execute('SHOW TABLES LIKE "' .. table_name .. '"')
  if query and query:fetch() then
    print("  ✓ " .. table_name .. " exists")
  else
    print("  ✗ " .. table_name .. " missing")
  end
end

-- Check creature_template structure
print("\n4. CREATURE_TEMPLATE table structure:")
local query = mysql:execute('DESCRIBE creature_template')
if query then
  local row = {}
  while query:fetch(row, "a") do
    print("  " .. (row.Field or row[1]) .. " - " .. (row.Type or row[2]))
  end
else
  print("  ERROR: Cannot describe creature_template table")
end

-- Test a sample creature query
print("\n5. Sample creature data:")
local query = mysql:execute('SELECT * FROM creature LIMIT 3')
if query then
  local row = {}
  local count = 0
  while query:fetch(row, "a") do
    count = count + 1
    print("  Row " .. count .. ":")
    for k, v in pairs(row) do
      print("    " .. k .. " = " .. tostring(v))
    end
    print()
    if count >= 2 then break end
  end
else
  print("  ERROR: Cannot query creature table")
end

mysql:close()
env:close()
print("Table structure check completed!")
