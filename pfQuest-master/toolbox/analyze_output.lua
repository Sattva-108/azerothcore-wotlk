-- Count lines in units-wotlk.lua
local file = io.open("output/units-wotlk.lua", "r")
if not file then
    print("File not found!")
    return
end

local line_count = 0
local max_id = 0
local current_id = nil

for line in file:lines() do
    line_count = line_count + 1

    -- Look for pattern [number] = {
    local id_match = line:match("%[(%d+)%] = {")
    if id_match then
        current_id = tonumber(id_match)
        if current_id and current_id > max_id then
            max_id = current_id
        end
    end
end

file:close()
print("File has " .. line_count .. " lines")
print("Maximum creature ID found: " .. max_id)
