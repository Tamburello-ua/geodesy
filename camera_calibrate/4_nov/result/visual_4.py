import cv2
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit

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

# Параметры калибровки (для справки)
camera_matrix = np.array([
    [3283.03741, 0.00000000, 1310.40704],
    [0.00000000, 3317.08032, 1868.84888],
    [0.00000000, 0.00000000, 1.00000000]
])
dist_coeffs = np.array([-0.04290051, -0.00711483, -0.00979527, 0.00517716, 0.08015856])

# 1. АНАЛИЗ ДАННЫХ - находим истинное расстояние
def find_true_distance(angles, measurements):
    """Находим истинное расстояние через медиану центральных измерений"""
    # Берем измерения вблизи центра (углы близкие к 0)
    center_indices = np.where(np.abs(angles) < 0.1)[0]
    true_distance = np.median(measurements[center_indices])
    return true_distance

true_distance = find_true_distance(angles, measured_px)
print(f"Истинное расстояние (центр кадра): {true_distance:.3f} px")

# 2. СТРОИМ КАЛИБРОВОЧНУЮ КРИВУЮ
def distortion_model(angle, a, b, c, d, e, f):
    """Полиномиальная модель коррекции дисторсии"""
    return a + b*angle + c*angle**2 + d*angle**3 + e*angle**4 + f*angle**5

# Вычисляем поправочные коэффициенты
correction_factors = true_distance / measured_px

# Подбираем полиномиальную модель
popt, pcov = curve_fit(distortion_model, angles, correction_factors, p0=[1, 0, 0, 0, 0, 0])

# 3. ПРИМЕНЯЕМ КОРРЕКЦИЮ
def apply_polynomial_correction(measured_values, angles, poly_params):
    """Применяет полиномиальную коррекцию"""
    corrections = distortion_model(angles, *poly_params)
    return measured_values * corrections

corrected_px_poly = apply_polynomial_correction(measured_px, angles, popt)

# 4. АЛЬТЕРНАТИВНЫЙ ПОДХОД - кусочно-линейная интерполяция
from scipy.interpolate import interp1d

# Создаем интерполяционную функцию
interp_func = interp1d(angles, true_distance/measured_px, kind='cubic', 
                      fill_value="extrapolate")

corrected_px_interp = measured_px * interp_func(angles)

# 5. ВИЗУАЛИЗАЦИЯ
plt.figure(figsize=(16, 12))

# График 1: Исходные данные и коррекция
plt.subplot(2, 2, 1)
plt.scatter(angles, measured_px, alpha=0.6, label='Измеренные', color='blue', s=30)
plt.axhline(y=true_distance, color='black', linestyle='--', label=f'Истинное: {true_distance:.2f}px')
plt.xlabel('Угол наклона (рад)')
plt.ylabel('Расстояние (пиксели)')
plt.title('Исходные измерения')
plt.legend()
plt.grid(True, alpha=0.3)

# График 2: После коррекции
plt.subplot(2, 2, 2)
plt.scatter(angles, corrected_px_poly, alpha=0.6, label='Полиномиальная', color='red', s=30)
plt.scatter(angles, corrected_px_interp, alpha=0.6, label='Интерполяция', color='green', s=30)
plt.axhline(y=true_distance, color='black', linestyle='--', label=f'Истинное: {true_distance:.2f}px')
plt.xlabel('Угол наклона (рад)')
plt.ylabel('Расстояние (пиксели)')
plt.title('После коррекции')
plt.legend()
plt.grid(True, alpha=0.3)

# График 3: Ошибки до коррекции
plt.subplot(2, 2, 3)
errors_before = (measured_px - true_distance) / true_distance * 100
plt.scatter(angles, errors_before, color='blue', s=30)
plt.axhline(y=0, color='black', linestyle='-')
plt.xlabel('Угол наклона (рад)')
plt.ylabel('Ошибка (%)')
plt.title('Ошибка до коррекции (%)')
plt.grid(True, alpha=0.3)

# График 4: Ошибки после коррекции
plt.subplot(2, 2, 4)
errors_after_poly = (corrected_px_poly - true_distance) / true_distance * 100
errors_after_interp = (corrected_px_interp - true_distance) / true_distance * 100

