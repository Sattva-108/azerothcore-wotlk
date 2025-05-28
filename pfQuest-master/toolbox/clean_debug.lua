-- Remove debug output from coordinate functions
local file = io.open("extractor.lua", "r")
local content = file:read("*all")
file:close()

print("Removing debug output...")

-- Remove the debug print statements
local debug_pattern = 'table%.insert%(ret, coord%)\n              print%("DEBUG: Added coord for ID " %-%- id %-%- ": " %-%- zone_x %-%- "," %-%- zone_y %-%- " zone=" %-%- final_zone%)'
local clean_pattern = "table.insert(ret, coord)"

content = string.gsub(content, debug_pattern, clean_pattern)

local file = io.open("extractor.lua", "w")
file:write(content)
file:close()

print("Cleaned debug output!")
print("Now run: lua extractor.lua")
print("This will process ALL 29947 creatures (may take a few minutes)")
