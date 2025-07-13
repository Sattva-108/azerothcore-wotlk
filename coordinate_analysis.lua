-- Анализ различий координат между рабочим и генерированным файлами миникарты
-- Дата: 2025-07-13

-- Рабочие данные из pfQuest-ascension-from-launcher
local working_data = {
  [1] = { 4924, 3283 },
  [3] = { 2487, 1658 },
  [4] = { 3350, 2234 },
  [8] = { 2294, 1530 },
  [10] = { 2699, 1800 },
  [11] = { 4136, 2757 },
  [12] = { 3470, 2315 },
  [14] = { 5288, 3524 },
  [15] = { 5251, 3500 },
  [16] = { 5070, 3381 },
  [17] = { 10132, 6755 },
  [25] = { 712.5, 475 },
  [28] = { 4299, 2866 },
  [33] = { 6380, 4254 },
  [36] = { 2799, 1866 },
  [38] = { 2759, 1840 },
  [40] = { 3499, 2333 },
  [41] = { 2500, 1667 },
  [44] = { 2171, 1447 },
  [45] = { 3600, 2400 },
  [46] = { 2929, 1952 },
  [47] = { 3850, 2566 },
  [51] = { 2232, 1487 },
  [65] = { 5608, 3740 },
  [66] = { 4993, 3329 },
  [67] = { 7111, 4741 }
}

-- Генерированные данные из eascminimap.lua output
local generated_data = {
  [4] = { 3525, 5287.5 }, -- Durotar
  [11] = { 6756.25, 10133.334 }, -- Barrens
  [14] = { 27149.68, 40741.18 }, -- Azeroth
  [15] = { 1866.6667, 2800.0003 }, -- Alterac
  [16] = { 2399.9997, 3600.0004 }, -- Arathi
  [17] = { 1658.334, 2487.5 }, -- Badlands
  [28] = { 1487.5, 2231.2503 }, -- SearingGorge
  [36] = { 1447.92, 2170.834 }, -- Redridge
  [38] = { 1529.167, 2293.75 }, -- SwampOfSorrows
  [40] = { 2756.25, 4135.4167 }, -- Wetlands
  [41] = { 3393.75, 5091.666 }, -- Teldrassil
}

-- Анализ совпадающих зон
print("=== АНАЛИЗ РАЗЛИЧИЙ КООРДИНАТ МИНИКАРТЫ ===")
print("Формат: ID | Рабочие (X,Y) | Генерированные (X,Y) | Коэффициенты (X_scale, Y_scale) | Тип преобразования")
print()

local transformations = {}

for zone_id, working_coords in pairs(working_data) do
  if generated_data[zone_id] then
    local work_x, work_y = working_coords[1], working_coords[2]
    local gen_x, gen_y = generated_data[zone_id][1], generated_data[zone_id][2]
    
    local x_scale = gen_x / work_x
    local y_scale = gen_y / work_y
    
    -- Проверяем возможную инверсию координат
    local inv_x_scale = gen_x / work_y
    local inv_y_scale = gen_y / work_x
    
    local transformation_type = "standard"
    if math.abs(inv_x_scale - inv_y_scale) < 0.01 then
      transformation_type = "inverted_xy"
      x_scale = inv_x_scale
      y_scale = inv_y_scale
    end
    
    print(string.format("ID %d | (%g, %g) | (%g, %g) | (%.3f, %.3f) | %s", 
      zone_id, work_x, work_y, gen_x, gen_y, x_scale, y_scale, transformation_type))
    
    transformations[zone_id] = {
      work_x = work_x, work_y = work_y,
      gen_x = gen_x, gen_y = gen_y,
      x_scale = x_scale, y_scale = y_scale,
      type = transformation_type
    }
  end
end

print()
print("=== ЗОНЫ ТОЛЬКО В РАБОЧЕМ ФАЙЛЕ ===")
for zone_id, coords in pairs(working_data) do
  if not generated_data[zone_id] then
    print(string.format("ID %d | (%g, %g) | ОТСУТСТВУЕТ В ГЕНЕРИРОВАННОМ", zone_id, coords[1], coords[2]))
  end
end

print()
print("=== ЗОНЫ ТОЛЬКО В ГЕНЕРИРОВАННОМ ФАЙЛЕ ===")
for zone_id, coords in pairs(generated_data) do
  if not working_data[zone_id] then
    print(string.format("ID %d | ОТСУТСТВУЕТ В РАБОЧЕМ | (%g, %g)", zone_id, coords[1], coords[2]))
  end
end

print()
print("=== СТАТИСТИКА КОЭФФИЦИЕНТОВ ===")
local x_scales, y_scales = {}, {}
for _, transform in pairs(transformations) do
  if transform.type == "standard" then
    table.insert(x_scales, transform.x_scale)
    table.insert(y_scales, transform.y_scale)
  end
end

if #x_scales > 0 then
  table.sort(x_scales)
  table.sort(y_scales)
  
  print(string.format("X коэффициенты: мин=%.3f, макс=%.3f, медиана=%.3f", 
    x_scales[1], x_scales[#x_scales], x_scales[math.ceil(#x_scales/2)]))
  print(string.format("Y коэффициенты: мин=%.3f, макс=%.3f, медиана=%.3f", 
    y_scales[1], y_scales[#y_scales], y_scales[math.ceil(#y_scales/2)]))
end