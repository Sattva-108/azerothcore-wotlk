-- FIXED GetCustomCoords function for AzerothCore with WorldMapArea support
-- Вставить этот код в extractor.lua строка ~914, заменив существующий if core == "acore" block

function GetCustomCoords(m,x,y)
  local worldmap = {}
  local ret = {}

  if core == "acore" then
    -- НОВЫЙ подход: сначала WorldMapArea, потом database fallback

    -- 1. Try WorldMapArea spatial lookup first
    local wma_sql = string.format([[
      SELECT areatableID, areaname_lang1, x_min, x_max, y_min, y_max
      FROM WorldMapArea_%s
      WHERE mapID = %d
        AND x_min < %f AND x_max > %f
        AND y_min < %f AND y_max > %f
        AND areatableID > 0
      ORDER BY areatableID
    ]], expansion, m, x, x, y, y)

    local wma_query = mysql:execute(wma_sql)
    local found_zones = {}

    if wma_query then
      while wma_query:fetch(worldmap, "a") do
        local zone_id = tonumber(worldmap.areatableID)
        local x_min = tonumber(worldmap.x_min)
        local x_max = tonumber(worldmap.x_max)
        local y_min = tonumber(worldmap.y_min)
        local y_max = tonumber(worldmap.y_max)

        if zone_id and zone_id > 0 and x_min and x_max and y_min and y_max then
          -- Calculate zone coordinates
          local px = round(100 - (y - y_min) / ((y_max - y_min)/100), 1)
          local py = round(100 - (x - x_min) / ((x_max - x_min)/100), 1)

          if px >= 0 and px <= 100 and py >= 0 and py <= 100 then
            table.insert(found_zones, {
              zone_id = zone_id,
              x = px,
              y = py,
              area_size = (x_max - x_min) * (y_max - y_min),
              priority = 1 -- WorldMapArea has priority 1
            })
          end
        end
      end
    end

    -- 2. If WorldMapArea found zones, use the smallest one (most specific)
    if #found_zones > 0 then
      -- Sort by area size (smallest = most specific zone)
      table.sort(found_zones, function(a, b) return a.area_size < b.area_size end)
      local best_zone = found_zones[1]

      print(string.format("WorldMapArea: coords (%.1f, %.1f) -> zone %d (area: %.0f)",
        x, y, best_zone.zone_id, best_zone.area_size))

      local coord = { best_zone.x, best_zone.y, best_zone.zone_id, 0 }
      table.insert(ret, coord)
      return ret
    end

    -- 3. Fallback: database lookup (original logic)
    print(string.format("WorldMapArea failed for (%.1f, %.1f), trying database...", x, y))

    local zone_query = string.format([[
      SELECT zoneId FROM creature
      WHERE map = %d AND zoneId > 0
      ORDER BY (
        (position_x - %f) * (position_x - %f) +
        (position_y - %f) * (position_y - %f)
      ) ASC
      LIMIT 1
    ]], m, x, x, y, y)

    local zone_result = {}
    local query = mysql:execute(zone_query)
    local actual_zone_id = nil

    if query then
      if query:fetch(zone_result, "a") then
        actual_zone_id = tonumber(zone_result.zoneId)
        print(string.format("Database fallback: coords (%.1f, %.1f) -> zone %d",
          x, y, actual_zone_id))
      end
    end

    -- 4. Final fallback: hardcoded mapping
    local fallback_zones = {
      [0] = 12,      -- Eastern Kingdoms -> Elwynn Forest
      [1] = 14,      -- Kalimdor -> Durotar
      [530] = 3520,  -- Outland -> Hellfire Peninsula
      [571] = 65     -- Northrend -> Dragonblight
    }

    local zone_id = actual_zone_id or fallback_zones[m] or m

    if zone_id and x and y then
      -- Simple world to zone coordinate conversion
      local zone_x = ((x + 17066.666) / 533.33333) * 100
      local zone_y = ((y + 17066.666) / 533.33333) * 100
      zone_x = math.max(0, math.min(100, zone_x))
      zone_y = math.max(0, math.min(100, zone_y))

      print(string.format("Final result: coords (%.1f, %.1f) -> zone %d", x, y, zone_id))

      local coord = { zone_x, zone_y, zone_id, 0 }
      table.insert(ret, coord)
    end

    return ret
  end

  -- Original non-acore logic continues here...
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
