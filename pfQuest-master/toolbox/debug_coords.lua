#!/usr/bin/lua

-- Debug script to test coordinate extraction
luasql = require("luasql.mysql")

local env = luasql.mysql()
mysql = env:connect("acore_world", "acore", "acore", "127.0.0.1", 3306)

if not mysql then
  print("ERROR: Failed to connect to database")
  return
end

print("Testing coordinate extraction for creature ID 1...")

-- Test query for creature ID 1
local creature_coords = {}
local query = mysql:execute([[
  SELECT creature.position_x, creature.position_y, creature.map, creature.zoneId, creature.areaId
  FROM creature
  WHERE creature.id1 = 1
  LIMIT 5
]])

if query then
  print("Query successful! Results:")
  while query:fetch(creature_coords, "a") do
    local x = tonumber(creature_coords.position_x)
    local y = tonumber(creature_coords.position_y)
    local map_id = tonumber(creature_coords.map)
    local zone_id = tonumber(creature_coords.zoneId)
    local area_id = tonumber(creature_coords.areaId)

    print(string.format("  x=%.2f, y=%.2f, map=%d, zone=%d, area=%d",
                        x or 0, y or 0, map_id or 0, zone_id or 0, area_id or 0))

    if x and y and map_id then
      local final_zone = area_id and area_id > 0 and area_id or zone_id and zone_id > 0 and zone_id or map_id

      -- Convert world coordinates to zone percentage
      local zone_x = math.floor((x + 17066) / 340 * 100) / 100
      local zone_y = math.floor((y + 17066) / 340 * 100) / 100

      -- Clamp to 0-100 range
      zone_x = math.max(0, math.min(100, zone_x))
      zone_y = math.max(0, math.min(100, zone_y))

      print(string.format("  -> Converted: x=%.2f, y=%.2f, zone=%d", zone_x, zone_y, final_zone))
    else
      print("  -> SKIPPED: Missing coordinates or map")
    end
  end
else
  print("Query failed!")
end

-- Test with creature ID 2843 from our earlier sample
print("\nTesting creature ID 2843...")
local query = mysql:execute([[
  SELECT creature.position_x, creature.position_y, creature.map, creature.zoneId, creature.areaId
  FROM creature
  WHERE creature.id1 = 2843
  LIMIT 3
]])

if query then
  while query:fetch(creature_coords, "a") do
    local x = tonumber(creature_coords.position_x)
    local y = tonumber(creature_coords.position_y)
    local map_id = tonumber(creature_coords.map)
    local zone_id = tonumber(creature_coords.zoneId)
    local area_id = tonumber(creature_coords.areaId)

    print(string.format("  x=%.2f, y=%.2f, map=%d, zone=%d, area=%d",
                        x or 0, y or 0, map_id or 0, zone_id or 0, area_id or 0))

    if x and y and map_id then
      local final_zone = area_id and area_id > 0 and area_id or zone_id and zone_id > 0 and zone_id or map_id

      local zone_x = math.floor((x + 17066) / 340 * 100) / 100
      local zone_y = math.floor((y + 17066) / 340 * 100) / 100

      zone_x = math.max(0, math.min(100, zone_x))
      zone_y = math.max(0, math.min(100, zone_y))

      print(string.format("  -> Converted: x=%.2f, y=%.2f, zone=%d", zone_x, zone_y, final_zone))
    else
      print("  -> SKIPPED: Missing coordinates or map")
    end
  end
end

mysql:close()
env:close()
print("Debug completed!")
