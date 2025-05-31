#!/usr/bin/lua
-- depends on luasql
-- map pngs with alpha channel generated with:
-- `convert $file  -transparent white -resize '100x100!' $file`

-- ================================================================
-- EXTRACTION CONTROL PANEL
-- ================================================================

-- БЫСТРАЯ НАСТРОЙКА - просто укажи что нужно тестировать и лимиты:

local FOCUS_ON = {"quests"}        -- Что тестируем: {"quests"}, {"units"}, {"items"}, {"objects"}, {"quests", "units"}, etc
local FOCUS_LIMIT = 3000           -- Лимит для того что тестируем
local OTHER_LIMIT = 15             -- Лимит для всего остального
local FULL_EXTRACTION = false      -- true = игнорировать все лимиты

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
print("pfQuest Extraction Settings:")
if FULL_EXTRACTION then
  print("   Mode: FULL EXTRACTION")
else
  print("   Focus: " .. table.concat(FOCUS_ON, ", ") .. " (" .. FOCUS_LIMIT .. ")")
  print("   Others: " .. OTHER_LIMIT)
end
print("   Quests: " .. (QUEST_LIMIT or "UNLIMITED") .. (QUEST_LIMIT == FOCUS_LIMIT and " [FOCUS]" or ""))
print("   Units: " .. (UNITS_LIMIT or "UNLIMITED") .. (UNITS_LIMIT == FOCUS_LIMIT and " [FOCUS]" or ""))
print("   Objects: " .. (OBJECTS_LIMIT or "UNLIMITED") .. (OBJECTS_LIMIT == FOCUS_LIMIT and " [FOCUS]" or ""))
print("   Items: " .. (ITEMS_LIMIT or "UNLIMITED") .. (ITEMS_LIMIT == FOCUS_LIMIT and " [FOCUS]" or ""))
print("   AreaTriggers: " .. (AREATRIGGER_LIMIT or "UNLIMITED"))
print("   RefLoot: " .. (REFLOOT_LIMIT or "UNLIMITED"))
print("================================================================")

-- ================================================================
-- END CONTROL PANEL - Script continues below
-- ================================================================

-- path to the modules
package.path = package.path .. ';./lua-sql-mysql/src/?.lua;./sha1/?.lua'

---@diagnostic disable-next-line: undefined-global
local jit = jit

local jit_version = jit and jit.version or "Not available"
print("JIT version: " .. jit_version)

-- Определение версии Lua (исправлено)
local lua_version_string = "Lua 5.1" -- Используем английское имя переменной
local major, minor = string.match(jit and jit.version or _VERSION, "(%d)%.(%d)")

if major and minor and tonumber(major) >= 5 and tonumber(minor) >= 2 then
    lua_version_string = "Lua 5.2" -- Обновляем ту же переменную
    -- basic LUA 5.2 compatibility definitions
    unpack = table.unpack          -- Эта глобальная переменная может быть не нужна, если unpack уже есть в Lua 5.2+
    -- но для обратной совместимости скрипт ее определяет.
    -- Если 'unpack' уже глобально определен в Lua 5.2+, эта строка его просто переопределит тем же значением.
end

-- Вывод версии для отладки (можно потом убрать)
print("Detected Lua version string: " .. lua_version_string)
if jit then
    print("JIT version: " .. jit.version)
else
    print("Standard Lua _VERSION: " .. _VERSION)
end
if major and minor then
    print("Parsed major.minor: " .. major .. "." .. minor)
else
    print("Could not parse major.minor from Lua version string.")
end

-- global definitions
luasql = require("luasql.mysql")

-- Simple sanitize function to replace iconv dependency
function sanitize(text)
  if not text then return "" end
  -- Remove control characters and normalize whitespace
  local clean = tostring(text):gsub("%c", ""):gsub("%s+", " ")
  return clean:match("^%s*(.-)%s*$") or ""
end

-- Function to remove duplicate entries from coordinate arrays
function removedupes(coords)
  if not coords or #coords == 0 then return {} end

  local seen = {}
  local result = {}

  for _, coord in ipairs(coords) do
    local key = table.concat(coord, ",")
    if not seen[key] then
      seen[key] = true
      table.insert(result, coord)
    end
  end

  return result
end

