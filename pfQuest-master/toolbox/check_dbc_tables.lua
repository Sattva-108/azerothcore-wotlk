#!/usr/bin/lua

-- Simple script to check what DBC tables exist in acore_world
luasql = require("luasql.mysql")

-- Connect to database
local env = luasql.mysql()
mysql = env:connect("acore_world", "acore", "acore", "127.0.0.1", 3306)

print("Checking for DBC tables in acore_world database:")
print("=" .. string.rep("=", 50))

-- Check for various possible table names
local tables_to_check = {
  "AreaTrigger_wotlk",
  "areatrigger_wotlk",
  "WorldMapArea_wotlk",
  "worldmaparea_wotlk",
  "FactionTemplate_wotlk",
  "factiontemplate_wotlk",
  "Lock_wotlk",
  "lock_wotlk",
  "SkillLine_wotlk",
  "skillline_wotlk",
  "AreaTable_wotlk",
  "areatable_wotlk",
  "WorldMapOverlay_wotlk",
  "worldmapoverlay_wotlk"
}

-- Check what tables exist
print("\nSearching for DBC tables:")
for _, table_name in pairs(tables_to_check) do
  local query = mysql:execute('SHOW TABLES LIKE "' .. table_name .. '"')
  if query and query:fetch() then
    print("✓ FOUND: " .. table_name)
  else
    print("✗ NOT FOUND: " .. table_name)
  end
end

-- Also check for any tables containing "wotlk"
print("\nAll tables containing 'wotlk':")
local query = mysql:execute('SHOW TABLES LIKE "%wotlk%"')
if query then
  local row = {}
  while query:fetch(row, "a") do
    for k, v in pairs(row) do
      print("  " .. v)
    end
  end
else
  print("  No tables found containing 'wotlk'")
end

-- Check for any AreaTrigger-like tables
print("\nAll tables containing 'area' or 'trigger':")
local query = mysql:execute('SHOW TABLES LIKE "%area%"')
if query then
  local row = {}
  while query:fetch(row, "a") do
    for k, v in pairs(row) do
      print("  " .. v)
    end
  end
end

local query = mysql:execute('SHOW TABLES LIKE "%trigger%"')
if query then
  local row = {}
  while query:fetch(row, "a") do
    for k, v in pairs(row) do
      print("  " .. v)
    end
  end
end

mysql:close()
env:close()
