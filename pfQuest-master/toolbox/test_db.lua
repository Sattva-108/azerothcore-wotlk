#!/usr/bin/lua

-- Test script to check AzerothCore database connection and verify creature coordinates
luasql = require("luasql.mysql")

print("Testing AzerothCore database connection...")

local env = luasql.mysql()
mysql = env:connect("acore_world", "acore", "acore", "127.0.0.1", 3306)

if not mysql then
  print("ERROR: Failed to connect to database")
  return
end

print("✓ Database connection successful!")

-- Test basic creature_template query
print("\nTesting creature_template table:")
local query = mysql:execute('SELECT entry, name, minlevel, maxlevel FROM creature_template LIMIT 5')
if query then
  print("✓ creature_template table accessible")
  local row = {}
  while query:fetch(row, "a") do
    print("  Creature " .. row.entry .. ": " .. row.name .. " (Level " .. row.minlevel .. "-" .. row.maxlevel .. ")")
  end
else
  print("✗ Failed to query creature_template")
end

-- Test creature coordinates query
print("\nTesting creature coordinates:")
local query = mysql:execute('SELECT id1, position_x, position_y, map, zoneId FROM creature WHERE id1 IN (1, 2, 3) LIMIT 10')
if query then
  print("✓ creature table accessible")
  local row = {}
  while query:fetch(row, "a") do
    print("  Creature " .. row.id1 .. " at (" .. row.position_x .. ", " .. row.position_y .. ") Map: " .. row.map .. " Zone: " .. (row.zoneId or "nil"))
  end
else
  print("✗ Failed to query creature coordinates")
end

-- Test areatrigger_teleport table
print("\nTesting areatrigger_teleport table:")
local query = mysql:execute('SELECT ID, target_map, target_position_x, target_position_y FROM areatrigger_teleport LIMIT 5')
if query then
  print("✓ areatrigger_teleport table accessible")
  local row = {}
  while query:fetch(row, "a") do
    print("  AT " .. row.ID .. " -> Map " .. row.target_map .. " at (" .. row.target_position_x .. ", " .. row.target_position_y .. ")")
  end
else
  print("✗ Failed to query areatrigger_teleport")
end

mysql:close()
env:close()
print("\nTest completed!")
