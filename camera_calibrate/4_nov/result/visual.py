import numpy as np
import cv2
import matplotlib.pyplot as plt

# Ваши параметры камеры
camera_matrix = np.array([[3283.03741, 0, 1310.40704],
                         [0, 3317.08032, 1868.84888],
                         [0, 0, 1]])
dist_coeffs = np.array([-0.04290051, -0.00711483, -0.00979527, 0.00517716, 0.08015856])

# Создаем пустое изображение
width, height = 2620, 3737
image = np.ones((height, width, 3), dtype=np.uint8) * 255

# Рисуем идеальную сетку (красные линии)
grid_size = 10
step_x = width // grid_size
step_y = height // grid_size

# Вертикальные линии
for i in range(grid_size + 1):
    x = i * step_x
    cv2.line(image, (x, 0), (x, height), (0, 0, 255), 2)  # Красный

# Горизонтальные линии  
for i in range(grid_size + 1):
    y = i * step_y
    cv2.line(image, (0, y), (width, y), (0, 0, 255), 2)  # Красный

# Применяем дисторсию к изображению
distorted_image = cv2.undistort(image, camera_matrix, dist_coeffs)

# Показываем результаты
plt.figure(figsize=(15, 6))

plt.subplot(1, 2, 1)
plt.imshow(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
plt.title("Идеальная сетка (без дисторсии)")
plt.axis('off')

plt.subplot(1, 2, 2)
plt.imshow(cv2.cvtColor(distorted_image, cv2.COLOR_BGR2RGB))
plt.title("Сетка с дисторсией")
plt.axis('off')

plt.tight_layout()
plt.show()


# Создаем точки сетки
points = []
for i in range(grid_size + 1):
    for j in range(grid_size + 1):
        points.append([i * step_x, j * step_y])

points = np.array(points, dtype=np.float32)

# Применяем дисторсию к точкам
points_distorted = cv2.undistortPoints(points.reshape(-1, 1, 2), 
                                     camera_matrix, dist_coeffs, P=camera_matrix)
points_distorted = points_distorted.reshape(-1, 2)

# Рисуем точки до и после
plt.figure(figsize=(15, 6))

plt.subplot(1, 2, 1)
plt.scatter(points[:, 0], points[:, 1], c='red', s=30)
plt.gca().invert_yaxis()  # Инвертируем ось Y для правильного отображения
plt.title("Идеальные точки")
plt.grid(True)

plt.subplot(1, 2, 2)
plt.scatter(points_distorted[:, 0], points_distorted[:, 1], c='blue', s=30)
plt.gca().invert_yaxis()
plt.title("Точки с дисторсией")
plt.grid(True)

plt.tight_layout()
plt.show()