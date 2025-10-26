import cv2
import numpy as np

# --- 1. Ваши данные калибровки ---
# Матрица камеры (K)
K = np.array([
    [3.44281429e+03, 0.00000000e+00, 1.17229852e+03],
    [0.00000000e+00, 3.45290820e+03, 2.00796838e+03],
    [0.00000000e+00, 0.00000000e+00, 1.00000000e+00]
])

# Коэффициенты дисторсии (D)
# [k1, k2, p1, p2, k3]
D = np.array([0.0477119, -0.00695201, -0.00190877, 0.00138233, -0.15064989])

# Разрешение изображения
IMG_WIDTH = 2296
IMG_HEIGHT = 4080

# --- 2. Параметры сетки (ИЗМЕНЕНО) ---
GRID_STEP = 200  # Шаг сетки в пикселях
BG_COLOR = (255, 255, 255)  # Белый

# Цвета для сравнения
COLOR_UNDISTORTED = (0, 255, 0)  # Зеленый (Идеальная сетка)
COLOR_DISTORTED = (0, 0, 255)    # Красный (Искаженная сетка)
LINE_THICKNESS = 1               # Устанавливаем толщину 1px для лучшего сравнения

# --- 3. Создание изображения (ИЗМЕНЕНО) ---
# Создаем ОДНО пустое белое изображение
img_comparison = np.full((IMG_HEIGHT, IMG_WIDTH, 3), BG_COLOR, dtype=np.uint8)

# --- 4. Извлечение параметров камеры ---
fx, fy = K[0, 0], K[1, 1]
cx, cy = K[0, 2], K[1, 2]
k1, k2, p1, p2, k3 = D[0], D[1], D[2], D[3], D[4]

# --- 5. Функция для применения дисторсии к точке ---
# (Остается без изменений)
def apply_distortion(u, v):
    # 1. Нормализация (перевод в "идеальные" координаты)
    x_norm = (u - cx) / fx
    y_norm = (v - cy) / fy

    # 2. Расчет радиальной дисторсии
    r2 = x_norm**2 + y_norm**2
    r4 = r2**2
    r6 = r4 * r2
    radial_dist = (1 + k1*r2 + k2*r4 + k3*r6)

    # 3. Расчет тангенциальной дисторсии
    dx_tan = (2*p1*x_norm*y_norm + p2*(r2 + 2*x_norm**2))
    dy_tan = (p1*(r2 + 2*y_norm**2) + 2*p2*x_norm*y_norm)
    
    # 4. Применение дисторсии к нормализованным координатам
    x_dist_norm = x_norm * radial_dist + dx_tan
    y_dist_norm = y_norm * radial_dist + dy_tan

    # 5. Де-нормализация (возврат в пиксельные координаты)
    u_dist = x_dist_norm * fx + cx
    v_dist = y_dist_norm * fy + cy
    
    return int(round(u_dist)), int(round(v_dist))

# --- 6. Генерация и отрисовка сеток (ИЗМЕНЕНО) ---

print("Генерация сеток...")

# Горизонтальные линии
for v in range(0, IMG_HEIGHT, GRID_STEP):
    points_undistorted = []
    points_distorted = []
    
    for u in range(0, IMG_WIDTH + 1, 10): # +1 чтобы дойти до края
        points_undistorted.append((u, v))
        points_distorted.append(apply_distortion(u, v))
    
    # Рисуем обе линии на ОДНОМ изображении
    cv2.polylines(img_comparison, [np.array(points_undistorted, dtype=np.int32)], False, COLOR_UNDISTORTED, LINE_THICKNESS)
    cv2.polylines(img_comparison, [np.array(points_distorted, dtype=np.int32)], False, COLOR_DISTORTED, LINE_THICKNESS)

# Вертикальные линии
for u in range(0, IMG_WIDTH, GRID_STEP):
    points_undistorted = []
    points_distorted = []

    for v in range(0, IMG_HEIGHT + 1, 10): # +1 чтобы дойти до края
        points_undistorted.append((u, v))
        points_distorted.append(apply_distortion(u, v))
        
    # Рисуем обе линии на ОДНОМ изображении
    cv2.polylines(img_comparison, [np.array(points_undistorted, dtype=np.int32)], False, COLOR_UNDISTORTED, LINE_THICKNESS)
    cv2.polylines(img_comparison, [np.array(points_distorted, dtype=np.int32)], False, COLOR_DISTORTED, LINE_THICKNESS)


# --- 7. Сохранение результатов (ИЗМЕНЕНО) ---
print("Сохранение изображения...")
cv2.imwrite("comparison_grid.png", img_comparison)

print(f"Готово! Создан 'comparison_grid.png'.")
print("Совет: Откройте файл и сильно увеличьте края, чтобы увидеть разницу.")