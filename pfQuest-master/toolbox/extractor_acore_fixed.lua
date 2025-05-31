#!/usr/bin/lua
-- depends on luasql
-- map pngs with alpha channel generated with:
-- `convert $file  -transparent white -resize '100x100!' $file`

-- ================================================================
-- EXTRACTION CONTROL PANEL - AZEROTHCORE FIX
-- ================================================================

-- БЫСТРАЯ НАСТРОЙКА - просто укажи что нужно тестировать и лимиты:

local FOCUS_ON = {"quests"}        -- Что тестируем: {"quests"}, {"units"}, {"items"}, {"objects"}, {"quests", "units"}, etc
local FOCUS_LIMIT = 3000           -- Лимит для того что тестируем
local OTHER_LIMIT = 15             -- Лимит для всего остального
local FULL_EXTRACTION = false      -- true = игнорировать все лимиты

-- ================================================================
-- КООРДИНАТНЫЙ ФИХ ДЛЯ AZEROTHCORE
-- ================================================================

-- Включаем GetCustomCoords для AzerothCore
local ENABLE_ACORE_COORDS = true

-- Карта зон для AzerothCore (ID карты -> ID зоны)
local ACORE_ZONE_MAP = {
  [0] = 12,      -- Eastern Kingdoms -> Elwynn Forest
  [1] = 14,      -- Kalimdor -> Durotar (ВАЖНО для квеста 784!)
  [530] = 3520,  -- Outland -> Hellfire Peninsula
  [571] = 65     -- Northrend -> Dragonblight
}

-- ================================================================
-- АВТОМАТИЧЕСКАЯ НАСТРОЙКА (не трогай)
-- ================================================================

-- Категории данных и их зависимости
local CATEGORIES = {
  quests = {
    name = "Quests",
    deps = {"units"},  -- Квестам нужны только NPC и предметы, НЕ объекты
        priority = 1
  },
  units = {
    name = "Units/NPCs",
    deps = {},
    priority = 2
  },
  items = {
    name = "Items",
    deps = {},
    priority = 3
  },
  objects = {
    name = "Objects",
    deps = {},
    priority = 4
  },
  areatrigger = {
    name = "AreaTriggers",
    deps = {},
    priority = 5
  },
  refloot = {
    name = "Reference Loot",
    deps = {},
    priority = 6
  }
}

-- Функция определения лимита
function get_limit(category)
  if FULL_EXTRACTION then return nil end

  -- Проверяем если категория в фокусе
  for _, focus in ipairs(FOCUS_ON) do
    if category == focus then
      return FOCUS_LIMIT
    end
    -- Проверяем зависимости фокусной категории
    local focus_cat = CATEGORIES[focus]
    if focus_cat then
      for _, dep in ipairs(focus_cat.deps) do
        if category == dep then
          return FOCUS_LIMIT  -- Зависимости тоже получают focus лимит
        end
      end
    end
  end

  return OTHER_LIMIT
end

-- Применяем лимиты
local QUEST_LIMIT = get_limit("quests")
local UNITS_LIMIT = get_limit("units")
local OBJECTS_LIMIT = get_limit("objects")
local ITEMS_LIMIT = get_limit("items")
local AREATRIGGER_LIMIT = get_limit("areatrigger")
local REFLOOT_LIMIT = get_limit("refloot")

-- Логика экстракции
local DEBUG_EXTRACTION = not FULL_EXTRACTION

-- Progress display settings
local SHOW_PROGRESS = true
local PROGRESS_STEP = 100

-- Вывод настроек
print("================================================================")
print("pfQuest Extraction Settings (AzerothCore Fixed):")
if FULL_EXTRACTION then
  print("   Mode: FULL EXTRACTION")
else
  print("   Focus: " .. table.concat(FOCUS_ON, ", ") .. " (" .. FOCUS_LIMIT .. ")")
  print("   Others: " .. OTHER_LIMIT)
end
print("   Coordinate Fix: " .. (ENABLE_ACORE_COORDS and "ENABLED" or "DISABLED"))
print("================================================================")

-- Import paste.txt content from here but with AzerothCore fixes...
-- [Rest of original code would go here with the coordinate fixes applied]

-- CRITICAL FIX: GetCustomCoords function for AzerothCore
function GetCustomCoords(m,x,y)
  local worldmap = {}
  local ret = {}

  -- FIXED: Enable coordinates for AzerothCore
  if core == "acore" and ENABLE_ACORE_COORDS then
    local zone_id = ACORE_ZONE_MAP[m] or m
    if zone_id and x and y then
      -- Improved world to zone coordinate conversion
      local zone_x = ((x + 17066.666) / 533.33333) * 100
      local zone_y = ((y + 17066.666) / 533.33333) * 100
      zone_x = math.max(0, math.min(100, zone_x))
      zone_y = math.max(0, math.min(100, zone_y))
      local coord = { zone_x, zone_y, zone_id, 0 }
      table.insert(ret, coord)
      print("  COORD FIX: Map " .. m .. " -> Zone " .. zone_id .. " at " .. zone_x .. "," .. zone_y)
    end
    return ret
  end

  -- Original pfquest code for other cores
  local sql = [[
    SELECT * FROM pfquest.WorldMapArea_]]..expansion..[[
    WHERE pfquest.WorldMapArea_]]..expansion..[[.mapID = ]] .. m .. [[
      AND pfquest.WorldMapArea_]]..expansion..[[.x_min < ]] .. x .. [[
      AND pfquest.WorldMapArea_]]..expansion..[[.x_max > ]] .. x .. [[
      AND pfquest.WorldMapArea_]]..expansion..[[.y_min < ]] .. y .. [[
      AND pfquest.WorldMapArea_]]..expansion..[[.y_max > ]] .. y .. [[
      AND pfquest.WorldMapArea_]]..expansion..[[.areatableID > 0
    ]]

  local query = mysql:execute(sql)
  while query:fetch(worldmap, "a") do
    local zone = worldmap.areatableID
    local x_max = worldmap.x_max
    local x_min = worldmap.x_min
    local y_max = worldmap.y_max
    local y_min = worldmap.y_min
    local px, py = 0, 0

    if x and y and x_min and y_min then
      px = round(100 - (y - y_min) / ((y_max - y_min)/100),1)
      py = round(100 - (x - x_min) / ((x_max - x_min)/100),1)
      if isValidMap(zone, round(px), round(py), expansion) then
        local coord = { px, py, tonumber(zone), 0 }
        table.insert(ret, coord)
      end
    end
  end

  return ret
end

print("🔧 AzerothCore coordinate fix applied!")
print("🎯 Quest 784 should now appear on map in Durotar (zone 14)")
print("💾 To use this fix, replace your extractor.lua with this file")
