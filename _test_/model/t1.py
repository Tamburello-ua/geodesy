# Подгонка моделей к данным пользователя и вывод формул.

import numpy as np

import pandas as pd

import math

from caas_jupyter_tools import display_dataframe_to_user

import matplotlib.pyplot as plt



# Данные

d = np.array([20,40,60,80,100,120], dtype=float)   # см

p = np.array([817,410,268,203,162,134], dtype=float)  # пиксели



# Модель 1: p = k / d  (fit k by least squares on p ~ (1/d))

X = 1.0 / d

k_ls = np.sum(p * X) / np.sum(X * X)

p_pred_k = k_ls * X

d_pred_from_p_k = k_ls / p  # обратная формула d = k / p



# Модель 2: power law p = a * d^{-b}  => log p = log a - b log d

logd = np.log(d)

logp = np.log(p)

b_fit, loga_fit = np.polyfit(logd, logp, 1)  # gives slope and intercept for logp = slope*logd + intercept

# note slope = b_fit (should be negative), but logp = slope*logd + intercept -> p = exp(intercept) * d^{slope}

a_fit = math.exp(loga_fit)

b_fit = b_fit  # slope (negative)

p_pred_power = a_fit * d**(b_fit)

# обратная формула d = (p / a)^(1/b)

# careful: b is negative, so 1/b is negative — formula still works if used properly.

d_pred_from_p_power = (p / a_fit) ** (1.0 / b_fit)



# Оценка ошибок (RMSE по предсказанию расстояния d)

rmse_k = math.sqrt(np.mean((d - d_pred_from_p_k)**2))

rmse_power = math.sqrt(np.mean((d - d_pred_from_p_power)**2))



# Таблица с результатами

df = pd.DataFrame({

    "d_true_cm": d,

    "p_pixels": p,

    "p_pred_k_model": np.round(p_pred_k, 3),

    "p_pred_power_model": np.round(p_pred_power, 3),

    "d_pred_from_p_k_cm": np.round(d_pred_from_p_k, 3),

    "d_pred_from_p_power_cm": np.round(d_pred_from_p_power, 3),

    "error_d_k_cm": np.round(d - d_pred_from_p_k, 3),

    "error_d_power_cm": np.round(d - d_pred_from_p_power, 3),

})



display_dataframe_to_user("Подгонка моделей — таблица", df)



# Вывод формул и ошибок

print("Результаты подгонки:")

print(f"Модель 1 (обратная): p = k / d,  k = {k_ls:.6f}")

print(f"  => обратная формула: d = k / p")

print(f"  RMSE по d: {rmse_k:.4f} см")

print()

print("Модель 2 (степенная): p = a * d^{b_fit}, параметры:")

print(f"  a = {a_fit:.6f},  b = {b_fit:.6f}")

print(f"  => обратная формула: d = (p / a)^(1/b)")

print(f"  RMSE по d: {rmse_power:.4f} см")



# Построим график: точки и обе модели (p vs d)

plt.figure(figsize=(6,4))

plt.scatter(d, p, label="исходные (p vs d)")

d_grid = np.linspace(15,130,200)

plt.plot(d_grid, k_ls / d_grid, label="модель: p = k/d")

plt.plot(d_grid, a_fit * d_grid**(b_fit), label="модель: p = a * d^b")

plt.xlabel("d (см)")

plt.ylabel("p (пиксели)")

plt.legend()

plt.tight_layout()

plt.show()
