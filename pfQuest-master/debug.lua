-- pfQuest Debug Commands
-- Add this to pfQuest addon for easy diagnostics

-- Create debug function
function pfQuestDebug()
    print("=== pfQuest Debug Report ===")

    -- Check pfDB existence
    if not pfDB then
        print("❌ ERROR: pfDB not found!")
        return
    end

    -- Count quests
    local questCount = 0
    if pfDB["quests"] and pfDB["quests"]["data"] then
        for _ in pairs(pfDB["quests"]["data"]) do
            questCount = questCount + 1
        end
    end

    -- Count locales
    local localeCount = 0
    if pfDB["quests"] and pfDB["quests"]["loc"] then
        for _ in pairs(pfDB["quests"]["loc"]) do
            localeCount = localeCount + 1
        end
    end

    -- Count units
    local unitCount = 0
    if pfDB["units"] and pfDB["units"]["data"] then
        for _ in pairs(pfDB["units"]["data"]) do
            unitCount = unitCount + 1
        end
    end

    -- Count zones
    local zoneCount = 0
    if pfDB["zones"] and pfDB["zones"]["data"] then
        for _ in pairs(pfDB["zones"]["data"]) do
            zoneCount = zoneCount + 1
        end
    end

    -- Results
    print("✅ pfDB found")
    print("📊 Quests loaded: " .. questCount)
    print("🌍 Locales loaded: " .. localeCount)
    print("🐲 Units loaded: " .. unitCount)
    print("🗺️ Zones loaded: " .. zoneCount)
    print("🎯 Current locale: " .. GetLocale())
    print("💾 Memory: " .. math.floor(collectgarbage("count")) .. " KB")

    -- Check for issues
    if questCount == 0 then
        print("⚠️  WARNING: No quests loaded!")
    elseif questCount < 100 then
        print("⚠️  WARNING: Very few quests (" .. questCount .. ")")
    else
        print("✅ Quest count looks good")
    end

    if localeCount == 0 then
        print("❌ ERROR: No locales loaded!")
    else
        print("✅ Locales working")
    end

    if zoneCount == 0 then
        print("❌ ERROR: No zones loaded!")
    else
        print("✅ Zones working")
    end

    print("=== End Debug Report ===")
end