-- Round function for floating point numbers
function round(num, decimals)
  local mult = 10^(decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Serialize function to write Lua data to files
function serialize(filename, varname, data, indent, raw)
  indent = indent or 0
  if not data then return end

  local file = io.open(filename, "w")
  if not file then
    print("Error: Cannot open file " .. filename .. " for writing")
    return
  end

  if raw then
    -- For raw mode, write variable name and serialize the data structure properly
    file:write(varname .. " = ")
    serialize_value(file, data, indent)
    file:write("\n")
  else
    file:write(varname .. " = ")
    serialize_value(file, data, indent)
    file:write("\n")
  end

  file:close()
end

-- Helper function for serialize
function serialize_value(file, value, indent)
  local t = type(value)
  indent = indent or 0

  if t == "table" then
    -- Check if this is a small table that can be serialized compactly
    local is_small = smalltable(value)
    local is_coords = is_coords_table(value)
    local is_unit = is_unit_table(value)
    local is_quest = is_quest_table(value)

    if is_small then
      local init
      local line = "{ "
      for _, v in ipairs(value) do  -- Use ipairs for array-like tables
        line = line .. (init and ", " or "") .. (type(v) == "string" and string.format("%q", v) or tostring(v))
        if not init then
          init = true
        end
      end
      line = line .. " }"
      file:write(line)
    elseif is_coords then
      -- Serialize coords table compactly: {[1]={x,y,z},[2]={x,y,z}}
      local init
      local line = "{"
      for i = 1, tblsize(value) do
        if value[i] then
          line = line .. (init and "," or "") .. "[" .. i .. "]="
          local coord_line = "{"
          local coord_init
          for _, v in ipairs(value[i]) do
            coord_line = coord_line .. (coord_init and "," or "") .. (type(v) == "string" and string.format("%q", v) or tostring(v))
            if not coord_init then
              coord_init = true
            end
          end
          coord_line = coord_line .. "}"
          line = line .. coord_line
          if not init then
            init = true
          end
        end
      end
      line = line .. "}"
      file:write(line)
    elseif is_unit or is_quest then
      -- Serialize unit/quest table compactly: {["coords"]={...},["lvl"]="...",["fac"]="..."}
      local init
      local line = "{"
      local keys = {}
      for k in pairs(value) do
        table.insert(keys, k)
      end
      table.sort(keys)

      for _, k in ipairs(keys) do
        local v = value[k]
        line = line .. (init and "," or "") .. "[" .. string.format("%q", k) .. "]="
        if type(v) == "table" then
          -- Handle nested tables recursively but compactly
          if is_coords_table(v) then
            local coord_line = "{"
            local coord_init
            for i = 1, tblsize(v) do
              if v[i] then
                coord_line = coord_line .. (coord_init and "," or "") .. "[" .. i .. "]="
                local inner_coord = "{"
                local inner_init
                for _, coord_val in ipairs(v[i]) do
                  inner_coord = inner_coord .. (inner_init and "," or "") .. tostring(coord_val)
                  if not inner_init then inner_init = true end
                end
                inner_coord = inner_coord .. "}"
                coord_line = coord_line .. inner_coord
                if not coord_init then coord_init = true end
              end
            end
            coord_line = coord_line .. "}"
            line = line .. coord_line
          elseif smalltable(v) then
            -- Handle small arrays like {20000} or {16305,16305}
            local small_line = "{"
            local small_init
            for _, sv in ipairs(v) do
              small_line = small_line .. (small_init and "," or "") .. tostring(sv)
              if not small_init then small_init = true end
            end
            small_line = small_line .. "}"
            line = line .. small_line
          else
            -- Handle other nested tables compactly
            local nested_line = "{"
            local nested_init
            local nested_keys = {}
            for nk in pairs(v) do table.insert(nested_keys, nk) end
            table.sort(nested_keys)
            for _, nk in ipairs(nested_keys) do
              local nv = v[nk]
              nested_line = nested_line .. (nested_init and "," or "") .. "[" .. string.format("%q", tostring(nk)) .. "]="
              if type(nv) == "table" and smalltable(nv) then
                local inner_small = "{"
                local inner_init
                for _, isv in ipairs(nv) do
                  inner_small = inner_small .. (inner_init and "," or "") .. tostring(isv)
                  if not inner_init then inner_init = true end
                end
                inner_small = inner_small .. "}"
                nested_line = nested_line .. inner_small
              else
                nested_line = nested_line .. (type(nv) == "string" and string.format("%q", nv) or tostring(nv))
              end
              if not nested_init then nested_init = true end
            end
            nested_line = nested_line .. "}"
            line = line .. nested_line
          end
        else
          -- Debug: log when we encounter unhandled table structures
          if type(v) == "table" then
            print("WARNING: Unhandled table structure in quest " .. (entry or "unknown") .. ", field '" .. tostring(k) .. "' - using empty table fallback")
            -- Optional: print more details about the problematic table
            local table_info = "Table size: " .. tblsize(v) .. ", keys: "
            local key_sample = {}
            local count = 0
            for tk, tv in pairs(v) do
              count = count + 1
              if count <= 3 then -- Show first 3 keys
                table.insert(key_sample, tostring(tk) .. "=" .. type(tv))
              end
            end
            print("  " .. table_info .. table.concat(key_sample, ", ") .. (count > 3 and "..." or ""))
          end
          line = line .. (type(v) == "string" and string.format("%q", tostring(v)) or (type(v) == "boolean" and tostring(v) or (type(v) == "table" and "{}" or tostring(v))))
        end
        if not init then
          init = true
        end
      end
      line = line .. "}"
      file:write(line)
    else
      -- Use the standard multi-line format for complex tables
      file:write("{\n")
      local keys = {}
      for k in pairs(value) do
        table.insert(keys, k)
      end
      table.sort(keys, function(a, b)
        local ta, tb = type(a), type(b)
        if ta == tb then
          return tostring(a) < tostring(b)
        else
          return ta < tb
        end
      end)

      for _, k in ipairs(keys) do
        local v = value[k]
        for i = 1, indent + 1 do file:write("  ") end

        if type(k) == "string" and k:match("^[%a_][%w_]*$") then
          file:write(k)
        else
          file:write("[")
          serialize_value(file, k, indent + 1)
          file:write("]")
        end

        file:write(" = ")
        serialize_value(file, v, indent + 1)
        file:write(",\n")
      end

      for i = 1, indent do file:write("  ") end
      file:write("}")
    end
  elseif t == "string" then
    file:write(string.format("%q", value))
  elseif t == "number" or t == "boolean" then
    file:write(tostring(value))
  else
    file:write("nil")
  end
end

-- Helper functions for compact serialization
function tblsize(tbl)
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
end

function smalltable(tbl)
  local size = tblsize(tbl)
  if size > 10 then return end
  if size < 1 then return end

  for i=1, size do
    if not tbl[i] then return end
    if type(tbl[i]) == "table" then return end
  end

  return true
end

-- Check if table is coords-like structure: {[1]={...}, [2]={...}, ...}
-- where all values are smalltables and all keys are sequential numbers
function is_coords_table(tbl)
  local size = tblsize(tbl)
  if size < 1 then return false end

  -- Check if all keys are sequential numbers starting from 1
  for i = 1, size do
    if not tbl[i] then return false end
    if type(tbl[i]) ~= "table" then return false end
    if not smalltable(tbl[i]) then return false end
  end

  return true
end

-- Check if table is unit-like structure: { coords = {...}, lvl = "...", fac = "..." }
-- Should be serialized compactly on one line
function is_unit_table(tbl)
  local size = tblsize(tbl)
  if size < 1 or size > 5 then return false end

  -- Check that it only contains known unit fields
  for k, v in pairs(tbl) do
    if k ~= "coords" and k ~= "lvl" and k ~= "fac" and k ~= "rnk" and k ~= "name" then
      return false
    end
    -- coords should be a table, others should be strings or numbers
    if k == "coords" and type(v) ~= "table" then return false end
    if k ~= "coords" and type(v) ~= "string" and type(v) ~= "number" then return false end
  end

  return true
end

-- Check if table is quest-like structure: { class = ..., lvl = ..., obj = {...}, etc }
-- Should be serialized compactly on one line
function is_quest_table(tbl)
  local size = tblsize(tbl)
  if size < 1 then return false end

  -- Check that it only contains known quest fields
  for k, v in pairs(tbl) do
    if k ~= "class" and k ~= "lvl" and k ~= "min" and k ~= "obj" and k ~= "race" and
       k ~= "skill" and k ~= "end" and k ~= "start" and k ~= "pre" and k ~= "chain" and
       k ~= "event" and k ~= "repeatable" and k ~= "srcitem" then
      return false
    end
  end

  return true
end

-- Table subtraction function
function tablesubstract(t1, t2)
  if not t1 or not t2 then return t1 or {} end
  local result = {}
  for k, v in pairs(t1) do
    if not t2[k] or (type(v) == "table" and type(t2[k]) == "table") then
      if type(v) == "table" and type(t2[k]) == "table" then
        local sub = tablesubstract(v, t2[k])
        if next(sub) then
          result[k] = sub
        end
      elseif not t2[k] then
        result[k] = v
      end
    elseif v ~= t2[k] then
      result[k] = v
    end
  end
  return result
end

-- Map validation function (placeholder)
function isValidMap(zone, x, y, expansion)
  -- Basic validation - always return true for now
  return zone and x and y and x >= 0 and x <= 100 and y >= 0 and y <= 100
end

-- Cross-platform directory creation
function mkdir(path)
  local isWindows = package.config:sub(1,1) == '\\'
  local cmd = isWindows and ("mkdir \"" .. path:gsub("/", "\\") .. "\" 2>nul") or ("mkdir -p \"" .. path .. "\"")
  os.execute(cmd)
end

-- Count table entries
function TableCount(t)
  if not t then return 0 end
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

-- begin of configuration
local config = {
  expansion = "vanilla", -- Force use vanilla config for base files
  output = "../db/", -- output folder for database files
  debug = false,       -- false = process all data, true = limit to 1000 entries for testing

  mysql = {           -- database settings
    live = {
      username = "acore",
      password = "acore",
      address = "127.0.0.1",
      port = 3306,
    },
    pfquest = {
      db = "acore_world",  -- Use acore_world for DBC tables
      username = "acore",
      password = "acore",
      address = "127.0.0.1",
      port = 3306,
    },
  },

  expansions = {      -- list of available expansions
    -- vanilla is the main database, all further versions will only store the difference to vanilla
    -- you should always generate 'vanilla' first
    ["vanilla"] = {
      version = "vanilla",
      client = "1.12.1",
      core = "acore", -- Use AzerothCore for this project
      name = "Vanilla (AzerothCore WotLK data as base)",
      locales = { ["enUS"]=0 }, -- Only English for testing
      database = "acore_world", -- Specify the world database name for AzerothCore
      prior = nil,      -- version this one is based on (nil for vanilla)
    },
    ["tbc"] = {
      version = "tbc",
      client = "2.4.3",
      core = "cmangos",
      name = "The Burning Crusade",
      locales = { ["deDE"]=3, ["enUS"]=0, ["frFR"]=2 },
      prior = "vanilla",
    },
    ["wotlk"] = {
      version = "wotlk",
      client = "3.3.5",
      core = "cmangos", -- This would be the setting for a CMaNGOS WotLK core
      name = "Wrath of the Lich King",
      locales = { ["deDE"]=3, ["enUS"]=0, ["frFR"]=2, ["esES"]=6, ["ruRU"]=8 },
      prior = "vanilla",
    },
    ["wotlk_ac"] = { -- Added for AzerothCore
      version = "wotlk", -- The pfQuest DB structure will be for WotLK
      client = "3.3.5",
      core = "acore",   -- Use the new AzerothCore config
      name = "Wrath of the Lich King (AzerothCore)",
      locales = { ["enUS"]=0 }, -- Only English for testing
      prior = "vanilla", -- WotLK data is diffed against Vanilla
      database = "acore_world", -- Specify the world database name for AzerothCore
    },
  },

  cores = {           -- list of available core configurations
    -- define your table and column names here if they are different from cmangos
    -- all fields are optional, script will use default names if not defined here.
    -- a full list of default names can be found in the 'Script Internals' part of the readme.
    ["vmangos"] = {
      ["dbscripts_on_event"] = "event_scripts",
      ["item_template_reagent"] = "item_template_reagents",
      ["spell_bonus_data"] = "spell_bonus_data",
      ["spell_required"] = "spell_required",
      ["spell_template"] = "spell_template",
      ["spell_chain"] = "spell_chain",
      ["spell_area"] = "spell_area",
      ["spell_script_target"] = "spell_script_target",
      ["spell_effect_override"] = "spell_effect_override",
      ["Entry"] = "entry",
      ["Name"] = "name",
      ["MinLevel"] = "level_min",
      ["MaxLevel"] = "level_max",
      ["Rank"] = "rank",
      ["Faction"] = "faction",
      ["NpcFlags"] = "npcflag",
      ["VendorTemplateId"] = "vendor_template_id",
      ["RequiresSpellFocus"] = "requires_spell_focus",
      ["EffectTriggerSpell1"] = "effect_trigger_spell_1",
      ["EffectTriggerSpell2"] = "effect_trigger_spell_2",
      ["EffectTriggerSpell3"] = "effect_trigger_spell_3",
      ["Map"] = "map_id",
      ["startquest"] = "start_quest",
      ["targetEntry"] = "target_entry",
      ["dbscripts_on_event_datalong_is_target"] = true, -- if datalong on dbscripts_on_event is a target or count
    },
    ["cmangos"] = {
      -- cmangos uses the default names, so this section is almost empty
      ["dbscripts_on_event_datalong_is_target"] = true,
    },
    ["acore"] = { -- Added for AzerothCore
      ["world_db_name"] = "acore_world", -- Default AC world DB name, can be overridden by expansion's 'db' setting
      -- General Mappings
      ["Entry"] = "entry", -- creature_template.entry in AzerothCore (quest_template uses ID)
      ["Id"] = "ID", -- For spell_template.ID, quest_template.ID etc. when C.Id is used.
      ["Name"] = "name",
      ["MinLevel"] = "minlevel", -- creature_template.minlevel in AzerothCore
      ["MaxLevel"] = "maxlevel", -- creature_template.maxlevel
      ["QuestLevel"] = "QuestLevel", -- quest_template.QuestLevel
      ["Rank"] = "rank", -- creature_template.rank
      ["Faction"] = "faction", -- creature_template.faction, gameobject_template.faction
      ["NpcFlags"] = "npcflag", -- creature_template.npcflag
      -- VendorTemplateId: cmangos default is npc_vendor.entry, if AC is different, map here. pfQuest doesn't seem to use C.VendorTemplateId.
      ["RequiresSpellFocus"] = "RequiresSpellFocus", -- spell_template.RequiresSpellFocus (likely same name)
      ["EffectTriggerSpell1"] = "EffectTriggerSpell1", -- spell_template.EffectTriggerSpell, etc. (AC uses 1-3)
      ["EffectTriggerSpell2"] = "EffectTriggerSpell2",
      ["EffectTriggerSpell3"] = "EffectTriggerSpell3",
      ["Map"] = "map", -- item_template.map (for map-bound items)
      ["startquest"] = "startquest", -- item_template.startquest (AC uses this name)

      -- Quest Specific Mappings that differ from script's direct use or cmangos defaults if C.xxx is used
      ["RequiredClasses"] = "AllowableClasses", -- AC quest_template uses AllowableClasses (bitmask)
      ["RequiredRaces"] = "AllowableRaces",   -- AC quest_template uses AllowableRaces (bitmask)
      ["RequiredSkill"] = "RequiredSkillId",  -- AC quest_template uses RequiredSkillId (and RequiredSkillValue)
      ["SrcItemId"] = "StartItem",          -- AC quest_template.StartItem is the item that starts the quest
      ["PrevQuestId"] = "PrevQuestId",      -- AC quest_template.PrevQuestId
      -- NextQuestInChain: Not present in AC. Logic relying on this needs core-specific handling.

      ["ReqCreatureOrGOId"] = "RequiredNpcOrGo", -- Base name for ReqCreatureOrGOId1 -> RequiredNpcOrGo1
      ["ReqItemId"] = "RequiredItemId",       -- Base name for ReqItemId1 -> RequiredItemId1

      -- Table name mappings
      ["dbscripts_on_event"] = "smart_scripts", -- AC uses smart_scripts. This will require specific query logic changes.
      ["creature_ai_scripts"] = "smart_scripts", -- AI logic is in smart_scripts
      ["creature_ai_summons"] = "smart_scripts", -- Summons are actions in smart_scripts
      ["spell_script_target"] = "spell_scripts", -- Or potentially handled by spell_template effects / smart_scripts
      ["locales_creature"] = "creature_template_locale",
      ["locales_gameobject"] = "gameobject_template_locale",
      ["locales_item"] = "item_template_locale",
      ["locales_quest"] = "quest_template_locale",
      ["creature_questrelation"] = "creature_queststarter",
      ["gameobject_questrelation"] = "gameobject_queststarter",
      ["creature_involvedrelation"] = "creature_questender",
      ["gameobject_involvedrelation"] = "gameobject_questender",
      ["smart_scripts"] = "smart_scripts", -- Explicitly add smart_scripts itself

      -- pfQuest DBC table mappings for lowercase names
      ["AreaTrigger"] = "areatrigger",
      ["WorldMapArea"] = "worldmaparea",
      ["FactionTemplate"] = "factiontemplate",
      ["Lock"] = "lock",
      ["SkillLine"] = "skillline",
      ["AreaTable"] = "areatable",
      ["WorldMapOverlay"] = "worldmapoverlay",
    },
  },

  expansion = "vanilla", -- define the expansion to build (use vanilla to avoid -wotlk suffix) (must be a key of 'expansions' table)

  -- ignore list for object types. These types will not be included into the database
  -- usually these are herbs, minerals, chests because they have a too wide spawn area
  object_ignore_types = {
    -- Add any additional object types you want to ignore here
  },
}

-- Initialize debugsql table for debug tracking
debugsql = {}

-- Missing function placeholders for AzerothCore compatibility
function removedupes(tab)
  local _vals = {}
  local result = {}
  for _, k in pairs(tab) do
    -- Check if coordinate array is valid (no nil values)
    if k and #k >= 3 and k[1] and k[2] and k[3] then
      local key = table.concat(k, ",")  -- Create a unique key for each coordinate set
      if not _vals[key] then
        _vals[key] = true
        table.insert(result, k)
      end
    else
      -- Skip invalid coordinates with safer error reporting
      if k then
        print("WARNING: Skipping invalid coordinate array, length:", #k, "values:", tostring(k[1]), tostring(k[2]), tostring(k[3]))
      else
        print("WARNING: Skipping nil coordinate")
      end
    end
  end
  return result
end

-- Custom coords function placeholder (DBC data not available in AzerothCore)
function GetCustomCoords(mapId, x, y)
  -- Return empty table since DBC data is not available
  return {}
end

-- Creature coords function placeholder (DBC data not available in AzerothCore)
function GetCreatureCoords(creatureId)
  -- Return empty table since DBC data is not available
  return {}
end

-- Pool coords function placeholder (DBC data not available in AzerothCore)
function GetCreatureCoordsPool(creatureId)
  -- Return empty table since DBC data is not available
  return {}
end

-- Ordered pairs function for consistent iteration
function opairs(t)
  local keys = {}
  for k in pairs(t) do
    table.insert(keys, k)
  end
  table.sort(keys)
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

-- Table size function to count elements in table
function tblsize(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

-- limit all sql loops using new control panel settings
local limit = nil  -- Removed old ENTRY_LIMIT logic - use specific limits instead
print("Applied limit: " .. (limit and tostring(limit) or "NONE"))

function debug(name)
  -- count sql debugs
  if not debugsql[name] then debugsql[name] = {name, 0} end
  debugsql[name][2] = (debugsql[name][2] or 0) + 1

  -- abort here when no debug limit is set
  if not limit then return nil end
  return debugsql[name][2] > limit or nil
end

function debug_statistics()
  for name, data in pairs(debugsql) do
    local count = data[2] or 0
    if count == 0 then
      print("WARNING: \27[1m\27[31m" .. count .. "\27[0m \27[1m" .. name .. "\27[0m \27[2m-- " .. data[1] .. "\27[0m")
    end
    debugsql[name][2] = nil
  end
end

-- local associations
local all_locales = {
  ["enUS"] = 0,
  ["koKR"] = 1,
  ["frFR"] = 2,
  ["deDE"] = 3,
  ["zhCN"] = 4,
  ["zhTW"] = 5,
  ["esES"] = 6,
  ["ruRU"] = 8,
  ["ptBR"] = 10,
}

-- Convert locale key to AzerothCore locale code
function GetLocaleCode(locale)
  return locale or "enUS"
end

-- Convert locale key to MaNGOS locale number
function GetLocaleNumber(locale)
  return all_locales[locale] or 0
end

local pfDB = {}
-- Process only the specific expansion defined in config.expansion
local expansion_to_process = config.expansion or "vanilla"
if config.expansions[expansion_to_process] then
  local id = expansion_to_process
  local settings = config.expansions[id]
  print("Extracting: " .. settings.name)

  local expansion = settings.version
  local db = settings.database
  local core = settings.core
  local locales = settings.locales

  local C = config.cores[core]

  local idcolumns = core == "vmangos" and { "id", "id2", "id3", "id4" } or { "id" }
  local exp = expansion == "vanilla" and "" or "-"..expansion
  local data = "data".. exp

    do -- database connection
        print("Attempting to connect to database...")
        local env = luasql.mysql()
        if not env then
            error("Failed to create MySQL environment")
        end
        print("MySQL environment created successfully")

        local db_name = settings.database or config.mysql.live.db or "acore_world"
        print("Connecting to database: " .. db_name)
        print("Host: " .. config.mysql.live.address .. ":" .. config.mysql.live.port)
        print("User: " .. config.mysql.live.username)

        mysql, err = env:connect(db_name, config.mysql.live.username, config.mysql.live.password, config.mysql.live.address, config.mysql.live.port)
        if not mysql then
            error("Database connection failed: " .. (err or "unknown error"))
        end
        print("Database connection successful!")
    end

  do -- database query functions
    function GetAreaTriggerCoords(id)
      local areatrigger = {}
      local ret = {}

      -- Enable areatrigger coordinates for AzerothCore
      if core == "acore" then
        -- AzerothCore with DBC tables (without pfquest prefix)
        local sql = [[
          SELECT * FROM AreaTrigger_]]..expansion..[[ LEFT JOIN WorldMapArea_]]..expansion..[[
          ON ( WorldMapArea_]]..expansion..[[.mapID = AreaTrigger_]]..expansion..[[.MapID
            AND WorldMapArea_]]..expansion..[[.x_min < AreaTrigger_]]..expansion..[[.X
            AND WorldMapArea_]]..expansion..[[.x_max > AreaTrigger_]]..expansion..[[.X
            AND WorldMapArea_]]..expansion..[[.y_min < AreaTrigger_]]..expansion..[[.Y
            AND WorldMapArea_]]..expansion..[[.y_max > AreaTrigger_]]..expansion..[[.Y
            AND WorldMapArea_]]..expansion..[[.areatableID > 0)
          WHERE AreaTrigger_]]..expansion..[[.ID = ]] .. id .. [[ ORDER BY areatableID ]]

        local query = mysql:execute(sql)
        if query then
          while query:fetch(areatrigger, "a") do
            if debug("areatrigger_coords") then break end
            local zone_id = tonumber(areatrigger.areatableID) or 0
            local world_x = tonumber(areatrigger.X) or 0
            local world_y = tonumber(areatrigger.Y) or 0

            if zone_id > 0 then
              -- Simple coordinate conversion - can be calibrated later
              local zone_x = math.floor((world_x + 17066) / 340 * 100) / 100
              local zone_y = math.floor((world_y + 17066) / 340 * 100) / 100
              zone_x = math.max(0, math.min(100, zone_x))
              zone_y = math.max(0, math.min(100, zone_y))

              local coord = { zone_x, zone_y, zone_id, 0 }
              table.insert(ret, coord)
            end
          end
        end
        return ret
      end

      local sql = [[
        SELECT * FROM pfquest.AreaTrigger_]]..expansion..[[ LEFT JOIN pfquest.WorldMapArea_]]..expansion..[[
        ON ( pfquest.WorldMapArea_]]..expansion..[[.mapID = pfquest.AreaTrigger_]]..expansion..[[.MapID
          AND pfquest.WorldMapArea_]]..expansion..[[.x_min < pfquest.AreaTrigger_]]..expansion..[[.X
          AND pfquest.WorldMapArea_]]..expansion..[[.x_max > pfquest.AreaTrigger_]]..expansion..[[.X
          AND pfquest.WorldMapArea_]]..expansion..[[.y_min < pfquest.AreaTrigger_]]..expansion..[[.Y
          AND pfquest.WorldMapArea_]]..expansion..[[.y_max > pfquest.AreaTrigger_]]..expansion..[[.Y
          AND pfquest.WorldMapArea_]]..expansion..[[.areatableID > 0)
        WHERE pfquest.AreaTrigger_]]..expansion..[[.ID = ]] .. id .. [[ ORDER BY areatableID ]]

      local query = mysql:execute(sql)
      while query:fetch(areatrigger, "a") do
        local zone = areatrigger.areatableID
        local x = areatrigger.X
        local y = areatrigger.Y
        local x_max = areatrigger.x_max
        local x_min = areatrigger.x_min
        local y_max = areatrigger.y_max
        local y_min = areatrigger.y_min
        local px, py = 0, 0

        if x and y and x_min and y_min then
          px = round(100 - (y - y_min) / ((y_max - y_min)/100),1)
          py = round(100 - (x - x_min) / ((x_max - x_min)/100),1)
          if isValidMap(zone, round(px), round(py), expansion) then
            local coord = { px, py, tonumber(zone) }
            table.insert(ret, coord)
          end
        end
      end

      return ret
    end

    function GetCustomCoords(m,x,y)
      local worldmap = {}
      local ret = {}

      -- Try pfquest DBC data first, then fall back to basic coordinate conversion
      if core == "acore" then
        -- Basic coordinate conversion for AzerothCore without pfquest
        local zone_map = {
          [0] = 12,      -- Eastern Kingdoms -> Elwynn Forest
          [1] = 14,      -- Kalimdor -> Durotar
          [530] = 3520,  -- Outland -> Hellfire Peninsula
          [571] = 65     -- Northrend -> Dragonblight
        }

        local zone_id = zone_map[m] or m
        if zone_id and x and y then
          -- Simple world to zone coordinate conversion
          local zone_x = ((x + 17066.666) / 533.33333) * 100
          local zone_y = ((y + 17066.666) / 533.33333) * 100
          zone_x = math.max(0, math.min(100, zone_x))
          zone_y = math.max(0, math.min(100, zone_y))
          local coord = { zone_x, zone_y, zone_id, 0 }
          table.insert(ret, coord)
        end
        return ret
      end

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

    function GetCreatureCoordsPool(id)
      -- Temporarily disabled due to DBC data issues
      return {}
    end

    function GetCreatureCoords(id)
      local ret = {}

      if core == "acore" then
        -- HARDCODED ZONE MAPPING for AzerothCore (since zoneId/areaId are empty)
        local zone_map = {
          [0] = 12,      -- Eastern Kingdoms -> Elwynn Forest
          [1] = 14,      -- Kalimdor -> Durotar (correct zone for quest 784!)
          [530] = 3520,  -- Outland -> Hellfire Peninsula
          [571] = 65     -- Northrend -> Dragonblight
        }

        -- For AzerothCore, get coordinates from creature table
        local creature_coords = {}
        local query = mysql:execute([[
          SELECT creature.position_x, creature.position_y, creature.map, creature.zoneId, creature.areaId
          FROM creature
          WHERE creature.id1 = ]] .. id .. [[
        ]])

        if query then
          while query:fetch(creature_coords, "a") do
            if debug("creature_coords") then break end

            local x = tonumber(creature_coords.position_x)
            local y = tonumber(creature_coords.position_y)
            local map_id = tonumber(creature_coords.map)
            local zone_id = tonumber(creature_coords.zoneId)
            local area_id = tonumber(creature_coords.areaId)

            if x and y and map_id then
              -- Use real zoneId/areaId from creature table, NO hardcoded mapping
              local final_zone = area_id and area_id > 0 and area_id or
                                zone_id and zone_id > 0 and zone_id or
                                nil -- Let it be nil if no zone info

              -- If no zone info, try to find it via WorldMapArea DBC
              if not final_zone then
                local worldmap_query = mysql:execute([[
                  SELECT areatableID FROM worldmaparea_wotlk
                  WHERE mapID = ]] .. map_id .. [[
                    AND x_min < ]] .. x .. [[ AND x_max > ]] .. x .. [[
                    AND y_min < ]] .. y .. [[ AND y_max > ]] .. y .. [[
                  ORDER BY (x_max - x_min) * (y_max - y_min) ASC
                  LIMIT 1
                ]])
                if worldmap_query then
                  local worldmap_result = {}
                  if worldmap_query:fetch(worldmap_result, "a") then
                    final_zone = tonumber(worldmap_result.areatableID)
                    if id == 3139 then
                      print("DEBUG: Found zone " .. final_zone .. " via WorldMapArea for NPC 3139")
                    end
                  else
                    if id == 3139 then
                      print("DEBUG: No WorldMapArea zone found for NPC 3139 coords:", x, y, "map:", map_id)
                    end
                    -- Fallback zones for all maps
                    if map_id == 1 then
                      final_zone = 14  -- Durotar for Kalimdor
                    elseif map_id == 0 then
                      final_zone = 12  -- Elwynn Forest for Eastern Kingdoms
                    else
                      final_zone = map_id  -- Use map ID as zone ID for other maps
                    end
                    if id == 3139 then
                      print("DEBUG: Using fallback zone " .. final_zone .. " for NPC 3139")
                    end
                  end
                end
              end

              -- Debug: log zone usage for specific NPCs only
              if id == 3139 then
                print("DEBUG: NPC 3139 (quest 784) - coords:", x, y, "map:", map_id, "zone:", zone_id, "area:", area_id, "final_zone:", final_zone)
              end

              -- Convert world coordinates to zone percentage (simplified)
              local zone_x = math.floor((x + 17066) / 340 * 100) / 100
              local zone_y = math.floor((y + 17066) / 340 * 100) / 100

              -- Clamp to 0-100 range
              zone_x = math.max(0, math.min(100, zone_x))
              zone_y = math.max(0, math.min(100, zone_y))

              local coord = { zone_x, zone_y, final_zone, 0 }
              table.insert(ret, coord)
            end
          end
        end

        return ret
      else
        -- Original function code for other cores would go here
        return {}
      end
    end

    function GetGameObjectCoords(id)
      local ret = {}

      if core == "acore" then
        -- For AzerothCore, get coordinates from gameobject table
        local object_coords = {}
        local query = mysql:execute([[
          SELECT gameobject.position_x, gameobject.position_y, gameobject.map, gameobject.zoneId, gameobject.areaId
          FROM gameobject
          WHERE gameobject.id = ]] .. id .. [[
          LIMIT 50
        ]])

        if query then
          while query:fetch(object_coords, "a") do
            if debug("object_coords") then break end

            local x = tonumber(object_coords.position_x)
            local y = tonumber(object_coords.position_y)
            local map_id = tonumber(object_coords.map)
            local zone_id = tonumber(object_coords.zoneId)
            local area_id = tonumber(object_coords.areaId)

            if x and y and map_id then
              -- Use area_id if available, otherwise zone_id
              local final_zone = area_id and area_id > 0 and area_id or zone_id and zone_id > 0 and zone_id or map_id

              -- Convert world coordinates to zone percentage (simplified)
              local zone_x = math.floor((x + 17066) / 340 * 100) / 100
              local zone_y = math.floor((y + 17066) / 340 * 100) / 100

              -- Clamp to 0-100 range
              zone_x = math.max(0, math.min(100, zone_x))
              zone_y = math.max(0, math.min(100, zone_y))

              local coord = { zone_x, zone_y, final_zone, 0 }
              table.insert(ret, coord)
              -- Debug print removed to avoid spam
            end
          end
        end

        return ret
      else
        -- Original function code for other cores would go here
        return {}
      end
    end
  end

  do -- areatrigger
    print("- loading areatrigger...")

    pfDB["areatrigger"] = pfDB["areatrigger"] or {}
    pfDB["areatrigger"][data] = {}

    -- Enable areatrigger for AzerothCore with DBC tables
    if core == "acore" then
      -- Use basic areatrigger_teleport table from AzerothCore instead of DBC
      local test_query = mysql:execute('SHOW TABLES LIKE "areatrigger_teleport"')
      if test_query and test_query:fetch() then
        print("  Found areatrigger_teleport table, extracting areatriggers...")
        local areatrigger = {}
        local query = mysql:execute('SELECT ID, target_map, target_position_x, target_position_y FROM areatrigger_teleport ORDER BY ID')
        if query then
          while query:fetch(areatrigger, "a") do
            if debug("areatrigger") then break end
            local entry = tonumber(areatrigger.ID)
            if entry then
              pfDB["areatrigger"][data][entry] = {}
              pfDB["areatrigger"][data][entry]["coords"] = {}
              -- Basic coordinate data without zone conversion
              local x = tonumber(areatrigger.target_position_x) or 0
              local y = tonumber(areatrigger.target_position_y) or 0
              local map = tonumber(areatrigger.target_map) or 0
              if x ~= 0 and y ~= 0 and map ~= 0 then
                -- Simple coordinate conversion
                local zone_x = math.floor((x + 17066) / 340 * 100) / 100
                local zone_y = math.floor((y + 17066) / 340 * 100) / 100
                zone_x = math.max(0, math.min(100, zone_x))
                zone_y = math.max(0, math.min(100, zone_y))
                table.insert(pfDB["areatrigger"][data][entry]["coords"], { zone_x, zone_y, map, 0 })
              end
            end
          end
          print("  SUCCESS: Extracted areatriggers from areatrigger_teleport")
        else
          print("  Warning: Failed to extract areatriggers")
        end
      else
        print("  Skipping areatrigger extraction (areatrigger_teleport table not found)")
      end
    else
      -- iterate over all areatriggers
      local areatrigger = {}
      local table_name = (C.AreaTrigger or "AreaTrigger") .. "_" .. settings.version
      print("Querying table: pfquest." .. table_name)
      local query, err = mysql:execute('SELECT * FROM pfquest.' .. table_name .. ' ORDER BY ID')
      if not query then
          print("ERROR: Failed to execute query for table: pfquest." .. table_name)
          if err then print("MySQL Error: " .. err) end
          print("Possible causes:")
          print("1. Table pfquest." .. table_name .. " does not exist")
          print("2. User 'acore' does not have access to pfquest database")
          print("3. pfquest database does not exist")
          error("Query failed for pfquest." .. table_name)
      end
      while query:fetch(areatrigger, "a") do
        if debug("areatrigger") then break end

        local entry = tonumber(areatrigger.ID)
        pfDB["areatrigger"][data][entry] = {}

        do -- coordinates
          pfDB["areatrigger"][data][entry]["coords"] = {}
          for id, coords in pairs(GetAreaTriggerCoords(entry)) do
            local x, y, zone, respawn = unpack(coords)
            table.insert(pfDB["areatrigger"][data][entry]["coords"], { x, y, zone, respawn })
          end
        end
      end
    end
  end

  do -- units
    print("- loading units...")

    pfDB["units"] = pfDB["units"] or {}
    pfDB["units"][data] = {}

    -- Count total creatures first
    local count_query = mysql:execute('SELECT COUNT(*) as total FROM creature_template')
    local count_result = {}
    count_query:fetch(count_result, "a")
    local total_creatures = tonumber(count_result.total) or 0
    print("  Processing " .. total_creatures .. " creatures...")

    -- iterate over all creatures
    local processed = 0
    local creature_template = {}
    local limit_clause = (DEBUG_EXTRACTION and not FULL_EXTRACTION) and (' LIMIT ' .. UNITS_LIMIT) or ''
    local query = mysql:execute('SELECT * FROM creature_template GROUP BY creature_template.entry ORDER BY creature_template.entry' .. limit_clause)
    while query:fetch(creature_template, "a") do
      if debug("units") then break end
      processed = processed + 1

      -- Show progress every 1000 creatures
      if processed % 1000 == 0 then
        print("  Processed " .. processed .. "/" .. total_creatures .. " creatures (" .. math.floor(processed/total_creatures*100) .. "%)")
      end

      local entry   = tonumber(creature_template[C.Entry])
      local name    = creature_template[C.Name]
      local minlvl  = tonumber(creature_template[C.MinLevel]) or 1
      local maxlvl  = tonumber(creature_template[C.MaxLevel]) or minlvl or 1
      local rnk     = tonumber(creature_template[C.Rank]) or 0
      local lvl     = (minlvl == maxlvl) and tostring(minlvl) or tostring(minlvl) .. "-" .. tostring(maxlvl)

      pfDB["units"][data][entry] = {}
      pfDB["units"][data][entry]["lvl"] = lvl
      if tonumber(rnk) > 0 then
        pfDB["units"][data][entry]["rnk"] = rnk
      end

      do -- detect faction
        local fac = ""
        local faction = {}
        local sql = [[
          SELECT A, H FROM creature_template, pfquest.factiontemplate_wotlk
          WHERE pfquest.factiontemplate_wotlk.factiontemplateID = creature_template.]] .. C.Faction .. [[
          AND creature_template.]] .. C.Entry .. [[ = ]] .. creature_template[C.Entry] .. [[
        ]]

        local query = mysql:execute(sql)
        if query then
          while query:fetch(faction, "a") do
            if debug("units_faction") then break end
            local A, H = faction.A, faction.H
            if A == "1" and not string.find(fac, "A") then fac = fac .. "A" end
            if H == "1" and not string.find(fac, "H") then fac = fac .. "H" end
          end
        end

        if fac ~= "" then
          pfDB["units"][data][entry]["fac"] = fac
        end
      end

      do -- coordinates
        pfDB["units"][data][entry]["coords"] = {}

        for id, coords in pairs(GetCreatureCoords(entry)) do
          local x, y, zone, respawn = unpack(coords)
          if debug("units_coords") then break end
          table.insert(pfDB["units"][data][entry]["coords"], { x, y, zone, respawn })
        end

        if core ~= "vmangos" then
          for id, coords in pairs(GetCreatureCoordsPool(entry)) do
            local x, y, zone, respawn = unpack(coords)
            if debug("units_coords_pool") then break end
            table.insert(pfDB["units"][data][entry]["coords"], { x, y, zone, respawn })
          end
        end

        -- search for Event summons (fixed position) - DISABLED for AzerothCore compatibility
        -- [Gazban:2624, Maraudine Khan Guard:6069, Echeyakee:3475]
        if core ~= "acore" then
          local dbscripts_on_event = {}
          local query = mysql:execute('SELECT id as event, x as x, y as y FROM '..C.dbscripts_on_event..' WHERE command = 10 AND datalong = ' .. entry)
          while query:fetch(dbscripts_on_event, "a") do
            if debug("units_event") then break end
            local event = tonumber(dbscripts_on_event.event)
            local x = tonumber(dbscripts_on_event.x)
            local y = tonumber(dbscripts_on_event.y)
            local map = nil

            -- guess map based on gameobject relation
            -- [Gazban:2624]
            local map_object = {}
            local query = mysql:execute([[
              SELECT map AS map FROM gameobject_template, gameobject
              WHERE gameobject_template.type = 10
                AND gameobject_template.data2 = ]]..event..[[
                AND gameobject.id = gameobject_template.entry
              GROUP BY gameobject.map
            ]])
            while query:fetch(map_object, "a") do
              if debug("units_event_map_object") then break end
              map = map or tonumber(map_object.map)
            end

            -- guess map based on spell relation
            local spell_template = {}
            local query = mysql:execute([[
              SELECT ]]..C.Id..[[ AS spell, ]]..C.RequiresSpellFocus..[[ AS focus FROM spell_template
              WHERE ( EffectMiscValue1 = ]]..event..[[ AND effect1 = 61 )
                 OR ( EffectMiscValue2 = ]]..event..[[ AND effect2 = 61 )
                 OR ( EffectMiscValue3 = ]]..event..[[ AND effect3 = 61 )
            ]])
            while query:fetch(spell_template, "a") do
              if debug("units_event_spell") then break end
              local spell = tonumber(spell_template.spell)
              local focus = tonumber(spell_template.focus)

              -- guess map based on gameobject target
              -- [Echeyakee:3475]
              local gameobject_template = {}
              local query = mysql:execute([[
                SELECT map as map FROM gameobject_template, gameobject
                WHERE gameobject.id = gameobject_template.entry
                  AND gameobject_template.data0 > 0
                  AND gameobject_template.type = 8
                  AND gameobject_template.data0 = ]]..focus..[[
                GROUP BY map
              ]])
              while query:fetch(gameobject_template, "a") do
                if debug("units_event_spell_map_object") then break end
                map = map or tonumber(gameobject_template.map)
              end

              -- guess map based on item map/area bond
              -- [Maraudine Khan Guard:6069]
              local item_template = {}
              local query = mysql:execute([[
                SELECT ]]..C.Map..[[ as map FROM item_template
                WHERE spelltrigger_1 = 0 AND spellid_1 = ]]..spell..[[
                GROUP BY map
              ]])
              while query:fetch(item_template, "a") do
                if debug("units_event_spell_map_item") then break end
                -- Zul'Farrak Executioner Key is not bound to map.
                -- Ignoring its unlocking spell that spawns sandfuries.
                if spell == 10738 then break end
                map = map or tonumber(item_template.map)
              end
            end

            if map then -- in case we found a map, add the coordinates
              for id, coords in pairs(GetCustomCoords(map, x, y)) do
                local x, y, zone, respawn = unpack(coords)
                table.insert(pfDB["units"][data][entry]["coords"], { x, y, zone, respawn })
              end
            end
          end
        end

        -- search for AI summons (fixed position) - DISABLED for AzerothCore compatibility
        -- [Verog Derwisch:3395]
        if core ~= "acore" then
          local creature_ai_scripts = {}
          local sql = core == "vmangos" and [[
            SELECT creature.map AS map, x AS x, y AS y FROM creature_ai_scripts, creature_ai_events, creature
            WHERE creature.id = creature_ai_events.creature_id
              AND creature_ai_scripts.command = 10
              AND creature_ai_scripts.id = creature_ai_events.id
              AND creature_ai_scripts.datalong = ]]..entry..[[
              AND x != 0 AND y != 0
            GROUP BY map
          ]] or [[
            SELECT creature.map as map, creature_ai_summons.position_x AS x, creature_ai_summons.position_y AS y FROM creature_ai_scripts
            LEFT JOIN creature_ai_summons ON creature_ai_scripts.action2_type = 32 AND creature_ai_scripts.action2_param3 = creature_ai_summons.id
            LEFT JOIN creature ON creature_ai_scripts.creature_id = creature.id
            WHERE action2_type = 32
              AND action2_param1 = ]]..entry..[[
            GROUP BY map
          ]]

          print("DEBUG: Executing AI summons query for entry " .. entry .. " with core " .. core)
          local query = mysql:execute(sql)
          if query then
            while query:fetch(creature_ai_scripts, "a") do
              if debug("units_summon_fixed") then break end
              for id, coords in pairs(GetCustomCoords(tonumber(creature_ai_scripts.map), tonumber(creature_ai_scripts.x), tonumber(creature_ai_scripts.y))) do
                local x, y, zone, respawn = unpack(coords)
                table.insert(pfDB["units"][data][entry]["coords"], { x, y, zone, respawn })
              end
            end
          else
            print("DEBUG: AI summons query failed for entry " .. entry)
          end
        else
          -- Skip AI summons for AzerothCore (no debug message needed)
        end

        -- search for AI summons (summoner position) - DISABLED for AzerothCore compatibility
        -- [Darrowshire Spirit:11064]
        if core ~= "acore" then
          local creature_ai_scripts = {}
          local query = mysql:execute(core == "vmangos" and [[
            SELECT creature_ai_events.creature_id AS summoner FROM creature_ai_scripts, creature_ai_events
            WHERE creature_ai_scripts.command = 10
              AND creature_ai_scripts.id = creature_ai_events.id
              AND creature_ai_scripts.datalong = ]]..entry..[[
              AND x = 0 AND y = 0
          ]] or [[
            SELECT creature_id AS summoner FROM spell_template
            LEFT JOIN creature_ai_scripts ON action1_type = 11 AND action1_param1 = spell_template.Id
            WHERE spell_template.Effect1 = 28 AND creature_id > 0 AND spell_template.EffectMiscValue1 = ]]..entry..[[
          ]])
          if query then
            while query:fetch(creature_ai_scripts, "a") do
              if debug("units_summon_unknown") then break end
              for id, coords in pairs(GetCreatureCoords(tonumber(creature_ai_scripts.summoner))) do
                local x, y, zone, respawn = unpack(coords)
                table.insert(pfDB["units"][data][entry]["coords"], { x, y, zone, respawn })
              end

              if core ~= "vmangos" then
                for id, coords in pairs(GetCreatureCoordsPool(tonumber(creature_ai_scripts.summoner))) do
                  local x, y, zone, respawn = unpack(coords)
                  table.insert(pfDB["units"][data][entry]["coords"], { x, y, zone, respawn })
                end
              end
            end
          end
        end

        -- clear duplicates
        pfDB["units"][data][entry]["coords"] = removedupes(pfDB["units"][data][entry]["coords"])
      end
    end

    do -- Patch creature table with manual entries
      -- Only use this method of adding creatures if there is REALLY no way
      -- to extract data out of the databases of the mangos cores. If the list
      -- becomes too big, this should be separated to another file.
      pfDB["units"][data][420] = {
        ["coords"] = { [1] = { 69, 21, 148, 300 } },
        ["fac"] = "H", ["lvl"] = "60",
      }

      do -- Sentinel Selarin:3694
        -- taken from https://classic.wowhead.com/npc=3694/sentinel-selarin
        if pfDB["units"][data][3694] then
          pfDB["units"][data][3694]["coords"] = { [1] = { 39.2, 43.4, 42, 0 } }
        end
      end

      do -- Mokk the Savage:1514
        -- taken from https://classic.wowhead.com/npc=1514/mokk-the-savage
        if pfDB["units"][data][1514] then
          pfDB["units"][data][1514]["coords"] = { [1] = { 35.2, 60.4, 33, 0 } }
        end
      end
    end
  end

  do -- objects
    print("- loading objects...")

    pfDB["objects"] = pfDB["objects"] or {}
    pfDB["objects"][data] = {}

    -- iterate over all objects (LIMITED FOR TESTING)
    local gameobject_template = {}
    local limit_clause = (DEBUG_EXTRACTION and not FULL_EXTRACTION) and (' LIMIT ' .. OBJECTS_LIMIT) or ''
    local query = mysql:execute('SELECT * FROM gameobject_template ORDER BY gameobject_template.entry ASC' .. limit_clause)
    if query then
      while query:fetch(gameobject_template, "a") do
      if debug("objects") then break end

      local entry  = tonumber(gameobject_template.entry)
      local name   = gameobject_template.name

      pfDB["objects"][data][entry] = {}

      do -- detect faction - DISABLED due to DBC data issues
        -- This would require pfquest.FactionTemplate_wotlk table
        local fac = ""
        -- Skip faction detection for now
        if fac ~= "" then
          pfDB["objects"][data][entry]["fac"] = fac
        end
      end

      do -- coordinates
        pfDB["objects"][data][entry]["coords"] = {}

        for id,coords in pairs(GetGameObjectCoords(entry)) do
          if debug("objects_coords") then break end
          local x, y, zone, respawn = unpack(coords)
          table.insert(pfDB["objects"][data][entry]["coords"], { x, y, zone, respawn })
        end
      end

        -- clear duplicates
        pfDB["objects"][data][entry]["coords"] = removedupes(pfDB["objects"][data][entry]["coords"])
      end
    end
  end

  do -- items
    print("- loading items...")

    pfDB["items"] = pfDB["items"] or {}
    pfDB["items"][data] = {}

    -- iterate over all items
    local item_template = {}
    local limit_clause = ITEMS_LIMIT and (' LIMIT ' .. ITEMS_LIMIT) or ''
    local query = mysql:execute('SELECT entry, name FROM item_template ORDER BY entry ASC' .. limit_clause)
    if query then
      while query:fetch(item_template, "a") do
      if debug("items") then break end

      local entry = tonumber(item_template.entry)
      local scans = { [0] = { entry, nil } }

      -- add items that contain the actual item to the itemlist
      local item_loot_item = {}
      local count = 0

      -- Check if entry exists
      if not item_template.entry then
        print("Warning: Skipping item with nil entry")
      else
        local query = mysql:execute('SELECT entry, ChanceOrQuestChance FROM item_loot_template WHERE item = ' .. item_template.entry .. ' ORDER BY entry')
        if query then
          while query:fetch(item_loot_item, "a") do
            if debug("items_container") then break end
            if math.abs(item_loot_item.ChanceOrQuestChance) > 0 then
              local chance = math.abs(item_loot_item.ChanceOrQuestChance)
              chance = chance < 0.01 and round(chance, 5) or round(chance, 2)
              table.insert(scans, { tonumber(item_loot_item.entry), chance })
            end
          end
        end
      end

      -- recursively read U, O, V, R blocks of the item
      for id, item in pairs(scans) do
        local entry = tonumber(item[1])
        local chance = item[2] and item[2] / 100 or 1
        pfDB["items"][data][entry] = pfDB["items"][data][entry] or {}

        -- fill unit table
        local creature_loot_template = {}
        local query = mysql:execute('SELECT entry, ChanceOrQuestChance FROM creature_loot_template WHERE item = ' .. entry .. ' ORDER BY entry')
        if query then
          while query:fetch(creature_loot_template, "a") do
            if debug("items_unit") then break end
            local chance = math.abs(creature_loot_template.ChanceOrQuestChance) * chance
            chance = chance < 0.01 and round(chance, 5) or round(chance, 2)

            if chance > 0 then
              pfDB["items"][data][entry]["U"] = pfDB["items"][data][entry]["U"] or {}
              pfDB["items"][data][entry]["U"][tonumber(creature_loot_template.entry)] = chance
            end
          end
        end

        -- fill object table
        local gameobject_loot_template = {}
        local query = mysql:execute([[
          SELECT gameobject_template.entry, gameobject_loot_template.ChanceOrQuestChance FROM gameobject_loot_template
          INNER JOIN gameobject_template ON gameobject_template.data1 = gameobject_loot_template.entry
          WHERE ( gameobject_template.type = 3 OR gameobject_template.type = 25 )
          AND gameobject_loot_template.item = ]] .. entry .. [[ ORDER BY gameobject_template.entry ]])
        if query then
          while query:fetch(gameobject_loot_template, "a") do
            if debug("items_object") then break end
            local chance = math.abs(gameobject_loot_template.ChanceOrQuestChance) * chance
            chance = chance < 0.01 and round(chance, 5) or round(chance, 2)

            if chance > 0 then
              pfDB["items"][data][entry]["O"] = pfDB["items"][data][entry]["O"] or {}
              pfDB["items"][data][entry]["O"][tonumber(gameobject_loot_template.entry)] = chance
            end
          end
        end

        -- fill reference table
        local reference_loot_template = {}
        local query = mysql:execute([[
          SELECT entry, ChanceOrQuestChance FROM reference_loot_template where reference_loot_template.item = ]] .. entry .. [[ ORDER BY entry
        ]])
        if query then
          while query:fetch(reference_loot_template, "a") do
            if debug("items_reference") then break end
            local chance = math.abs(reference_loot_template.ChanceOrQuestChance)
            chance = chance < 0.01 and round(chance, 5) or round(chance, 2)

            pfDB["items"][data][entry]["R"] = pfDB["items"][data][entry]["R"] or {}
            pfDB["items"][data][entry]["R"][tonumber(reference_loot_template.entry)] = chance
          end
        end

        -- fill vendor table
        local npc_vendor = {}
        local query = mysql:execute('SELECT entry, maxcount FROM npc_vendor WHERE item = ' .. entry .. ' ORDER BY entry')
        if query then
          while query:fetch(npc_vendor, "a") do
            if debug("items_vendor") then break end
            pfDB["items"][data][entry]["V"] = pfDB["items"][data][entry]["V"] or {}
            pfDB["items"][data][entry]["V"][tonumber(npc_vendor.entry)] = tonumber(npc_vendor.maxcount)
          end
        end

        -- handle vendor template tables
        local npc_vendor = {}
        local vendor_field = C["VendorTemplateId"] or "VendorTemplateId" -- Default fallback
        local query = mysql:execute('SELECT creature_template.Entry, maxcount FROM npc_vendor_template, creature_template WHERE item = ' .. entry .. ' and creature_template.' .. vendor_field .. ' = npc_vendor_template.entry ORDER BY creature_template.Entry')
        if query then
          while query:fetch(npc_vendor, "a") do
            if debug("items_vendortemplate") then break end
            pfDB["items"][data][entry]["V"] = pfDB["items"][data][entry]["V"] or {}
            pfDB["items"][data][entry]["V"][tonumber(npc_vendor.Entry)] = tonumber(npc_vendor.maxcount)
          end
        end
      end
    end
  end

  do -- refloot
    print("- loading refloot...")

    pfDB["refloot"] = pfDB["refloot"] or {}
    pfDB["refloot"][data] = {}

    -- iterate over all reference loots (LIMITED FOR TESTING)
    local reference_loot_template = {}
    local limit_clause = REFLOOT_LIMIT and (' LIMIT ' .. REFLOOT_LIMIT) or ''
    local query = mysql:execute('SELECT entry, ChanceOrQuestChance FROM reference_loot_template ORDER BY entry' .. limit_clause)
    if query then
      while query:fetch(reference_loot_template, "a") do
        if debug("refloot") then break end

        local entry = tonumber(reference_loot_template.entry)

        -- fill unit table
        local creature_loot_template = {}
        local count = 0
        local query = mysql:execute([[
          SELECT entry FROM creature_loot_template
          WHERE creature_loot_template.mincountOrRef < 0
          AND item = ]] .. entry .. [[ ORDER BY entry
        ]])
        if query then
          while query:fetch(creature_loot_template, "a") do
            if debug("refloot_unit") then break end
            pfDB["refloot"][data][entry] = pfDB["refloot"][data][entry] or {}
            pfDB["refloot"][data][entry]["U"] = pfDB["refloot"][data][entry]["U"] or {}
            pfDB["refloot"][data][entry]["U"][tonumber(creature_loot_template.entry)] = 1
          end
        end

        -- fill object table
        local gameobject_template = {}
        local count = 0
        local query = mysql:execute([[
          SELECT gameobject_template.entry FROM gameobject_template, gameobject_loot_template
          WHERE gameobject_template.data1 = gameobject_loot_template.entry
          AND gameobject_loot_template.mincountOrRef < 0
          AND gameobject_loot_template.item = ]] .. entry .. [[ ORDER BY gameobject_template.entry ;
        ]])
        if query then
          while query:fetch(gameobject_template, "a") do
            if debug("refloot_object") then break end
            pfDB["refloot"][data][entry] = pfDB["refloot"][data][entry] or {}
            pfDB["refloot"][data][entry]["O"] = pfDB["refloot"][data][entry]["O"] or {}
            pfDB["refloot"][data][entry]["O"][tonumber(gameobject_template.entry)] = 1
          end
        end
      end
    end
  end

  do -- quests
    print("- loading quests...")

    pfDB["quests"] = pfDB["quests"] or {}
    pfDB["quests"][data] = {}

    pfDB["quests-itemreq"] = pfDB["quests-itemreq"] or {}
    pfDB["quests-itemreq"][data] = {}

    -- iterate over all quests (LIMITED FOR TESTING)
    local quest_template = {}
    local quest_pk_column = (core == "acore" and "ID" or "entry") -- Added for AzerothCore
    local limit_clause = (DEBUG_EXTRACTION and not FULL_EXTRACTION) and (' LIMIT ' .. QUEST_LIMIT) or ''
    local query_string = 'SELECT * FROM quest_template ORDER BY quest_template.' .. quest_pk_column .. limit_clause

    -- Count total quests first for progress
    local count_query = mysql:execute('SELECT COUNT(*) as total FROM quest_template' .. limit_clause)
    local count_result = {}
    count_query:fetch(count_result, "a")
    local total_quests = tonumber(count_result.total) or 0
    print("  Processing " .. total_quests .. " quests...")

    local query = mysql:execute(query_string) -- Modified for AzerothCore
    if query then
      local processed = 0
      while query:fetch(quest_template, "a") do
      if debug("quests") then break end

        processed = processed + 1
        -- Show progress every 1000 quests
        if processed % 1000 == 0 then
          print("  Processed " .. processed .. "/" .. total_quests .. " quests (" .. math.floor(processed/total_quests*100) .. "%)")
        end

        local entry = tonumber(quest_template[quest_pk_column]) -- Modified for AzerothCore
        local quest_id = quest_template[quest_pk_column] or quest_template.entry -- For SQL queries
        local minlevel = tonumber(quest_template.MinLevel)
      local questlevel = tonumber(quest_template.QuestLevel)
      local class_column = C.RequiredClasses or "RequiredClasses" -- Default if not in C
      local race_column = C.RequiredRaces or "AllowableRaces" -- Default to AC if not in C
      local skill_column = C.RequiredSkill or "RequiredSkillId" -- Default to AC if not in C
      local srcitem_column = C.SrcItemId or "StartItem" -- Default to AC if not in C
      local prevquest_column = C.PrevQuestId or "PrevQuestId" -- Default if not in C

        local class = quest_template[class_column] and tonumber(quest_template[class_column]) or 0
        local race = quest_template[race_column] and tonumber(quest_template[race_column]) or 0
        local skill = quest_template[skill_column] and tonumber(quest_template[skill_column]) or 0
        local chain = quest_template.NextQuestInChain and tonumber(quest_template.NextQuestInChain) or 0 -- This will be problematic for AC
        local srcitem = quest_template[srcitem_column] and tonumber(quest_template[srcitem_column]) or 0
        local repeatable = quest_template.SpecialFlags and (tonumber(quest_template.SpecialFlags) % 2) or 0
      local event = nil

        -- try to detect event by quest event entry
        local game_event_quest = {}
        local query = mysql:execute('SELECT event FROM game_event_quest WHERE quest = ' .. entry)
        if query then
          while query:fetch(game_event_quest, "a") do
            if debug("quests_events") then break end
            event = tonumber(game_event_quest.event)
            break
          end
        end

        -- try to detect event by creature event
        if not event then
        local game_event_creature = {}

        -- Use correct quest ID field for AzerothCore
        local quest_id = quest_template[quest_pk_column] or quest_template.entry
        if not quest_id then
          print("Warning: Quest with nil ID, skipping event detection")
        else
          local sql = [[
            SELECT game_event_creature.event as event FROM creature, game_event_creature, creature_questrelation
            WHERE creature.guid = game_event_creature.guid
            AND creature.id = creature_questrelation.id
            AND creature_questrelation.quest = ]] .. quest_id
          local query = mysql:execute(sql)
          if query then
            while query:fetch(game_event_creature, "a") do
              if debug("quests_eventscreature") then break end
              event = tonumber(game_event_creature.event)
              break
            end
          end
        end
      end

        -- try to detect event by gameobject event
        if not event then
          local game_event_gameobject = {}

          -- Use correct quest ID field for AzerothCore
          local quest_id = quest_template[quest_pk_column] or quest_template.entry
          if quest_id then
            local sql = [[
              SELECT game_event_gameobject.event as event FROM gameobject, game_event_gameobject, gameobject_questrelation
              WHERE gameobject.guid = game_event_gameobject.guid
              AND gameobject.id = gameobject_questrelation.id
              AND gameobject_questrelation.quest = ]] .. quest_id
            local query = mysql:execute(sql)
            if query then
              while query:fetch(game_event_gameobject, "a") do
                if debug("quests_eventsobjects") then break end
                event = tonumber(game_event_gameobject.event)
                break
              end
            end
          end
        end

      pfDB["quests"][data][entry] = {}
      pfDB["quests"][data][entry]["min"] = minlevel ~= 0 and minlevel
      pfDB["quests"][data][entry]["skill"] = skill ~= 0 and skill
      pfDB["quests"][data][entry]["lvl"] = questlevel ~= 0 and questlevel
      pfDB["quests"][data][entry]["class"] = class ~= 0 and class
      pfDB["quests"][data][entry]["race"] = race ~= 0 and race
      pfDB["quests"][data][entry]["skill"] = skill ~= 0 and skill
      pfDB["quests"][data][entry]["event"] = event ~= 0 and event

      -- quest objectives
      local units, objects, items, itemreq, areatrigger, zones, pre = {}, {}, {}, {}, {}, {}, {}

        -- add single pre-quests
        local prevquest_value = quest_template[prevquest_column]
        if prevquest_value and tonumber(prevquest_value) and tonumber(prevquest_value) ~= 0 then
          pre[math.abs(tonumber(prevquest_value))] = true
        end

      -- add required pre-quests
      local prequests = {}
      -- AC doesn't have NextQuestId for this logic, this part of pre-quest finding might be problematic for AC
      local next_quest_id_column = core == "acore" and "PrevQuestId" or "NextQuestId" -- HACK: AC uses PrevQuestId on the *next* quest. This query is for *current* quest.
      local exclusive_group_column = core == "acore" and "ExclusiveGroup" or "ExclusiveGroup" -- Assuming same name
        local pre_query_string = 'SELECT quest_template.' .. quest_pk_column .. ' AS entry FROM quest_template WHERE ' .. next_quest_id_column .. ' = ' .. entry .. ' AND ' .. exclusive_group_column .. ' < 0'
        local query = mysql:execute(pre_query_string)
        if query then
          while query:fetch(prequests, "a") do
            if debug("quests_prequests") then break end
            pre[tonumber(prequests["entry"])] = true
          end
        end

      -- add pre quests from quest chains
      -- This NextQuestInChain will be an issue for AzerothCore as it does not exist.
      -- This part of pre-quest detection might not work correctly for AC.
      if quest_template.NextQuestInChain then -- Check if column exists
        local pre_chain_query_string = 'SELECT quest_template.' .. quest_pk_column .. ' AS entry FROM quest_template WHERE NextQuestInChain = ' .. entry
        query = mysql:execute(pre_chain_query_string)
        while query:fetch(prequests, "a") do
          if debug("quests_prequestchain") then break end
          pre[tonumber(prequests["entry"])] = true
        end
      end

      -- temporary add provided quest item
      items[srcitem] = true

      -- Mapping for ReqCreatureOrGOId, ReqItemId, ReqSourceId based on C config or defaults
      local req_npc_go_id_base = C.ReqCreatureOrGOId or "RequiredNpcOrGo" -- Defaulting to AC naming
      local req_item_id_base = C.ReqItemId or "RequiredItemId" -- Defaulting to AC naming
      local req_source_id_base = C.ReqSourceId or "RequiredItemSourceId" -- Placeholder, AC might not have direct ReqSourceId, often covered by loot or quest item spells

      for i=1,4 do
        local req_npc_go_col = req_npc_go_id_base .. i
        local req_item_col = req_item_id_base .. i
        local req_source_col = req_source_id_base .. i -- Might be unused if AC has no direct map

        if quest_template[req_npc_go_col] and tonumber(quest_template[req_npc_go_col]) > 0 then
          units[tonumber(quest_template[req_npc_go_col])] = true
        elseif quest_template[req_npc_go_col] and tonumber(quest_template[req_npc_go_col]) < 0 then
          objects[math.abs(tonumber(quest_template[req_npc_go_col]))] = true
        end
        if quest_template[req_item_col] and tonumber(quest_template[req_item_col]) > 0 then
          items[tonumber(quest_template[req_item_col])] = true
        end
        -- Handling ReqSourceId needs to be verified for AC. It might involve looking at item loot that starts quests or specific quest flags.
        -- For now, we attempt to use it if the column exists in the query result.
        if quest_template[req_source_col] and tonumber(quest_template[req_source_col]) > 0 then
          items[tonumber(quest_template[req_source_col])] = true
        end

        if quest_template["ReqSpellCast" .. i] and tonumber(quest_template["ReqSpellCast" .. i]) > 0 then
          local spell_template = {}
          local query = mysql:execute('SELECT * FROM spell_template WHERE spell_template.' .. C.Id .. ' = ' .. quest_template["ReqSpellCast" .. i])
          while query:fetch(spell_template, "a") do
            if debug("quests_questspellobject") then break end
            if spell_template[C.RequiresSpellFocus] ~= "0" then
              local gameobject_template = {}
              local query = mysql:execute('SELECT * FROM gameobject_template WHERE gameobject_template.type = 8 and gameobject_template.data0 = ' .. spell_template[C.RequiresSpellFocus])
              while query:fetch(gameobject_template, "a") do
                objects[tonumber(gameobject_template["entry"])] = true
              end
            end
          end
        end
      end

      -- add all units that give kill credit for one of the known units
      if core ~= "vmangos" then
        for id in pairs(units) do
          local creature_template = {}
          local query = mysql:execute('SELECT * FROM creature_template WHERE KillCredit1 = ' .. id .. ' or KillCredit2 = ' .. id)
          while query:fetch(creature_template, "a") do
            if debug("quests_credit") then break end
            if creature_template["Entry"] and tonumber(creature_template["Entry"]) then
              units[tonumber(creature_template["Entry"])] = true
            end
          end
        end
      end

      -- scan all involved questitems for spells that require or are required by gameobjects, units or zones
        for id in pairs(items) do
          if id > 0 then
            local item_template = {}
            for _, spellcolumn in pairs({ "spellid_1", "spellid_2", "spellid_3", "spellid_4", "spellid_5" }) do
              local query = mysql:execute('SELECT * FROM item_template WHERE ' .. spellcolumn .. ' > 0 and entry = ' .. id)
              if query then
                while query:fetch(item_template, "a") do
                  if debug("quests_item") then break end
                  local spellid = item_template[spellcolumn]

                  -- scan through all spells that are associated with the item
                  local spell_template = {}
                  local spell_query = mysql:execute('SELECT * FROM spell_template WHERE ' .. C.Id .. ' = ' .. spellid)
                  if spell_query then
                    while spell_query:fetch(spell_template, "a") do
                      if debug("quests_itemspell") then break end
                local area = spell_template["AreaId"]
                local focus = spell_template[C.RequiresSpellFocus]
                local match = nil

                -- spell requires focusing a creature
                local spell_script_target = {}
                for itemid in pairs(items) do
                  local query = mysql:execute([[
                    SELECT spell_script_target.targetEntry AS creature
                    FROM spell_script_target, item_template
                    WHERE ]] .. spellid .. [[ > 0 AND ]] .. spellid .. [[ = spell_script_target.entry
                  ]])
                  while query:fetch(spell_script_target, "a") do
                    if debug("quests_itemspellcreature") then break end
                    pfDB["quests-itemreq"][data][id] = pfDB["quests-itemreq"][data][id] or {}
                    pfDB["quests-itemreq"][data][id][tonumber(spell_script_target.creature)] = spellid
                    itemreq[id] = true
                    match = true
                  end
                end

                -- spell requries focusing an object
                if focus and tonumber(focus) > 0  then
                  local gameobject_template = {}
                  local query = mysql:execute('SELECT * FROM gameobject_template WHERE gameobject_template.type = 8 and gameobject_template.data0 = ' .. focus)
                  while query:fetch(gameobject_template, "a") do
                    if debug("quests_itemspellobject") then break end
                    pfDB["quests-itemreq"][data][id] = pfDB["quests-itemreq"][data][id] or {}
                    pfDB["quests-itemreq"][data][id][-tonumber(gameobject_template["entry"])] = spellid
                    itemreq[id] = true
                    match = true
                  end
                end

                -- spell triggers something that requires a special target
                for _, trigger in pairs({ spell_template[C["EffectTriggerSpell"]..1], spell_template[C["EffectTriggerSpell"]..2], spell_template[C["EffectTriggerSpell"]..3] }) do
                  if trigger and tonumber(trigger) > 0 then
                    local spell_script_target = {}
                    local query = mysql:execute('SELECT * FROM spell_script_target WHERE entry = ' .. trigger)
                    while query:fetch(spell_script_target, "a") do
                      if debug("quests_itemspellscript") then break end
                      local targetobj = spell_script_target["type"]
                      local targetentry = spell_script_target["targetEntry"]

                      if tonumber(targetobj) == 0 then
                        -- object
                        pfDB["quests-itemreq"][data][id] = pfDB["quests-itemreq"][data][id] or {}
                        pfDB["quests-itemreq"][data][id][-tonumber(targetentry)] = spellid
                        itemreq[id] = true
                        match = true
                      elseif tonumber(targetobj) == 1 then
                        -- unit
                        pfDB["quests-itemreq"][data][id] = pfDB["quests-itemreq"][data][id] or {}
                        pfDB["quests-itemreq"][data][id][tonumber(targetentry)] = spellid
                        itemreq[id] = true
                        match = true
                      end
                    end
                  end
                end

                -- only spell limitation is a zone
                if not match and area and tonumber(area) > 0 then
                  zones[tonumber(area)] = true
                end
                    end -- spell_query:fetch
                  end -- if spell_query
                end -- query:fetch
              end -- if query
            end -- for spellcolumn
          end -- if id > 0
        end -- for id in pairs(items)

        -- item is used to open a creature
        for id in pairs(items) do
          if id > 0 then
            local creature_items = {}
            local target_entry_field = C.targetEntry or "targetEntry" -- Default fallback
            local query = mysql:execute([[
              SELECT ]] .. target_entry_field .. [[ AS creature FROM item_required_target
              WHERE entry = ]] .. id .. [[
            ]])
            if query then
              while query:fetch(creature_items, "a") do
                if debug("quests_itemcreature") then break end
                pfDB["quests-itemreq"][data][id] = pfDB["quests-itemreq"][data][id] or {}
                pfDB["quests-itemreq"][data][id][tonumber(creature_items.creature)] = 0
                itemreq[id] = true
              end
            end
          end
        end

        -- item is used to open an object (DISABLED - requires pfquest)
        for id in pairs(items) do
          if id > 0 then
            -- DISABLED: This requires pfquest.Lock table which is not available in AzerothCore
            if false then -- Disable pfquest dependency
              local object_items = {}
              local query = mysql:execute([[
                SELECT gameobject_template.entry AS object
                FROM gameobject_template, pfquest.Lock_]]..expansion..[[
                WHERE type = 10 and data0 = pfquest.Lock_]]..expansion..[[.id
                AND pfquest.Lock_]]..expansion..[[.data = ]] .. id .. [[
              ]])
              if query then
                while query:fetch(object_items, "a") do
                  if debug("quests_itemobject") then break end
                  pfDB["quests-itemreq"][data][id] = pfDB["quests-itemreq"][data][id] or {}
                  pfDB["quests-itemreq"][data][id][-tonumber(object_items.object)] = 0
                  itemreq[id] = true
                end
              end
            end
          end
        end

        -- scan for related areatriggers
        local areatrigger_involvedrelation = {}
        local query = mysql:execute('SELECT * FROM areatrigger_involvedrelation WHERE quest = ' .. entry)
        if query then
          while query:fetch(areatrigger_involvedrelation, "a") do
            if debug("quests_areatrigger") then break end
            areatrigger[tonumber(areatrigger_involvedrelation["id"])] = true
          end
        end

      -- remove provided quest item from objectives
      items[srcitem] = nil

      -- write pre-quests
      for id in opairs(pre) do
        pfDB["quests"][data][entry]["pre"] = pfDB["quests"][data][entry]["pre"] or {}
        table.insert(pfDB["quests"][data][entry]["pre"], tonumber(id))
      end

          do -- write objectives
              if tblsize(units) > 0 or tblsize(objects) > 0 or tblsize(items) > 0 or tblsize(itemreq) > 0 or tblsize(areatrigger) > 0 or tblsize(zones) > 0 then
                  pfDB["quests"][data][entry]["obj"] = pfDB["quests"][data][entry]["obj"] or {}

                  for id in opairs(units) do
                      pfDB["quests"][data][entry]["obj"]["U"] = pfDB["quests"][data][entry]["obj"]["U"] or {}
                      table.insert(pfDB["quests"][data][entry]["obj"]["U"], tonumber(id))
                  end

                  for id in opairs(objects) do
                      pfDB["quests"][data][entry]["obj"]["O"] = pfDB["quests"][data][entry]["obj"]["O"] or {}
                      table.insert(pfDB["quests"][data][entry]["obj"]["O"], tonumber(id))
                  end

                  for id in opairs(items) do
                      pfDB["quests"][data][entry]["obj"]["I"] = pfDB["quests"][data][entry]["obj"]["I"] or {}
                      table.insert(pfDB["quests"][data][entry]["obj"]["I"], tonumber(id))
                  end

                  for id in opairs(itemreq) do
                      pfDB["quests"][data][entry]["obj"]["IR"] = pfDB["quests"][data][entry]["obj"]["IR"] or {}
                      table.insert(pfDB["quests"][data][entry]["obj"]["IR"], tonumber(id))
                  end

                  for id in opairs(areatrigger) do
                      pfDB["quests"][data][entry]["obj"]["A"] = pfDB["quests"][data][entry]["obj"]["A"] or {}
                      table.insert(pfDB["quests"][data][entry]["obj"]["A"], tonumber(id))
                  end

                  for id in opairs(zones) do
                      pfDB["quests"][data][entry]["obj"]["Z"] = pfDB["quests"][data][entry]["obj"]["Z"] or {}
                      table.insert(pfDB["quests"][data][entry]["obj"]["Z"], tonumber(id))
                  end
              end

              -- quest starter
              local creature_questrelation = {}
              local starter_table = (core == "acore" and "creature_queststarter" or "creature_questrelation")
              local sql = [[
          SELECT * FROM ]] .. starter_table .. [[ WHERE ]] .. starter_table .. [[.quest = ]] .. quest_id
              local query = mysql:execute(sql)
              if query then
                  while query:fetch(creature_questrelation, "a") do
                      if debug("quests_starterunit") then break end
                      pfDB["quests"][data][entry]["start"] = pfDB["quests"][data][entry]["start"] or {}
                      pfDB["quests"][data][entry]["start"]["U"] = pfDB["quests"][data][entry]["start"]["U"] or {}
                      table.insert(pfDB["quests"][data][entry]["start"]["U"], tonumber(creature_questrelation.id))
                  end
              end

              local gameobject_questrelation = {}
              local go_starter_table = (core == "acore" and "gameobject_queststarter" or "gameobject_questrelation")
              local sql = [[
          SELECT * FROM ]] .. go_starter_table .. [[ WHERE ]] .. go_starter_table .. [[.quest = ]] .. quest_id
              local query = mysql:execute(sql)
              if query then
                  while query:fetch(gameobject_questrelation, "a") do
                      if debug("quests_starterobject") then break end
                      pfDB["quests"][data][entry]["start"] = pfDB["quests"][data][entry]["start"] or {}
                      pfDB["quests"][data][entry]["start"]["O"] = pfDB["quests"][data][entry]["start"]["O"] or {}
                      table.insert(pfDB["quests"][data][entry]["start"]["O"], tonumber(gameobject_questrelation.id))
                  end
              end

              local item_template = {}
              local sql = [[
          SELECT entry as id FROM item_template WHERE ]] .. C.startquest .. [[ = ]] .. quest_id
              local query = mysql:execute(sql)
              if query then
                  while query:fetch(item_template, "a") do
                      if debug("quests_starteritem") then break end

                      -- remove quest start items from objectives
                      if pfDB["quests"][data][entry]["obj"] and pfDB["quests"][data][entry]["obj"]["I"] then
                          for id, objective in pairs(pfDB["quests"][data][entry]["obj"]["I"]) do
                              if objective == tonumber(item_template.id) then
                                  pfDB["quests"][data][entry]["obj"]["I"][id] = nil
                              end
                          end
                      end

                      -- add item to quest starters
                      pfDB["quests"][data][entry]["start"] = pfDB["quests"][data][entry]["start"] or {}
                      pfDB["quests"][data][entry]["start"]["I"] = pfDB["quests"][data][entry]["start"]["I"] or {}
                      table.insert(pfDB["quests"][data][entry]["start"]["I"], tonumber(item_template.id))
                  end
              end

              -- quest ender
              local creature_involvedrelation = {}
              local ender_table = (core == "acore" and "creature_questender" or "creature_involvedrelation")
              local sql = [[
          SELECT * FROM ]] .. ender_table .. [[ WHERE ]] .. ender_table .. [[.quest = ]] .. quest_id
              local query = mysql:execute(sql)
              if query then
                  while query:fetch(creature_involvedrelation, "a") do
                      if debug("quests_enderunit") then break end
                      pfDB["quests"][data][entry]["end"] = pfDB["quests"][data][entry]["end"] or {}
                      pfDB["quests"][data][entry]["end"]["U"] = pfDB["quests"][data][entry]["end"]["U"] or {}
                      table.insert(pfDB["quests"][data][entry]["end"]["U"], tonumber(creature_involvedrelation.id))
                  end
              end

              local gameobject_involvedrelation = {}
              local first = true
              local go_ender_table = (core == "acore" and "gameobject_questender" or "gameobject_involvedrelation")
              local sql = [[
          SELECT * FROM ]] .. go_ender_table .. [[ WHERE ]] .. go_ender_table .. [[.quest = ]] .. quest_id
              local query = mysql:execute(sql)
              if query then
                  while query:fetch(gameobject_involvedrelation, "a") do
                      if debug("quests_enderobject") then break end
                      pfDB["quests"][data][entry]["end"] = pfDB["quests"][data][entry]["end"] or {}
                      pfDB["quests"][data][entry]["end"]["O"] = pfDB["quests"][data][entry]["end"]["O"] or {}
                      table.insert(pfDB["quests"][data][entry]["end"]["O"], tonumber(gameobject_involvedrelation.id))
                  end
              end
          end
          end
      end
    end
  end

  do -- zones
    print("- loading zones...")
    pfDB["zones"] = pfDB["zones"] or {}
    pfDB["zones"][data] = {}

    if core == "acore" then
      -- For AzerothCore, extract zones from creature spawns since AreaTable_vanilla is empty
      local zones = {}
      local query = mysql:execute('SELECT DISTINCT zoneId, areaId FROM creature WHERE zoneId > 0')  -- NO LIMIT for zones
      if query then
        while query:fetch(zones, "a") do
          if debug("zones") then break end
          local zone_id = tonumber(zones.zoneId)
          local area_id = tonumber(zones.areaId)

          if zone_id and zone_id > 0 then
            pfDB["zones"][data][zone_id] = { zone_id, 100, 100, 50, 50 } -- zone, width, height, cx, cy
          end
          if area_id and area_id > 0 and area_id ~= zone_id then
            pfDB["zones"][data][area_id] = { zone_id or area_id, 100, 100, 50, 50 }
          end
        end
        print("  SUCCESS: Extracted " .. TableCount(pfDB["zones"][data]) .. " zones from creature spawns")
      else
        print("  Warning: Failed to query zones from creature table")
      end
    else
      -- Original zones logic for cores with pfquest DBC data
      local zones = {}
      local query = mysql:execute('SELECT * FROM pfquest.WorldMapOverlay_'..expansion..' LEFT JOIN pfquest.AreaTable_'..expansion..' ON pfquest.WorldMapOverlay_'..expansion..'.areaID = pfquest.AreaTable_'..expansion..'.id')
      while query:fetch(zones, "a") do
        if debug("zones") then break end
        local entry = tonumber(zones.id)
        local zone = tonumber(zones.zoneID)
        local textureWidth = tonumber(zones.textureWidth)
        local textureHeight = tonumber(zones.textureHeight)
        local offsetX = tonumber(zones.offsetX)
        local offsetY = tonumber(zones.offsetY)

        -- convert square to map scale
        local hitRectTop = tonumber(zones.hitRectTop)/668*100
        local hitRectLeft = tonumber(zones.hitRectLeft)/1002*100
        local hitRectBottom = tonumber(zones.hitRectBottom)/668*100
        local hitRectRight = tonumber(zones.hitRectRight)/1002*100

        -- area size
        local width = hitRectRight - hitRectLeft
        local height = hitRectBottom - hitRectTop

        -- area center
        local cx = (hitRectLeft+hitRectRight)/2
        local cy = (hitRectTop+hitRectBottom)/2

        if entry then
          pfDB["zones"][data][entry] = { zone, round(width,2), round(height,2), round(cx,2), round(cy,2)}
        end
      end
    end
  end

  do -- minimap
    print("- loading minimap...")

    pfDB["minimap"..exp] = pfDB["minimap"..exp] or {}

    if core == "acore" then
      -- For AzerothCore, use loaded DBC tables
      local minimap_size = {}
      local query = mysql:execute('SELECT * FROM WorldMapArea_'..expansion..' ORDER BY areatableID ASC')
      if query then
        print("  SUCCESS: WorldMapArea_" .. expansion .. " table found!")
        while query:fetch(minimap_size, "a") do
          if debug("minimap") then break end
          local mapID = minimap_size.mapID
          local areaID = minimap_size.areatableID
          local name = minimap_size.name
          local x_min = minimap_size.x_min
          local y_min = minimap_size.y_min
          local x_max = minimap_size.x_max
          local y_max = minimap_size.y_max

          local x = -1 * x_min + x_max
          local y = -1 * y_min + y_max

          pfDB["minimap"..exp][tonumber(areaID)] = { tonumber(y+.0), tonumber(x+.0) }
        end
        print("  SUCCESS: Extracted minimap from DBC tables")
      else
        print("  Warning: Failed to query minimap from DBC tables - run load_dbc.lua first")
      end
    else
      -- Test if pfquest database is available
      local minimap_size = {}
      local query = mysql:execute('SELECT * FROM pfquest.WorldMapArea_'..expansion..' ORDER BY areatableID ASC LIMIT 5')
      if query then
        print("  SUCCESS: pfquest.WorldMapArea_" .. expansion .. " table found!")
        while query:fetch(minimap_size, "a") do
          if debug("minimap") then break end
          local mapID = minimap_size.mapID
          local areaID = minimap_size.areatableID
          local name = minimap_size.name
          local x_min = minimap_size.x_min
          local y_min = minimap_size.y_min
          local x_max = minimap_size.x_max
          local y_max = minimap_size.y_max

          local x = -1 * x_min + x_max
          local y = -1 * y_min + y_max

          pfDB["minimap"..exp][tonumber(areaID)] = { tonumber(y+.0), tonumber(x+.0) }
          print("    Processed zone: " .. (name or "Unknown") .. " (ID: " .. areaID .. ")")
        end
      else
        print("  DISABLED: pfquest database not available")
      end
    end
  end

  do -- meta
    print("- loading meta...")

    pfDB["meta"..exp] = pfDB["meta"..exp] or {
      ["mines"] = {},
      ["herbs"] = {},
      ["chests"] = {},
      ["rares"] = {},
      ["flight"] = {},
    }

    do -- flightmasters
      local mask = core == "vmangos" and 8 or 8192
      local creature_template = {}

      if core == "acore" then
        -- For AzerothCore, get flightmasters without faction detection
        local npcflag_field = C.NpcFlags or "npcflag"
        local entry_field = C.Entry or "entry"
        local query = mysql:execute([[
          SELECT ]] .. entry_field .. [[ FROM `creature_template`
          WHERE ( ]] .. npcflag_field .. [[ & ]]..mask..[[) > 0
        ]])

        if query then
          while query:fetch(creature_template, "a") do
            if debug("meta_taxi") then break end
            local entry = tonumber(creature_template[entry_field])
            if entry then
              pfDB["meta"..exp]["flight"][entry] = "AH" -- Default to both factions for AC
            end
          end
        else
          print("  Warning: Failed to execute flightmasters query")
        end
      else
        -- Original logic for other cores
        local query = mysql:execute([[
          SELECT Entry, A, H FROM `creature_template`, `pfquest`.FactionTemplate_]]..expansion..[[
          WHERE pfquest.FactionTemplate_]]..expansion..[[.factiontemplateID = creature_template.]] .. C.Faction .. [[
          AND ( ]] .. C.NpcFlags .. [[ & ]]..mask..[[) > 1
        ]])

        if query then
          while query:fetch(creature_template, "a") do
            if debug("meta_taxi") then break end
            local fac = ""
            local entry = tonumber(creature_template.Entry)
            local A = tonumber(creature_template.A)
            local H = tonumber(creature_template.H)
            if A >= 0 then fac = fac .. "A" end
            if H >= 0 then fac = fac .. "H" end
            pfDB["meta"..exp]["flight"][entry] = fac
          end
        end
      end
    end

    do -- raremobs
      local creature_template = {}
      local rank_field = C.Rank or "rank"
      local limit_clause = UNITS_LIMIT and (' LIMIT ' .. UNITS_LIMIT) or ''  -- Use UNITS_LIMIT for raremobs
      local query = mysql:execute([[
        SELECT * FROM `creature_template` WHERE ]] .. rank_field .. [[ = 4 OR ]] .. rank_field .. [[ = 2 ORDER BY entry]] .. limit_clause)

      if query then
        while query:fetch(creature_template, "a") do
          if debug("meta_rares") then break end
          local entry_field = C.Entry or "entry"
          local minlevel_field = C.MinLevel or "minlevel"
          local entry = tonumber(creature_template[entry_field])
          local level = tonumber(creature_template[minlevel_field])
          if entry and level then
            pfDB["meta"..exp].rares[entry] = level
          end
        end
      else
        print("  Warning: Failed to execute raremobs query")
      end
    end

    do -- gameobject relations
      if core == "acore" then
        -- For AzerothCore, use loaded DBC Lock table
        local gameobject_template = {}
        local limit_clause = OBJECTS_LIMIT and (' LIMIT ' .. OBJECTS_LIMIT) or ''  -- Use OBJECTS_LIMIT for gameobjects
        local query = mysql:execute([[
          SELECT * FROM `gameobject_template`, Lock_]]..expansion..[[
          WHERE `type` = 3 AND `locktype` = 2 AND `flags` = 0 AND `data1` > 0 and id = data0 GROUP BY `gameobject_template`.entry ORDER BY `gameobject_template`.entry ASC]] .. limit_clause .. [[
        ]])

        if not query then
          -- Fallback without Lock table
          query = mysql:execute([[
            SELECT * FROM `gameobject_template`
            WHERE `type` = 3 AND `data1` > 0
            ORDER BY entry ASC]] .. limit_clause .. [[
          ]])
        end

        if query then
          while query:fetch(gameobject_template, "a") do
            if debug("meta_farm") then break end
            local entry   = tonumber(gameobject_template.entry) * -1
            local data = tonumber(gameobject_template.data)
            local skill = tonumber(gameobject_template.skill)
            if data == 1 then
              pfDB["meta"..exp]["chests"][entry] = skill
            elseif data == 2 then
              pfDB["meta"..exp]["herbs"][entry] = skill
            elseif data == 3 then
              pfDB["meta"..exp]["mines"][entry] = skill
            end
          end
          print("  SUCCESS: Extracted gameobject relations from DBC tables")
        else
          print("  Warning: Failed to query gameobject relations from DBC tables - run load_dbc.lua first")
        end
      else
        -- Original logic for other cores
        local gameobject_template = {}
        local query = mysql:execute([[
          SELECT * FROM `gameobject_template`, pfquest.Lock_]]..expansion..[[
          WHERE `type` = 3 AND `locktype` = 2 AND `flags` = 0 AND `data1` > 0 and id = data0 GROUP BY `gameobject_template`.entry ORDER BY `gameobject_template`.entry ASC
        ]])

        if query then
          while query:fetch(gameobject_template, "a") do
            if debug("meta_farm") then break end
            local entry   = tonumber(gameobject_template.entry) * -1
            local data = tonumber(gameobject_template.data)
            local skill = tonumber(gameobject_template.skill)
            if data == 1 then
              pfDB["meta"..exp]["chests"][entry] = skill
            elseif data == 2 then
              pfDB["meta"..exp]["herbs"][entry] = skill
            elseif data == 3 then
              pfDB["meta"..exp]["mines"][entry] = skill
            end
          end
        end
      end
    end
  end

  print("- loading locales...")
  do -- unit locales
    if core == "acore" then
      -- AzerothCore uses separate locale records
      for loc in pairs(locales) do
        local locales_creature = {}
        local locale_code = GetLocaleCode(loc)

        local query = mysql:execute('SELECT creature_template.entry, creature_template.name FROM creature_template ORDER BY creature_template.entry ASC')

        if query then
          while query:fetch(locales_creature, "a") do
            if debug("locales_unit") then break end

            local entry = tonumber(locales_creature.entry)
            local name = locales_creature.name
            local locale_name = locales_creature.locale_name

            if entry then
              local final_name = locale_name or name or ""
              if final_name ~= "" then
                local locale = loc .. ( expansion ~= "vanilla" and "-" .. expansion or "" )
                pfDB["units"][locale] = pfDB["units"][locale] or { [420] = "Shagu" }
                pfDB["units"][locale][entry] = sanitize(final_name)
              end
            end
          end
        else
          print("  Warning: Failed to execute unit locales query for " .. loc)
        end
      end
    else
      -- Original MaNGOS logic
      local locales_creature = {}
      local creature_loc_pk_col = "entry"
      local creature_template_pk_col = "entry"

      local query = mysql:execute('SELECT *, creature_template.'..creature_template_pk_col..' AS _entry FROM creature_template LEFT JOIN ' .. (C.locales_creature or "creature_template_locale") .. ' ON ' .. (C.locales_creature or "creature_template_locale") .. '.' .. creature_loc_pk_col .. ' = creature_template.' .. creature_template_pk_col .. ' GROUP BY creature_template.' .. creature_template_pk_col .. ' ORDER BY creature_template.' .. creature_template_pk_col .. ' ASC')

      if query then
        while query:fetch(locales_creature, "a") do
          if debug("locales_unit") then break end

          local entry = tonumber(locales_creature["_entry"])
          local name = locales_creature["name"]

          if entry then
            for loc in pairs(locales) do
              local name_loc_col = "name_loc" .. GetLocaleNumber(loc)
              local name_loc = locales_creature[name_loc_col]
              if not name_loc or name_loc == "" then name_loc = name or "" end
              if name_loc and name_loc ~= "" then
                local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
                pfDB["units"][locale] = pfDB["units"][locale] or { [420] = "Shagu" }
                pfDB["units"][locale][entry] = sanitize(name_loc)
              end
            end
          end
        end
      else
        print("  Warning: Failed to execute unit locales query")
      end
    end
  end

  do -- objects locales
    if core == "acore" then
      -- AzerothCore uses separate locale records
      for loc in pairs(locales) do
        local locales_gameobject = {}
        local locale_code = GetLocaleCode(loc)
        local limit_clause = OBJECTS_LIMIT and (' LIMIT ' .. OBJECTS_LIMIT) or ''  -- Use OBJECTS_LIMIT

        -- Try simple query without locale table since it may not exist
        local query = mysql:execute('SELECT entry, name FROM gameobject_template ORDER BY entry ASC' .. limit_clause)

        if query then
          while query:fetch(locales_gameobject, "a") do
            if debug("locales_object") then break end

            local entry = tonumber(locales_gameobject.entry)
            local name = locales_gameobject.name
            -- No locale_name since we're using simplified query

            if entry then
              local final_name = name or ""
              if final_name ~= "" then
                local locale = loc .. ( expansion ~= "vanilla" and "-" .. expansion or "" )
                pfDB["objects"][locale] = pfDB["objects"][locale] or {}
                pfDB["objects"][locale][entry] = sanitize(final_name)
              end
            end
          end
        else
          print("  Warning: Failed to execute objects locales query for " .. loc)
        end
      end
    else
      -- Original MaNGOS logic
      local locales_gameobject = {}
      local go_loc_pk_col = "entry"
      local go_template_pk_col = "entry"

      local query = mysql:execute('SELECT *, gameobject_template.'..go_template_pk_col..' AS _entry FROM gameobject_template LEFT JOIN ' .. (C.locales_gameobject or "gameobject_template_locale") .. ' ON ' .. (C.locales_gameobject or "gameobject_template_locale") .. '.' .. go_loc_pk_col .. ' = gameobject_template.' .. go_template_pk_col .. ' GROUP BY gameobject_template.' .. go_template_pk_col .. ' ORDER BY gameobject_template.' .. go_template_pk_col .. ' ASC')

      if query then
        while query:fetch(locales_gameobject, "a") do
          if debug("locales_object") then break end

          local entry = tonumber(locales_gameobject["_entry"])
          local name = locales_gameobject["name"]

          if entry then
            for loc in pairs(locales) do
              local name_loc_col = "name_loc" .. GetLocaleNumber(loc)
              local name_loc = locales_gameobject[name_loc_col]
              if not name_loc or name_loc == "" then name_loc = name or "" end
              if name_loc and name_loc ~= "" then
                local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
                pfDB["objects"][locale] = pfDB["objects"][locale] or {}
                pfDB["objects"][locale][entry] = sanitize(name_loc)
              end
            end
          end
        end
      else
        print("  Warning: Failed to execute objects locales query")
      end
    end
  end

  do -- items locales
    if core == "acore" then
      -- AzerothCore uses separate locale records
      for loc in pairs(locales) do
        local locales_item = {}
        local locale_code = GetLocaleCode(loc)
        local limit_clause = ITEMS_LIMIT and (' LIMIT ' .. ITEMS_LIMIT) or ''  -- Use ITEMS_LIMIT

        local query = mysql:execute('SELECT item_template.entry, item_template.name, item_template_locale.Name AS locale_name FROM item_template LEFT JOIN item_template_locale ON item_template_locale.ID = item_template.entry AND item_template_locale.locale = \'' .. locale_code .. '\' ORDER BY item_template.entry ASC' .. limit_clause)

        if query then
          while query:fetch(locales_item, "a") do
            if debug("locales_item") then break end

            local entry = tonumber(locales_item.entry)
            local name = locales_item.name
            local locale_name = locales_item.locale_name

            if entry then
              local final_name = locale_name or name or ""
              if final_name ~= "" then
                local locale = loc .. ( expansion ~= "vanilla" and "-" .. expansion or "" )
                pfDB["items"][locale] = pfDB["items"][locale] or {}
                pfDB["items"][locale][entry] = sanitize(final_name)
              end
            end
          end
        else
          print("  Warning: Failed to execute items locales query for " .. loc)
        end
      end
    else
      -- Original MaNGOS logic
      local locales_item = {}
      local item_loc_pk_col = "entry"
      local item_template_pk_col = "entry"

      local query = mysql:execute('SELECT *, item_template.'..item_template_pk_col..' AS _entry FROM item_template LEFT JOIN ' .. (C.locales_item or "item_template_locale") .. ' ON ' .. (C.locales_item or "item_template_locale") .. '.' .. item_loc_pk_col .. ' = item_template.' .. item_template_pk_col .. ' GROUP BY item_template.' .. item_template_pk_col .. ' ORDER BY item_template.' .. item_template_pk_col .. ' ASC')

      if query then
        while query:fetch(locales_item, "a") do
          if debug("locales_item") then break end

          local entry = tonumber(locales_item["_entry"])
          local name = locales_item["name"]

          if entry then
            for loc in pairs(locales) do
              local name_loc_col = "name_loc" .. GetLocaleNumber(loc)
              local name_loc = locales_item[name_loc_col]
              if not name_loc or name_loc == "" then name_loc = name or "" end
              if name_loc and name_loc ~= "" then
                local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
                pfDB["items"][locale] = pfDB["items"][locale] or {}
                pfDB["items"][locale][entry] = sanitize(name_loc)
              end
            end
          end
        end
      else
        print("  Warning: Failed to execute items locales query")
      end
    end
  end

  do -- quests locales
    if core == "acore" then
      -- AzerothCore uses separate locale records
      for loc in pairs(locales) do
        local locales_quest = {}
        local locale_code = GetLocaleCode(loc)
        local limit_clause = QUEST_LIMIT and (' LIMIT ' .. QUEST_LIMIT) or ''  -- Use QUEST_LIMIT

        local query = mysql:execute('SELECT quest_template.ID, quest_template.LogTitle, quest_template.QuestDescription, quest_template.LogDescription, quest_template_locale.Title AS locale_title, quest_template_locale.Details AS locale_details, quest_template_locale.Objectives AS locale_objectives FROM quest_template LEFT JOIN quest_template_locale ON quest_template_locale.ID = quest_template.ID AND quest_template_locale.locale = \'' .. locale_code .. '\' ORDER BY quest_template.ID ASC' .. limit_clause)

        if query then
          while query:fetch(locales_quest, "a") do
            if debug("locales_quest") then break end

            local entry = tonumber(locales_quest.ID)

            if entry then
              local locale = loc .. ( expansion ~= "vanilla" and "-" .. expansion or "" )
              pfDB["quests"][locale] = pfDB["quests"][locale] or {}

              local title = locales_quest.locale_title or locales_quest.LogTitle or ""
              local details = locales_quest.locale_details or locales_quest.QuestDescription or ""
              local objectives = locales_quest.locale_objectives or locales_quest.LogDescription or ""

              pfDB["quests"][locale][entry] = {
                ["T"] = sanitize(title),
                ["O"] = sanitize(objectives),
                ["D"] = sanitize(details)
              }
            end
          end
        else
          print("  Warning: Failed to execute quests locales query for " .. loc)
        end
      end
    else
      -- Original MaNGOS logic
      local locales_quest = {}
      local quest_loc_pk_col = "entry"
      local quest_template_pk_col = "entry"

      local query = mysql:execute('SELECT *, quest_template.'..quest_template_pk_col..' AS _entry FROM quest_template LEFT JOIN ' .. (C.locales_quest or "quest_template_locale") .. ' ON ' .. (C.locales_quest or "quest_template_locale") ..'.' .. quest_loc_pk_col .. ' = quest_template.' .. quest_template_pk_col .. ' GROUP BY quest_template.' .. quest_template_pk_col .. ' ORDER BY quest_template.' .. quest_template_pk_col .. ' ASC')

      if query then
        while query:fetch(locales_quest, "a") do
          if debug("locales_quest") then break end

          for loc in pairs(locales) do
            local entry = tonumber(locales_quest["_entry"])

            if entry then
              local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
              pfDB["quests"][locale] = pfDB["quests"][locale] or {}

              local title_loc = locales_quest["Title_loc" .. locales[loc]]
              local details_loc = locales_quest["Details_loc" .. locales[loc]]
              local objectives_loc = locales_quest["Objectives_loc" .. locales[loc]]

              if not title_loc or title_loc == "" then title_loc = locales_quest.Title or "" end
              if not details_loc or details_loc == "" then details_loc = locales_quest.Details or "" end
              if not objectives_loc or objectives_loc == "" then objectives_loc = locales_quest.Objectives or "" end

              pfDB["quests"][locale][entry] = {
                ["T"] = sanitize(title_loc),
                ["O"] = sanitize(objectives_loc),
                ["D"] = sanitize(details_loc)
              }
            end
          end
        end
      else
        print("  Warning: Failed to execute quests locales query")
      end
    end
  end

  do -- professions locales
    pfDB["professions"] = {}

    if core == "acore" then
      -- For AzerothCore, use loaded DBC SkillLine table
      local locales_professions = {}
      local query = mysql:execute('SELECT * FROM SkillLine_'..expansion..' ORDER BY id ASC')
      if query then
        while query:fetch(locales_professions, "a") do
          if debug("locales_profession") then break end

          local entry = tonumber(locales_professions.id)

          if entry then
            for loc in pairs(locales) do
              local name = locales_professions["name_loc0"] -- Only enUS from DBC
              if name and name ~= "" then
                local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
                pfDB["professions"][locale] = pfDB["professions"][locale] or {}
                pfDB["professions"][locale][entry] = sanitize(name)
              end
            end
          end
        end
        print("  SUCCESS: Extracted professions locales from DBC tables")
      else
        print("  Warning: Failed to query professions locales from DBC tables - run load_dbc.lua first")
      end
    else
      -- Original logic for other cores
      local locales_professions = {}
      local query = mysql:execute('SELECT * FROM pfquest.SkillLine_'..expansion..' ORDER BY id ASC')
      if query then
        while query:fetch(locales_professions, "a") do
          if debug("locales_profession") then break end

          local entry = tonumber(locales_professions.id)

          if entry then
            for loc in pairs(locales) do
              local name = locales_professions["name_loc" .. locales[loc]]
              if name and name ~= "" then
                local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
                pfDB["professions"][locale] = pfDB["professions"][locale] or {}
                pfDB["professions"][locale][entry] = sanitize(name)
              end
            end
          end
        end
      end
    end
  end

  do -- zones locales
    if core == "acore" then
      -- For AzerothCore, use loaded DBC AreaTable table
      local locales_zones = {}
      local table_name = "AreaTable_" .. expansion
      print("  Attempting to query zones from table: " .. table_name)

      local query = mysql:execute('SELECT * FROM ' .. table_name .. ' ORDER BY id ASC')  -- NO LIMIT for zones
      if query then
        while query:fetch(locales_zones, "a") do
          if debug("locales_zone") then break end

          local entry = tonumber(locales_zones.id)

          if entry then
            for loc in pairs(locales) do
              local name = locales_zones["name_loc0"] -- Only enUS from DBC
              if name and name ~= "" then
                local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
                pfDB["zones"][locale] = pfDB["zones"][locale] or {}
                pfDB["zones"][locale][entry] = sanitize(name)
              end
            end
          end
        end
        print("  SUCCESS: Extracted zones locales from DBC tables")
      else
        print("  Warning: Failed to query zones from table " .. table_name .. " - checking alternative names")

        -- Try alternative table names
        local alt_names = {"AreaTable", "pfquest.AreaTable_" .. expansion}
        for _, alt_name in ipairs(alt_names) do
          local alt_query = mysql:execute('SELECT * FROM ' .. alt_name .. ' ORDER BY id ASC LIMIT 10')
          if alt_query then
            print("  SUCCESS: Found zones table as " .. alt_name)
            while alt_query:fetch(locales_zones, "a") do
              if debug("locales_zone") then break end
              local entry = tonumber(locales_zones.id)
              if entry then
                for loc in pairs(locales) do
                  local name = locales_zones["name_loc0"]
                  if name and name ~= "" then
                    local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
                    pfDB["zones"][locale] = pfDB["zones"][locale] or {}
                    pfDB["zones"][locale][entry] = sanitize(name)
                  end
                end
              end
            end
            break
          else
            print("  Warning: Table " .. alt_name .. " not found")
          end
        end
      end
    else
      -- Original logic for other cores
      local locales_zones = {}
      local query = mysql:execute('SELECT * FROM pfquest.AreaTable_'..expansion..' ORDER BY id ASC')
      if query then
        while query:fetch(locales_zones, "a") do
          if debug("locales_zone") then break end

          local entry = tonumber(locales_zones.id)

          if entry then
            for loc in pairs(locales) do
              local name = locales_zones["name_loc" .. locales[loc]]
              if name and name ~= "" then
                local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
                pfDB["zones"][locale] = pfDB["zones"][locale] or {}
                pfDB["zones"][locale][entry] = sanitize(name)
              end
            end
          end
        end
      end
    end
  end

  if expansion ~= "vanilla" then
    print("- compress DB")
    pfDB["areatrigger"][data] = tablesubstract(pfDB["areatrigger"][data], pfDB["areatrigger"]["data"])
    pfDB["units"][data] = tablesubstract(pfDB["units"][data], pfDB["units"]["data"])
    pfDB["objects"][data] = tablesubstract(pfDB["objects"][data], pfDB["objects"]["data"])
    pfDB["items"][data] = tablesubstract(pfDB["items"][data], pfDB["items"]["data"])
    pfDB["refloot"][data] = tablesubstract(pfDB["refloot"][data], pfDB["refloot"]["data"])
    pfDB["quests"][data] = tablesubstract(pfDB["quests"][data], pfDB["quests"]["data"])
    pfDB["quests-itemreq"][data] = tablesubstract(pfDB["quests-itemreq"][data], pfDB["quests-itemreq"]["data"])
    pfDB["zones"][data] = tablesubstract(pfDB["zones"][data], pfDB["zones"]["data"])
    pfDB["minimap"..exp] = tablesubstract(pfDB["minimap"..exp], pfDB["minimap"])
    pfDB["meta"..exp] = tablesubstract(pfDB["meta"..exp], pfDB["meta"])

    for loc in pairs(locales) do
      local locale = loc .. exp
      local prev_locale = loc

      pfDB["units"][locale] = pfDB["units"][locale] and tablesubstract(pfDB["units"][locale], pfDB["units"][prev_locale]) or {}
      pfDB["objects"][locale] = pfDB["objects"][locale] and tablesubstract(pfDB["objects"][locale], pfDB["objects"][prev_locale]) or {}
      pfDB["items"][locale] = pfDB["items"][locale] and tablesubstract(pfDB["items"][locale], pfDB["items"][prev_locale]) or {}
      pfDB["quests"][locale] = pfDB["quests"][locale] and tablesubstract(pfDB["quests"][locale], pfDB["quests"][prev_locale]) or {}
      pfDB["zones"][locale] = pfDB["zones"][locale] and tablesubstract(pfDB["zones"][locale], pfDB["zones"][prev_locale]) or {}
      pfDB["professions"][locale] = pfDB["professions"][locale] and tablesubstract(pfDB["professions"][locale], pfDB["professions"][prev_locale]) or {}
    end
  end

  -- write down tables
  print("- writing database...")
  local output = settings.custom and "output/custom/" or "output/"

  mkdir(output)
  serialize(output .. string.format("areatrigger%s.lua", exp), "pfDB[\"areatrigger\"][\""..data.."\"]", pfDB["areatrigger"][data])
  serialize(output .. string.format("units%s.lua", exp), "pfDB[\"units\"][\""..data.."\"]", pfDB["units"][data])
  serialize(output .. string.format("objects%s.lua", exp), "pfDB[\"objects\"][\""..data.."\"]", pfDB["objects"][data])
  serialize(output .. string.format("items%s.lua", exp), "pfDB[\"items\"][\""..data.."\"]", pfDB["items"][data])
  serialize(output .. string.format("refloot%s.lua", exp), "pfDB[\"refloot\"][\""..data.."\"]", pfDB["refloot"][data])
  serialize(output .. string.format("quests%s.lua", exp), "pfDB[\"quests\"][\""..data.."\"]", pfDB["quests"][data])
  serialize(output .. string.format("quests-itemreq%s.lua", exp), "pfDB[\"quests-itemreq\"][\""..data.."\"]", pfDB["quests-itemreq"][data])
  serialize(output .. string.format("zones%s.lua", exp), "pfDB[\"zones\"][\""..data.."\"]", pfDB["zones"][data])
  serialize(output .. string.format("minimap%s.lua", exp), "pfDB[\"minimap"..exp.."\"]", pfDB["minimap"..exp])
  serialize(output .. string.format("meta%s.lua", exp), "pfDB[\"meta"..exp.."\"]", pfDB["meta"..exp])

  for loc in pairs(locales) do
    local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )

    mkdir(output .. loc)
    serialize(output .. string.format("%s/units%s.lua", loc, exp), "pfDB[\"units\"][\""..locale.."\"]", pfDB["units"][locale])
    serialize(output .. string.format("%s/objects%s.lua", loc, exp), "pfDB[\"objects\"][\""..locale.."\"]", pfDB["objects"][locale])
    serialize(output .. string.format("%s/items%s.lua", loc, exp), "pfDB[\"items\"][\""..locale.."\"]", pfDB["items"][locale])
    serialize(output .. string.format("%s/quests%s.lua", loc, exp), "pfDB[\"quests\"][\""..locale.."\"]", pfDB["quests"][locale])
    serialize(output .. string.format("%s/professions%s.lua", loc, exp), "pfDB[\"professions\"][\""..locale.."\"]", pfDB["professions"][locale])
    serialize(output .. string.format("%s/zones%s.lua", loc, exp), "pfDB[\"zones\"][\""..locale.."\"]", pfDB["zones"][locale])
  end

  -- Create minimal empty init.lua to avoid 'block too big' error
  if not settings.custom then
    local init_file = io.open(output .. "init.lua", "w")
    if init_file then
      init_file:write([[pfDB = {
  ["areatrigger"] = {},
  ["items"] = {},
  ["meta"] = {},
  ["minimap"] = {},
  ["objects"] = {},
  ["professions"] = {},
  ["quests"] = {},
  ["quests-itemreq"] = {},
  ["refloot"] = {},
  ["units"] = {},
  ["zones"] = {},
}
]])
      init_file:close()
      print("Created empty init.lua")
    end
  end

  debug_statistics()
else
  print("Error: Expansion '" .. expansion_to_process .. "' not found in config.expansions")
end

-- Close main processing
