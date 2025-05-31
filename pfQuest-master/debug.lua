-- pfQuest Debug Script - Enhanced Analysis
-- Usage: /pftest and /pfq <questID>

local function findWorkingQuests()
    if not pfDB then
        print("❌ pfDB not loaded")
        return {}
    end

    if not pfDB["quests"] or not pfDB["quests"]["data"] then
        print("❌ No quest data found")
        return {}
    end

    local workingQuests = {}

    for questId, quest in pairs(pfDB["quests"]["data"]) do
        -- A quest is "working" if it has both start and end NPCs/objects
        local hasStarter = false
        local hasFinisher = false

        -- Check for quest starters
        if quest.start then
            if (quest.start.U and #quest.start.U > 0) or
               (quest.start.O and #quest.start.O > 0) or
               (quest.start.I and #quest.start.I > 0) then
                hasStarter = true
            end
        end

        -- Check for quest finishers (using "end" field)
        if quest["end"] then
            if (quest["end"].U and #quest["end"].U > 0) or
               (quest["end"].O and #quest["end"].O > 0) then
                hasFinisher = true
            end
        end

        if hasStarter and hasFinisher then
            table.insert(workingQuests, questId)
        end
    end

    -- Sort quest IDs
    table.sort(workingQuests)

    return workingQuests
end

SLASH_PFTEST1 = "/pftest"
SlashCmdList["PFTEST"] = function()
    print("=== pfQuest Enhanced Debug ===")

    -- Check if pfDB is loaded
    if not pfDB then
        print("❌ pfDB not loaded! Make sure pfQuest addon is running.")
        return
    end

    -- Display loaded data counts
    local questCount = pfDB["quests"] and pfDB["quests"]["data"] and TableCount(pfDB["quests"]["data"]) or 0
    local unitCount = pfDB["units"] and pfDB["units"]["data"] and TableCount(pfDB["units"]["data"]) or 0
    local zoneCount = pfDB["zones"] and pfDB["zones"]["data"] and TableCount(pfDB["zones"]["data"]) or 0

    -- Count units with coordinates
    local unitsWithCoords = 0
    if pfDB["units"] and pfDB["units"]["data"] then
        for unitId, unit in pairs(pfDB["units"]["data"]) do
            if unit.coords and #unit.coords > 0 then
                unitsWithCoords = unitsWithCoords + 1
            end
        end
    end

    print("📊 Data loaded:")
    print("   Quests: " .. questCount)
    print("   Units: " .. unitCount .. " (" .. unitsWithCoords .. " with coords)")
    print("   Zones: " .. zoneCount)

    -- Find working quests
    print("🔍 Finding working quests...")
    local workingQuests = findWorkingQuests()

    if #workingQuests > 0 then
        print("✅ Found " .. #workingQuests .. " working quests!")

        -- Show only first 10 as examples
        local maxToShow = math.min(10, #workingQuests)
        if maxToShow < #workingQuests then
            print("📋 Showing first " .. maxToShow .. " examples:")
        else
            print("📋 Complete list:")
        end

        for i = 1, maxToShow do
            local questId = workingQuests[i]
            -- Get quest name, handle if it's a table
            local questName = "Quest " .. questId
            if pfDB["quests"] and pfDB["quests"]["loc"] and pfDB["quests"]["loc"][questId] then
                local questData = pfDB["quests"]["loc"][questId]
                if type(questData) == "table" and questData.T then
                    questName = questData.T  -- Title from table
                elseif type(questData) == "string" then
                    questName = questData
                end
            end

            -- Get quest info for race and zones
            local quest = pfDB["quests"]["data"][questId]
            local raceInfo = ""
            local zoneInfo = ""

            if quest then
                -- Race info (fixed codes)
                if quest.race then
                    if quest.race == 1101 then raceInfo = " [Alliance]"
                    elseif quest.race == 690 then raceInfo = " [Horde]"
                    elseif quest.race == 77 then raceInfo = " [Alliance-old]"
                    elseif quest.race == 178 then raceInfo = " [Horde-old]"
                    else raceInfo = " [Race:" .. quest.race .. "]" end
                else
                    raceInfo = " [Both factions]"
                end

                -- Zone info from starter NPCs with names
                if quest.start and quest.start.U then
                    for unitId, _ in pairs(quest.start.U) do
                        if pfDB["units"]["data"][unitId] and pfDB["units"]["data"][unitId].coords then
                            for _, coord in ipairs(pfDB["units"]["data"][unitId].coords) do
                                local zoneId = coord[3]
                                if zoneId == 1519 then zoneInfo = " (Stormwind City)"
                                elseif zoneId == 1637 then zoneInfo = " (Orgrimmar)"
                                elseif zoneId == 3520 then zoneInfo = " (Hellfire Peninsula)"
                                elseif zoneId == 65 then zoneInfo = " (Dragonblight)"
                                else
                                    -- Try to get zone name from pfDB
                                    if pfDB["zones"] and pfDB["zones"]["loc"] and pfDB["zones"]["loc"][zoneId] then
                                        zoneInfo = " (" .. pfDB["zones"]["loc"][zoneId] .. ")"
                                    else
                                        zoneInfo = " (Zone:" .. zoneId .. ")"
                                    end
                                end
                                break
                            end
                            break
                        else
                            zoneInfo = " (Unit " .. unitId .. " no coords)"
                        end
                    end
                else
                    zoneInfo = " (No start NPC)"
                end
            end

            print("   " .. questId .. ": " .. questName .. raceInfo .. zoneInfo)
        end

        print("")
        print("🧪 TEST COMMANDS:")
        for i = 1, math.min(3, #workingQuests) do
            print("   /pfq " .. workingQuests[i])
        end
    else
        print("❌ No working quests found!")
    end

    print("=== End Debug ===")
end

-- Register slash command for quest testing
SLASH_PFQUESTTEST1 = "/pfq"
SlashCmdList["PFQUESTTEST"] = function(questId)
    questId = tonumber(questId)
    if not questId then
        print("❌ Usage: /pfq <questID>")
        print("   Example: /pfq 784")
        return
    end

    local quest = pfDB["quests"]["data"][questId]
    if not quest then
        print("❌ Quest " .. questId .. " not found in database")
        return
    end

    print("=== pfQuest Quest Analysis ===")
    print("🔍 Testing Quest " .. questId)

    -- Get quest name, handle if it's a table
    local questName = "Quest " .. questId
    if pfDB["quests"]["loc"] and pfDB["quests"]["loc"][questId] then
        local questData = pfDB["quests"]["loc"][questId]
        if type(questData) == "table" and questData.T then
            questName = questData.T  -- Title from table
        elseif type(questData) == "string" then
            questName = questData
        end
    end

    print("📜 " .. questName)

    -- Quest level and race info
    print("📊 Level: " .. (quest.lvl or "Unknown") .. " (Min: " .. (quest.min or "Unknown") .. ")")
    local raceInfo = ""
    if quest.race then
        if quest.race == 1101 then raceInfo = "Alliance"
        elseif quest.race == 690 then raceInfo = "Horde"
        else raceInfo = "Race " .. quest.race end
    else
        raceInfo = "Both factions"
    end
    print("🏳️ Faction: " .. raceInfo)

    -- Check quest starters
    if quest.start then
        print("🚀 Quest Starters:")
        if quest.start.U then
            for i, unitId in ipairs(quest.start.U) do
                local unit = pfDB["units"]["data"][unitId]
                if unit then
                    local coords_count = unit.coords and #unit.coords or 0
                    print("   NPC " .. unitId .. ": " .. coords_count .. " spawns")
                    if coords_count > 0 then
                        local coord = unit.coords[1]
                        print("     First spawn: " .. coord[1] .. ", " .. coord[2] .. " zone " .. coord[3])
                        -- Check if zone exists in pfQuest zones
                        local zone_names = {
                            [14] = "Durotar",
                            [1519] = "Stormwind City",
                            [1637] = "Orgrimmar",
                            [17] = "The Barrens",
                            [141] = "Teldrassil",
                            [215] = "Mulgore",
                            [3520] = "Hellfire Peninsula",
                            [65] = "Dragonblight"
                        }

                        local zone_name = zone_names[coord[3]]
                        if not zone_name and pfDB["zones"] and pfDB["zones"]["data"] and pfDB["zones"]["data"][coord[3]] then
                            zone_name = "Zone " .. coord[3]  -- We have zone data but no name lookup yet
                        end
                        zone_name = zone_name or "Unknown"

                        print("     Zone: " .. zone_name .. " (ID: " .. coord[3] .. ")")
                    end
                else
                    print("   NPC " .. unitId .. ": NO DATA")
                end
            end
        end
        if quest.start.O then
            for i, objectId in ipairs(quest.start.O) do
                print("   Object " .. objectId .. ": Check objects table")
            end
        end
        if quest.start.I then
            for i, itemId in ipairs(quest.start.I) do
                print("   Item " .. itemId .. ": Quest starting item")
            end
        end
    else
        print("❌ No quest starters found!")
    end

    -- Check quest finishers
    if quest["end"] then
        print("🏁 Quest Finishers:")
        if quest["end"].U then
            for i, unitId in ipairs(quest["end"].U) do
                local unit = pfDB["units"]["data"][unitId]
                if unit then
                    local coords_count = unit.coords and #unit.coords or 0
                    print("   NPC " .. unitId .. ": " .. coords_count .. " spawns")
                    if coords_count > 0 then
                        local coord = unit.coords[1]
                        print("     Location: " .. coord[1] .. ", " .. coord[2] .. " zone " .. coord[3])
                    end
                else
                    print("   NPC " .. unitId .. ": NO DATA")
                end
            end
        end
        if quest["end"].O then
            for i, objectId in ipairs(quest["end"].O) do
                print("   Object " .. objectId .. ": Check objects table")
            end
        end
    else
        print("❌ No quest finishers found!")
    end

    -- Check unit objectives
    if quest.obj and quest.obj.U then
        print("🐲 Unit objectives:")
        for i, unitId in ipairs(quest.obj.U) do
            local unit = pfDB["units"]["data"][unitId]
            if unit then
                local coords_count = unit.coords and #unit.coords or 0
                print("   Unit " .. unitId .. ": " .. coords_count .. " spawns")
                if coords_count > 0 then
                    local coord = unit.coords[1]
                    print("     First spawn: " .. coord[1] .. ", " .. coord[2] .. " zone " .. coord[3])
                end
            else
                print("   Unit " .. unitId .. ": NO DATA")
            end
        end
    end

    -- Check item objectives
    if quest.obj and quest.obj.I then
        print("💎 Item objectives:")
        for i, itemId in ipairs(quest.obj.I) do
            print("   Item " .. itemId)
        end
    end

    -- pfQuest working quest analysis
    print("")
    print("🔧 pfQuest Analysis:")
    local hasStarter = (quest.start and (quest.start.U or quest.start.O or quest.start.I))
    local hasFinisher = (quest["end"] and (quest["end"].U or quest["end"].O))

    print("   Has starter: " .. (hasStarter and "✅ YES" or "❌ NO"))
    print("   Has finisher: " .. (hasFinisher and "✅ YES" or "❌ NO"))

    if hasStarter and hasFinisher then
        print("   Status: ✅ Should be WORKING QUEST")
        print("   🗺️ Should appear on map if zone coordinates are correct")

        -- Additional map debugging
        if quest.start and quest.start.U then
            for i, unitId in ipairs(quest.start.U) do
                local unit = pfDB["units"]["data"][unitId]
                if unit and unit.coords and #unit.coords > 0 then
                    local coord = unit.coords[1]
                    local zoneId = coord[3]
                    print("   📍 Map Debug: Quest starter at zone " .. zoneId)
                    if zoneId == 14 then
                        print("      → Should appear in Durotar area on Kalimdor map")
                    elseif zoneId == 1519 then
                        print("      → Should appear in Stormwind area on Eastern Kingdoms map")
                    elseif zoneId == 1637 then
                        print("      → Should appear in Orgrimmar area on Kalimdor map")
                    else
                        print("      → Zone mapping available - should appear on map")
                    end
                end
            end
        end
    else
        print("   Status: ❌ NOT a working quest - missing start/end")
    end

    print("=== End Analysis ===")
end

-- Helper function for counting table entries
function TableCount(t)
    if not t then return 0 end
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

print("✅ Enhanced pfQuest debug loaded! Use /pftest и /pfq <questID>")

-- === ГЛУБОКАЯ ПРОВЕРКА ДЛЯ /pfq ===
SLASH_PFQDEEP1 = "/pfqdeep"
SlashCmdList["PFQDEEP"] = function(msg)
  local qid = tonumber(msg)
  if not qid then print("Использование: /pfqdeep <questID>") return end
  print("=== pfQuest Deep Map Debug for QuestID:", qid, "===")

  -- 1. Проверка наличия квеста
  local quest = pfDB["quests"] and pfDB["quests"]["loc"] and pfDB["quests"]["loc"][qid]
  if not quest then print("❌ Quest not found in pfDB[quests][loc]") return end
  print("✅ Quest found:", quest.T or "(no title)")

  -- 2. Проверка стартера/финишера
  local qdata = pfDB["quests"] and pfDB["quests"]["data"] and pfDB["quests"]["data"][qid]
  local starter, finisher = qdata and qdata.start, qdata and qdata["end"]
  if starter then
    print("✅ Starter:", starter.U and starter.U[1] or starter.O and starter.O[1] or starter.I and starter.I[1] or "Unknown")
  else
    print("❌ No starter info")
  end
  if finisher then
    print("✅ Finisher:", finisher.U and finisher.U[1] or finisher.O and finisher.O[1] or "Unknown")
  else
    print("❌ No finisher info")
  end

  -- 3. Проверка целей (units/objects/coords)
  local objectives = qdata and qdata.obj or {}
  if objectives.U then
    for _, unitId in ipairs(objectives.U) do
      local unit = pfDB["units"] and pfDB["units"]["data"] and pfDB["units"]["data"][unitId]
      if unit and unit.coords and #unit.coords > 0 then
        print("✅ Unit objective:", unitId, "coords:", unit.coords[1][1], unit.coords[1][2], "zone:", unit.coords[1][3])
      else
        print("❌ Unit", unitId, "has no coords!")
      end
    end
  end
  if objectives.O then
    for _, objId in ipairs(objectives.O) do
      local obj = pfDB["objects"] and pfDB["objects"]["data"] and pfDB["objects"]["data"][objId]
      if obj and obj.coords and #obj.coords > 0 then
        print("✅ Object objective:", objId, "coords:", obj.coords[1][1], obj.coords[1][2], "zone:", obj.coords[1][3])
      else
        print("❌ Object", objId, "has no coords!")
      end
    end
  end

  -- 4. Проверка зоны
  local zoneid = nil
  if starter and starter.U and pfDB["units"] and pfDB["units"]["data"] and pfDB["units"]["data"][starter.U[1]] and pfDB["units"]["data"][starter.U[1]].coords then
    zoneid = pfDB["units"]["data"][starter.U[1]].coords[1][3]
  elseif objectives.U and pfDB["units"] and pfDB["units"]["data"] and pfDB["units"]["data"][objectives.U[1]] and pfDB["units"]["data"][objectives.U[1]].coords then
    zoneid = pfDB["units"]["data"][objectives.U[1]].coords[1][3]
  end
  if zoneid then
    local zoneinfo = pfDB["zones"] and pfDB["zones"]["data"] and pfDB["zones"]["data"][zoneid]
    if zoneinfo then
      print("✅ Zone", zoneid, "found in zones.lua:", unpack(zoneinfo))
    else
      print("❌ Zone", zoneid, "not found in zones.lua!")
    end
  else
    print("❌ No zoneID found for quest")
  end

  -- 5. Проверка наличия точек в pfMap.nodes после поиска
  if pfDatabase and pfDatabase.SearchQuestID then
    local meta = { ["addon"] = "PFQUEST" }
    pfDatabase:SearchQuestID(qid, meta)
    local nodes = pfMap.nodes["PFQUEST"]
    local found = false
    if nodes then
      for zid, points in pairs(nodes) do
        for coords, node in pairs(points) do
          print("✅ Node in pfMap.nodes: zone", zid, "coords", coords)
          found = true
        end
      end
    end
    if not found then
      print("❌ No nodes for this quest in pfMap.nodes after SearchQuestID")
    end
  else
    print("❌ pfDatabase:SearchQuestID not available")
  end

  -- 6. Проверка сопоставления zoneID/mapID
  if zoneid and pfMap and pfMap.GetMapNameByID then
    local name = pfMap:GetMapNameByID(zoneid)
    print("ZoneID", zoneid, "-> MapName:", name or "Unknown")
    local id2 = pfMap:GetMapIDByName(name)
    print("MapName", name, "-> ZoneID:", id2 or "Unknown")
  end

  -- 7. Проверка настроек
  if pfQuest_config then
    print("pfQuest_config: showspawn", pfQuest_config.showspawn, "showcluster", pfQuest_config.showcluster, "minimapnodes", pfQuest_config.minimapnodes)
  end

  print("=== End pfQuest Deep Map Debug ===")
end
