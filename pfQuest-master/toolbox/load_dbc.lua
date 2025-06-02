#!/usr/bin/lua

-- Script to load DBC CSV files into acore_world database
luasql = require("luasql.mysql")

-- Helper function to count table elements
function TableCount(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

local env = luasql.mysql()
mysql = env:connect("acore_world", "acore", "acore", "127.0.0.1", 3306)

if not mysql then
  print("ERROR: Failed to connect to database")
  return
end

print("Loading DBC data into acore_world database...")

-- Function to parse CSV line properly
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
      -- Remove quotes and convert commas to dots for decimals
      value = value:gsub('^"', ''):gsub('"$', ''):gsub(',', '.')
      table.insert(values, value)
      start = i + 1
    end

    i = i + 1
  end

  -- Add the last value
  local value = line:sub(start)
  value = value:gsub('^"', ''):gsub('"$', ''):gsub(',', '.')
  table.insert(values, value)

  return values
end

-- Function to read CSV file and create table
function load_dbc_csv(filename, table_name, create_sql, custom_insert)
  print("Processing: " .. filename)

  -- Drop table if exists
  mysql:execute("DROP TABLE IF EXISTS `" .. table_name .. "`")

  -- Create table
  local result = mysql:execute(create_sql)
  if not result then
    print("ERROR: Failed to create table " .. table_name)
    return false
  end

  -- Read CSV file
  local file = io.open(filename, "r")
  if not file then
    print("ERROR: Cannot open file " .. filename)
    return false
  end

  -- Skip header line
  local header = file:read("*line")
  print("  Header: " .. header)

  local count = 0
  for line in file:lines() do
    if line and line ~= "" then
      local values = parse_csv_line(line)

      if #values > 0 then
        local sql
        if custom_insert then
          sql = custom_insert(values)
        else
          -- Standard insert
          local quoted_values = {}
          for _, v in ipairs(values) do
            table.insert(quoted_values, "'" .. v .. "'")
          end
          sql = "INSERT INTO `" .. table_name .. "` VALUES (" .. table.concat(quoted_values, ",") .. ")"
        end

        if sql then
          local result = mysql:execute(sql)
          if result then
            count = count + 1
          else
            print("  ERROR inserting row: " .. line)
          end
        end
      end
    end
  end

  file:close()
  print("  SUCCESS: Loaded " .. count .. " rows into " .. table_name)
  return true
end

-- Create and load AreaTrigger_wotlk
load_dbc_csv("DBC/wotlk/AreaTrigger.dbc.csv", "AreaTrigger_wotlk", [[
  CREATE TABLE `AreaTrigger_wotlk` (
    `ID` int(11) NOT NULL,
    `MapID` int(11) NOT NULL,
    `X` float NOT NULL,
    `Y` float NOT NULL,
    `Z` float NOT NULL,
    `Radius` float NOT NULL,
    `Box_Length` float NOT NULL,
    `Box_Width` float NOT NULL,
    `Box_Height` float NOT NULL,
    `Box_Yaw` float NOT NULL,
    PRIMARY KEY (`ID`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
]])

-- Create and load WorldMapArea_wotlk
load_dbc_csv("DBC/wotlk/WorldMapArea.dbc.csv", "WorldMapArea_wotlk", [[
  CREATE TABLE `WorldMapArea_wotlk` (
    `ID` int(11) NOT NULL,
    `mapID` int(11) NOT NULL,
    `areatableID` int(11) NOT NULL,
    `name` varchar(255) DEFAULT NULL,
    `x_min` float NOT NULL,
    `x_max` float NOT NULL,
    `y_min` float NOT NULL,
    `y_max` float NOT NULL,
    `DisplayMapID` int(11) NOT NULL,
    `DefaultDungeonFloor` int(11) NOT NULL,
    `ParentWorldMapID` int(11) NOT NULL,
    PRIMARY KEY (`ID`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
]])

-- Create and load FactionTemplate_wotlk with custom logic
load_dbc_csv("DBC/wotlk/FactionTemplate.dbc.csv", "FactionTemplate_wotlk", [[
  CREATE TABLE `FactionTemplate_wotlk` (
    `factiontemplateID` int(11) NOT NULL,
    `A` tinyint(1) NOT NULL DEFAULT 0,
    `H` tinyint(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`factiontemplateID`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
]], function(values)
  -- Custom logic for FactionTemplate
  -- values[1] = ID, values[2] = Faction, values[3] = Flags, values[4] = FactionGroup
  local id = values[1]
  local faction_group = tonumber(values[4]) or 0

  local A = 0
  local H = 0

  -- Simple faction logic based on FactionGroup
  if faction_group == 2 or faction_group == 4 then -- Alliance
    A = 1
  elseif faction_group == 3 or faction_group == 5 then -- Horde
    H = 1
  else
    -- Neutral or other
    A = 1
    H = 1
  end

  return "INSERT INTO `FactionTemplate_wotlk` (`factiontemplateID`, `A`, `H`) VALUES ('" .. id .. "', '" .. A .. "', '" .. H .. "')"
end)

-- Simple Lock table (we need to analyze the actual structure)
load_dbc_csv("DBC/wotlk/Lock.dbc.csv", "Lock_wotlk", [[
  CREATE TABLE `Lock_wotlk` (
    `id` int(11) NOT NULL,
    `data` int(11) NOT NULL DEFAULT 0,
    `skill` int(11) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
]], function(values)
  -- Simplified lock logic - just take ID from first column
  local id = values[1]
  return "INSERT INTO `Lock_wotlk` (`id`, `data`, `skill`) VALUES ('" .. id .. "', '0', '0')"
end)

-- Create hybrid table combining AreaTable (hierarchy) + WorldMapArea (coordinates)
function create_enriched_area_table()
  print("Creating enriched area table from AreaTable + WorldMapArea...")

  -- First, create the table structure
  mysql:execute("DROP TABLE IF EXISTS `AreaTable_wotlk_enriched`")
  local create_sql = [[
    CREATE TABLE `AreaTable_wotlk_enriched` (
      `ID` int(11) NOT NULL,
      `MapID_continent` int(11) NOT NULL,
      `ParentZoneID` int(11) NOT NULL,
      `name_loc0` varchar(255) DEFAULT NULL,
      `x_min` float NOT NULL DEFAULT 0,
      `x_max` float NOT NULL DEFAULT 0,
      `y_min` float NOT NULL DEFAULT 0,
      `y_max` float NOT NULL DEFAULT 0,
      PRIMARY KEY (`ID`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  ]]

  local result = mysql:execute(create_sql)
  if not result then
    print("ERROR: Failed to create AreaTable_wotlk_enriched table")
    return false
  end

  -- Load AreaTable data (hierarchy + names)
  local area_data = {}
  local area_file = io.open("DBC/wotlk/enUS/AreaTable.dbc.csv", "r")
  if not area_file then
    print("ERROR: Cannot open AreaTable.dbc.csv")
    return false
  end

  -- Skip header
  local header = area_file:read("*line")
  print("  AreaTable header: " .. header)

  for line in area_file:lines() do
    if line and line ~= "" then
      local values = parse_csv_line(line)
      if #values >= 12 then
        local id = values[1]
        local continent = values[2] or "0"
        local parent = values[3] or "0"
        local name = values[12] or ""
        name = name:gsub("'", "\\'")
        area_data[id] = {continent, parent, name}
      end
    end
  end
  area_file:close()
  print("  Loaded " .. TableCount(area_data) .. " areas from AreaTable")

  -- Load WorldMapArea data (coordinates)
  local wma_data = {}
  local wma_file = io.open("DBC/wotlk/WorldMapArea.dbc.csv", "r")
  if not wma_file then
    print("WARNING: Cannot open WorldMapArea.dbc.csv - coordinates will be 0")
  else
    -- Skip header
    local header = wma_file:read("*line")
    print("  WorldMapArea header: " .. header)

    for line in wma_file:lines() do
      if line and line ~= "" then
        local values = parse_csv_line(line)
        if #values >= 8 then
          local wma_id = values[1]  -- WorldMapArea ID
          local map_id = values[2]  -- Map ID
          local area_id = values[3] -- AreaTable ID
          local loc_left = tonumber(values[5]) or 0
          local loc_right = tonumber(values[6]) or 0
          local loc_top = tonumber(values[7]) or 0
          local loc_bottom = tonumber(values[8]) or 0

          -- Calculate coordinates like bash script
          local x_min = math.min(loc_left, loc_right)
          local x_max = math.max(loc_left, loc_right)
          local y_min = math.min(loc_top, loc_bottom)
          local y_max = math.max(loc_top, loc_bottom)

          wma_data[area_id] = {x_min, x_max, y_min, y_max}
        end
      end
    end
    wma_file:close()
    print("  Loaded " .. TableCount(wma_data) .. " coordinate entries from WorldMapArea")
  end

  -- Combine and insert data
  local count = 0
  for area_id, area_info in pairs(area_data) do
    local continent = area_info[1]
    local parent = area_info[2]
    local name = area_info[3]

    -- Get coordinates if available
    local coords = wma_data[area_id] or {0, 0, 0, 0}
    local x_min, x_max, y_min, y_max = coords[1], coords[2], coords[3], coords[4]

    local sql = "INSERT INTO `AreaTable_wotlk_enriched` (`ID`, `MapID_continent`, `ParentZoneID`, `name_loc0`, `x_min`, `x_max`, `y_min`, `y_max`) VALUES ('" .. area_id .. "', '" .. continent .. "', '" .. parent .. "', '" .. name .. "', '" .. x_min .. "', '" .. x_max .. "', '" .. y_min .. "', '" .. y_max .. "')"

    local result = mysql:execute(sql)
    if result then
      count = count + 1
    else
      print("  ERROR inserting area " .. area_id)
    end
  end

  print("  SUCCESS: Created AreaTable_wotlk_enriched with " .. count .. " entries")
  return true
end

-- Call the function to create enriched table
create_enriched_area_table()

-- Remove the old CSV-based approach (commented out for now)
-- [[
-- Create and load AreaTable_wotlk_enriched with MapID_continent and ParentZoneID
-- load_dbc_csv("DBC/wotlk/enUS/AreaTable.dbc.csv", "AreaTable_wotlk_enriched", [[
--   CREATE TABLE `AreaTable_wotlk_enriched` (
--     `ID` int(11) NOT NULL,
--     `MapID_continent` int(11) NOT NULL,
--     `ParentZoneID` int(11) NOT NULL,
--     `name_loc0` varchar(255) DEFAULT NULL,
--     `x_min` float NOT NULL DEFAULT 0,
--     `x_max` float NOT NULL DEFAULT 0,
--     `y_min` float NOT NULL DEFAULT 0,
--     `y_max` float NOT NULL DEFAULT 0,
--     PRIMARY KEY (`ID`)
--   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
-- ]], function(values)
--   -- values structure from AreaTable.dbc.csv header:
--   -- ID, ContinentID, ParentAreaID, AreaBit, Flags, ..., AreaName_Lang_enUS, ...
--   local id = values[1]
--   local mapid_continent = values[2] or "0"
--   local parent_zone_id = values[3] or "0"
--   local name = values[12] or ""
--   name = name:gsub("'", "\\'") -- Escape quotes
--
--   -- For AreaTable, we don't have coordinate fields like WorldMapArea
--   -- Set default coordinates (will be 0,0,0,0)
--   local x_min = 0
--   local x_max = 0
--   local y_min = 0
--   local y_max = 0
--
--   return "INSERT INTO `AreaTable_wotlk_enriched` (`ID`, `MapID_continent`, `ParentZoneID`, `name_loc0`, `x_min`, `x_max`, `y_min`, `y_max`) VALUES ('" .. id .. "', '" .. mapid_continent .. "', '" .. parent_zone_id .. "', '" .. name .. "', '" .. x_min .. "', '" .. x_max .. "', '" .. y_min .. "', '" .. y_max .. "')"
-- end)
-- ]]

-- Create and load AreaTable_wotlk (keep original for backward compatibility)
load_dbc_csv("DBC/wotlk/enUS/AreaTable.dbc.csv", "AreaTable_wotlk", [[
  CREATE TABLE `AreaTable_wotlk` (
    `id` int(11) NOT NULL,
    `name_loc0` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
]], function(values)
  -- values[1] = ID, values[2] = Name
  local id = values[1]
  local name = values[2] or ""
  name = name:gsub("'", "\\'") -- Escape quotes
  return "INSERT INTO `AreaTable_wotlk` (`id`, `name_loc0`) VALUES ('" .. id .. "', '" .. name .. "')"
end)

-- Create and load SkillLine_wotlk
load_dbc_csv("DBC/wotlk/enUS/SkillLine.dbc.csv", "SkillLine_wotlk", [[
  CREATE TABLE `SkillLine_wotlk` (
    `id` int(11) NOT NULL,
    `name_loc0` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
]], function(values)
  -- values[1] = ID, values[2] = Name
  local id = values[1]
  local name = values[2] or ""
  name = name:gsub("'", "\\'") -- Escape quotes
  return "INSERT INTO `SkillLine_wotlk` (`id`, `name_loc0`) VALUES ('" .. id .. "', '" .. name .. "')"
end)

mysql:close()
env:close()
print("DBC data loading completed!")
print("")
print("Now you can run: lua extractor.lua")
