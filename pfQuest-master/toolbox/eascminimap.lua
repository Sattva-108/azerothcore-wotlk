#!/usr/bin/lua

-- Ascension Minimap Data Extractor
-- Creates minimap.lua for Ascension WoW server
-- Only extracts zone boundary data needed for minimap functionality

print("Ascension Minimap Data Extractor v1.0")
print("=====================================")

-- Function to parse CSV line properly (same as load_dbc.lua)
function parse_csv_line(line)
  local values = {}
  local i = 1
  local start = 1
  local in_quotes = false

  while i <= #line do
    local char = line:sub(i, i)

    if char == '"' then
      in_quotes = not in_quotes
    elseif char == ',' and not in_quotes then
      local value = line:sub(start, i-1)
      -- Remove quotes but keep original for numbers
      value = value:gsub('^"', ''):gsub('"$', '')
      table.insert(values, value)
      start = i + 1
    end

    i = i + 1
  end

  -- Add the last value
  local value = line:sub(start)
  value = value:gsub('^"', ''):gsub('"$', '')
  table.insert(values, value)

  return values
end

-- Function to check if file exists
function file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

-- Function to safely convert string to number
function safe_tonumber(str)
  if not str or str == "" then
    return 0
  end
  -- Handle both comma and period as decimal separator
  str = str:gsub(',', '.')
  return tonumber(str) or 0
end

-- Load WorldMapArea data from Ascension DBC
function load_worldmaparea_data()
  local worldmaparea_file = "DBC/ascension/WorldMapArea.dbc.csv"
  
  if not file_exists(worldmaparea_file) then
    print("ERROR: Cannot find " .. worldmaparea_file)
    return nil
  end

  print("Loading WorldMapArea data from: " .. worldmaparea_file)
  
  local file = io.open(worldmaparea_file, "r")
  if not file then
    print("ERROR: Cannot open " .. worldmaparea_file)
    return nil
  end

  local worldmaparea_data = {}
  
  -- Skip header line
  local header = file:read("*line")
  print("  Header: " .. header)
  
  local count = 0
  for line in file:lines() do
    if line and line ~= "" then
      local values = parse_csv_line(line)
      
      if #values >= 11 then
        local areaID = tonumber(values[1]) or 0
        local mapID = tonumber(values[2]) or 0
        local areaTableID = tonumber(values[3]) or 0
        local areaName = values[4] or ""
        local locLeft = safe_tonumber(values[5])
        local locRight = safe_tonumber(values[6])
        local locTop = safe_tonumber(values[7])
        local locBottom = safe_tonumber(values[8])
        
        worldmaparea_data[areaID] = {
          mapID = mapID,
          areaTableID = areaTableID,
          areaName = areaName,
          locLeft = locLeft,
          locRight = locRight,
          locTop = locTop,
          locBottom = locBottom
        }
        
        count = count + 1
      end
    end
  end
  
  file:close()
  print("  SUCCESS: Loaded " .. count .. " WorldMapArea entries")
  return worldmaparea_data
end

-- Load DungeonMap data from Ascension DBC (fallback for missing boundaries)
function load_dungeonmap_data()
  local dungeonmap_file = "DBC/ascension/DungeonMap.dbc.csv"
  
  if not file_exists(dungeonmap_file) then
    print("WARNING: Cannot find " .. dungeonmap_file .. " - no dungeon fallback data")
    return {}
  end

  print("Loading DungeonMap data from: " .. dungeonmap_file)
  
  local file = io.open(dungeonmap_file, "r")
  if not file then
    print("WARNING: Cannot open " .. dungeonmap_file)
    return {}
  end

  local dungeonmap_data = {}
  
  -- Skip header line
  local header = file:read("*line")
  print("  Header: " .. header)
  
  local count = 0
  for line in file:lines() do
    if line and line ~= "" then
      local values = parse_csv_line(line)
      
      if #values >= 8 then
        local id = tonumber(values[1]) or 0
        local mapID = tonumber(values[2]) or 0
        local floorIndex = tonumber(values[3]) or 0
        local minX = safe_tonumber(values[4])
        local maxX = safe_tonumber(values[5])
        local minY = safe_tonumber(values[6])
        local maxY = safe_tonumber(values[7])
        local parentWorldMapID = tonumber(values[8]) or 0
        
        -- Use parentWorldMapID as the key for fallback lookups
        if parentWorldMapID > 0 then
          dungeonmap_data[parentWorldMapID] = {
            id = id,
            mapID = mapID,
            floorIndex = floorIndex,
            minX = minX,
            maxX = maxX,
            minY = minY,
            maxY = maxY
          }
        end
        
        count = count + 1
      end
    end
  end
  
  file:close()
  print("  SUCCESS: Loaded " .. count .. " DungeonMap entries")
  return dungeonmap_data
