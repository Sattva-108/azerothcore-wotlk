-- Quick fix script to update coordinate functions in extractor.lua
local file = io.open("extractor.lua", "r")
if not file then
  print("ERROR: Cannot open extractor.lua")
  return
end

local content = file:read("*all")
file:close()

print("Original functions found, applying fixes...")

-- Fix creature coords condition - more specific replacement
local old_pattern = "if x and y and zone_id and zone_id > 0 then"
local new_pattern = "if x and y and map_id then"

local count = 0
content = string.gsub(content, old_pattern, function(match)
  count = count + 1
  print("  Fixed creature coords condition #" .. count)
  return new_pattern
end)

-- Fix the zone assignment logic
local old_zone_logic = "local final_zone = area_id and area_id > 0 and area_id or zone_id"
local new_zone_logic = "local final_zone = area_id and area_id > 0 and area_id or zone_id and zone_id > 0 and zone_id or map_id"

content = string.gsub(content, old_zone_logic, function(match)
  count = count + 1
  print("  Fixed zone logic #" .. count)
  return new_zone_logic
end)

-- Write back
local file = io.open("extractor.lua", "w")
if not file then
  print("ERROR: Cannot write to extractor.lua")
  return
end

file:write(content)
file:close()

print("SUCCESS: Fixed " .. count .. " coordinate functions!")
print("")
print("Now run: lua extractor.lua")
