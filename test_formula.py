#!/usr/bin/env python3

# Тест формулы масштабирования для Ascension minimap
# Сравнение DBC данных с рабочими координатами

# Тестовые данные из DBC
test_zones = [
    # [id, name, locLeft, locRight, locTop, locBottom, expected_width, expected_height]
    [4, "Durotar", -1962.5, -7250, 1808.333, -1716.667, 3350, 2234],
    [11, "Barrens", 2622.917, -7510.417, 1612.5, -5143.75, 4136, 2757],
    [12, "Elwynn", 1262.5, -2208.333, 200, -2114.583, 3470, 2315],
    [17, "Badlands", -2079.167, -4566.667, -5889.583, -7547.917, 10132, 6755]
]

print("Тест формулы масштабирования Ascension minimap")
print("=" * 60)

scale_factors = []

for zone in test_zones:
    zone_id, name, left, right, top, bottom, exp_w, exp_h = zone
    
    # Базовая формула
    raw_width = abs(right - left)
    raw_height = abs(top - bottom)
    
    # Вычисление коэффициентов
    scale_w = exp_w / raw_width if raw_width != 0 else 0
    scale_h = exp_h / raw_height if raw_height != 0 else 0
    
    scale_factors.append(scale_w)
    scale_factors.append(scale_h)
    
    print(f"{name} (ID: {zone_id})")
    print(f"  DBC размеры: {raw_width:.1f} x {raw_height:.1f}")
    print(f"  Ожидаемые:   {exp_w} x {exp_h}")
    print(f"  Коэффициент: {scale_w:.4f} x {scale_h:.4f}")
    print()

# Средний коэффициент
avg_scale = sum(scale_factors) / len(scale_factors)
print(f"Средний коэффициент масштабирования: {avg_scale:.4f}")

# Тест с коэффициентом 0.634
print("\nТест с коэффициентом 0.634:")
print("-" * 40)

for zone in test_zones:
    zone_id, name, left, right, top, bottom, exp_w, exp_h = zone
    
    # Формула с масштабированием
    scaled_width = abs(right - left) * 0.634
    scaled_height = abs(top - bottom) * 0.634
    
    # Точность
    accuracy_w = abs(exp_w - scaled_width) / exp_w * 100 if exp_w != 0 else 0
    accuracy_h = abs(exp_h - scaled_height) / exp_h * 100 if exp_h != 0 else 0
    
    print(f"{name}: {scaled_width:.1f} x {scaled_height:.1f} (ошибка: {accuracy_w:.1f}% x {accuracy_h:.1f}%)")