import cv2
import numpy as np
import matplotlib.pyplot as plt

# Данные замеров
angles = np.array([
    -0.5931069572, -0.5843231693, -0.5754001662, -0.5657200862, -0.5500896729,
    -0.5413428825, -0.5303397303, -0.5209721723, -0.5084898847, -0.4972907275,
    -0.4869039245, -0.4754648541, -0.4643708043, -0.4531218609, -0.4377053132,
    -0.4283927587, -0.412518517, -0.3985650051, -0.3897506919, -0.3796336478,
    -0.3690546744, -0.3588857381, -0.3484583841, -0.3378894157, -0.3273401394,
    -0.3155292272, -0.3017710346, -0.2858613744, -0.2705857577, -0.2606379936,
    -0.247415113, -0.2370463214, -0.2273454091, -0.2184387456, -0.2057356729,
    -0.1942994403, -0.1805768322, -0.1704161296, -0.159577153, -0.1435877817,
    -0.1296444695, -0.1203606683, -0.1071904275, -0.09266298329, -0.08258683819,
    -0.07145362471, -0.06192300936, -0.05131192444, -0.04229679849, -0.0248651305,
    -0.01424472113, 0.009289876353, 0.02713023722, 0.03617314967, 0.05060557497,
    0.06830894096, 0.08098111595, 0.09315887325, 0.1385330546, 0.1718509375,
    0.1887410556, 0.1987238732, 0.2106108767, 0.2199582068, 0.2295581211,
    0.2382704073, 0.2524875088, 0.2649042198, 0.2828407613, 0.2948759758,
    0.3082946092, 0.3192475327, 0.3290932917, 0.3385381012, 0.3480985238,
    0.362077509, 0.3708985098, 0.3826825279, 0.3928837295, 0.4036891828,
    0.4140958051, 0.4242416958, 0.436244786, 0.4466781298, 0.4557012567,
    0.4648936816, 0.4740144347, 0.4837897442
])

measured_px = np.array([
    104.81042, 103.824908, 102.840482, 101.791516, 100.139297,
    99.237022, 98.124636, 97.197425, 95.990138, 94.934298,
    93.978072, 92.950518, 91.979438, 91.02032, 89.74742,
    89.001695, 87.77059, 86.729961, 86.092531, 85.379836,
    84.656182, 83.981297, 83.310276, 82.651774, 82.016134,
    81.330021, 80.564668, 79.724862, 78.963924, 78.49218,
    77.894037, 77.44799, 77.048896, 76.697933, 76.222873,
    75.820728, 75.369969, 75.058452, 74.74691, 74.326288,
    73.997195, 73.797459, 73.540563, 73.293017, 73.143283,
    72.998659, 72.892147, 72.79225, 72.72279, 72.628439,
    72.59665, 72.595044, 72.656595, 72.708323, 72.819329,
    73.002988, 73.166386, 73.348365, 74.239625, 75.105358,
    75.611626, 75.931984, 76.33381, 76.665258, 77.019776,
    77.353842, 77.924054, 78.447349, 79.244629, 79.806817,
    80.45923, 81.011658, 81.523425, 82.027795, 82.551684,
    83.341742, 83.854901, 84.557985, 85.182762, 85.860785,
    86.529493, 87.196213, 88.003699, 88.721981, 89.35541,
    90.012336, 90.67567, 91.399299
])

# Параметры калибровки камеры
camera_matrix = np.array([
    [3283.03741, 0.00000000, 1310.40704],
    [0.00000000, 3317.08032, 1868.84888],
    [0.00000000, 0.00000000, 1.00000000]
])

dist_coeffs = np.array([-0.04290051, -0.00711483, -0.00979527, 0.00517716, 0.08015856])

