-- Emergency Zones Generator Test
print("🚨 Emergency zones generation test...")

local emergency_zones = {}

-- Critical zones from old-DB reference
local critical_mappings = {
    [9] = { 12, 17.47, 27.69, 51.15, 42.29 },    -- Northshire
    [77] = { 1, 29.84, 25.21, 50.15, 49.78 },    -- Dun Morogh
    [148] = { 14, 43.66, 39.42, 58.88, 69.99 },  -- Durotar
    [219] = { 40, 44.16, 20.21, 59.88, 65.49 },  -- Westfall
    [362] = { 14, 9.48, 11.98, 54.64, 42.66 },   -- Valley of Trials
    [363] = { 14, 9.98, 15.72, 44.41, 66.99 },   -- Cave
    [18] = { 12, 15.47, 14.22, 52.64, 64 },      -- Goldshire
    [20] = { 40, 10.48, 20.21, 44.16, 65.49 },   -- Westfall zones
    [57] = { 12, 16.97, 15.72, 38.42, 84.21 },   -- Elwynn zones
    [68] = { 44, 34.93, 20.96, 41.92, 59.13 }    -- Redridge zones
}

-- Add critical zones
for areaId, data in pairs(critical_mappings) do
    emergency_zones[areaId] = data
end

-- Add dummy data for remaining zones
for areaId = 1, 2500 do
    if not emergency_zones[areaId] then
        emergency_zones[areaId] = { 1, 10, 10, 90, 90 }
    end
end

-- Write zones.lua file
local zones_file = io.open("output/zones.lua", "w")
if zones_file then
    zones_file:write('pfDB["zones"]["data"] = {\n')

    local count = 0
    for areaId, data in pairs(emergency_zones) do
        zones_file:write(string.format('  [%d] = { %d, %.2f, %.2f, %.2f, %.2f },\n',
            areaId, data[1], data[2], data[3], data[4], data[5]))
        count = count + 1
    end

    zones_file:write('}\n')
    zones_file:close()

    print(string.format("✅ Emergency zones.lua generated! Total areas: %d", count))
else
    print("❌ Failed to create zones.lua file!")
end
