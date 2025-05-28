-- Fix to allow zone=0 (map coordinates)
local file = io.open("extractor.lua", "r")
local content = file:read("*all")
file:close()

print("Fixing zone=0 filtering...")

-- The issue: coordinates with zone=0 are valid but get filtered out
-- Solution: Allow zone=0 since it represents map-level coordinates

-- No changes needed to coordinate extraction - the issue is elsewhere
-- Let's check what happens to coordinates after they're generated

-- Add debug output to see what's happening
local debug_pattern = "table%.insert%(ret, coord%)"
local debug_replacement = [[table.insert(ret, coord)
              print("DEBUG: Added coord for ID " .. id .. ": " .. zone_x .. "," .. zone_y .. " zone=" .. final_zone)]]

content = string.gsub(content, debug_pattern, debug_replacement)

local file = io.open("extractor.lua", "w")
file:write(content)
file:close()

print("Added debug output to coordinate functions")
print("Now run: lua extractor.lua")
print("You should see DEBUG messages showing which coordinates are being added")
