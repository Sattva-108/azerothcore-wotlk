local loc = GetLocale()
local dbs = { "items", "quests", "quests-itemreq", "objects", "units", "zones", "professions", "areatrigger", "refloot" }
local noloc = { "items", "quests", "objects", "units" }

-- Patch databases to merge ascension data
local function patchtable(base, diff)
  for k, v in pairs(diff) do
    if base[k] and type(v) == "table" then
      patchtable(base[k], v)
    elseif type(v) == "string" and v == "_" then
      base[k] = nil
    else
      base[k] = v
    end
  end
end
-- fix map-id 1519 spawns [Stormwind]
for _, obj in pairs(pfDB["objects"]["data"]) do
  if obj.coords then
    for num, tbl in pairs(obj.coords) do
      if tbl[3] == 1519 then -- map
        tbl[1] = tbl[1] + 6.8 -- x
        tbl[2] = tbl[2] + 10.1 -- y
      end
    end
  end
end
-- fix map-id 1519 spawns [Stormwind]
for _, obj in pairs(pfDB["units"]["data"]) do
  if obj.coords then
    for num, tbl in pairs(obj.coords) do
      if tbl[3] == 1519 then -- map
        tbl[1] = tbl[1] + 6.8 -- x
        tbl[2] = tbl[2] + 10.1 -- y
      end
    end
  end
end
-- fix map-id 1519 spawns [Stormwind]
for _, obj in pairs(pfDB["areatrigger"]["data"]) do
  if obj.coords then
    for num, tbl in pairs(obj.coords) do
      if tbl[3] == 1519 then -- map
        tbl[1] = tbl[1] + 6.8 -- x
        tbl[2] = tbl[2] + 10.1 -- y
      end
    end
  end
end
local loc_core, loc_update
for _, db in pairs(dbs) do
  if pfDB[db]["data-ascension"] then
    patchtable(pfDB[db]["data"], pfDB[db]["data-ascension"])
  end

  for loc, _ in pairs(pfDB.locales) do
    if pfDB[db][loc] and pfDB[db][loc.."-ascension"] then
      loc_update = pfDB[db][loc.."-ascension"] or pfDB[db]["enUS-ascension"]
      patchtable(pfDB[db][loc], loc_update)
    end
  end
end

loc_core = pfDB["professions"][loc] or pfDB["professions"]["enUS"]
loc_update = pfDB["professions"][loc.."-ascension"] or pfDB["professions"]["enUS-ascension"]
if loc_update then patchtable(loc_core, loc_update) end

if pfDB["minimap-ascension"] then 
  -- Debug: Show original Durotar data before patch (both ID=4 and ID=14)
  local durotar4_original = pfDB["minimap"][4] and "{" .. pfDB["minimap"][4][1] .. ", " .. pfDB["minimap"][4][2] .. "}" or "MISSING"
  local durotar4_patch = pfDB["minimap-ascension"][4] and "{" .. pfDB["minimap-ascension"][4][1] .. ", " .. pfDB["minimap-ascension"][4][2] .. "}" or "MISSING"
  local durotar14_original = pfDB["minimap"][14] and "{" .. pfDB["minimap"][14][1] .. ", " .. pfDB["minimap"][14][2] .. "}" or "MISSING"
  local durotar14_patch = pfDB["minimap-ascension"][14] and "{" .. pfDB["minimap-ascension"][14][1] .. ", " .. pfDB["minimap-ascension"][14][2] .. "}" or "MISSING"
  
  patchtable(pfDB["minimap"], pfDB["minimap-ascension"])
  
  -- Fix Durotar Map ID mapping - copy correct sizes from ID=4 to ID=14
  if pfDB["minimap"][4] and pfDB["minimap"][14] then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Fixing Durotar: copying ID=4 size to ID=14|r")
    pfDB["minimap"][14] = { pfDB["minimap"][4][1], pfDB["minimap"][4][2] }
  end 
  
  -- Debug: Show Durotar data after patch  
  local durotar4_final = pfDB["minimap"][4] and "{" .. pfDB["minimap"][4][1] .. ", " .. pfDB["minimap"][4][2] .. "}" or "MISSING"
  local durotar14_final = pfDB["minimap"][14] and "{" .. pfDB["minimap"][14][1] .. ", " .. pfDB["minimap"][14][2] .. "}" or "MISSING"
  
  -- Delayed message with timer
  local debugTimer = CreateFrame("Frame")
  debugTimer.elapsed = 0
  debugTimer:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1
    if this.elapsed >= 3 then
      local count = 0; for k,v in pairs(pfDB["minimap-ascension"]) do count = count + 1 end
      DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00pfQuest-ascension: minimap patch applied with " .. count .. " zones|r")
      DEFAULT_CHAT_FRAME:AddMessage("|cffyellow=== DUROTAR DEBUG ===|r")
      DEFAULT_CHAT_FRAME:AddMessage("|cffccccccID=4  Orig: " .. durotar4_original .. " Patch: " .. durotar4_patch .. " Final: " .. durotar4_final .. "|r")
      DEFAULT_CHAT_FRAME:AddMessage("|cffccccccID=14 Orig: " .. durotar14_original .. " Patch: " .. durotar14_patch .. " Final: " .. durotar14_final .. "|r")
      DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Durotar fix applied - check zone info above|r")
      
      -- Real-time zone debug
      local zoneTimer = CreateFrame("Frame")
      zoneTimer.elapsed = 0
      zoneTimer.lastZone = ""
      zoneTimer:SetScript("OnUpdate", function()
        this.elapsed = this.elapsed + arg1
        if this.elapsed >= 2 then
          this.elapsed = 0
          local currentZone = GetRealZoneText()
          if currentZone ~= this.lastZone and currentZone ~= "" then
            this.lastZone = currentZone
            local mapID = pfMap and pfMap.GetMapIDByName and pfMap:GetMapIDByName(currentZone)
            if mapID then
              local zoneSize = pfDB["minimap"][mapID] and "{" .. pfDB["minimap"][mapID][1] .. ", " .. pfDB["minimap"][mapID][2] .. "}" or "MISSING"
              DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Zone: " .. currentZone .. " (ID=" .. mapID .. ") Size: " .. zoneSize .. "|r")
            else
              DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Zone: " .. currentZone .. " - NO MAP ID FOUND|r")
            end
          end
        end
      end)
      
      this:SetScript("OnUpdate", nil)
    end
  end)