def correct_measured_distance(measured_distance, x_position, y_position, camera_matrix, dist_coeffs):
    """
    Корректирует измеренное расстояние с учетом дисторсии
    """
    # Предполагаем, что точки расположены горизонтально на высоте y_position
    center_x = camera_matrix[0, 2]
    
    # Создаем две точки на измеренном расстоянии
    point1 = [x_position - measured_distance/2, y_position]
    point2 = [x_position + measured_distance/2, y_position]
    
    # Корректируем дисторсию для обеих точек
    points = np.array([point1, point2], dtype=np.float32).reshape(-1, 1, 2)
    corrected_points = cv2.undistortPoints(points, camera_matrix, dist_coeffs, P=camera_matrix)
    
    # Вычисляем исправленное расстояние
    pt1_corrected = corrected_points[0][0]
    pt2_corrected = corrected_points[1][0]
    corrected_dist = np.linalg.norm(pt1_corrected - pt2_corrected)
    
    return corrected_dist

# ПРАВИЛЬНЫЙ ПОДХОД: находим оптимальную высоту и позицию точек
def find_optimal_correction(angles, measured_px, camera_matrix, dist_coeffs):
    """
    Находит оптимальные параметры для коррекции, минимизируя разброс
    """
    # Пробуем разные высоты расположения точек
    best_std = float('inf')
    best_corrected = None
    best_y_position = None
    
    center_x = camera_matrix[0, 2]
    
    for test_y in range(500, 2500, 100):  # Перебираем возможные высоты
        corrected_distances = []
        
        for angle, dist_px in zip(angles, measured_px):
            # Вычисляем x-позицию на основе угла (точки движутся по горизонтали)
            radius = 2000  # примерный радиус
            x_position = center_x + radius * np.tan(angle)
            
            corrected_dist = correct_measured_distance(dist_px, x_position, test_y, camera_matrix, dist_coeffs)
            corrected_distances.append(corrected_dist)
        
        current_std = np.std(corrected_distances)
        if current_std < best_std:
            best_std = current_std
            best_corrected = corrected_distances
            best_y_position = test_y
    
    return np.array(best_corrected), best_y_position, best_std

# Применяем оптимизированную коррекцию
corrected_px_optimized, best_y, best_std = find_optimal_correction(angles, measured_px, camera_matrix, dist_coeffs)

# Альтернативный подход: простая коррекция центральной точки
def simple_center_correction(measured_px, camera_matrix, dist_coeffs):
    """
    Корректирует расстояния, предполагая что точки в центре кадра
    """
    center_x, center_y = camera_matrix[0, 2], camera_matrix[1, 2]
    corrected_distances = []
    
    for dist_px in measured_px:
        corrected_dist = correct_measured_distance(dist_px, center_x, center_y, camera_matrix, dist_coeffs)
        corrected_distances.append(corrected_dist)
    
    return np.array(corrected_distances)

# Коррекция для центра кадра
corrected_center = simple_center_correction(measured_px, camera_matrix, dist_coeffs)

# Визуализация результатов
plt.figure(figsize=(15, 10))

# График 1: Все измерения
plt.subplot(2, 2, 1)
plt.scatter(angles, measured_px, alpha=0.7, label='Измеренные', color='blue', s=30)
plt.scatter(angles, corrected_center, alpha=0.7, label='Коррекция центра', color='green', s=30)
plt.scatter(angles, corrected_px_optimized, alpha=0.7, label='Оптимизированная', color='red', s=30)
plt.xlabel('Угол наклона (рад)')
plt.ylabel('Расстояние (пиксели)')
plt.title('Сравнение методов коррекции')
plt.legend()
plt.grid(True, alpha=0.3)

# График 2: Отклонения от среднего
mean_measured = np.mean(measured_px)
mean_optimized = np.mean(corrected_px_optimized)

plt.subplot(2, 2, 2)
plt.scatter(angles, measured_px - mean_measured, alpha=0.7, label='Измеренные', color='blue', s=30)
plt.scatter(angles, corrected_px_optimized - mean_optimized, alpha=0.7, label='Оптимизированная', color='red', s=30)
plt.xlabel('Угол наклона (рад)')
plt.ylabel('Отклонение от среднего (px)')
plt.title('Отклонения от среднего значения')
plt.legend()
plt.grid(True, alpha=0.3)