-- Comprehensive quest display diagnostic
function pfQuestDisplayTest()
    print("=== pfQuest Display Diagnostic ===")

    if not pfDB then
        print("❌ pfDB missing - addon not loaded")
        return
    end

    -- Test 1: Check zones
    local zoneCount = 0
    local sampleZone = nil
    if pfDB["zones"] and pfDB["zones"]["data"] then
        for id, zone in pairs(pfDB["zones"]["data"]) do
            zoneCount = zoneCount + 1
            if not sampleZone then sampleZone = {id, zone} end
            if zoneCount >= 3 then break end
        end
    end

    print("🗺️ Zones: " .. zoneCount .. " loaded")
    if sampleZone then
        print("   Sample zone " .. sampleZone[1] .. ": " .. (sampleZone[2][1] or "nil"))
    end

    -- Test 2: Check quest with objectives
    local questWithUnits = nil
    local questWithItems = nil
    local questWithObjects = nil

    if pfDB["quests"] and pfDB["quests"]["data"] then
        for id, quest in pairs(pfDB["quests"]["data"]) do
            if quest.obj then
                if quest.obj.U and not questWithUnits then
                    questWithUnits = {id, quest}
                end
                if quest.obj.I and not questWithItems then
                    questWithItems = {id, quest}
                end
                if quest.obj.O and not questWithObjects then
                    questWithObjects = {id, quest}
                end
            end
            if questWithUnits and questWithItems and questWithObjects then break end
        end
    end

    print("🎯 Quest objectives:")
    if questWithUnits then
        print("   ✅ Quest " .. questWithUnits[1] .. " has unit objectives")
    else
        print("   ❌ No quests with unit objectives found")
    end

    if questWithItems then
        print("   ✅ Quest " .. questWithItems[1] .. " has item objectives")
    else
        print("   ❌ No quests with item objectives found")
    end

    if questWithObjects then
        print("   ✅ Quest " .. questWithObjects[1] .. " has object objectives")
    else
        print("   ❌ No quests with object objectives found")
    end

    -- Test 3: Check unit coordinates
    local unitsWithCoords = 0
    local sampleUnit = nil

    if pfDB["units"] and pfDB["units"]["data"] then
        for id, unit in pairs(pfDB["units"]["data"]) do
            if unit.coords and #unit.coords > 0 then
                unitsWithCoords = unitsWithCoords + 1
                if not sampleUnit then
                    sampleUnit = {id, unit.coords[1]}
                end
                if unitsWithCoords >= 10 then break end
            end
        end
    end

    print("🐲 Units with coordinates: " .. unitsWithCoords)
    if sampleUnit then
        local coord = sampleUnit[2]
        print("   Sample unit " .. sampleUnit[1] .. " at: " .. coord[1] .. ", " .. coord[2] .. " zone " .. coord[3])
    end

    -- Test 4: Check current zone
    local currentZone = GetRealZoneText()
    local currentSubZone = GetSubZoneText()
    print("📍 Current location: " .. currentZone .. " / " .. currentSubZone)

    -- Test 5: Quest-Unit linking test
    if questWithUnits then
        local questId = questWithUnits[1]
        local quest = questWithUnits[2]
        print("🔗 Testing quest-unit linking for quest " .. questId .. ":")

        if quest.obj and quest.obj.U then
            for unitId, count in pairs(quest.obj.U) do
                local unit = pfDB["units"]["data"][unitId]
                if unit then
                    local coordCount = unit.coords and #unit.coords or 0
                    print("   Unit " .. unitId .. ": " .. coordCount .. " coordinates")
                    if coordCount > 0 then
                        local coord = unit.coords[1]
                        print("      First coord: " .. coord[1] .. ", " .. coord[2] .. " zone " .. coord[3])

                        -- Check if zone exists
                        local zoneData = pfDB["zones"]["data"][coord[3]]
                        if zoneData then
                            print("      ✅ Zone " .. coord[3] .. " data exists")
                        else
                            print("      ❌ Zone " .. coord[3] .. " data missing")
                        end
                    end
                else
                    print("   ❌ Unit " .. unitId .. " data missing")
                end
            end
        end
    end

    -- Test 6: Final recommendation
    print("")
    print("📋 RECOMMENDATIONS:")

    if zoneCount == 0 then
        print("❌ CRITICAL: No zones loaded - re-extract with zone fixes")
    elseif unitsWithCoords == 0 then
        print("❌ CRITICAL: No unit coordinates - check extraction")
    elseif not questWithUnits then
        print("⚠️  WARNING: No quests with unit objectives found")
    else
        print("✅ All components present - try /db quests command")
        print("✅ Or open map (M) and right-click for pfQuest menu")
    end

    print("=== End Display Diagnostic ===")
end

-- Register slash command
SLASH_PFQUESTDEBUG1 = "/pfquestdebug"
SLASH_PFQUESTDEBUG2 = "/pfdebug"
SlashCmdList["PFQUESTDEBUG"] = pfQuestDebug

-- Register comprehensive display test
SLASH_PFQUESTDISPLAY1 = "/pfquesttest"
SLASH_PFQUESTDISPLAY2 = "/pftest"
SlashCmdList["PFQUESTDISPLAY"] = pfQuestDisplayTest

-- Short version command
SLASH_PFQUESTSTATS1 = "/pfstats"
SlashCmdList["PFQUESTSTATS"] = function()
    if not pfDB then
        print("❌ pfDB not found!")
        return
    end

    local qc = 0
    if pfDB["quests"] and pfDB["quests"]["data"] then
        for _ in pairs(pfDB["quests"]["data"]) do qc = qc + 1 end
    end

    local zc = 0
    if pfDB["zones"] and pfDB["zones"]["data"] then
        for _ in pairs(pfDB["zones"]["data"]) do zc = zc + 1 end
    end

    print("pfQuest: " .. qc .. " quests, " .. zc .. " zones loaded")
end

print("pfQuest debug commands loaded: /pfquestdebug, /pfdebug, /pfstats, /pftest")