end

-- Calculate minimap dimensions for a zone
function calculate_minimap_dimensions(area_data, dungeon_fallback)
  local locLeft = area_data.locLeft
  local locRight = area_data.locRight
  local locTop = area_data.locTop
  local locBottom = area_data.locBottom
  
  -- If all coordinates are zero, try dungeon fallback
  if locLeft == 0 and locRight == 0 and locTop == 0 and locBottom == 0 then
    if dungeon_fallback then
      print("    Using dungeon fallback for area " .. area_data.areaName)
      locLeft = dungeon_fallback.minX
      locRight = dungeon_fallback.maxX
      locTop = dungeon_fallback.minY
      locBottom = dungeon_fallback.maxY
    else
      print("    WARNING: No boundary data for area " .. area_data.areaName)
      return nil
    end
  end
  
  -- Calculate width and height (same logic as extractor.lua)
  local width = math.abs(locRight - locLeft)
  local height = math.abs(locTop - locBottom)
  
  -- Ensure we have valid dimensions
  if width == 0 or height == 0 then
    print("    WARNING: Invalid dimensions for area " .. area_data.areaName .. " (w:" .. width .. ", h:" .. height .. ")")
    return nil
  end
  
  return { height = height, width = width }
end

-- Generate minimap.lua file
function generate_minimap_file(minimap_data)
  local output_file = "minimap-ascension.lua"
  
  print("Generating minimap file: " .. output_file)
  
  local file = io.open(output_file, "w")
  if not file then
    print("ERROR: Cannot create " .. output_file)
    return false
  end
  
  -- Write header
  file:write("-- Ascension Minimap Data\n")
  file:write("-- Generated by extract_ascension_minimap.lua\n")
  file:write("-- Date: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
  file:write("\n")
  file:write("if not pfDB then pfDB = {} end\n")
  file:write("pfDB[\"minimap\"] = {\n")
  
  -- Sort areas by ID for consistent output
  local sorted_areas = {}
  for areaID, _ in pairs(minimap_data) do
    table.insert(sorted_areas, areaID)
  end
  table.sort(sorted_areas)
  
  -- Write area data
  local count = 0
  for _, areaID in ipairs(sorted_areas) do
    local data = minimap_data[areaID]
    file:write("  [" .. areaID .. "] = { " .. data.height .. ", " .. data.width .. " }, -- " .. data.areaName .. "\n")
    count = count + 1
  end
  
  file:write("}\n")
  file:close()
  
  print("  SUCCESS: Generated minimap file with " .. count .. " areas")
  return true
end

-- Main execution
function main()
  print("Starting Ascension minimap data extraction...")
  
  -- Load DBC data
  local worldmaparea_data = load_worldmaparea_data()
  if not worldmaparea_data then
    print("ERROR: Failed to load WorldMapArea data")
    return false
  end
  
  local dungeonmap_data = load_dungeonmap_data()
  
  -- Process areas and calculate minimap dimensions
  local minimap_data = {}
  local processed_count = 0
  local skipped_count = 0
  
  print("Processing areas...")
  for areaID, area_data in pairs(worldmaparea_data) do
    local dungeon_fallback = dungeonmap_data[areaID]
    local dimensions = calculate_minimap_dimensions(area_data, dungeon_fallback)
    
    if dimensions then
      minimap_data[areaID] = {
        height = dimensions.height,
        width = dimensions.width,
        areaName = area_data.areaName
      }
      processed_count = processed_count + 1
    else
      skipped_count = skipped_count + 1
    end
  end
  
  print("Processing complete:")
  print("  Processed: " .. processed_count .. " areas")
  print("  Skipped: " .. skipped_count .. " areas")
  
  -- Generate output file
  if processed_count > 0 then
    return generate_minimap_file(minimap_data)
  else
    print("ERROR: No valid minimap data to generate")
    return false
  end
end

-- Run the extraction
if main() then
  print("\nAscension minimap extraction completed successfully!")
  print("Use the generated minimap_ascension.lua file in your pfQuest addon.")
else
  print("\nAscension minimap extraction failed!")
end