-- Enhanced pfQuest Debug Commands

-- Main debug function
function pfQuestDebug()
    print("=== pfQuest Enhanced Debug ===")

    if not pfDB then
        print("❌ ERROR: pfDB not found!")
        return
    end

    -- Count data
    local questCount = 0
    local unitCount = 0
    local unitsWithCoords = 0
    local zoneCount = 0

    if pfDB["quests"] and pfDB["quests"]["data"] then
        for _ in pairs(pfDB["quests"]["data"]) do questCount = questCount + 1 end
    end

    if pfDB["units"] and pfDB["units"]["data"] then
        for _, unit in pairs(pfDB["units"]["data"]) do
            unitCount = unitCount + 1
            if unit.coords and #unit.coords > 0 then
                unitsWithCoords = unitsWithCoords + 1
            end
        end
    end

    if pfDB["zones"] and pfDB["zones"]["data"] then
        for _ in pairs(pfDB["zones"]["data"]) do zoneCount = zoneCount + 1 end
    end

    print("📊 Data loaded:")
    print("   Quests: " .. questCount)
    print("   Units: " .. unitCount .. " (" .. unitsWithCoords .. " with coords)")
    print("   Zones: " .. zoneCount)

    -- Find working quests
    print("")
    print("🔍 Finding working quests...")
    local workingQuests = {}
    local checkedQuests = 0

    if pfDB["quests"] and pfDB["quests"]["data"] and pfDB["units"] and pfDB["units"]["data"] then
        for questId, quest in pairs(pfDB["quests"]["data"]) do
            checkedQuests = checkedQuests + 1
            if checkedQuests > 1000 then break end -- Check all 1000 quests

            local hasWorkingObjectives = false

            if quest.obj and quest.obj.U then
                for unitId, count in pairs(quest.obj.U) do
                    local unit = pfDB["units"]["data"][tonumber(unitId)]
                    if unit and unit.coords and #unit.coords > 0 then
                        -- Check if any coordinate has zone > 0
                        for _, coord in ipairs(unit.coords) do
                            if coord[3] and coord[3] > 0 then
                                hasWorkingObjectives = true
                                break
                            end
                        end
                        if hasWorkingObjectives then break end
                    end
                end
            end

            if hasWorkingObjectives then
                table.insert(workingQuests, questId)
                if #workingQuests >= 10 then break end
            end
        end
    end

    if #workingQuests > 0 then
        print("✅ Found " .. #workingQuests .. " working quests:")
        for i, questId in ipairs(workingQuests) do
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
                                    if pfDB["zones"] and pfDB["zones"]["enUS"] and pfDB["zones"]["enUS"][zoneId] then
                                        zoneInfo = " (" .. pfDB["zones"]["enUS"][zoneId] .. ")"
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
            print("   /pfquesttest " .. workingQuests[i])
        end
    else
        print("❌ No working quests found!")
    end

    print("=== End Debug ===")
end

-- Test specific quest
function pfQuestTestQuest(questId)
    print("🧪 Testing Quest " .. questId)

    if not pfDB or not pfDB["quests"] or not pfDB["quests"]["data"] then
        print("❌ No quest data")
        return
    end

    local quest = pfDB["quests"]["data"][questId]
    if not quest then
        print("❌ Quest not found")
        return
    end

    -- Get quest name
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

    -- Check unit objectives
    if quest.obj and quest.obj.U then
        print("🐲 Unit objectives:")
        for unitId, count in pairs(quest.obj.U) do
            local unit = pfDB["units"]["data"][tonumber(unitId)]
            if unit then
                local coordCount = unit.coords and #unit.coords or 0
                print("   Unit " .. unitId .. ": " .. coordCount .. " spawns")

                if coordCount > 0 then
                    local coord = unit.coords[1]
                    print("     First spawn: " .. coord[1] .. ", " .. coord[2] .. " zone " .. (coord[3] or 0))
                end
            else
                print("   Unit " .. unitId .. ": NO DATA")
            end
        end
    else
        print("❌ No unit objectives")
    end
end

-- Register commands
SLASH_PFTEST1 = "/pftest"
SlashCmdList["PFTEST"] = pfQuestDebug

SLASH_PFQUESTTEST1 = "/pfquesttest"
SlashCmdList["PFQUESTTEST"] = function(msg)
    local questId = tonumber(msg)
    if questId then
        pfQuestTestQuest(questId)
    else
        print("Usage: /pfquesttest <questid>")
    end
end

print("✅ Enhanced pfQuest debug loaded! Use /pftest and /pfquesttest")
