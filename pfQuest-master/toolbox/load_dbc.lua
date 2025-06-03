#!/usr/bin/lua

-- Script to load DBC CSV files into acore_world database
luasql = require("luasql.mysql")

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

-- WorldMapOverlay_wotlk (аналогично bash-версии)
load_dbc_csv("DBC/wotlk/WorldMapOverlay.dbc.csv", "WorldMapOverlay_wotlk", [[
  CREATE TABLE `WorldMapOverlay_wotlk` (
    `areaID` int(11) NOT NULL,
    `zoneID` int(11) NOT NULL,
    `texture` varchar(255) DEFAULT NULL,
    `textureWidth` int(11) DEFAULT NULL,
    `textureHeight` int(11) DEFAULT NULL,
    `offsetX` int(11) DEFAULT NULL,
    `offsetY` int(11) DEFAULT NULL,
    `hitRectTop` int(11) DEFAULT NULL,
    `hitRectLeft` int(11) DEFAULT NULL,
    `hitRectBottom` int(11) DEFAULT NULL,
    `hitRectRight` int(11) DEFAULT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
]], function(values)
      local areaID = values[3]
      local zoneID = values[2]
      local texture = values[9] or ""
      local textureWidth = values[10] or "0"
      local textureHeight = values[11] or "0"
      local offsetX = values[12] or "0"
      local offsetY = values[13] or "0"
      local hitRectTop = values[14] or "0"
      local hitRectLeft = values[15] or "0"
      local hitRectBottom = values[16] or "0"
      local hitRectRight = values[17] or "0"
      texture = texture:gsub("'", "\\'")
      return "INSERT INTO `WorldMapOverlay_wotlk` (`areaID`, `zoneID`, `texture`, `textureWidth`, `textureHeight`, `offsetX`, `offsetY`, `hitRectTop`, `hitRectLeft`, `hitRectBottom`, `hitRectRight`) VALUES ('" .. areaID .. "', '" .. zoneID .. "', '" .. texture .. "', '" .. textureWidth .. "', '" .. textureHeight .. "', '" .. offsetX .. "', '" .. offsetY .. "', '" .. hitRectTop .. "', '" .. hitRectLeft .. "', '" .. hitRectBottom .. "', '" .. hitRectRight .. "')"
    end)

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

-- AreaTable_wotlk (минимально нужное: id, zoneID, name_loc0)
load_dbc_csv("DBC/wotlk/enUS/AreaTable.dbc.csv", "AreaTable_wotlk", [[
  CREATE TABLE `AreaTable_wotlk` (
    `id` int(11) NOT NULL,
    `zoneID` int(11) DEFAULT NULL,
    `mapID` int(11) DEFAULT NULL,
    `name_loc0` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
]], function(values)
  -- values[1]=ID, [2]=ContinentID(mapID), [3]=ParentAreaID(zoneID), [12]=AreaName_Lang_enUS
  local id = values[1]
  local mapID = values[2]
  local zoneID = values[3]
  local name = values[12] or ""
  name = name:gsub("'", "\\'")
  return "INSERT INTO `AreaTable_wotlk` (`id`, `zoneID`, `mapID`, `name_loc0`) VALUES ('" .. id .. "', '" .. zoneID .. "', '" .. mapID .. "', '" .. name .. "')"
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