else
  -- Show error if file not loaded
  local errorTimer = CreateFrame("Frame")
  errorTimer.elapsed = 0
  errorTimer:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1
    if this.elapsed >= 3 then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff0000pfQuest-ascension: ERROR - minimap-ascension.lua not loaded!|r")
      this:SetScript("OnUpdate", nil)
    end
  end)
end
if pfDB["meta-ascension"] then patchtable(pfDB["meta"], pfDB["meta-ascension"]) end

-- Fix missing minimap_zoom variable in pfQuest master map.lua
if not minimap_zoom then
  minimap_zoom = {
    [0] = { [0] = 300,
            [1] = 240,
            [2] = 180,
            [3] = 120,
            [4] = 80,
            [5] = 50,
    },

    [1] = { [0] = 466 + 2/3,
            [1] = 400,
            [2] = 333 + 1/3,
            [3] = 266 + 2/6,
            [4] = 200,
            [5] = 133 + 1/3,
    },
  }
end

-- Fix for Minimap:GetViewRadius() returning nil
local originalGetViewRadius = Minimap.GetViewRadius
Minimap.GetViewRadius = function(self)
  local radius = originalGetViewRadius(self)
  if not radius or radius == 0 then
    -- Default fallback radius for outdoor zones
    return 100
  end
  return radius
end

-- Fix minimap_zoom access with safe fallback
local originalMinimap_indoor = minimap_indoor
minimap_indoor = function()
  local state = originalMinimap_indoor()
  -- Ensure state is valid (0 or 1)
  if not state or (state ~= 0 and state ~= 1) then
    return 0  -- Default to outdoor
  end
  return state
end

-- Extend minimap_zoom table for higher zoom levels (6, 7, 8, etc.)
if minimap_zoom then
  -- Extend [0] table (outdoor)
  if not minimap_zoom[0][6] then minimap_zoom[0][6] = 40 end
  if not minimap_zoom[0][7] then minimap_zoom[0][7] = 30 end
  if not minimap_zoom[0][8] then minimap_zoom[0][8] = 20 end
  
  -- Extend [1] table (indoor)
  if not minimap_zoom[1][6] then minimap_zoom[1][6] = 100 end
  if not minimap_zoom[1][7] then minimap_zoom[1][7] = 80 end
  if not minimap_zoom[1][8] then minimap_zoom[1][8] = 60 end
end

-- SIMPLE FIX: Just add missing zoom levels to the original table
-- This will prevent the nil access error
local timer = CreateFrame("Frame")
timer.elapsed = 0
timer:SetScript("OnUpdate", function()
  this.elapsed = this.elapsed + arg1
  if this.elapsed >= 1 then
    -- Add missing zoom levels every second until they exist
    if minimap_zoom and minimap_zoom[0] and minimap_zoom[1] then
      -- Add missing outdoor zoom levels (index 0)
      if not minimap_zoom[0][6] then minimap_zoom[0][6] = 40 end
      if not minimap_zoom[0][7] then minimap_zoom[0][7] = 30 end
      if not minimap_zoom[0][8] then minimap_zoom[0][8] = 20 end
      if not minimap_zoom[0][9] then minimap_zoom[0][9] = 15 end
      
      -- Add missing indoor zoom levels (index 1)  
      if not minimap_zoom[1][6] then minimap_zoom[1][6] = 100 end
      if not minimap_zoom[1][7] then minimap_zoom[1][7] = 80 end
      if not minimap_zoom[1][8] then minimap_zoom[1][8] = 60 end
      if not minimap_zoom[1][9] then minimap_zoom[1][9] = 45 end
      
      -- Once fixed, disable this timer
      this:SetScript("OnUpdate", nil)
      DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00pfQuest: minimap zoom levels fixed - minimap should work now|r")
    end
    this.elapsed = 0
  end
end)

-- Reload all pfQuest internal database shortcuts
pfDatabase:Reload()