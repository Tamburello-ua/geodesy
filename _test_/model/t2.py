import numpy as np
import pandas as pd
import math
import matplotlib.pyplot as plt

# ==== ДАННЫЕ ====
# d — расстояние от камеры до цели (см)
# p — размер цели на изображении (пиксели)
d = np.array([20, 40, 60, 80, 100, 120], dtype=float)
p = np.array([817, 410, 268, 203, 162, 134], dtype=float)

# ==== МОДЕЛЬ 1: простая обратная зависимость p = k / d ====
X = 1.0 / d
k_ls = np.sum(p * X) / np.sum(X * X)

# Предсказания
p_pred_k = k_ls / d
d_pred_k = k_ls / p
rmse_k = math.sqrt(np.mean((d - d_pred_k) ** 2))

# ==== МОДЕЛЬ 2: степенная зависимость p = a * d^b ====
logd = np.log(d)
logp = np.log(p)
b_fit, loga_fit = np.polyfit(logd, logp, 1)  # logp = b*logd + loga
a_fit = math.exp(loga_fit)

# Предсказания и ошибки
p_pred_power = a_fit * d**b_fit
d_pred_power = (p / a_fit) ** (1 / b_fit)
rmse_power = math.sqrt(np.mean((d - d_pred_power) ** 2))

# ==== РЕЗУЛЬТАТЫ ====
print("=== Модель 1: p = k / d ===")
print(f"k = {k_ls:.6f}")
print(f"Формула пересчёта: d = {k_ls:.6f} / p")
print(f"RMSE по расстоянию: {rmse_k:.4f} см\n")

print("=== Модель 2: p = a * d^b ===")
print(f"a = {a_fit:.6f}, b = {b_fit:.6f}")
print(f"Формула пересчёта: d = (p / {a_fit:.6f}) ** (1 / {b_fit:.6f})")
print(f"RMSE по расстоянию: {rmse_power:.4f} см\n")

# ==== СРАВНИТЕЛЬНАЯ ТАБЛИЦА ====
df = pd.DataFrame({
    "d_истинное (см)": d,
    "p (пиксели)": p,
    "d_модель_1 (см)": np.round(d_pred_k, 2),
    "d_модель_2 (см)": np.round(d_pred_power, 2),
})
print(df)

# ==== ГРАФИК ====
plt.figure(figsize=(6, 4))
plt.scatter(d, p, label="данные", color="black")
d_grid = np.linspace(15, 130, 300)
plt.plot(d_grid, k_ls / d_grid, label="p = k/d")
plt.plot(d_grid, a_fit * d_grid**b_fit, label="p = a*d^b")
plt.xlabel("Расстояние, см")
plt.ylabel("Пиксели")
plt.legend()
plt.title("Зависимость размера объекта (в пикселях) от дистанции")
plt.grid(True)
plt.tight_layout()
plt.show()