plt.scatter(angles, errors_after_poly, alpha=0.6, label='Полиномиальная', color='red', s=30)
plt.scatter(angles, errors_after_interp, alpha=0.6, label='Интерполяция', color='green', s=30)
plt.axhline(y=0, color='black', linestyle='-')
plt.axhline(y=1, color='red', linestyle='--', alpha=0.5, label='±1%')
plt.axhline(y=-1, color='red', linestyle='--', alpha=0.5)
plt.xlabel('Угол наклона (рад)')
plt.ylabel('Ошибка (%)')
plt.title('Ошибка после коррекции (%)')
plt.legend()
plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.show()

# 6. ДЕТАЛЬНЫЙ АНАЛИЗ
print("=" * 70)
print("ПРАКТИЧЕСКАЯ КОРРЕКЦИЯ ДИСТОРСИИ - АНАЛИЗ РЕЗУЛЬТАТОВ")
print("=" * 70)

print(f"\nИСТИННОЕ РАССТОЯНИЕ (в центре): {true_distance:.3f} px")

print(f"\nДО КОРРЕКЦИИ:")
print(f"Стандартное отклонение: {np.std(measured_px):.3f} px")
print(f"Максимальная ошибка: {np.max(np.abs(measured_px - true_distance)):.3f} px")
print(f"Относительная ошибка: {np.std(measured_px)/true_distance*100:.2f}%")

print(f"\nПОСЛЕ ПОЛИНОМИАЛЬНОЙ КОРРЕКЦИИ:")
print(f"Стандартное отклонение: {np.std(corrected_px_poly):.3f} px")
print(f"Максимальная ошибка: {np.max(np.abs(corrected_px_poly - true_distance)):.3f} px")
print(f"Относительная ошибка: {np.std(corrected_px_poly)/true_distance*100:.2f}%")

print(f"\nПОСЛЕ ИНТЕРПОЛЯЦИОННОЙ КОРРЕКЦИИ:")
print(f"Стандартное отклонение: {np.std(corrected_px_interp):.3f} px")
print(f"Максимальная ошибка: {np.max(np.abs(corrected_px_interp - true_distance)):.3f} px")
print(f"Относительная ошибка: {np.std(corrected_px_interp)/true_distance*100:.2f}%")

# 7. ФУНКЦИЯ ДЛЯ ПРАКТИЧЕСКОГО ИСПОЛЬЗОВАНИЯ
def create_distortion_corrector(angles_calib, measurements_calib):
    """Создает функцию коррекции на основе калибровочных данных"""
    true_dist = np.median(measurements_calib[np.abs(angles_calib) < 0.1])
    interp_func = interp1d(angles_calib, true_dist/measurements_calib, 
                          kind='cubic', fill_value="extrapolate")
    
    def correct_measurement(angle, measured_px):
        correction = interp_func(angle)
        return measured_px * correction
    
    return correct_measurement, true_dist

# Создаем корректор
distortion_corrector, true_dist = create_distortion_corrector(angles, measured_px)

# Пример использования
test_angle = -0.5
test_measurement = 100.0
corrected_value = distortion_corrector(test_angle, test_measurement)

print(f"\nПРИМЕР КОРРЕКЦИИ:")
print(f"Угол: {test_angle:.2f} рад, Измерено: {test_measurement:.2f} px")
print(f"После коррекции: {corrected_value:.2f} px")
print(f"Ожидаемое: {true_dist:.2f} px")

# 8. ПРОВЕРКА ДОСТИЖЕНИЯ ЦЕЛЕВОЙ ТОЧНОСТИ
target_std_px = 2.0  # Целевая точность 2 пикселя

print(f"\nЦЕЛЕВАЯ ТОЧНОСТЬ: {target_std_px} px")
for method_name, corrected_data in [("Полином", corrected_px_poly), 
                                   ("Интерполяция", corrected_px_interp)]:
    std_dev = np.std(corrected_data)
    if std_dev <= target_std_px:
        print(f"✅ {method_name}: {std_dev:.3f} px - ЦЕЛЬ ДОСТИГНУТА")
    else:
        print(f"⚠️ {method_name}: {std_dev:.3f} px - цель не достигнута")

print(f"\nРЕКОМЕНДАЦИИ:")
print("1. Используйте интерполяционный метод для коррекции")
print("2. Для новых измерений используйте функцию distortion_corrector()")
print("3. Периодически перекалибруйте систему")
print("4. Рассмотрите использование более качественного объектива")