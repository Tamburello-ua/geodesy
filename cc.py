import cv2
import numpy as np
import glob
import os

# === ПАРАМЕТРЫ КАЛИБРОВОЧНОЙ ДОСКИ ===
# Количество пересечений внутренних углов (не квадратов!)
CHESSBOARD_SIZE = (8, 6)  # 9x6 часто стандарт
SQUARE_SIZE = 25.0  # мм (укажи реальный размер клетки)

# === ПУТИ ===
images_dir = "camera_calibrate"
pattern = os.path.join(images_dir, "*.jpg")

# === МАССИВЫ ДЛЯ ТОЧЕК ===
obj_points = []  # 3D точки в реальном пространстве
img_points = []  # 2D точки на изображении

# Подготовим объектные точки (0,0,0), (1,0,0), (2,0,0) ... масштабированные
objp = np.zeros((CHESSBOARD_SIZE[0]*CHESSBOARD_SIZE[1], 3), np.float32)
objp[:, :2] = np.mgrid[0:CHESSBOARD_SIZE[0], 0:CHESSBOARD_SIZE[1]].T.reshape(-1, 2)
objp *= SQUARE_SIZE

# === ОБРАБОТКА ИЗОБРАЖЕНИЙ ===
images = glob.glob(pattern)
print(f"Найдено {len(images)} изображений")

for fname in images:
    img = cv2.imread(fname)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Поиск углов
    ret, corners = cv2.findChessboardCorners(gray, CHESSBOARD_SIZE, None)

    if ret:
        # Уточнение координат углов
        corners2 = cv2.cornerSubPix(
            gray, corners, (11, 11), (-1, -1),
            (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)
        )
        obj_points.append(objp)
        img_points.append(corners2)

        # Отрисовка найденных углов
        cv2.drawChessboardCorners(img, CHESSBOARD_SIZE, corners2, ret)
        cv2.imshow('Chessboard', img)
        cv2.waitKey(200)
    else:
        print(f"⚠️ Углы не найдены на {fname}")

cv2.destroyAllWindows()

# === КАЛИБРОВКА ===
print("\nВыполняется калибровка...")
ret, camera_matrix, dist_coeffs, rvecs, tvecs = cv2.calibrateCamera(
    obj_points, img_points, gray.shape[::-1], None, None
)

print("\n=== РЕЗУЛЬТАТЫ ===")
print("RMS ошибка:", ret)
print("Матрица камеры:\n", camera_matrix)
print("Коэффициенты дисторсии:\n", dist_coeffs.ravel())

# === СОХРАНЕНИЕ ===
np.savez("calibration_data.npz",
         camera_matrix=camera_matrix,
         dist_coeffs=dist_coeffs,
         rvecs=rvecs,
         tvecs=tvecs)

print("\n✅ Калибровка завершена. Результаты сохранены в calibration_data.npz")