# График 3: Распределение
plt.subplot(2, 2, 3)
plt.hist(measured_px, bins=20, alpha=0.7, label=f'Измеренные (std: {np.std(measured_px):.2f}px)', color='blue')
plt.hist(corrected_px_optimized, bins=20, alpha=0.7, label=f'Оптимизированные (std: {np.std(corrected_px_optimized):.2f}px)', color='red')
plt.xlabel('Расстояние (пиксели)')
plt.ylabel('Частота')
plt.title('Распределение измерений')
plt.legend()
plt.grid(True, alpha=0.3)

# График 4: Детальный анализ остаточных ошибок
plt.subplot(2, 2, 4)
residuals = corrected_px_optimized - np.mean(corrected_px_optimized)
plt.scatter(angles, residuals, color='purple', s=30)
plt.axhline(y=0, color='black', linestyle='-', alpha=0.5)
plt.axhline(y=2, color='red', linestyle='--', alpha=0.5, label='±2px')
plt.axhline(y=-2, color='red', linestyle='--', alpha=0.5)
plt.xlabel('Угол наклона (рад)')
plt.ylabel('Остаточная ошибка (px)')
plt.title(f'Остаточные ошибки после коррекции\nStd: {np.std(residuals):.3f}px')
plt.legend()
plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.show()

# Детальный анализ
print("=" * 60)
print("ДЕТАЛЬНЫЙ АНАЛИЗ КОРРЕКЦИИ ДИСТОРСИИ")
print("=" * 60)

print(f"\nИСХОДНЫЕ ДАННЫЕ:")
print(f"Среднее расстояние: {np.mean(measured_px):.2f} px")
print(f"Стандартное отклонение: {np.std(measured_px):.3f} px")
print(f"Размах: {np.max(measured_px) - np.min(measured_px):.2f} px")
print(f"Min: {np.min(measured_px):.2f} px, Max: {np.max(measured_px):.2f} px")

print(f"\nПОСЛЕ ОПТИМИЗИРОВАННОЙ КОРРЕКЦИИ:")
print(f"Среднее расстояние: {np.mean(corrected_px_optimized):.2f} px")
print(f"Стандартное отклонение: {np.std(corrected_px_optimized):.3f} px")
print(f"Размах: {np.max(corrected_px_optimized) - np.min(corrected_px_optimized):.2f} px")
print(f"Min: {np.min(corrected_px_optimized):.2f} px, Max: {np.max(corrected_px_optimized):.2f} px")

improvement = (np.std(measured_px) - np.std(corrected_px_optimized)) / np.std(measured_px) * 100
print(f"\nУЛУЧШЕНИЕ ТОЧНОСТИ: {improvement:.1f}%")
print(f"Коэффициент улучшения: {np.std(measured_px)/np.std(corrected_px_optimized):.1f}x")

print(f"\nОптимальная высота точек: {best_y} px")

# Проверяем, достигли ли мы целевой точности 2-3 пикселя
target_std = 2.5
achieved_std = np.std(corrected_px_optimized)

if achieved_std <= target_std:
    print(f"✅ ЦЕЛЕВАЯ ТОЧНОСТЬ ДОСТИГНУТА: {achieved_std:.3f}px ≤ {target_std}px")
else:
    print(f"⚠️ Целевая точность не достигнута: {achieved_std:.3f}px > {target_std}px")
    print("Рекомендации:")
    print("1. Проверьте качество калибровочных изображений")
    print("2. Увеличьте количество калибровочных изображений")
    print("3. Проверьте равномерность освещения на изображениях")
    print("4. Убедитесь, что шаблон калибровки плоский и не деформирован")

# Анализ остаточных ошибок
print(f"\nАНАЛИЗ ОСТАТОЧНЫХ ОШИБОК:")
residuals = corrected_px_optimized - np.mean(corrected_px_optimized)
within_2px = np.sum(np.abs(residuals) <= 2) / len(residuals) * 100
within_3px = np.sum(np.abs(residuals) <= 3) / len(residuals) * 100

print(f"Измерений в пределах ±2px: {within_2px:.1f}%")
print(f"Измерений в пределах ±3px: {within_3px:.1f}%")